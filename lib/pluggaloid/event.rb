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
    @subscribers = Hash.new { |h, k| h[k] = [] }
    @stream_generators = Hash.new { |h, k| h[k] = Set.new }
  end

  def prototype
    @options[:prototype]
  end

  # イベント _event_name_ を宣言する
  # ==== Args
  # [new_options] イベントの定義
  def defevent(new_options)
    @options.merge!(new_options)
    if collect_index
      new_proto = self.prototype.dup
      new_proto[self.collect_index] = Pluggaloid::STREAM
      collection_add_event.defevent(prototype: new_proto)
      collection_delete_event.defevent(prototype: new_proto)
    end
    self
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
    case listener
    when Pluggaloid::Listener
      Lock.synchronize do
        if @listeners.map(&:slug).include?(listener.slug)
          raise Pluggaloid::DuplicateListenerSlugError, "Listener slug #{listener.slug} already exists."
        end
        @listeners = [*@listeners, listener].freeze
      end
      @stream_generators.values.each do |generators|
        generators.each(&:on_subscribed)
      end
    when Pluggaloid::Subscriber
      accepted_hash = listener.accepted_hash
      Lock.synchronize do
        @subscribers[accepted_hash] << listener
      end
      @stream_generators.fetch(accepted_hash, nil)&.each(&:on_subscribed)
    else
      raise Pluggaloid::ArgumentError, "First argument must be Pluggaloid::Listener or Pluggaloid::Subscriber, but given #{listener.class}."
    end
    self
  end

  # subscribe(_*specs_) で、ストリームの受信をしようとしているリスナが定義されていればtrueを返す。
  # on_* で通常のイベントリスナが登録されて居る場合は、 _*specs_ の内容に関わらず常にtrueを返す。
  def subscribe?(*specs)
    !@listeners.empty? || @subscribers.key?(argument_hash(specs, nil))
  end

  def subscribe_hash?(hash)   # :nodoc:
    !@listeners.empty? || @subscribers.key?(hash)
  end

  def delete_listener(listener)
    Lock.synchronize do
      @listeners = @listeners.dup
      @listeners.delete(listener)
      @listeners.freeze
    end
    self
  end

  def delete_subscriber(listener)
    Lock.synchronize do
      ss = @subscribers[listener.accepted_hash]
      ss.delete(listener)
      if ss.empty?
        @subscribers.delete(listener.accepted_hash)
      end
    end
    @stream_generators.fetch(listener.accepted_hash, nil)&.each(&:on_unsubscribed)
    self
  end

  def delete_stream_generator(listener)
    Lock.synchronize do
      ss = @stream_generators[listener.accepted_hash]
      ss.delete(listener)
      if ss.empty?
        @stream_generators.delete(listener.accepted_hash)
      end
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

  def argument_hash(args, exclude_index)
    args.each_with_index.map do |item, i|
      if i != exclude_index
        item.hash
      end
    end.compact.freeze
  end

  def stream_index
    unless defined?(@stream_index)
      @stream_index = self.prototype&.index(Pluggaloid::STREAM)
    end
    @stream_index
  end

  def collect_index
    unless defined?(@collect_index)
      @collect_index = self.prototype&.index(Pluggaloid::COLLECT)
    end
    @collect_index
  end

  # defeventで定義されたprototype引数に _Pluggaloid::COLLECT_ を含むイベントに対して使える。
  # フィルタの _Pluggaloid::COLLECT_ 引数に空の配列を渡して実行したあと、その配列を返す。
  # ==== Args
  # [*args] Pluggaloid::COLLECT 以外の引数のリスト
  # ==== Return
  # [Array] フィルタ実行結果
  def collect(*args)
    specified_index = args.index(Pluggaloid::COLLECT)
    specified_index&.yield_self(&args.method(:delete_at))
    insert_index = collect_index || specified_index
    if insert_index
      Enumerator.new do |yielder|
        cargs = args.dup
        cargs.insert(insert_index, yielder)
        filtering(*cargs)
      end
    else
      raise Pluggaloid::UndefinedCollectionIndexError, 'To call collect(), it must define prototype arguments include `Pluggaloid::COLLECT\'.'
    end
  end

  def register_stream_generator(stream_generator)
    @stream_generators[stream_generator.accepted_hash] << stream_generator
    self
  end

  def collection_add_event
    self.class['%{name}__add' % {name: name}]
  end

  def collection_delete_event
    self.class['%{name}__delete' % {name: name}]
  end

  private
  def call_all_listeners(args)
    if stream_index
      @subscribers[argument_hash(args, stream_index)]&.each do |subscriber|
        subscriber.call(*args)
      end
    end
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
