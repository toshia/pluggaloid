# -*- coding: utf-8 -*-
module Pluggaloid
  class Error < ::StandardError; end

  class ArgumentError < Error; end

  class TypeError < Error; end

  class FilterError < Error; end

  class NoDefaultDelayerError < Error; end

  class DuplicateListenerSlugError < Error; end

  class UndefinedCollectionIndexError < Error; end
end
