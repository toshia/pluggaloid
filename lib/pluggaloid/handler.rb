# -*- coding: utf-8 -*-

=begin rdoc
イベントのListenerやFilterのスーパクラス。
イベントに関連付けたり、タグを付けて管理することができる
=end
class Pluggaloid::Handler
  attr_reader :name, :slug, :tags

  # ==== Args
  # [event] 監視するEventのインスタンス
  # [name:] 名前(String | nil)
  # [slug:] ハンドラスラッグ(Symbol | nil)
  # [tags:] Pluggaloid::ListenerTag|Array リスナのタグ
  # [&callback] コールバック
  def initialize(event, name: nil, slug: SecureRandom.uuid, tags: [])
    raise Pluggaloid::TypeError, "Argument `event' must be instance of Pluggaloid::Event, but given #{event.class}." unless event.is_a? Pluggaloid::Event
    @event = event
    @name = name.to_s.freeze
    @slug = slug.to_sym
    _tags = tags.is_a?(Pluggaloid::ListenerTag) ? [tags] : Array(tags)
    _tags.each{|t| raise "#{t} is not a Pluggaloid::ListenerTag" unless t.is_a?(Pluggaloid::ListenerTag) }
    @tags = Set.new(_tags).freeze
  end

  def inspect
    "#<#{self.class} event: #{@event.name.inspect}, slug: #{slug.inspect}, name: #{name.inspect}>"
  end
end
