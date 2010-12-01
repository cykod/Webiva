

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
    "<ul class='action_panel'><li class='right'><a target='_blank' title='#{"Help about this page".t}' href='#{opts.documentation_url}?ref=#{ref_string}'>?</a></li></ul>"
  end
end
