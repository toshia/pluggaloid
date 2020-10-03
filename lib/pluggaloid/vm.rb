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
      next_nodes(event_entity.from.vmid).each do |vm|
        event_entity.fire(vm)
      end
    end

    def call_filter_in_child_vm(filter_entity, srcs)
      next_nodes(filter_entity.from.vmid).reduce(srcs) do |args, vm|
        filter_entity.fire(vm, args)
      end
    end

    def filtered_in_vm?(event_name)
      !self.Event[event_name].filters.empty?
    end

    # イベント名 _event_name_ が、ネットワーク上の何処かでフィルタされているなら真を返す
    def filtered_in_network?(event_name, root_id = vmid)
      filtered_in_vm?(event_name) || next_nodes(root_id).any? do |vm|
        vm.filtered_in_network?(event_name, root_id)
      end
    end
  end
end
