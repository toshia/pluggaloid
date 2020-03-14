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

  it 'hoge' do
    refute Pluggaloid::Event[:tick].subscribe?
  end

  describe 'event' do
    before do
      log = @log = []
      listener = nil
      Pluggaloid::Plugin.create(:event) do
        defevent :list, prototype: [Integer, Pluggaloid::STREAM]

        generate(:list, 1) do |yielder|
          log << [:g1, :start]
          on_tick do |digit|
            log << [:g1, digit]
            yielder << digit
          end
        end

        listener = subscribe(:list, 1) do |stream|
          ;
        end
      end
      @listener = listener
      eval_all_events
    end

    it 'subscribed event which define in generate block' do
      assert Pluggaloid::Event[:tick].subscribe?
    end

    describe 'unsubscribe generate stream' do
      before do
        Pluggaloid::Plugin.create(:event).detach(@listener)
        eval_all_events
      end

      it 'unsubscribed event which define in generate block' do
        refute Pluggaloid::Event[:tick].subscribe?
      end
    end
  end
end
