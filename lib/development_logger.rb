
class DevelopmentLogger < Logger
  def initialize(logdev, shift_age = 0, shift_size = 1048576)
    super
    if logdev && logdev.to_s.include?('.log')
      @error_logdev = LogDevice.new(logdev.to_s.sub('.log', '.error_log'), :shift_age => shift_age, :shift_size => shift_size)
    end
  end

  def add(severity, message = nil, progname = nil, &block)
    severity ||= UNKNOWN
    if @logdev.nil? or severity < @level
      return true
    end
    progname ||= @progname
    if message.nil?
      if block_given?
        message = yield
      else
        message = progname
        progname = @progname
      end
    end
    msg = format_message(format_severity(severity), Time.now, progname, message)
    @logdev.write(color_special_msg(msg, severity))
    @error_logdev.write(msg) if @error_logdev && severity > INFO
    true
  end

  def color_special_msg(msg, severity)
    # ignore messages with 2 spaces, most likely a rails message that has already been styled.
    return msg if msg =~ /^  /

    # unix console styler
    # http://snippets.dzone.com/posts/show/4822
    sub_color = '44' # blue background
    if severity == WARN
      sub_color = '43'  # yellow background
    elsif severity >= ERROR
      sub_color = '41' # red background
      msg = "\033[1m#{msg}\033[0m" # bold
    end

    msg.sub(/^/, "\033[#{sub_color}m \033[0m ")
  end

  def self.wrap_msg(msg, style)
    "\033[#{style}m#{msg}\033[0m"
  end
end
