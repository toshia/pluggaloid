# -*- coding: utf-8 -*-
require 'securerandom'
require 'set'

class Pluggaloid::Listener
  attr_reader :name, :slug, :tags

  # プラグインコールバックをこれ以上実行しない。
  def self.cancel!
    throw :plugin_exit, false end

  # ==== Args
  # [event] 監視するEventのインスタンス
  # [name:] 名前(String | nil)
  # [slug:] イベントリスナスラッグ(Symbol | nil)
  # [tags:] Pluggaloid::ListenerTag|Array リスナのタグ
  # [&callback] コールバック
  def initialize(event, name: nil, slug: SecureRandom.uuid, tags: nil, &callback)
    raise Pluggaloid::TypeError, "Argument `event' must be instance of Pluggaloid::Event, but given #{event.class}." unless event.is_a? Pluggaloid::Event
    @event = event
    @name = name.to_s.freeze
    @slug = slug.to_sym
    @tags = Set.new(Array(tags)).freeze
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

  def inspect
    "#<#{self.class} event: #{@event.name.inspect}, slug: #{slug.inspect}, name: #{name.inspect}>"
  end
end
