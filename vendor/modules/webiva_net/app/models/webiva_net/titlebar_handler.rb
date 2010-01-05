

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
    "<a target='_blank' href='#{opts.documentation_url}?ref=#{ref_string}'><img src='#{@ctrl.send(:theme_src,"framework/page_title_help_icon.gif")}' align='absmiddle' title='#{@ctrl.send(:vh,"Webiva.net Help on this Page".t)}' /></a>"
  end
end
