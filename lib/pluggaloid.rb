require 'pluggaloid/network'
require "pluggaloid/version"
require 'pluggaloid/collection'
require "pluggaloid/plugin"
require 'pluggaloid/stream'
require 'pluggaloid/event_entity'
require 'pluggaloid/event'
require "pluggaloid/identity"
require "pluggaloid/handler"
require 'pluggaloid/listener'
require 'pluggaloid/subscriber'
require 'pluggaloid/filter'
require 'pluggaloid/stream_generator'
require "pluggaloid/handler_tag"
require 'pluggaloid/vm'
require 'pluggaloid/error'

require 'delayer'

module Pluggaloid

  class PrototypeStream; end
  class PrototypeCollect; end
  STREAM = PrototypeStream.new.freeze
  COLLECT = PrototypeCollect.new.freeze

  def self.new(delayer)
    VM.new(
      Delayer: delayer,
      Plugin: Class.new(Plugin),
      Event: Class.new(Event),
      Listener: Class.new(Listener),
      Filter: Class.new(Filter),
      HandlerTag: Class.new(HandlerTag),
      Subscriber: Class.new(Subscriber),
      StreamGenerator: Class.new(StreamGenerator)
    )
  end
end
