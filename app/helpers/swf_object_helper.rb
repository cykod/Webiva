
module SwfObjectHelper
  include EscapeHelper

  def swf_object_default_options
    @swf_object_default_options ||= { :flash_version => 9,
                                      :express_install_swf_url => '/javascripts/swfobject/plugins/expressInstall.swf',
                                      :flash_params => { :wmode => 'transparent', :quality => 'high' },
                                      :flash_vars => {},
                                      :flash_attributes => {:style => 'outline: none'},
                                      :callback => nil
                                    }
  end

  def render_swf_object(container_id, swf_url, width, height, opts=nil)
    options = opts ? self.swf_object_default_options.deep_merge(opts) : self.swf_object_default_options

    express_install_swf_url = options[:express_install_swf_url] ? "'#{options[:express_install_swf_url]}'" : 'false'
    callback = options[:callback] ? "'#{options[:callback]}'" : 'false'

    flash_params_json = options[:flash_params].to_json

    # if scale is specified, make sure it is the first element
    if flash_params_json =~ /,("scale":"[^"]+")/
      scale = $1
      flash_params_json = flash_params_json.sub(",#{scale}", '').sub('{', "{#{scale},")
    end

    output = "swfobject.embedSWF('#{swf_url}', '#{container_id}', '#{width}', '#{height}', '#{options[:flash_version]}', #{express_install_swf_url}, #{options[:flash_vars].to_json}, #{flash_params_json}, #{options[:flash_attributes].to_json}, #{callback});\n";
  end

  def render_swf_container(container_id, notice=nil)
    notice = self.default_flash_notice unless notice

    "<div id='#{container_id}'>#{notice}</div>"
  end

  def default_flash_notice
    <<-GET_FLASH_NOTICE
    <p>This content requires the Adobe Flash Player.</p>
    <p><a href="http://www.adobe.com/go/getflashplayer"><img src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif" alt="Get Adobe Flash player" /></a></p>
    GET_FLASH_NOTICE
  end
end
