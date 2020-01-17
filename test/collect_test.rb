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

  describe 'collection' do
    it 'add' do
      Pluggaloid::Plugin.create(:event) do
        defevent :list, prototype: [Integer, Pluggaloid::COLLECT]
        defevent :insert, prototype: [Pluggaloid::STREAM]

        collection(:list, 3) do |collector|
          subscribe(:insert).each do |i|
            collector.add(i * 3)
          end
        end
      end
      eval_all_events do
        Pluggaloid::Event[:insert].call([2, 5])
      end
      assert_equal([6, 15], Pluggaloid::Event[:list].collect(3).to_a)
    end

    it 'delete' do
      Pluggaloid::Plugin.create(:event) do
        defevent :list, prototype: [Integer, Pluggaloid::COLLECT]
        defevent :destroy, prototype: [Pluggaloid::STREAM]

        collection(:list, 3) do |collector|
          collector << 1 << 2 << 3
          subscribe(:destroy).each do |i|
            collector.delete(i)
          end
        end
      end
      eval_all_events do
        Pluggaloid::Event[:destroy].call([2, 4])
      end
      assert_equal([1, 3], Pluggaloid::Event[:list].collect(3).to_a)
    end
  end

end
