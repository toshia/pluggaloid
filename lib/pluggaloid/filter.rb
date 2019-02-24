# -*- coding: utf-8 -*-

class Pluggaloid::Filter < Pluggaloid::Handler
  NotConverted = Class.new
  THROUGH = NotConverted.new.freeze

  # フィルタ内部で使う。フィルタの実行をキャンセルする。Plugin#filtering はfalseを返し、
  # イベントのフィルタの場合は、そのイベントの実行自体をキャンセルする。
  # また、 _result_ が渡された場合、Event#filtering の戻り値は _result_ になる。
  def self.cancel!(result=false)
    throw :filter_exit, result end

  CANCEL_PROC = method(:cancel!)

  # ==== Args
  # [event] 監視するEventのインスタンス
  # [name:] 名前(String | nil)
  # [slug:] フィルタスラッグ(Symbol | nil)
  # [tags:] Pluggaloid::HandlerTag|Array フィルタのタグ
  # [&callback] コールバック
  def initialize(event, **kwrest, &callback)
    super
    @callback = callback
    event.add_filter self end

  # イベントを実行する
  # ==== Args
  # [*args] イベントの引数
  # ==== Return
  # 加工後の引数の配列
  def filtering(*args)
    length = args.size
    result = @callback.call(*args, &CANCEL_PROC)
    case
    when THROUGH == result
      args
    when length != result.size
      raise Pluggaloid::FilterError, "filter changes arguments length (#{length} to #{result.size})"
    else
      result
    end
  end

  # このリスナを削除する
  # ==== Return
  # self
  def detach
    @event.delete_filter(self)
    self end

end
