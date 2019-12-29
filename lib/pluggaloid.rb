require "pluggaloid/version"
require "pluggaloid/plugin"
require 'pluggaloid/event'
require "pluggaloid/identity"
require "pluggaloid/handler"
require 'pluggaloid/listener'
require 'pluggaloid/filter'
require "pluggaloid/handler_tag"
require 'pluggaloid/error'

require 'delayer'

module Pluggaloid
  VM = Struct.new(*%i<Delayer Plugin Event Listener Filter HandlerTag>)

  class Yield; end
  YIELD = Yield.new.freeze

  def self.new(delayer)
    vm = VM.new(delayer,
                Class.new(Plugin),
                Class.new(Event),
                Class.new(Listener),
                Class.new(Filter),
                Class.new(HandlerTag))
    vm.Plugin.vm = vm.Event.vm = vm
  end
end
