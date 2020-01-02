# -*- coding: utf-8 -*-

require 'instance_storage'
require 'delayer'
require 'securerandom'
require 'set'

# プラグインの本体。
# DSLを提供し、イベントやフィルタの管理をする
module Pluggaloid
  class Plugin
    include InstanceStorage

    class << self
      attr_writer :vm

      def vm
        @vm ||= begin
                  raise Pluggaloid::NoDefaultDelayerError, "Default Delayer was not set." unless Delayer.default
                  vm = Pluggaloid::VM.new(
                    Delayer: Delayer.default,
                    Plugin: self,
                    Event: Pluggaloid::Event,
                    Listener: Pluggaloid::Listener,
                    Filter: Pluggaloid::Filter,
                    HandlerTag: Pluggaloid::HandlerTag,
                    Subscriber: Pluggaloid::Subscriber
                  )
                  vm.Event.vm = vm end end

      # プラグインのインスタンスを返す。
      # ブロックが渡された場合、そのブロックをプラグインのインスタンスのスコープで実行する
      # ==== Args
      # [plugin_name] プラグイン名
      # ==== Return
      # Plugin
      def create(plugin_name, &body)
        self[plugin_name].instance_eval(&body) if body
        self[plugin_name] end

      # イベントを宣言する。
      # ==== Args
      # [event_name] イベント名
      # [options] 以下のキーを持つHash
      # :prototype :: 引数の数と型。Arrayで、type_strictが解釈できる条件を設定する
      # :priority :: Delayerの優先順位
      def defevent(event_name, options = {})
        vm.Event[event_name].options = options end

      # イベント _event_name_ を発生させる
      # ==== Args
      # [event_name] イベント名
      # [*args] イベントの引数
      # ==== Return
      # Delayer
      def call(event_name, *args)
        vm.Event[event_name].call(*args) end

      # 引数 _args_ をフィルタリングした結果を返す
      # ==== Args
      # [*args] 引数
      # ==== Return
      # フィルタされた引数の配列
      def filtering(event_name, *args)
        vm.Event[event_name].filtering(*args) end

      # 互換性のため
      def uninstall(plugin_name)
        self[plugin_name].uninstall end

      # 互換性のため
      def filter_cancel!
        vm.Filter.cancel! end

      alias plugin_list instances_name

      alias __clear_aF4e__ clear!
      def clear!
        if defined?(@vm) and @vm
          @vm.Event.clear!
          @vm = nil end
        __clear_aF4e__() end
    end

    # プラグインの名前
    attr_reader :name

    # spec
    attr_accessor :spec

    # 最初にプラグインがロードされた時刻(uninstallされるとリセットする)
    attr_reader :defined_time

    # ==== Args
    # [plugin_name] プラグイン名
    def initialize(*args)
      super
      @defined_time = Time.new.freeze
      @events = Set.new
      @filters = Set.new
    end

    # イベントリスナを新しく登録する
    # ==== Args
    # [event] 監視するEventのインスタンス
    # [name:] 名前(String | nil)
    # [slug:] イベントリスナスラッグ(Symbol | nil)
    # [tags:] Pluggaloid::HandlerTag|Array リスナのタグ
    # [&callback] コールバック
    # ==== Return
    # Pluggaloid::Listener
    def add_event(event_name, **kwrest, &callback)
      result = vm.Listener.new(vm.Event[event_name], **kwrest, &callback)
      @events << result
      result end

    # イベントフィルタを新しく登録する
    # ==== Args
    # [event] 監視するEventのインスタンス
    # [name:] 名前(String | nil)
    # [slug:] フィルタスラッグ(Symbol | nil)
    # [tags:] Pluggaloid::HandlerTag|Array フィルタのタグ
    # [&callback] コールバック
    # ==== Return
    # Pluggaloid::Filter
    def add_event_filter(event_name, **kwrest, &callback)
      result = vm.Filter.new(vm.Event[event_name], **kwrest, &callback)
      @filters << result
      result end

    def subscribe(event_name, *specs, **kwrest, &block)
      if block
        result = vm.Subscriber.new(vm.Event[event_name], *specs, **kwrest, &block)
        @events << result
        result
      else
        Stream.new(
          Enumerator.new do |yielder|
            @events << vm.Subscriber.new(vm.Event[event_name], *specs, **kwrest) do |stream|
              stream.each(&yielder.method(:<<))
            end
          end.lazy
        )
      end
    end

    # このプラグインのHandlerTagを作る。
    # ブロックが渡された場合は、ブロックの中を実行し、ブロックの中で定義された
    # Handler全てにTagを付与する。
    # ==== Args
    # [slug] スラッグ
    # [name] タグ名
    # ==== Return
    # Pluggaloid::HandlerTag
    def handler_tag(slug=SecureRandom.uuid, name=slug, &block)
      tag = case slug
            when String, Symbol
              vm.HandlerTag.new(slug: slug.to_sym, name: name.to_s, plugin: self)
            when vm.HandlerTag
              slug
            else
              raise Pluggaloid::TypeError, "Argument `slug' must be instance of Symbol, String or Pluggaloid::HandlerTag, but given #{slug.class}."
            end
      if block
        handlers = @events + @filters
        block.(tag)
        (@events + @filters - handlers).each do |handler|
          handler.add_tag(tag)
        end
      else
        tag
      end
    end

    # イベントリスナを列挙する
    # ==== Return
    # Set of Pluggaloid::Listener
    def listeners(&block)
      if block
        @events.each(&block)
      else
        @events.dup
      end
    end

    # フィルタを列挙する
    # ==== Return
    # Set of Pluggaloid::Filter
    def filters(&block)
      if block
        @filters.each(&block)
      else
        @filters.dup
      end
    end


    # イベントを削除する。
    # 引数は、Pluggaloid::ListenerかPluggaloid::Filterのみ(on_*やfilter_*の戻り値)。
    # 互換性のため、二つ引数がある場合は第一引数は無視され、第二引数が使われる。
    # ==== Args
    # [*args] 引数
    # ==== Return
    # self
    def detach(*args)
      listener = args.last
      case listener
      when vm.Listener, vm.Subscriber
        @events.delete(listener)
        listener.detach
      when vm.Filter
        @filters.delete(listener)
        listener.detach
      when Enumerable
        listener.each(&method(:detach))
      else
        raise ArgumentError, "Argument must be Pluggaloid::Listener, Pluggaloid::Filter, Pluggaloid::HandlerTag or Enumerable. But given #{listener.class}."
      end
      self end

    # このプラグインを破棄する
    # ==== Return
    # self
    def uninstall
      vm.Event[:unload].call(self.name)
      vm.Delayer.new do
        @events.map(&:detach)
        @filters.map(&:detach)
        self.class.destroy name
      end
      self end

    # イベント _event_name_ を宣言する
    # ==== Args
    # [event_name] イベント名
    # [options] イベントの定義
    def defevent(event_name, options={})
      vm.Event[event_name].options.merge!({plugin: self}.merge(options)) end

    # DSLメソッドを新しく追加する。
    # 追加されたメソッドは呼ぶと &callback が呼ばれ、その戻り値が返される。引数も順番通り全て &callbackに渡される
    # ==== Args
    # [dsl_name] 新しく追加するメソッド名
    # [&callback] 実行されるメソッド
    # ==== Return
    # self
    def defdsl(dsl_name, &callback)
      self.class.instance_eval {
        define_method(dsl_name, &callback) }
      self end

    # プラグインが Plugin.uninstall される時に呼ばれるブロックを登録する。
    def onunload(&callback)
      add_event(:unload) do |plugin_slug|
        if plugin_slug == self.name
          callback.call
        end
      end
    end
    alias :on_unload :onunload

    # マジックメソッドを追加する。
    # on_?name :: add_event(name)
    # filter_?name :: add_event_filter(name)
    def method_missing(method, *args, **kwrest, &proc)
      method_name = method.to_s
      case
      when method_name.start_with?('on')
        event_name = method_name[(method_name[2] == '_' ? 3 : 2)..method_name.size]
        add_event(event_name.to_sym, *args, **kwrest, &proc)
      when method_name.start_with?('filter')
        event_name = method_name[(method_name[6] == '_' ? 7 : 6)..method_name.size]
        add_event_filter(event_name.to_sym, **kwrest, &proc)
      else
        super
      end
    end

    private

    def vm
      self.class.vm end

  end
end
