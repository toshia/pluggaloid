# -*- coding: utf-8 -*-

require 'securerandom'

=begin rdoc
= リスナをまとめて管理するプラグイン

Pluggaloid::Listener や、 Pluggaloid::Filter をまとめて扱うための仕組み。
Pluggaloid::Plugin#add_event などの引数 _tags:_ に、このインスタンスを設定する。

== インスタンスの作成

Pluggaloid::Plugin#listener_tag を使って生成する。 Pluggaloid::ListenerTag の
_plugin:_ 引数には、レシーバ(Pluggaloid::Plugin)が渡される。
Pluggaloid::ListenerTag は、このプラグインの中でだけ使える。複数のプラグインのリスナ
をまとめて管理することはできない。

== リスナにタグをつける

Pluggaloid::Plugin#add_event または Pluggaloid::Plugin#add_event_filter の
_tags:_ 引数にこれのインスタンスを渡す。

== このタグがついたListenerやFilterを取得する

Enumerable をincludeしていて、リスナやフィルタを取得することができる。
また、
- Pluggaloid::ListenerTag#listeners で、 Pluggaloid::Listener だけ
- Pluggaloid::ListenerTag#filters で、 Pluggaloid::Filter だけ
を対象にした Enumerator を取得することができる

== このタグがついたリスナを全てdetachする

Pluggaloid::Plugin#detach の第一引数に Pluggaloid::ListenerTag の
インスタンスを渡すことで、そのListenerTagがついたListener、Filterは全てデタッチ
される

=end
class Pluggaloid::ListenerTag
  include Enumerable

  attr_reader :name

  # ==== Args
  # [name:] タグの名前(String | nil)
  def initialize(name: SecureRandom.uuid, plugin:)
    @name = name.to_s.freeze
    @plugin = plugin
  end

  # このTagがついている Pluggaloid::Listener と Pluggaloid::Filter を全て列挙する
  # ==== Return
  # Enumerable
  def each
    if block_given?
      Enumerator.new do |y|
        listeners{|x| y << x }
        filters{|x| y << x }
      end.each(&Proc.new)
    else
      Enumerator.new do |y|
        listeners{|x| y << x }
        filters{|x| y << x }
      end
    end
  end

  # このTagがついている Pluggaloid::Listener を全て列挙する
  # ==== Return
  # Enumerable
  def listeners
    if block_given?
      listeners.each(&Proc.new)
    else
      @plugin.to_enum(:listeners).lazy.select{|l| l.tags.include?(self) }
    end
  end

  # このTagがついている Pluggaloid::Filter を全て列挙する
  # ==== Return
  # Enumerable
  def filters
    if block_given?
      filters.each(&Proc.new)
    else
      @plugin.to_enum(:filters).lazy.select{|l| l.tags.include?(self) }
    end
  end

  def inspect
    "#<#{self.class} #{@name.inspect}>"
  end
end
