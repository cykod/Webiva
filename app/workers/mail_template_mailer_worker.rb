
class MailTemplateMailerWorker < Workling::Base #:nodoc:all
  def do_work(args)
    MailTemplateMailer.receive(args[:mail])
  end
end
