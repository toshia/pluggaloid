# frozen_string_literal: true

module Pluggaloid
  class Subscriber
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

    (Enumerator.instance_methods - Enumerator.superclass.instance_methods).each do |method_name|
      define_method(method_name) do |*rest, **kwrest, &block|
        if kwrest.empty?
          r = @enumerator.__send__(method_name, *rest, &block)
        else
          r = @enumerator.__send__(method_name, *rest, **kwrest, &block)
        end
        if r.is_a?(Enumerator::Lazy)
          Subscriber.new(r)
        else
          r
        end
      end
    end
  end
end
