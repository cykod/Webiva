
class MailTemplateMailerWorker < Workling::Base #:nodoc:all
  def do_work(args)
    logger.warn("mail: #{args[:mail]}")
    MailTemplateMailer.receive(args[:mail])
  end
end
