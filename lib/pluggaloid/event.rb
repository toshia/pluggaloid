# -*- coding: utf-8 -*-

class Pluggaloid::Event
  Lock = Mutex.new

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
    @listeners = [].freeze
    @filters = [].freeze
  end

  def vm
    self.class.vm end

  # イベントの優先順位を取得する
  # ==== Return
  # プラグインの優先順位
  def priority
    if @options.has_key? :priority
      @options[:priority] end end

  # イベントを引数 _args_ で発生させる
  # ==== Args
  # [*args] イベントの引数
  # ==== Return
  # Delayerか、イベントを待ち受けているリスナがない場合はnil
  def call(*args)
    if self.class.filter_another_thread
      if @filters.empty?
        vm.Delayer.new(*Array(priority)) do
        call_all_listeners(args) end
      else
        Thread.new do
          filtered_args = filtering(*args)
          if filtered_args.is_a? Array
            vm.Delayer.new(*Array(priority)) do
              call_all_listeners(filtered_args) end end end end
    else
      vm.Delayer.new(*Array(priority)) do
        args = filtering(*args) if not @filters.empty?
        call_all_listeners(args) if args.is_a? Array end end end

  # 引数 _args_ をフィルタリングした結果を返す
  # ==== Args
  # [*args] 引数
  # ==== Return
  # フィルタされた引数の配列
  def filtering(*args)
    catch(:filter_exit) {
      @filters.reduce(args){ |acm, event_filter|
        event_filter.filtering(*acm) } } end

  def add_listener(listener)
    unless listener.is_a? Pluggaloid::Listener
      raise Pluggaloid::ArgumentError, "First argument must be Pluggaloid::Listener, but given #{listener.class}."
    end
    Lock.synchronize do
      if @listeners.map(&:slug).include?(listener.slug)
        raise Pluggaloid::DuplicateListenerSlugError, "Listener slug #{listener.slug} already exists."
      end
      @listeners = [*@listeners, listener].freeze
    end
    self
  end

  def delete_listener(listener)
    Lock.synchronize do
      @listeners = @listeners.dup
      @listeners.delete(listener)
      @listeners.freeze
    end
    self
  end

  # イベントフィルタを追加する
  # ==== Args
  # [event_filter] イベントフィルタ(Filter)
  # ==== Return
  # self
  def add_filter(event_filter)
    unless event_filter.is_a? Pluggaloid::Filter
      raise Pluggaloid::ArgumentError, "First argument must be Pluggaloid::Filter, but given #{event_filter.class}." end
    @filters = [*@filters, event_filter].freeze
    self
  end

  # イベントフィルタを削除する
  # ==== Args
  # [event_filter] イベントフィルタ(EventFilter)
  # ==== Return
  # self
  def delete_filter(event_filter)
    Lock.synchronize do
      @filters = @filters.dup
      @filters.delete(event_filter)
      @filters.freeze
    end
    self
  end

  private
  def call_all_listeners(args)
    catch(:plugin_exit) do
      @listeners.each do |listener|
        listener.call(*args)
      end
    end
  end

  class << self
    attr_accessor :filter_another_thread, :vm

    alias __clear_aF4e__ clear!
    def clear!
      @filter_another_thread = false
      __clear_aF4e__()
    end
  end

  clear!
end
