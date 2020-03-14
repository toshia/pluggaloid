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

  it "subscribe" do
    sum = []

    Pluggaloid::Plugin.create(:event) do
      defevent :increase, prototype: [Integer, Pluggaloid::STREAM]
      subscribe(:increase, 1) do |v|
        sum = v
      end
    end

    eval_all_events do
      Pluggaloid::Event[:increase].call(1, [:one])
      Pluggaloid::Event[:increase].call(2, [:two])
    end

    assert_equal(%i[one], sum)
  end

  it "subscribe 2" do
    sum = []

    Pluggaloid::Plugin.create(:event) do
      defevent :increase, prototype: [Pluggaloid::STREAM, Integer]
      subscribe(:increase, 1) do |v|
        sum = v
      end
    end

    eval_all_events do
      Pluggaloid::Event[:increase].call([:one], 1)
      Pluggaloid::Event[:increase].call([:two], 2)
    end

    assert_equal(%i[one], sum)
  end

  it "raises subscribe without definition" do
    assert_raises Pluggaloid::UndefinedStreamIndexError do
      Pluggaloid::Plugin.create(:event) do
        subscribe(:increase, 1) { ; }
      end
    end
  end

  it "subscribe? first value" do
    Pluggaloid::Plugin.create(:event) do
      defevent :increase, prototype: [Integer, Pluggaloid::STREAM]
      subscribe(:increase, 1) do |v|
      end
    end
    assert(Pluggaloid::Plugin[:event].subscribe?(:increase, 1))
    refute(Pluggaloid::Plugin[:event].subscribe?(:increase, 2))
  end

  it "subscribe? last value" do
    Pluggaloid::Plugin.create(:event) do
      defevent :increase, prototype: [Pluggaloid::STREAM, Integer]
      subscribe(:increase, 1) do |v|
      end
    end
    assert(Pluggaloid::Plugin[:event].subscribe?(:increase, 1))
    refute(Pluggaloid::Plugin[:event].subscribe?(:increase, 2))
  end

  it "subscribe? returns always true if plugin listener exist" do
    Pluggaloid::Plugin.create(:event) do
      defevent :increase, prototype: [Integer, Pluggaloid::STREAM]
      on_increase do |i, y|
      end
    end
    assert(Pluggaloid::Plugin[:event].subscribe?(:increase, 1))
    assert(Pluggaloid::Plugin[:event].subscribe?(:increase, 2))
  end

  it "subscribe enumerable" do
    sum = []

    Pluggaloid::Plugin.create(:event) do
      defevent :increase, prototype: [Integer, Pluggaloid::STREAM]
      subscribe(:increase, 1).each do |v|
        sum = v
      end
    end

    eval_all_events do
      Pluggaloid::Event[:increase].call(1, [:one])
      Pluggaloid::Event[:increase].call(2, [:two])
    end

    assert_equal(:one, sum)
  end

  it "detach" do
    sum = 0
    subscriber = nil
    Pluggaloid::Plugin.create(:event) do
      defevent :increase, prototype: [Pluggaloid::STREAM]
      subscriber = subscribe(:increase) do |v|
        sum += v
      end
    end
    eval_all_events do
      Pluggaloid::Event[:increase].call(1)
    end
    assert_equal(1, sum, "It should execute subscriber when event called")

    eval_all_events do
      Pluggaloid::Plugin[:event].detach subscriber
      Pluggaloid::Event[:increase].call(1)
    end
    assert_equal(1, sum, "It should not execute detached subscriber when event called")
  end

  it "subscribe enumerable chain" do
    sum = []

    Pluggaloid::Plugin.create(:event) do
      defevent :increase, prototype: [Integer, Pluggaloid::STREAM]
      subscribe(:increase, 1).map{|v| v.to_s }.each do |v|
        sum << v
      end
    end

    eval_all_events do
      Pluggaloid::Event[:increase].call(1, [:one])
      Pluggaloid::Event[:increase].call(2, [:two])
      Pluggaloid::Event[:increase].call(1, [:three])
    end

    assert_equal(%w[one three], sum)
  end

  it "subscribe each_slice" do
    sum = []

    Pluggaloid::Plugin.create(:event) do
      defevent :increase, prototype: [Integer, Pluggaloid::STREAM]
      subscribe(:increase, 1).each_slice(3).each do |v|
        sum << v
      end
    end

    eval_all_events do
      Pluggaloid::Event[:increase].call(1, 100.times)
    end

    assert_equal([0, 1, 2], sum.first)
    assert_equal([96, 97, 98], sum.last)
    assert_equal(33, sum.size)

    eval_all_events do
      Pluggaloid::Event[:increase].call(1, [100, 101])
    end

    assert_equal([99, 100, 101], sum.last)
    assert_equal(34, sum.size)
  end

  it "throttle" do
    sum = []

    Pluggaloid::Plugin.create(:event) do
      defevent :increase, prototype: [Integer, Pluggaloid::STREAM]
      subscribe(:increase, 1).throttle(0.001).each do |v|
        sum << v
      end
    end

    eval_all_events do
      Pluggaloid::Event[:increase].call(1, (1..10).to_a)
      Pluggaloid::Event[:increase].call(1, (11..20).to_a)
    end

    assert_equal(1, sum.last)
    assert_equal(1, sum.size)

    sleep 0.01

    eval_all_events do
      Pluggaloid::Event[:increase].call(1, (21..30).to_a)
    end

    assert_equal(21, sum.last)
    assert_equal(2, sum.size)
  end

  it "debounce" do
    sum = []

    Pluggaloid::Plugin.create(:event) do
      defevent :increase, prototype: [Integer, Pluggaloid::STREAM]
      subscribe(:increase, 1).debounce(0.01).each do |v|
        sum << v
      end
    end

    eval_all_events do
      Pluggaloid::Event[:increase].call(1, (1..10).to_a)
      Pluggaloid::Event[:increase].call(1, (11..20).to_a)
    end

    assert_equal(0, sum.size)

    sleep 0.02
    Delayer.run

    assert_equal(1, sum.size)
    assert_equal(20, sum.last)
  end

  it "buffer" do
    sum = []

    Pluggaloid::Plugin.create(:event) do
      defevent :increase, prototype: [Integer, Pluggaloid::STREAM]
      subscribe(:increase, 1).buffer(0.01).each do |v|
        sum << v
      end
    end

    eval_all_events do
      Pluggaloid::Event[:increase].call(1, (1..10).to_a)
      Pluggaloid::Event[:increase].call(1, (11..20).to_a)
    end

    assert_equal(0, sum.size)

    sleep 0.1
    Delayer.run
    Pluggaloid::Event[:increase].call(1, [21])
    Delayer.run

    assert_equal(1, sum.size)
    assert_equal((1..20).to_a, sum.last)
  end

  it "merge" do
    sum = sum1 = sum2 = 0
    Pluggaloid::Plugin.create(:event) do
      defevent :increase, prototype: [Integer, Pluggaloid::STREAM]
      subscribe(:increase, 1).each do |v|
        sum1 += v
      end

      subscribe(:increase, 2).each do |v|
        sum2 += v
      end

      subscribe(:increase, 1).merge(subscribe(:increase, 2)).each do |v|
        sum += v
      end
    end

    eval_all_events do
      Pluggaloid::Event[:increase].call(1, (1..10).to_a)
      Pluggaloid::Event[:increase].call(2, (11..20).to_a)
    end

    assert_equal((1..10).to_a.sum, sum1)
    assert_equal((11..20).to_a.sum, sum2)
    assert_equal((1..20).to_a.sum, sum)
  end
end
