# -*- coding: utf-8 -*-

class Pluggaloid::Listener
  # プラグインコールバックをこれ以上実行しない。
  def self.cancel!
    throw :plugin_exit, false end

  # ==== Args
  # [event] 監視するEventのインスタンス
  # [&callback] コールバック
  def initialize(event, &callback)
    raise Pluggaloid::TypeError, "Argument `event' must be instance of Pluggaloid::Event, but given #{event.class}." unless event.is_a? Pluggaloid::Event
    @event = event
    @callback = Proc.new
    event.add_listener(self) end

  # イベントを実行する
  # ==== Args
  # [*args] イベントの引数
  def call(*args)
    @callback.call(*args, &self.class.method(:cancel!)) end

  # このリスナを削除する
  # ==== Return
  # self
  def detach
    @event.delete_listener(self)
    self end
end
