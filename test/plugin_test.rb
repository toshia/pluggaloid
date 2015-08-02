# -*- coding: utf-8 -*-

require 'bundler/setup'
require 'minitest/autorun'

require 'pluggaloid'

describe(Pluggaloid::Plugin) do
  before do
    Delayer.default = Delayer.generate_class(priority: %i<high normal low>, default: :normal)
    Pluggaloid::Plugin.clear!
  end

  def eval_all_events
    native = Thread.list
    yield if block_given?
    Delayer.run while not(Delayer.empty? and (Thread.list - native).empty?)
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
    filter_thread = nil
    Pluggaloid::Plugin.create(:event) do
      on_thread do
      end

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
      Pluggaloid::Event[:thread].call end
    assert filter_thread, "The filter doesn't run."
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

  it "unload hook" do
    value = 0
    Pluggaloid::Plugin.create(:unload) {
      on_unload {
        value += 2 }
      on_unload {
        value += 1 } }
    assert_equal(value, 0)
    Pluggaloid::Plugin.create(:unload).uninstall
    assert_equal(value, 3)
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
end
