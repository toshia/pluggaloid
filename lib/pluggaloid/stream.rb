# frozen_string_literal: true

module Pluggaloid
  class Stream
    include Enumerable

    def initialize(enumerator)
      @enumerator = enumerator
    end

    def throttle(sec)
      throttling = 0
      @enumerator.select do |item|
        r0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        if throttling <= r0
          throttling = r0 + sec
        end
      end
    end

    def debounce(sec)
      throttling_promise = nil
      Stream.new(
        Enumerator.new do |yielder|
          @enumerator.each do |item|
            throttling_promise&.cancel
            throttling_promise = Delayer.new(delay: sec) do
              yielder << item
            end
          end
        end.lazy
      )
    end

    def buffer(sec)
      throttling_promise = nil
      buffer = []
      Stream.new(
        Enumerator.new do |yielder|
          @enumerator.each do |item|
            buffer << item
            throttling_promise ||= Delayer.new(delay: sec) do
              yielder << buffer.freeze
              buffer = []
              throttling_promise = nil
            end
          end
        end.lazy
      )
    end

    def merge(*streams)
      Stream.new(Merge.new(self, *streams).lazy)
    end

    (Enumerator.instance_methods - Enumerator.superclass.instance_methods).each do |method_name|
      define_method(method_name) do |*rest, **kwrest, &block|
        if kwrest.empty?
          r = @enumerator.__send__(method_name, *rest, &block)
        else
          r = @enumerator.__send__(method_name, *rest, **kwrest, &block)
        end
        if r.is_a?(Enumerator::Lazy)
          Pluggaloid::Stream.new(r)
        else
          r
        end
      end
    end

    class Merge
      include Enumerable

      def initialize(*sources)
        @sources = sources
      end

      def each(&block)
        fiber = Fiber.new do
          loop do
            block.call(Fiber.yield)
          end
        end
        fiber.resume
        @sources.each do |source|
          source.each(&fiber.method(:resume))
        end
        self
      end
    end
  end
end
