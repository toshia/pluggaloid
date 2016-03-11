# -*- coding: utf-8 -*-

module PluggaloidTestHelper
  def eval_all_events(delayer=Delayer)
    native = Thread.list
    yield if block_given?
    delayer.run while not(delayer.empty? and (Thread.list - native).empty?)
  end
end
