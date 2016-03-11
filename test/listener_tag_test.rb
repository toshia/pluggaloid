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
  end
end
