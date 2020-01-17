# frozen_string_literal: true

module Pluggaloid
  class Collection
    attr_reader :values

    def initialize(event, *specs)
      @event = event
      @spec = argument_hash(specs)
      @values = [].freeze
    end

    def add(*v)
      rewind do |privitive|
        privitive + v
      end
      self
    end
    alias_method :<<, :add

    def delete(*v)
      rewind do |privitive|
        privitive - v
      end
      self
    end

    def rewind(&block)
      new_values = block.(@values.dup)
      @values = new_values.freeze
    end

    def argument_hash_same?(specs)
      @spec == argument_hash(specs)
    end

    private

    def argument_hash(specs)
      @event.argument_hash(specs, @event.collect_index)
    end
  end
end
