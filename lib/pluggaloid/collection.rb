# frozen_string_literal: true

module Pluggaloid
  class Collection
    attr_reader :values

    def initialize(event, *args)
      @event = event
      args[event.collect_index] = nil
      @args = args.freeze
      @spec = argument_hash(args)
      @values = [].freeze
    end

    def add(*v)
      rewind do |primitive|
        primitive + v
      end
    end
    alias_method :<<, :add

    def delete(*v)
      rewind do |primitive|
        primitive - v
      end
    end

    def rewind(&block)
      new_values = block.(@values.dup)
      added, deleted = new_values - @values, @values - new_values
      @values = new_values.freeze
      unless added.empty?
        args = @args.dup
        args[@event.collect_index] = added
        @event.collection_add_event.call(*args)
      end
      unless deleted.empty?
        args = @args.dup
        args[@event.collect_index] = deleted
        @event.collection_delete_event.call(*args)
      end
      self
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
