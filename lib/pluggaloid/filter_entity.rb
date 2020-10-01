# frozen_string_literal: true

# Plugin.filteringで実行したフィルタのインスタンス
# 良い子はPlugin.filteringを使おう
class Pluggaloid::FilterEntity < Struct.new(:event_name, :args, :from, keyword_init: true)
  def fire(vm, srcs)
    catch(:filter_exit) do
      converted = vm.Event[event_name].filters.reduce(srcs) do |acm, event_filter|
        event_filter.filtering(*acm)
      end
      vm.call_filter_in_child_vm(self, converted)
    end
  end
end
