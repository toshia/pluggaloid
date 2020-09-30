# frozen_string_literal: true

# Plugin.callで発生させたイベントのインスタンス。
# 良い子はPlugin.callを使おう
class Pluggaloid::EventEntity < Struct.new(:event_name, :args, :from, keyword_init: true)
  def fire(vm)
    vm.call_event_in_child_vm(self)
    event = vm.Event[event_name]
    if event.class.filter_another_thread
      if event.filters.empty?
        vm.Delayer.new(*Array(event.priority)) do
          event.call_all_listeners(self.args)
        end
      else
        Thread.new do
          filtered_args = event.filtering(*self.args)
          if filtered_args.is_a? Array
            vm.Delayer.new(*Array(event.priority)) do
              event.call_all_listeners(filtered_args)
            end
          end
        end
      end
    else
      vm.Delayer.new(*Array(event.priority)) do
        args = self.args
        args = event.filtering(*args) unless event.filters.empty?
        event.call_all_listeners(args) if args.is_a? Array
      end
    end
    nil
  end
end
