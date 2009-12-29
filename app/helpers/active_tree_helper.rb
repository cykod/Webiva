# Copyright (C) 2009 Pascal Rettig.


=begin rdoc

Helper methods for generating a drag-and-drop sortable list of elements, 
used in the book module to generate the chapter / page list.

=end
module ActiveTreeHelper

  class ActiveTreeBuilder # :nodoc:all
    def initialize(element,tpl,options={})
      @opts = options
      @template = tpl
      @element = element
    end

    def child(obj,level=1)
      returning html = '' do
        html << "\n<#{@opts[:leaf_tg]} class='#{@opts[:leaf_clss]}' id='#{@element}_#{obj.id}'>"
        html << "<span class='active_tree_dropper'></span><span class='toggle'></span>#{'<span class=\'handle\'></span>' unless @opts[:no_handle]}<a class='#{@opts[:leaf_content_clss]}' href='javascript:void(0);' onclick='#{@opts[:js_obj]}.select(#{obj.id},\"#{@element}_#{obj.id}\");'>"
        html << @template.send(:render,:partial => @opts[:partial],:locals => { :tree => self, @element.to_sym => obj }).to_s
        html << "</a>"
        html << self.children(obj,level+1)
        
        html << "</#{@opts[:leaf_tg]}>\n"
      end
        
    end

    def children(object,level=1,wrap=true)
      returning html = '' do
        html << "<#{@opts[:tg]} id='#{@element}_#{object.id}_children' class='#{@opts[:branch_clss]}'>" if wrap
        # First time around we already have an array of objects
        objects = wrap ?  object.send(@opts[:children]) : object
        objects.each do |obj|
          html << self.child(obj,level)
        end
        html << "</#{@opts[:tg]}>" if wrap
      end
    end
  end

  
  # Output an active tree.
  #
  # === Supported options
  # [:tg]
  #   Tag to use for container - defaults to ul
  # [:leaf_tag]    
  #   Tag to use for leaf, defaults to li
  # [:clss] 
  #   CSS class name to us - defaults to 'active_tree'
  # [:leaf_class]
  #   CSS class to use for leafs defaults to clss option + "_leaf"
  # [:wrapper_class]
  #   CSS class to use for leafs defaults to clss option + "_line"
  # [:branch_class]
  #   CSS class to use for leafs defaults to clss option + "_branch"
  # [:leaf_content_class]
  #   CSS class to use for leafs defaults to clss option + "_leaf_content"
  # [:children]
  #   attribute of the objects that contains an Array of children
  # [:js_obj]
  #   name of the javascript object - defaults to the [Element]Tree 
  # [:partial]
  #    name of the partial to render for each element, should render the title of element, 
  #    defaults to name of the element
  #
  # see vendor/modules/book/app/views/manage/edit.rhtml for an example usage
  def active_tree(element,objects,options = {})
    options = options.symbolize_keys

    builder_opts = {}
    builder_opts[:tg]  = options.delete(:tag) || "ul"
    builder_opts[:leaf_tg] = options.delete(:leaf_tag) || ( builder_opts[:tg] == 'ul' ? 'li' : 'div' )
    builder_opts[:clss] = options.delete(:class_name) || "active_tree"
    builder_opts[:leaf_clss] = options.delete(:leaf_class_name) || (builder_opts[:clss] + "_leaf")
    builder_opts[:wrapper_clss] = options.delete(:wrapper_class_name) || (builder_opts[:clss] + "_line")
    builder_opts[:branch_clss] = options.delete(:branch_class_name) || (builder_opts[:clss] + "_branch")
    builder_opts[:leaf_content_clss] = options.delete(:leaf_content_class_name) || (builder_opts[:clss] + "_leaf_content")
    builder_opts[:children] = options.delete(:children) || 'children'
    
    builder_opts[:js_obj] = options.delete(:javascript) || "#{element}_tree".classify

    builder_opts[:partial] = (options.delete(:partial) || element).to_s

    html = "<#{builder_opts[:tg]} id='#{element}_tree' class='#{builder_opts[:clss]} #{builder_opts[:branch_clss]}'>"

    tree = ActiveTreeBuilder.new(element,self,builder_opts)

    html << tree.children(objects,1,false)
    html << <<-HTML
</#{builder_opts[:tg]}>
<script>
      var #{element}_tree =  new SortableTree('#{element}_tree',{
          onDrop: function(drag,drop,event,tree_drag,position) {

            if(tree_drag) {
             ActiveTree.rebuildArrows();
             #{builder_opts[:js_obj]}.drop(drag.to_params(),drag,drop);
            } else {
             #{builder_opts[:js_obj]}.add(drag.id,drop.id(),position);
            }

          },
          draggable: { scroll: window, handle: 'handle'  } 

      });
      #{element}_tree.setSortable();

      ActiveTree = {

        rebuildArrows: function(event) {
            var branches =  $$('.active_tree_branch');
            var b_len = branches.length;
            var chld;
            for(var i=0;i<b_len;i++) {
              var element = branches[i];
              var children = element.childElements();
              var c_len=children.length;
          
              if(c_len == 0) {
                element.parentNode.down('.toggle').addClassName('no_children');
              } else {
                element.parentNode.down('.toggle').removeClassName('no_children');
              }
              for(var k=0;k<c_len;k++) {
                 chld = children[k];
                 if(k == c_len - 1)  {
                   chld.saved_bg = 'none';
                   chld.removeClassName('active_tree_center_item');
                   chld.addClassName('active_tree_last_item');
                 } else {
                   chld.addClassName('active_tree_center_item');
                   chld.removeClassName('active_tree_last_item');
                }
              }
           }
        },

        toggleFolder: function(event) {
          var element = event.element().ancestors().first();
          if(element.hasClassName('closed')) {
            element.removeClassName('closed');
          } else {
            element.addClassName('closed');
          }
         },
     };
  
    $$('ul.active_tree li span.toggle').each(function(element){
      Event.observe(element, 'click', ActiveTree.toggleFolder);
    });

  ActiveTree.rebuildArrows();


</script>
HTML
    
  end

end
