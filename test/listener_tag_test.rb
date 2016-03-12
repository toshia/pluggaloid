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
      a = b = c = tag_a = nil
      lst = @lst = []
      @plugin = @pluggaloid.Plugin.create :parent do
        a = on_a{ lst << :a }
        tag_a = listener_tag :pg
        b = on_b(tags: tag_a){ lst << :b }
        c = on_c(tags: tag_a){ lst << :c }
      end
      @a, @b, @c, @tag_a = a, b, c, tag_a
    end

    it 'plugin has 3 listeners' do
      assert_equal 3, @plugin.listeners.count
    end

    it 'listener a has no tag' do
      assert_empty @a.tags
    end

    it 'listener b has tag_a' do
      assert_equal Set.new([@tag_a]), @b.tags
    end

    it 'listener c has tag_a' do
      assert_equal Set.new([@tag_a]), @c.tags
    end

    describe 'detach tag' do
      before do
        @plugin.detach(@tag_a)
      end

      it 'should not call event in tag' do
        @pluggaloid.Event[:a].call
        @pluggaloid.Event[:b].call
        @pluggaloid.Event[:c].call
        eval_all_events(@pluggaloid.Delayer)
        assert_equal [:a], @lst
      end
    end

    describe 'each' do
      it 'should count of listeners and filters are 2' do
        assert_equal 2, @tag_a.count
      end

      it 'should count of listeners are 2' do
        assert_equal 2, @tag_a.listeners.count
      end

      it 'should there are no filters' do
        assert_equal 0, @tag_a.filters.count
      end
    end

  end
end
