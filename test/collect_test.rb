# frozen_string_literal: true

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

  it 'collect' do
    Pluggaloid::Plugin.create(:event) do
      defevent :list, prototype: [Integer, Pluggaloid::COLLECT]

      filter_list do |i, yielder|
        i.times(&yielder.method(:<<))
        [i, yielder]
      end
    end

    assert_equal([0, 1, 2], Pluggaloid::Event[:list].collect(3).to_a)
  end
end
