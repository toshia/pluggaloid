# frozen_string_literal: true

require 'set'

module Pluggaloid
  class VM < Struct.new(*%i[Delayer Plugin Event Listener Filter HandlerTag Subscriber StreamGenerator], keyword_init: true)
    include Pluggaloid::Network

    attr_reader :vmid

    def initialize(*)
      super
      @vm_map = Set[self]
      @vmid = SecureRandom.random_number(1 << 64)
      self.Plugin.vm = self.Event.vm = self
    end

    def call_event_in_child_vm(event_entity)
      children(event_entity.from.vmid).each do |vm|
        event_entity.fire(vm)
      end
      if event_entity.from == self && counterpart
        event_entity.fire(counterpart)
      end
    end

    def call_filter_in_child_vm(filter_entity, srcs)
      converted = children(filter_entity.from.vmid).reduce(srcs) do |args, vm|
        filter_entity.fire(vm, args)
      end
      if filter_entity.from == self && counterpart
        filter_entity.fire(counterpart, converted)
      else
        converted
      end
    end
  end
end
