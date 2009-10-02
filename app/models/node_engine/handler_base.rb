# Copyright (C) 2009 Pascal Rettig.



class NodeEngine::HandlerBase

  def initialize(engine)
    @engine = engine
  end

  attr_reader :engine
  attr_accessor

  def controller
    engine.controller
  end
   
  def page
    @engine.page_information
  end
end
