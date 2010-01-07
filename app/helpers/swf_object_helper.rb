
module SwfObjectHelper
  include EscapeHelper

  def swf_object_default_options
    @swf_object_default_options ||= { :background_color => '#FFFFFF',
                                      :flash_version => 8,
                                      :quality => 'high',
                                      :xi_redirect_url => 'false',
                                      :redirect_url => 'false',
                                      :detect_key => 'detectflash',
                                      :flash_params => { :wmode => 'transparent'
                                                       }
                                    }
  end

  def render_swf_object(container_id, swf_url, width, height, opts=nil)
    options = opts ? self.swf_object_default_options.deep_merge(opts) : self.swf_object_default_options

    swf_object_name = "swf_#{container_id}"

    output = "var #{swf_object_name} = new SWFObject('#{swf_url}', 'swf_#{container_id}', '#{width}', '#{height}', '#{options[:flash_version]}', '#{options[:background_color]}', '#{options[:quality]}', #{options[:xi_redirect_url]}, #{options[:redirect_url]}, '#{options[:detect_key]}');\n";


    options[:flash_params].each do |key,value|
      output << "#{swf_object_name}.addParam('#{jh key}', '#{jh value}');\n"
    end if options[:flash_params]

    options[:flash_vars].each do |key,value|
      output << "#{swf_object_name}.addVariable('#{jh key}', '#{jh value}');\n"
    end if options[:flash_vars]

    options[:flash_attributes].each do |key,value|
      output << "#{swf_object_name}.setAttribute('#{jh key}', '#{jh value}');\n"
    end if options[:flash_attributes]

    output << "#{swf_object_name}.write('#{container_id}');\n"
    output
  end

  def render_swf_container(container_id, notice=nil)
    notice = self.default_flash_notice unless notice

    <<-CONTAINER
    <div id='#{container_id}'>
      #{notice}
    </div>
    CONTAINER
  end

  def default_flash_notice
    <<-GET_FLASH_NOTICE
    <p>This content requires the Adobe Flash Player.</p>
    <p><a href="http://www.adobe.com/go/getflashplayer"><img src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif" alt="Get Adobe Flash player" /></a></p>
    GET_FLASH_NOTICE
  end
end
