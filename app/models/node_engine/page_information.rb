# Copyright (C) 2009 Pascal Rettig.

class NodeEngine::PageInformation < DefaultsHashObject

  def initialize(hsh = {})
    super(hsh,
          {
            :locks => [],
            :zone_paragraphs => {},
            :zone_locks => {},
            :zone_clears => {},
            :context => {},
            :includes => {},
            :paction => nil,
            :title => {},
            :paction_data => nil
          })
  end

end
