# -*- coding: utf-8 -*-
require 'bundler/setup'
require 'minitest/autorun'

require 'pluggaloid'
require_relative 'helper'

describe(Pluggaloid::ListenerTag) do
  include PluggaloidTestHelper

  before do
    Delayer.default = Delayer.generate_class(priority: %i<high normal low>, default: :normal)
    Pluggaloid::Plugin.clear!
    @pluggaloid = Pluggaloid.new(Delayer.default)
  end

  describe 'plugin tag' do
    before do
      a = b = c = d = fd = tag_a = tag_b = tag_c = nil
      lst = @lst = []
      @plugin = @pluggaloid.Plugin.create :parent do
        a = on_a{ lst << :a }
        tag_a = listener_tag :tag_a
        tag_b = listener_tag :tag_b
        tag_c = listener_tag :tag_c
        b = on_b(tags: tag_a){ lst << :b }
        c = on_c(tags: [tag_a, tag_b]){ lst << :c }
        d = on_d(tags: tag_b){ lst << :d }
        fd = filter_d(tags: tag_c){|&stop| stop.call }
      end
      @a, @b, @c, @d, @fd, @tag_a, @tag_b, @tag_c = a, b, c, d, fd, tag_a, tag_b, tag_c
    end

    it 'plugin has 4 listeners' do
      assert_equal 4, @plugin.listeners.count
    end

    it 'listener a has no tag' do
      assert_empty @a.tags
    end

    it 'listener b has tag_a' do
      assert_equal Set.new([@tag_a]), @b.tags
    end

    it 'listener c has tag_a and tag_b' do
      assert_equal Set.new([@tag_a, @tag_b]), @c.tags
    end

    it 'listener d has tag_b' do
      assert_equal Set.new([@tag_b]), @d.tags
    end

    it 'filter fd has tag_c' do
      assert_equal Set.new([@tag_c]), @fd.tags
    end

    describe 'detach tag_a' do
      before do
        @plugin.detach(@tag_a)
        @pluggaloid.Event[:a].call
        @pluggaloid.Event[:b].call
        @pluggaloid.Event[:c].call
        eval_all_events(@pluggaloid.Delayer)
      end

      it 'should not call event in tag' do
        assert_equal [:a], @lst
      end
    end

    describe 'detach tag_c' do
      before do
        @pluggaloid.Event[:a].call
        @pluggaloid.Event[:b].call
        @pluggaloid.Event[:c].call
        @pluggaloid.Event[:d].call
      end

      describe 'detach' do
        before do
          @plugin.detach(@tag_c)
          eval_all_events(@pluggaloid.Delayer)
        end

        it 'should not call filter' do
          assert_equal [:a, :b, :c, :d], @lst
        end
      end

      describe 'does not detach' do
        before do
          eval_all_events(@pluggaloid.Delayer)
        end

        it 'should call filter' do
          assert_equal [:a, :b, :c], @lst
        end
      end
    end

    describe 'each' do
      it 'should count of listeners and filters are 2' do
        assert_equal 2, @tag_a.count
      end

      it 'should count of listeners are 2 in tag_a' do
        assert_equal 2, @tag_a.listeners.count
      end

      it 'should there are no filter in tag_a' do
        assert_equal 0, @tag_a.filters.count
      end

      it 'should count of listeners are 2 in tag_b' do
        assert_equal 2, @tag_b.listeners.count
      end

      it 'should there are no filter in tag_b' do
        assert_equal 0, @tag_b.filters.count
      end

      it 'should there are no listener in tag_c' do
        assert_equal 0, @tag_c.listeners.count
      end

      it 'should has one filter in tag_c' do
        assert_equal 1, @tag_c.filters.count
      end
    end

  end
end
