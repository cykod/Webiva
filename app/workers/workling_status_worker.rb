
class WorklingStatusWoker <  Workling::Base #:nodoc:all
  def do_work(args)
    workling_classes = {}
    Workling::Discovery.discovered.each { |clazz| workling_classes[clazz.name] = nil }

    Thread.list.each do |t|
      next unless t.key?(:name)
      name = t[:name]
      workling_classes[name] = t if workling_classes.include?(name)
    end

    workling_classes.each do |name, t|
      status = ''
      if t.nil?
	status = DevelopmentLogger.wrap_msg("not running", '31')
      else
	if t.status.nil?
	  status = DevelopmentLogger.wrap_msg("raised an exception", '31')
	elsif t.status === false
	  status = DevelopmentLogger.wrap_msg("terminated normally", '31')
	elsif t.status == 'aborting'
	  status = DevelopmentLogger.wrap_msg("aborting", '31')
	else
	  status = DevelopmentLogger.wrap_msg("running", '33')
	end
      end

      logger.warn("#{name} status:#{status}, #{t.inspect}")
    end
  end
end
