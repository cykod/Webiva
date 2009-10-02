# Copyright (C) 2009 Pascal Rettig.

class DomainEmail < DomainModel
  validates_presence_of :email
  validates_uniqueness_of :email
  validates_confirmation_of :password
  validates_format_of :email_type, :with => /mailbox|alias|bounce/
  
  validates_as_email_name :email
  
  attr_protected :email
  
  belongs_to :end_user
  
  attr_accessor :password
  attr_accessor :password_confirmation
  
  has_options :email_type, [ ['Mailbox','mailbox'],['Alias','alias'], ['Bounce','bounce']]


  def before_save
    self.hashed_password = EndUser.hash_password(self.password) unless self.password.blank?
    self.redirects = redirect_list.join("\n")
  end
  
  def after_save
    self.propogate_system_emails
  end
  
  def after_destroy
    self.destroy_system_emails
  end
  
  def validate
    if self.email_type == 'mailbox'
      if !self.linked_account?
	if self.password.blank? && ( !self.id || self.hashed_password.blank? )
	  errors.add(:password, 'is missing')
        end
      elsif !self.end_user
         errors.add(:end_user_id,'is missing')
      end
    end
    if self.email_type == 'alias'
      self.redirect_list.each do |adr|
         if !(adr =~ RFC822::EmailAddress)
          errors.add(:redirects,'are all not valid email addresses')
          break;
         end
      end
      if self.redirect_list.length == 0
        errors.add(:redirects,'must alias to at least 1 email address')
      end
    end
  end
  
  def redirect_list
    self.redirects.to_s.split("\n").collect { |email| email.strip }.find_all { |email| !email.blank? }
  end
  
  def full_email
    self.email.to_s + "@" + Configuration.domain
  end
  
  def active_password
    if self.linked_account? && self.end_user
      self.end_user.hashed_password
    else
      self.hashed_password
    end
  end
  
  def self.setup_domain_emails
  
    # Make sure we have a noreply -> bounce
    unless(self.find_by_email('bounce'))
      email = DomainEmail.new(:system_email => true,
                       :email_type => 'bounce')
      email.email = 'bounce'
      email.save
    end
                       
    # postmaster -> mailbox (no pw)
    unless(self.find_by_email('postmaster'))
      email = DomainEmail.new(:system_email => true,
                          :email_type => 'mailbox',
                          :hashed_password => 'RESET')
      email.email = 'postmaster'
      email.save(false)
    end
                          
    # abuse -> redirect to postmaster
    unless(self.find_by_email('abuse'))
      email = DomainEmail.new( :system_email => true,
                          :email_type => 'alias',
                          :redirects => "postmaster@#{Configuration.domain}")
      email.email = 'abuse'
      email.save
    end
  
    EmailTransport.update_all("touched=0", ['domain_id=?',Configuration.domain_id]);
    EmailMailbox.update_all("touched=0", ['domain_id=?',Configuration.domain_id]);
    EmailAlias.update_all("touched=0", ['domain_id=?',Configuration.domain_id]);
    
    # go through each domain email and propogate it again
    self.find(:all).each do |dmn_email|
      dmn_email.propogate_system_emails
    end
  
    # Delete any left over domain emails
    EmailTransport.delete_all(['touched=0 and domain_id=?',Configuration.domain_id]);
    EmailMailbox.delete_all(['touched=0 and domain_id=?',Configuration.domain_id]);
    EmailAlias.delete_all(['touched=0 and domain_id=?',Configuration.domain_id]);
  end
  
  def propogate_system_emails
    # Used the touched field so what we don't delete/recreate emails
    EmailTransport.update_all("touched=0", ['domain_id=? AND domain_email_id=?',Configuration.domain_id,self.id]);
    EmailMailbox.update_all("touched=0", ['domain_id=? AND domain_email_id=?',Configuration.domain_id,self.id]);
    EmailAlias.update_all("touched=0", ['domain_id=? AND domain_email_id=?',Configuration.domain_id,self.id]);
    
    
    case self.email_type
    when 'bounce':
      # Create a transport entry & a mailbox for relaying purposes
      transport = EmailTransport.find_by_domain_id_and_domain_email_id(Configuration.domain_id,self.id) ||
		    EmailTransport.new( :domain_id => Configuration.domain_id,
					:domain_email_id => self.id)
      transport.update_attributes(:touched => 1,
                                  :user => self.full_email,
                                  :transport => 'webiva')
      mailbox = EmailMailbox.find_by_domain_id_and_domain_email_id(Configuration.domain_id,self.id) ||
                  EmailMailbox.new( :domain_id => Configuration.domain_id,
                                    :domain_email_id => self.id)
      mailbox.update_attributes(:touched => 1,
                                :mailbox_type => 'bounce',
                                :user => self.email,
                                :email => self.full_email,
                                :password => '')
                                
    when 'mailbox':
      # Find or create a mailbox w/ mailbox type 'mailbox' and user, email && password updated
      mailbox = EmailMailbox.find_by_domain_id_and_domain_email_id(Configuration.domain_id,self.id) ||
                  EmailMailbox.new( :domain_id => Configuration.domain_id,
                                    :domain_email_id => self.id)
      mailbox.update_attributes(:touched => 1,
                                :mailbox_type => 'mailbox',
                                :user => self.email,
                                :email => self.full_email,
                                :password => self.active_password)
      
    when 'alias':
      self.redirect_list.each do |adr|
        redirect = EmailAlias.find(:first, :conditions => [ 'domain_id=? AND domain_email_id=? AND alias=? AND destination=?',  
                                                          Configuration.domain_id,self.id,self.full_email,adr]) ||
                      EmailAlias.new(:domain_id => Configuration.domain_id,
                                     :domain_email_id => self.id,
                                     :alias => self.full_email,
                                     :destination => adr)
        redirect.update_attribute(:touched,1)
      end
    end
    
    EmailTransport.delete_all(['touched=0 AND domain_id=? AND domain_email_id=?',Configuration.domain_id,self.id]);
    EmailMailbox.delete_all(['touched=0 AND domain_id=? AND domain_email_id=?',Configuration.domain_id,self.id]);
    EmailAlias.delete_all(['touched=0 AND domain_id=? AND domain_email_id=?',Configuration.domain_id,self.id]);
  end
  
  def destroy_system_emails
    EmailTransport.delete_all(['domain_id=? AND domain_email_id=?',Configuration.domain_id,self.id]);
    EmailMailbox.delete_all(['domain_id=? AND domain_email_id=?',Configuration.domain_id,self.id]);
    EmailAlias.delete_all(['domain_id=? AND domain_email_id=?',Configuration.domain_id,self.id]);
  
  end
end
