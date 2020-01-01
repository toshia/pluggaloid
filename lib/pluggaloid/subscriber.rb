# -*- coding: utf-8 -*-
require 'securerandom'
require 'set'

class Pluggaloid::Subscriber < Pluggaloid::Handler
  attr_reader :accepted_hash

  include Enumerable

  # ==== Args
  # [event] 監視するEventのインスタンス
  # [name:] 名前(String | nil)
  # [slug:] イベントリスナスラッグ(Symbol | nil)
  # [tags:] Pluggaloid::HandlerTag|Array リスナのタグ
  # [&callback] コールバック
  def initialize(event, *specs, **kwrest, &callback)
    super(event, **kwrest)
    @callback = callback
    @accepted_hash = @event.argument_hash(specs)
    event.add_listener(self)
  end

  def each(event_name, &block)
    @callback = ->(stream) do
      block.call(stream)
    end
  end

  # イベントを実行する
  # ==== Args
  # [stream] イベントの引数
  def call(*args)
    @callback.call(args[@event.yield_index])
  end

  # このリスナを削除する
  # ==== Return
  # self
  def detach
    @event.delete_listener(self)
    self
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
    Enumerator.new do |yielder|
      @enumerator.each do |item|
        throttling_promise&.cancel
        throttling_promise = Delayer.new(delay: sec) do
          yielder << item
        end
      end
    end.lazy
  end

  def buffer(sec)
    throttling_promise = nil
    buffer = []
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
  end

  (Enumerator.instance_methods - Enumerator.superclass.instance_methods).each do |method_name|
    define_method(method_name) do |*rest, **kwrest, &block|
      if kwrest.empty?
        r = @enumerator.__send__(method_name, *rest, &block)
      else
        r = @enumerator.__send__(method_name, *rest, **kwrest, &block)
      end
      if r.is_a?(Enumerator::Lazy)
        Stream.new(r)
      else
        r
      end
    end
  end
end
