# frozen_string_literal: true

require 'bundler/setup'
require 'minitest/autorun'

require 'pluggaloid'
require_relative 'helper'

describe(Pluggaloid::Plugin) do
  include PluggaloidTestHelper

  it 'resume' do
    k = Class.new do
      include Pluggaloid::Mirage
    end
    a = k.new
    assert_equal(a, Pluggaloid::Mirage.unwrap(namespace: k.to_s, id: a.pluggaloid_mirage_id))
  end

  it 'custom mirage id' do
    k = Class.new do
      include Pluggaloid::Mirage

      def initialize(a)
        @a = a
      end

      def generate_pluggaloid_mirage_id
        @a.to_s
      end
    end

    a = k.new('same')
    b = k.new('differ')
    assert_equal('same', a.pluggaloid_mirage_id)
    assert_equal(a, Pluggaloid::Mirage.unwrap(namespace: k.to_s, id: a.pluggaloid_mirage_id))
    assert_equal('differ', b.pluggaloid_mirage_id)
    assert_equal(b, Pluggaloid::Mirage.unwrap(namespace: k.to_s, id: b.pluggaloid_mirage_id))
  end

  it 'not confuse other mirage classese' do
    definition = ->(*) do
      include Pluggaloid::Mirage

      def initialize(a)
        @a = a
      end

      def generate_pluggaloid_mirage_id
        @a.to_s
      end
    end

    k = Class.new(&definition)
    l = Class.new(&definition)

    a = k.new('same')
    b = l.new('same')
    c = l.new('differ')

    refute_equal(k.to_s, l.to_s)
    assert_equal('same', a.pluggaloid_mirage_id)
    assert_equal('same', b.pluggaloid_mirage_id)
    assert_equal('differ', c.pluggaloid_mirage_id)

    assert_equal(b, Pluggaloid::Mirage.unwrap(namespace: l.to_s, id: 'same'))
    assert_equal(c, Pluggaloid::Mirage.unwrap(namespace: l.to_s, id: 'differ'))
    assert_equal(a, Pluggaloid::Mirage.unwrap(namespace: k.to_s, id: 'same'))
    assert_raises(Pluggaloid::ArgumentError) { Pluggaloid::Mirage.unwrap(namespace: k.to_s, id: 'differ') }
  end

  it 'inherit class' do
    k = Class.new do
      include Pluggaloid::Mirage

      def initialize(a)
        @a = a
      end

      def generate_pluggaloid_mirage_id
        @a.to_s
      end
    end
    l = Class.new(k)

    a = k.new('same')
    b = l.new('same')
    c = l.new('differ')

    refute_equal(k.to_s, l.to_s)
    assert_equal('same', a.pluggaloid_mirage_id)
    assert_equal('same', b.pluggaloid_mirage_id)
    assert_equal('differ', c.pluggaloid_mirage_id)

    assert_equal(b, Pluggaloid::Mirage.unwrap(namespace: l.to_s, id: 'same'))
    assert_equal(c, Pluggaloid::Mirage.unwrap(namespace: l.to_s, id: 'differ'))
    assert_equal(a, Pluggaloid::Mirage.unwrap(namespace: k.to_s, id: 'same'))
    assert_raises(Pluggaloid::ArgumentError) { Pluggaloid::Mirage.unwrap(namespace: k.to_s, id: 'differ') }
  end

  it 'inherit before include mirage' do
    k = Class.new do
      def initialize(a)
        @a = a
      end

      def generate_pluggaloid_mirage_id
        @a.to_s
      end
    end
    l = Class.new(k)
    k.include Pluggaloid::Mirage

    a = k.new('same')
    b = l.new('same')
    c = l.new('differ')

    refute_equal(k.to_s, l.to_s)
    assert_equal('same', a.pluggaloid_mirage_id)
    assert_equal('same', b.pluggaloid_mirage_id)
    assert_equal('differ', c.pluggaloid_mirage_id)

    assert_equal(b, Pluggaloid::Mirage.unwrap(namespace: l.to_s, id: 'same'))
    assert_equal(c, Pluggaloid::Mirage.unwrap(namespace: l.to_s, id: 'differ'))
    assert_equal(a, Pluggaloid::Mirage.unwrap(namespace: k.to_s, id: 'same'))
    assert_raises(Pluggaloid::ArgumentError) { Pluggaloid::Mirage.unwrap(namespace: k.to_s, id: 'differ') }
  end

end
