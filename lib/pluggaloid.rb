require "pluggaloid/version"
require "pluggaloid/plugin"
require 'pluggaloid/event'
require 'pluggaloid/listener'
require 'pluggaloid/filter'
require 'pluggaloid/error'

require 'delayer'

module Pluggaloid
  VM = Struct.new(*%i<Delayer Plugin Event Listener Filter>)

  def new(delayer)
    VM.new(delayer,
           Class.new(Plugin),
           Class.new(Event) do
             define_method :delayer do
               delayer end end,
           Class.new(Listener),
           Class.new(Filter)) end
end
