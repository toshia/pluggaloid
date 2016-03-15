require "pluggaloid/version"
require "pluggaloid/plugin"
require 'pluggaloid/event'
require "pluggaloid/handler"
require 'pluggaloid/listener'
require 'pluggaloid/filter'
require "pluggaloid/listener_tag"
require 'pluggaloid/error'

require 'delayer'

module Pluggaloid
  VM = Struct.new(*%i<Delayer Plugin Event Listener Filter ListenerTag>)

  def self.new(delayer)
    vm = VM.new(delayer,
                Class.new(Plugin),
                Class.new(Event),
                Class.new(Listener),
                Class.new(Filter),
                Class.new(ListenerTag))
    vm.Plugin.vm = vm.Event.vm = vm
  end
end
