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

  it 'call event in new vm' do
    vm_a = Pluggaloid.new(Delayer.generate_class(priority: %i[high normal low], default: :normal))
    vm_b = Pluggaloid.new(Delayer.generate_class(priority: %i[high normal low], default: :normal))
    foo = bar = false
    vm_a.Plugin.create(:foo_plugin) do
      on_foo do
        foo = true
      end
    end
    vm_b.Plugin.create(:bar_plugin) do
      on_bar do
        bar = true
      end
    end

    assert_equal(%i[foo_plugin], vm_a.Plugin.instances_name)
    assert_equal(%i[bar_plugin], vm_b.Plugin.instances_name)

    eval_all_events(vm_a.Delayer) do
      vm_a.Plugin.call(:foo)
      vm_a.Plugin.call(:bar)
    end
    assert foo, 'Event foo should be called'
    refute bar, 'Event bar should not be called'

    foo = bar = false
    eval_all_events(vm_b.Delayer) do
      vm_b.Plugin.call(:foo)
      vm_b.Plugin.call(:bar)
    end
    refute foo, 'Event foo should not be called'
    assert bar, 'Event bar should be called'
  end

  it 'calls receive on another vm' do
    vm_a = Pluggaloid.new(Delayer.generate_class(priority: %i[high normal low], default: :normal))
    vm_b = Pluggaloid.new(Delayer.generate_class(priority: %i[high normal low], default: :normal))
    foo = bar = false
    vm_a.Plugin.create(:foo_plugin) do
      on_foo do
        foo = true
      end
    end
    vm_b.Plugin.create(:bar_plugin) do
      on_bar do
        bar = true
      end
    end

    assert_equal(%i[foo_plugin], vm_a.Plugin.instances_name)
    assert_equal(%i[bar_plugin], vm_b.Plugin.instances_name)

    vm_a.connect(vm_b)

    eval_all_events(vm_a.Delayer) do
      vm_a.Plugin.call(:foo)
      vm_a.Plugin.call(:bar)
    end
    eval_all_events(vm_b.Delayer)
    assert foo, 'Event foo should be called'
    assert bar, 'Event bar should be called'

    foo = bar = false
    eval_all_events(vm_b.Delayer) do
      vm_b.Plugin.call(:foo)
      vm_b.Plugin.call(:bar)
    end
    eval_all_events(vm_a.Delayer)
    assert foo, 'Event foo should be called'
    assert bar, 'Event foo should be called'
  end
end
