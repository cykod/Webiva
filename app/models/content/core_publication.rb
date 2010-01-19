# Copyright (C) 2009 Pascal Rettig.


# This defines the core publications types supported by the system
# See PublicationTypeHandler for details on how to create your own
# publications
class Content::CorePublication < Content::PublicationTypeHandler

  
  # Available Content Fields, with meta information
  register_publication_types [
         { :name => :view,
           :description => 'Display a single entry',
           :renderer => '/editor/publication_renderer'
         },
         { :name => :list, 
           :description => 'List of entries',
           :renderer => '/editor/publication_renderer'
         },
         { :name => :create,
           :description => 'Form (create a new entry)',
           :renderer => '/editor/publication_renderer'
         },
         { :name => :edit,
           :description => 'Form (edit an existing entry)',
           :renderer => '/editor/publication_renderer'
         },
         { :name => :admin_list,
           :description => 'Admin list - delete entries',
           :renderer => '/editor/publication_renderer'
         },
         { :name => :data,
           :description => 'Data output',
           :renderer => '/editor/publication_renderer'
         }
         ]


  register_publication_fields [
          { :name => :header,
            :description => 'Display a header separator'
          }
      
         ]
  

  
  

end
