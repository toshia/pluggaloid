# -*- coding: utf-8 -*-

=begin rdoc
イベントのListenerやFilterのスーパクラス。
イベントに関連付けたり、タグを付けたりできる
=end
class Pluggaloid::Handler < Pluggaloid::Identity
  Lock = Mutex.new
  attr_reader :tags

  # ==== Args
  # [event] 監視するEventのインスタンス
  # [name:] 名前(String | nil)
  # [slug:] ハンドラスラッグ(Symbol | nil)
  # [tags:] Pluggaloid::HandlerTag|Array リスナのタグ
  # [&callback] コールバック
  def initialize(event, tags: [], **kwrest)
    raise Pluggaloid::TypeError, "Argument `event' must be instance of Pluggaloid::Event, but given #{event.class}." unless event.is_a? Pluggaloid::Event
    super(**kwrest)
    @event = event
    _tags = tags.is_a?(Pluggaloid::HandlerTag) ? [tags] : Array(tags)
    _tags.each{|t| raise "#{t} is not a Pluggaloid::HandlerTag" unless t.is_a?(Pluggaloid::HandlerTag) }
    @tags = Set.new(_tags).freeze
  end

  def add_tag(tag)
    raise Pluggaloid::TypeError, "Argument `tag' must be instance of Pluggaloid::HandlerTag, but given #{tag.class}." unless tag.is_a? Pluggaloid::HandlerTag
    Lock.synchronize do
      @tags = Set.new([tag, *@tags]).freeze
    end
    self
  end

  def remove_tag(tag)
    Lock.synchronize do
      @tags -= tag
      @tags.freeze
    end
    self
  end

  def inspect
    "#<#{self.class} #{name.inspect}(#{slug}) for #{@event.name} event>"
  end
end
