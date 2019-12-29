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
      defevent :increase, prototype: [Integer, Pluggaloid::YIELD]
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

end
