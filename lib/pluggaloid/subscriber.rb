# -*- coding: utf-8 -*-
require 'securerandom'
require 'set'

class Pluggaloid::Subscriber < Pluggaloid::Handler
  attr_reader :accepted_hash

  # ==== Args
  # [event] 監視するEventのインスタンス
  # [name:] 名前(String | nil)
  # [slug:] イベントリスナスラッグ(Symbol | nil)
  # [tags:] Pluggaloid::HandlerTag|Array リスナのタグ
  # [&callback] コールバック
  def initialize(event, *specs, **kwrest, &callback)
    super(event, **kwrest)
    @callback = callback
    @accepted_hash = @event.argument_hash(specs)
    event.add_listener(self)
  end

  # イベントを実行する
  # ==== Args
  # [stream] イベントの引数
  def call(*args)
    @callback.call(args[@event.yield_index])
  end

  # このリスナを削除する
  # ==== Return
  # self
  def detach
    @event.delete_listener(self)
    self
  end
end
