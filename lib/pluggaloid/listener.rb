# -*- coding: utf-8 -*-
require 'securerandom'
require 'set'

class Pluggaloid::Listener < Pluggaloid::Handler
  # プラグインコールバックをこれ以上実行しない。
  def self.cancel!
    throw :plugin_exit, false end

  # ==== Args
  # [event] 監視するEventのインスタンス
  # [name:] 名前(String | nil)
  # [slug:] イベントリスナスラッグ(Symbol | nil)
  # [tags:] Pluggaloid::HandlerTag|Array リスナのタグ
  # [&callback] コールバック
  def initialize(event, **kwrest, &callback)
    super
    @callback = callback
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
