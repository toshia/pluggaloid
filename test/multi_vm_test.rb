# -*- coding: utf-8 -*-

require 'bundler/setup'
require 'minitest/autorun'

require 'pluggaloid'
require_relative 'helper'

describe(Pluggaloid) do
  include PluggaloidTestHelper

  before do
    Delayer.default = Delayer.generate_class(priority: %i[high normal low], default: :normal)
    Pluggaloid::Plugin.clear!
  end

  it 'should take new plugin classes' do
    pluggaloid = Pluggaloid.new(Delayer.default)
    assert_equal Delayer.default, pluggaloid.Delayer, ''
    assert_includes(pluggaloid.Plugin.ancestors, Pluggaloid::Plugin, 'Plugin should subbclass of Pluggaloid::Plugin')
    assert_includes(pluggaloid.Event.ancestors, Pluggaloid::Event, 'Event should subbclass of Pluggaloid::Event')
    assert_includes(pluggaloid.Listener.ancestors, Pluggaloid::Listener, 'Listener should subbclass of Pluggaloid::Listener')
    assert_includes(pluggaloid.Filter.ancestors, Pluggaloid::Filter, 'Filter should subbclass of Pluggaloid::Filter')
  end

  describe 'calls receive on another vm' do
    before do
      @vm_a = Pluggaloid.new(Delayer.generate_class(priority: %i[high normal low], default: :normal))
      @vm_b = Pluggaloid.new(Delayer.generate_class(priority: %i[high normal low], default: :normal))
      called = @called = Set.new
      @vm_a.Plugin.create(:foo_plugin) do
        on_foo do
          called << :foo_a
        end

        on_bar do
          called << :bar_a
        end

        on_filter_twice do |num|
          [num * 2]
        end

        on_filter_twice_a do |num|
          [num * 2]
        end
      end
      @vm_b.Plugin.create(:bar_plugin) do
        on_foo do
          called << :foo_b
        end

        on_bar do
          called << :bar_b
        end

        on_filter_twice do |num|
          [num * 2]
        end
      end
    end

    it 'assigned plugin' do
      assert_equal(%i[foo_plugin], @vm_a.Plugin.instances_name)
      assert_equal(%i[bar_plugin], @vm_b.Plugin.instances_name)
    end

    describe 'connect' do
      before do
        @vm_a.connect(@vm_b)
      end

      describe 'fire event in one-side' do
        before do
          eval_all_events(@vm_a.Delayer) do
            @vm_a.Plugin.call(:foo)
            @vm_a.Plugin.call(:bar)
          end
        end

        it 'event foo should be call in VM a' do
          assert @called.include?(:foo_a)
        end

        it 'event foo shouldn\'t be call in VM b' do
          refute @called.include?(:foo_b)
        end

        describe 'give tick counterpart' do
          before do
            eval_all_events(@vm_b.Delayer)
          end

          it 'event foo should be call in VM b' do
            assert @called.include?(:foo_b)
          end
        end
      end
    end                         # connected

    describe 'not connected' do
      describe 'fire event in one-side' do
        before do
          eval_all_events(@vm_a.Delayer) do
            @vm_a.Plugin.call(:foo)
            @vm_a.Plugin.call(:bar)
          end
        end

        it 'event foo should be call in VM a' do
          assert @called.include?(:foo_a)
        end

        it 'event foo shouldn\'t be call in VM b' do
          refute @called.include?(:foo_b)
        end

        describe 'give tick counterpart' do
          before do
            eval_all_events(@vm_b.Delayer)
          end

          it 'event foo shouldn\'t be call in VM b' do
            refute @called.include?(:foo_b)
          end
        end
      end
    end                         # not connected

  end
end
