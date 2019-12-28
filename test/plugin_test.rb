# -*- coding: utf-8 -*-

require 'bundler/setup'
require 'minitest/autorun'

require 'pluggaloid'
require_relative 'helper'

describe(Pluggaloid::Plugin) do
  include PluggaloidTestHelper

  before do
    Delayer.default = Delayer.generate_class(priority: %i<high normal low>, default: :normal)
    Pluggaloid::Plugin.clear!
  end

  it "fire and filtering event, receive a plugin" do
    sum = 0
    Pluggaloid::Plugin.create(:event) do
      on_increase do |v|
        sum += v end

      filter_increase do |v|
        [v * 2] end end
    eval_all_events do
      Pluggaloid::Event[:increase].call(1) end
    assert_equal(2, sum)
  end

  it "filter in another thread" do
    success = filter_thread = nil
    Pluggaloid::Plugin.create(:event) do
      on_thread do
      end

      on_unhandled do
        success = true end

      filter_thread do
        filter_thread = Thread.current
        [] end end
    eval_all_events do
      Pluggaloid::Event[:thread].call end
    assert filter_thread
    assert_equal Thread.current, filter_thread

    Pluggaloid::Event.filter_another_thread = true
    filter_thread = nil
    eval_all_events do
      Pluggaloid::Event[:thread].call
      Pluggaloid::Event[:unhandled].call end
    assert filter_thread, "The filter doesn't run."
    assert success, "Event :unhandled doesn't run."
    refute_equal Thread.current, filter_thread, 'The filter should execute in not a main thread'
  end

  it "uninstall" do
    sum = 0
    Pluggaloid::Plugin.create(:event) do
      on_increase do |v|
        sum += v end
      filter_increase do |v|
        [v * 2] end end
    eval_all_events do
      Pluggaloid::Plugin.create(:event).uninstall
      Pluggaloid::Event[:increase].call(1) end
    assert_equal(0, sum)
  end

  it "detach" do
    sum = 0
    event = filter = nil
    Pluggaloid::Plugin.create(:event) do
      event = on_increase do |v|
        sum += v end
      filter = filter_increase do |v|
        [v * 2] end end
    eval_all_events do
      Pluggaloid::Event[:increase].call(1) end
    assert_equal(2, sum, "It should execute filter when event called")

    eval_all_events do
      Pluggaloid::Plugin[:event].detach filter
      Pluggaloid::Event[:increase].call(1) end
    assert_equal(3, sum, "It should not execute detached filter when event called")

    eval_all_events do
      Pluggaloid::Plugin.create(:event).detach event
      Pluggaloid::Event[:increase].call(1) end
    assert_equal(3, sum, "It should not executed detached event")
  end

  it "get plugin list" do
    assert_empty(Pluggaloid::Plugin.plugin_list, "Plugin list must empty in first time")
    Pluggaloid::Plugin.create(:plugin_0)
    assert_equal(%i<plugin_0>, Pluggaloid::Plugin.plugin_list, "The new plugin should appear plugin list")
    Pluggaloid::Plugin.create(:plugin_1)
    assert_equal(%i<plugin_0 plugin_1>, Pluggaloid::Plugin.plugin_list, "The new plugin should appear plugin list")
  end

  it "dsl method defevent" do
    Pluggaloid::Plugin.create :defevent do
      defevent :increase, prototype: [Integer] end
    assert_equal([Integer], Pluggaloid::Event[:increase].options[:prototype])
    assert_equal(Pluggaloid::Plugin[:defevent], Pluggaloid::Event[:increase].options[:plugin])
  end

  describe "unload hook" do
    before do
      @value = value = []
      Pluggaloid::Plugin.create(:temporary) {
        on_unload {
          value << 2 }
        on_unload {
          value << 1 } }
      Pluggaloid::Plugin.create(:eternal) {
        on_unload {
          raise "try to unload eternal plugin" } }
    end

    it 'should not call unload event it is not unload' do
      assert_empty(@value)
    end

    describe 'unload temporary plugin' do
      before do
        eval_all_events do
          Pluggaloid::Plugin.create(:temporary).uninstall
        end
      end

      it 'was called unload hooks' do
        assert_equal([1, 2].sort, @value.sort)
      end
    end
  end

  describe "defdsl" do
    it "simple dsl" do
      Pluggaloid::Plugin.create :dsl_def do
        defdsl :twice do |number|
          number * 2 end end

      dsl_use = Pluggaloid::Plugin[:dsl_use]
      assert_equal(4, dsl_use.twice(2))
      assert_equal(0, dsl_use.twice(0))
      assert_equal(-26, dsl_use.twice(-13))
    end

    it "callback dsl" do
      Pluggaloid::Plugin.create :dsl_def do
        defdsl :rejector do |value, &condition|
          value.reject(&condition) end end

      dsl_use = Pluggaloid::Plugin.create(:dsl_use)
      assert_equal([2, 4, 6], dsl_use.rejector(1..6){ |d| 0 != (d & 1) })
    end
  end

  it 'raises NoDefaultDelayerError if Delayer do not have default delayer' do
    Delayer.default = nil
    Pluggaloid::Plugin.clear!
    assert_raises(Pluggaloid::NoDefaultDelayerError) do
      Pluggaloid::Plugin.create(:raises) do
        on_no_default_delayer_error do; end end end
  end

  describe "named listener" do
    it 'raises when duplicate slug registered to equally events' do
      assert_raises(Pluggaloid::DuplicateListenerSlugError) do
        Pluggaloid::Plugin.create :duplicate_slug do
          on_a(slug: :duplicate){}
          on_a(slug: :duplicate){}
        end
      end
    end

    it 'was not raises when duplicate slug registered to another events' do
      Pluggaloid::Plugin.create :duplicate_slug do
        on_a(slug: :duplicate){}
        on_b(slug: :duplicate){}
      end
    end

    it 'successful when dupliacte name registered to another events' do
      a = b = nil
      Pluggaloid::Plugin.create :duplicate_name do
        a = on_a(name: "duplicate"){}
        b = on_b(name: "duplicate"){}
      end
      assert_equal("duplicate", a.name, 'a.name should be "duplicate"')
      assert_equal("duplicate", b.name, 'b.name should be "duplicate"')
    end

    it 'include listener slug and name in Pluggaloid::Listener#inspect' do
      a = nil
      Pluggaloid::Plugin.create :inspect do
        a = on_a(slug: :inspect_slug, name: "inspect name"){}
      end
      assert(a.inspect.include?("inspect_slug"), 'Pluggaloid::Listener.inspect does not include slug')
      assert(a.inspect.include?("inspect name"), 'Pluggaloid::Listener.inspect does not include name')
    end
  end

  it 'call undefined method in plugin context' do
    assert_raises(NameError) do
      Pluggaloid::Plugin.create(:raises) do
        undefined_call
      end
    end
  end

end
