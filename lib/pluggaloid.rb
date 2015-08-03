require "pluggaloid/version"
require "pluggaloid/plugin"
require 'pluggaloid/event'
require 'pluggaloid/listener'
require 'pluggaloid/filter'
require 'pluggaloid/error'

require 'delayer'

module Pluggaloid
  VM = Struct.new(*%i<Delayer Plugin Event Listener Filter>)

  def self.new(delayer)
    vm = VM.new(delayer,
                Class.new(Plugin),
                Class.new(Event),
                Class.new(Listener),
                Class.new(Filter))
    vm.Plugin.vm = vm.Event.vm = vm
  end
end
