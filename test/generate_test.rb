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

  describe 'event' do
    before do
      log = @log = []
      Pluggaloid::Plugin.create(:event) do
        defevent :list, prototype: [Integer, Pluggaloid::STREAM]

        generate(:list, 1) do |yielder|
          log << [:g1, :start]
          on_tick do |digit|
            log << [:g1, digit]
            yielder << digit
          end
        end
      end
    end

    it 'does not call generate block in not subscribed' do
      assert_equal([], @log)
    end

    it 'does not call generate block in subscribed other caller arguments' do
      Pluggaloid::Plugin.create(:event) do
        subscribe(:list, 2) {}
      end
      assert_equal([], @log)
    end

    describe 'after subscribe' do
      before do
        listener = nil
        Pluggaloid::Plugin.create(:event) do
          listener = subscribe(:list, 1) {}
        end
        @listener = listener
        eval_all_events
      end

      it 'call generate block' do
        assert_equal([[:g1, :start]], @log)
      end

      it 'call once generate block if subscribe twice' do
        Pluggaloid::Plugin.create(:event) do
          subscribe(:list, 1) {}
        end
        eval_all_events
        assert_equal([[:g1, :start]], @log)
      end

      describe 'detach all listeners' do
        before do
          Pluggaloid::Plugin.create(:event).detach(@listener)
          Pluggaloid::Plugin.call(:event, 1, [69])
          eval_all_events
        end

        it 'should detach handlers in generate block after unsubscribed' do
          assert_equal([[:g1, :start]], @log)
        end
      end

    end

    describe 'after add_event_listener' do
      before do
        listener = nil
        Pluggaloid::Plugin.create(:event) do
          listener = on_list { |_num, _lst| ; }
        end
        @listener = listener
        eval_all_events
      end

      it 'call generate block' do
        assert_equal([[:g1, :start]], @log)
      end

      it 'call once generate block if subscribe twice' do
        Pluggaloid::Plugin.create(:event) do
          on_list { |_num, _lst| ; }
        end
        eval_all_events
        assert_equal([[:g1, :start]], @log)
      end

      describe 'detach all listeners' do
        before do
          Pluggaloid::Plugin.create(:event).detach(@listener)
          Pluggaloid::Plugin.call(:event, 1, [105])
          eval_all_events
        end

        it 'detach handlers in generate block after unsubscribed' do
          assert_equal([[:g1, :start]], @log)
        end
      end

    end
  end

end
