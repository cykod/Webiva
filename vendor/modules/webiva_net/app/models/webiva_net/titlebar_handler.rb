

class WebivaNet::TitlebarHandler

  def initialize(ctrl)
    @ctrl = ctrl
  end

  def self.webiva_titlebar_handler_info
    {  :name => 'WebivaNet Help' }
  end

  def titlebar_html
    opts = WebivaNet::AdminController.module_options
    params = @ctrl.send(:params)
    ref_string = params[:controller] + "/" + params[:action]
    titlebar_str = "<ul class='action_panel'><li class='right'><a target='_blank' title='#{"Help about this page".t}' href='#{opts.documentation_url}?ref=#{ref_string}'>?</a></li></ul>"
    if(params[:controller] == 'dashboard' && params[:action] == 'index') 
      if SiteNode.count < 3
        titlebar_str << "\n<script>
         $j(function() { SCMS.remoteOverlay('/website/webiva_net/themes/welcome'); });
       </script>"
      end
    end

    titlebar_str
  end
end
