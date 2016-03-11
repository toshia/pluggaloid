# -*- coding: utf-8 -*-

require 'securerandom'

class Pluggaloid::ListenerTag
  # ==== Args
  # [name:] タグの名前(String | nil)
  def initialize(name: SecureRandom.uuid, plugin:)
    @name = name.to_s.freeze
    @plugin = plugin
  end

  def inspect
    "#<#{self.class} #{name.inspect} #{slug.inspect} has #{@listeners.size} listener(s).>"
  end
end
