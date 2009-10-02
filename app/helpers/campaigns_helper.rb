# Copyright (C) 2009 Pascal Rettig.

module CampaignsHelper

  class WizardSteps
    def initialize(wizard_step,wizard_max_step) 
      @wizard_step = wizard_step
      @wizard_max_step = wizard_max_step
    end
    
    def step(number,txt,url = {})
    
      if number == @wizard_step
        "<b class='large_ajax_link_selected'>#{number}. #{txt}</b>"
      elsif number <= @wizard_max_step
        
        "<a href='#{url}'>#{number}. #{txt}</a>"
      else
        "#{number}. #{txt}"
      end
    end
    
  end
  
  def wizard_steps(wizard_step,wizard_max_step) 
    yield WizardSteps.new(wizard_step,wizard_max_step)
  end


  def message_excerpt(seg)
    msg = 'Subject: '.t + seg.subject + '<br/>'
    msg += 'Message: '.t 
    msg += truncate(seg.body_type.include?('text') ?  seg.body_text : seg.body_html.gsub(/<\/?[^>]*>/, ""),60)
      
    msg
  end
  
 def setup_campaign_steps
    if !@campaign.id 
      @campaign_max_step = 1
    elsif !@campaign.market_segment
      @campaign_max_step = 2
    elsif !@campaign.mail_template || !@campaign.market_campaign_message
      @campaign_max_step = 3
    elsif @campaign.status == 'created'
      @campaign_max_step = 4
    else
      @campaign_max_step = 5
    end
      
  end
    
end
