

class WebivaMenu

  attr_reader :items

  MenuItem = Struct.new(:priority,:name,:identifier,:permissions,:url)

  def initialize(&block)
    @items = []
    yield self
  end
  
  def item(priority,name,permissions,url)
    @items << MenuItem.new( priority, name, name.underscore,permissions,url)
  end


  def authorize(user)
    @items.sort! { |item_a,item_b| item_a.priority <=> item_b.priority } 

    @items = @items.select do |item|
      if item[3]
        user.has_any_role?(item.permissions)
      else
        user.editor? 
      end
    end
  end

  def each(&block)
    @items.each do |item|
      yield item
    end
  end
  
end
