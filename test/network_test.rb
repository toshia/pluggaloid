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

    #       4 (00001110/1110)
    #     c   (00000110/110)
    #   8     (00000010/10)
    #     0   (00001010/010)
    # a       (00000000/0)
    #     6   (00001100/100)
    #   e     (00000100/00)
    #     2   (00001000/000)
    # ----
    #       5 (00001111/1111)
    #     d   (00000111/111)
    #   9     (00000011/11)
    #     1   (00001011/011)
    # b       (00000001/1)
    #     7   (00001101/101)
    #   f     (00000101/01)
    #     3   (00001001/001)
    describe 'network contains 16 nodes' do
      before do
        @vms = 16.times.map { |c| @klass.new(c) }
        @vms.each_cons(2) { |a, b| a.connect(b) }
      end

      it 'has 16 nodes in network' do
        @vms.each do |v|
          assert_equal 16, v.vm_map.size
        end
      end

      it 'depth of a' do
        assert_equal 0, @vms[0xa].depth_in(0xa)
      end

      it 'depth of 4' do
        assert_equal 3, @vms[4].depth_in(0xa)
      end
    end
  end

  it 'genus returns except me' do
    a = @klass.new(0)
    b = @klass.new(1)
    a.connect(b)
    assert_equal Set[b], a.genus
    assert_equal Set[a], b.genus
  end

  it 'raises in try connect across other network' do
    @n1 = 2.times.map { |c| @klass.new(c) }
    @n2 = 2.times.map { |c| @klass.new(c + 2) }
    @n1.each_cons(2) { |a, b| a.connect(b) }
    @n2.each_cons(2) { |a, b| a.connect(b) }
    assert_raises(RuntimeError) do
      @n1[0].connect(@n2[0])
    end
  end
end
