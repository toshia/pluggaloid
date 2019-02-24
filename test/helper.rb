# -*- coding: utf-8 -*-

module PluggaloidTestHelper
  def eval_all_events(delayer=Delayer, &block)
    native = Thread.list
    block.() if block
    delayer.run while not(delayer.empty? and (Thread.list - native).empty?)
  end
end
