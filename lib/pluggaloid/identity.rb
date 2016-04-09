# -*- coding: utf-8 -*-

=begin rdoc
slugと名前をもつオブジェクト。
これの参照を直接持たずとも、slugで一意に参照したり、表示名を設定することができる
=end
class Pluggaloid::Identity
  attr_reader :name, :slug

  # ==== Args
  # [name:] 名前(String | nil)
  # [slug:] ハンドラスラッグ(Symbol | nil)
  def initialize(slug: SecureRandom.uuid, name: slug)
    @name = name.to_s.freeze
    @slug = slug.to_sym
  end

  def inspect
    "#<#{self.class} slug: #{slug.inspect}, name: #{name.inspect}>"
  end
end
