require "pluggaloid/version"
require 'pluggaloid/collection'
require "pluggaloid/plugin"
require 'pluggaloid/stream'
require 'pluggaloid/event'
require "pluggaloid/identity"
require "pluggaloid/handler"
require 'pluggaloid/listener'
require 'pluggaloid/subscriber'
require 'pluggaloid/filter'
require 'pluggaloid/stream_generator'
require "pluggaloid/handler_tag"
require 'pluggaloid/mirage'
require 'pluggaloid/error'

require 'delayer'

module Pluggaloid
  VM = Struct.new(*%i<Delayer Plugin Event Listener Filter HandlerTag Subscriber StreamGenerator>, keyword_init: true)

  class PrototypeStream; end
  class PrototypeCollect; end
  STREAM = PrototypeStream.new.freeze
  COLLECT = PrototypeCollect.new.freeze

  def self.new(delayer)
    vm = VM.new(Delayer: delayer,
                Plugin: Class.new(Plugin),
                Event: Class.new(Event),
                Listener: Class.new(Listener),
                Filter: Class.new(Filter),
                HandlerTag: Class.new(HandlerTag),
                Subscriber: Class.new(Subscriber),
                StreamGenerator: Class.new(StreamGenerator))
    vm.Plugin.vm = vm.Event.vm = vm
  end
end
