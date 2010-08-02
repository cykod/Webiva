
class SimpleSiteWizard < HashModel
  attributes :pages => [], :name => nil


  options_form(
               fld(:pages, :text_area),
               fld(:name, :text_field, :label => 'Website Name')
               )

  def validate
    self.errors.add(:name, 'is missing') if self.name.blank?
    self.errors.add(:pages, 'are missing') if self.pages.blank?
  end

  def pages=(val)
    @pages = val.is_a?(Array) ? val : val.split("\n").collect {|l| l.strip }
  end

  def pages
    @pages.is_a?(Array) ? @pages.join("\n") : @pages
  end

  def add_to_site!
    root = SiteVersion.current.root_node
    root.site_node_modifiers.each do |modifier|
      modifier.destroy if modifier.modifier_type == 'template'
    end

    root.reload

    framework_modifier = root.site_node_modifiers.to_a.find { |modifier| modifier.modifier_type == 'framework' }
    framework_modifier ||= root.add_modifier 'framework'

    rv = framework_modifier.page_revisions[0].create_temporary
    rv.make_real
    automenu_para = rv.add_paragraph '/editor/menu', 'automenu', {:root_page => root.id, :levels => 1}, :zone => 2
    automenu_para.save

    theme = self.create_simple_theme
    theme_modifier = root.add_modifier 'template'
    theme_modifier.options.template_id = theme.id
    theme_modifier.save

    @pages.each do |page|
      url = page.underscore.strip.gsub(/[ _]+/, '-').gsub(/[^a-z0-9.\-]/, '')
      url = '' if url == 'home'
      nd = SiteVersion.current.site_nodes.find(:first, :conditions => {:node_type => 'P', :node_path => "/#{url}"})
      nd ||= root.add_subpage(url)
      nd.save

      rv = nd.live_revisions[0].create_temporary

      rv.title = page
      rv.make_real

      basic_para = rv.page_paragraphs[0]
      basic_para.display_body = "<h1>#{page}</h1>\n" + DummyText.paragraphs(1+rand(3), :max => 1).map { |p| "<p>#{p}</p>" }.join("\n")
      basic_para.save
    end
  end

  def create_simple_theme
    site_template = SiteTemplate.create :template_type => 'site', :name => 'Simple Site Theme', :description => '', :template_html => self.simple_template_html, :style_design => self.simple_style_design, :style_struct => self.simple_style_struct

    ['Content', 'Main Menu', 'Sidebar'].each_with_index do |name, idx|
      site_template.site_template_zones.create :name => name, :position => (idx+1)
    end

    site_template
  end

  def simple_template_html
    <<-HTML
<div id='container'>

  <div id='header'>
    <div id='logo'><a href='/'>#{self.name}</a></div>
    <div id='main-menu'>
      <cms:zone name='Main Menu'/>
    </div>
  </div> <!-- end #header -->

  <div id='content-container'>
    <div id='content'>
      <cms:zone name='Content'/>
    </div> <!-- end #content -->
    <div id='sidebar'>
      <cms:zone name='Sidebar'/>
    </div> <!-- end #sidebar -->
    <div class='clear'></div>
  </div> <!-- end #content-container -->

</div> <!-- end #container -->
    HTML
  end

  def simple_style_design
    <<-CSS
* {  padding:0px; margin:0px; }

body {  font-family: "Times New Roman"; font-size:14px; color:black; }

a { outline:none; }
a img { border:0px; }

ul, li {  margin-left:10px; padding-left:10px; }

h1 {  font-size:28px; color:#999999; margin-bottom:5px; }
p {  padding-bottom:10px; }                              

.left-image {  float:left; padding:0px 10px 10px 0px; }

.clear {  clear:both; }
    CSS
  end

  def simple_style_struct
    <<-CSS
#container {  width:900px; margin:0 auto; }

#header {  
          height:85px; 
          border-bottom:5px solid black; 
          position:relative;             
          padding:0 90px;                
}                                        

  #top-menu {  
              background-color:#CCCCCC; 
              text-align:center;        
              padding:5px 10px;         
              color:black;              
              position:absolute;        
              top:0px;                  
              right:90px;               
              }                         
                                        
  #top-menu a {                         
                font-size:17px;         
                color:black;            
                text-decoration:none;   
                font-weight:bold;       
                }                       



  #logo {  position:absolute; left:90px; bottom:0px; font-size:15px; font-weight:bold;}
  #logo a { text-decoration: none; font-size:26px; font-weight:bold; color:#000;}
  #main-menu {  position:absolute; right:90px; bottom:0px; }
  #main-menu ul {  padding:0px; margin:0px; background-color:black; }
  #main-menu li {
                  padding:0px;
                  margin:0px;
                  background-color:black;
                  list-style-type:none;
                  display:block;
                  float:left;
                  }
#main-menu li a {
                  display:block;
                  float:left;
                  text-decoration:none;
                  color:white;
                  padding:5px 15px;
                  font-size:17px;
                  font-weight:bold;

                  }
#main-menu li a:hover { color:#CCCCCC; }

#content-container {  padding:20px 90px 0px 90px;; }
  #content {  float:left; width: 380px; padding-top:10px; }
  #sidebar {
             float:right;
             width:175px;
             font-weight:bold;
             background-color: #cccccc;
             padding: 30px;
             }
  .sidebar-menu { padding-bottom:20px; }
  .sidebar-title {  font-size:19px; font-weight:bold; }
  .sidebar-menu ul.menu {  padding-left:10px; margin-left:0px;  }
  .sidebar-menu ul.menu li {
                             margin-left:0px;
                             padding-top:10px;
                             list-style-type:none;
                             }
   .sidebar-menu ul.menu li a {  text-decoration:none; color:black; }
   .sidebar-menu ul.menu li a:hover {  text-decoration:underline; }
    CSS
  end
end
