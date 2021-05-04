# frozen_string_literal: true

module Pluggaloid
  module Mirage
    MIRAGE_ID_BASE_NUMBER = 36

    module Extend
      # `Pluggaloid::Mirage` をincludeしたClassのうち、`pluggaloid_mirage_identity`
      # メソッドを呼ばれたインスタンスを記録するオブジェクトを返す。
      # 戻り値は、以下のメソッドに応答すること。
      # - `repository#[](String id)` idに対応するオブジェクトを返す
      # - `repository#[]=(String id, self obj)` objを記録する
      # Class毎に適したコンテナを返すようにoverrideすること
      def pluggaloid_mirage_repository
        @pluggaloid_mirage_repository ||= {}
      end

      # `Pluggaloid::Mirage` をincludeしたClassのnamespaceを返す。
      # namespaceはStringで、 `Pluggaloid::Mirage` をincludeしたほかのClassと
      # 重複しない。
      # 同じClassであれば、別のPluggaloid host(Pluggaloid::VMやプロセス)でも
      # 同じ値を返す。
      def pluggaloid_mirage_namespace
        -to_s
      end

      def inherited(klass)
        Mirage.pluggaloid_mirage_classes[klass.pluggaloid_mirage_namespace] = klass
      end
    end

    def self.unwrap(namespace:, id:)
      klass = pluggaloid_mirage_classes[namespace]
      if klass
        result = klass.pluggaloid_mirage_repository[id]
        unless result&.is_a?(Pluggaloid::Mirage) # nilの場合は常にraise
          raise ArgumentError, "The id `#{id}' was not found."
        end
        result
      else
        raise ArgumentError, "The namespace `#{namespace}' was not found."
      end
    end

    def self.included(klass)
      klass.extend(Extend)
      pluggaloid_mirage_classes[klass.pluggaloid_mirage_namespace] = klass
    end

    def self.pluggaloid_mirage_classes
      @pluggaloid_mirage_classes ||= {}
    end

    # このClassのなかで、Pluggaloid::Mirageがインスタンスを同定するためのid(String)を返す。
    # このメソッドではなく、 `generate_pluggaloid_mirage_id` をoverrideすること
    def pluggaloid_mirage_id
      generate_pluggaloid_mirage_id.freeze.tap do |id|
        self.class.pluggaloid_mirage_repository[id] = self
        Mirage.pluggaloid_mirage_classes[self.class.pluggaloid_mirage_namespace] ||= self.class
      end
    end

    def pluggaloid_mirage_namespace
      self.class.pluggaloid_mirage_namespace
    end

    private

    # このClassのなかで、Pluggaloid::Mirageがインスタンスを同定するためのid(String)を返す。
    # Class毎に適したコンテナを返すようにoverrideすること
    def generate_pluggaloid_mirage_id
      object_id.to_s(MIRAGE_ID_BASE_NUMBER)
    end
  end
end
