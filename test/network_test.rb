# frozen_string_literal: true
require 'bundler/setup'
require 'minitest/autorun'

require 'pluggaloid'
require_relative 'helper'
require 'pry'

describe(Pluggaloid::Network) do
  before do
    @klass = Class.new(Struct.new(:vmid)) do
      include Pluggaloid::Network
    end
  end

  describe 'children' do
    it 'lonely network' do
      a = @klass.new(42)
      assert_empty(a.children(42))
    end

    it 'network contains 2 nodes' do
      a = @klass.new(0b00)
      b = @klass.new(0b10)
      a.connect(b)
      assert_equal [b], a.children(0)
      assert_equal [a], b.children(2)
    end

    it 'network contains 16 nodes' do
      vms = 16.times.map { |c| @klass.new(c) }
      vms.each_cons(2) { |a, b| a.connect(b) }
      assert_equal 16, vms[0].vm_map.size
    end

    it 'network contains 16 nodes 5' do
      vms = 32.times.map { |c| @klass.new(c**3) }
      vms.each_cons(2) { |a, b| a.connect(b) }
      puts ''
      vms[0].render_tree
      #assert_equal 16, vms[0].vm_map.size
    end

  end

  it 'genus returns except me' do
    a = @klass.new(0)
    b = @klass.new(1)
    a.connect(b)
    assert_equal Set[b], a.genus
    assert_equal Set[a], b.genus
  end
end
