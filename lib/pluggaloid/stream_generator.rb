# -*- coding: utf-8 -*-
require 'securerandom'
require 'set'

class Pluggaloid::StreamGenerator < Pluggaloid::Handler
  attr_reader :accepted_hash

  def initialize(event, *specs, plugin:, **kwrest, &callback)
    raise Pluggaloid::UndefinedStreamIndexError, 'To call generate(%{event}), it must define prototype arguments include `Pluggaloid::STREAM\'.' % {event: event.name} unless event.stream_index
    super(event, **kwrest)
    @callback = callback
    @specs = specs.freeze
    @accepted_hash = @event.argument_hash(specs, nil)
    @last_subscribe_state = @event.subscribe?(*@specs)
    @plugin = plugin
    subscribe_start if @last_subscribe_state
    @event.register_stream_generator(self)
  end

  def on_subscribed
    if !@last_subscribe_state
      @last_subscribe_state = true
      subscribe_start
    end
  end

  def on_unsubscribed
    subscribe_state = @event.subscribe_hash?(@accepted_hash)
    if @last_subscribe_state && !subscribe_state
      @last_subscribe_state = false
      subscribe_stop
    end
  end

  # このリスナを削除する
  # ==== Return
  # self
  def detach
    @event.delete_stream_generator(self)
    @yielder&.die
    @yielder = nil
    self
  end

  private

  def subscribe_start
    @tag = @plugin.handler_tag do
      @yielder = Yielder.new(@event, args: @specs)
      @callback.call(@yielder)
    end
  end

  def subscribe_stop
    @plugin.detach(@tag)
    @yielder.die
    @yielder = nil
  end

  class Yielder
    def initialize(event, args:)
      @event = event
      @args = args.freeze
      @alive = true
    end

    def bulk_add(lst)
      raise Pluggaloid::NoReceiverError, "All event listener of #{self.class} already detached." if die?
      args = @args.dup
      args.insert(@event.stream_index, lst)
      @event.call(*args)
    end

    def add(value)
      bulk_add([value])
    end
    alias_method :<<, :add

    def die?
      !@alive
    end

    def die
      @alive = false
      freeze
    end
  end
end
