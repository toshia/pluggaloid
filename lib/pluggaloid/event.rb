# -*- coding: utf-8 -*-

require 'observer'

class Pluggaloid::Event
  include Observable
  include InstanceStorage

  # オプション。以下のキーを持つHash
  # :prototype :: 引数の数と型。Arrayで、type_strictが解釈できる条件を設定する
  # :priority :: Delayerの優先順位
  attr_accessor :options

  # フィルタを別のスレッドで実行する。偽ならメインスレッドでフィルタを実行する
  @filter_another_thread = false

  def initialize(*args)
    super
    @options = {}
    @filters = [] end

  # イベントの優先順位を取得する
  # ==== Return
  # プラグインの優先順位
  def priority
    if @options.has_key? :priority
      @options[:priority] end end

  def delayer
    raise Pluggaloid::NoDefautDelayerError, "Default Delayer was not set." unless Delayer.default
    Delayer.default
  end

  # イベントを引数 _args_ で発生させる
  # ==== Args
  # [*args] イベントの引数
  # ==== Return
  # Delayerか、イベントを待ち受けているリスナがない場合はnil
  def call(*args)
    if self.class.filter_another_thread
      if @filters.empty?
        delayer.new(*Array(priority)) do
          changed
          catch(:plugin_exit){ notify_observers(*args) } end
      else
        Thread.new do
          filtered_args = filtering(*args)
          if filtered_args.is_a? Array
            delayer.new(*Array(priority)) do
              changed
              catch(:plugin_exit){ notify_observers(*filtered_args) } end end end end
    else
      delayer.new(*Array(priority)) do
        changed
        args = filtering(*args) if not @filters.empty?
        catch(:plugin_exit){ notify_observers(*args) } if args.is_a? Array end end end

  # 引数 _args_ をフィルタリングした結果を返す
  # ==== Args
  # [*args] 引数
  # ==== Return
  # フィルタされた引数の配列
  def filtering(*args)
    catch(:filter_exit) {
      @filters.reduce(args){ |acm, event_filter|
        event_filter.filtering(*acm) } } end

  # イベントフィルタを追加する
  # ==== Args
  # [event_filter] イベントフィルタ(Filter)
  # ==== Return
  # self
  def add_filter(event_filter)
    unless event_filter.is_a? Pluggaloid::Filter
      raise Pluggaloid::ArgumentError end
    @filters << event_filter
    self end

  # イベントフィルタを削除する
  # ==== Args
  # [event_filter] イベントフィルタ(EventFilter)
  # ==== Return
  # self
  def delete_filter(event_filter)
    @filters.delete(event_filter)
    self end

  class << self
    attr_accessor :filter_another_thread

    alias __clear_aF4e__ clear!
    def clear!
      @filter_another_thread = false
      __clear_aF4e__()
    end
  end

  clear!
end
