class DrbController < ApplicationController

  def index
  end
 
  def start
    if request.xhr?
      session[:job_key] = 
        ::MiddleMan.new_worker(:class => :progress_worker,
                               :args => {:text => 'this text has been sent to the worker.'})
      render :update do |page|
        page.replace_html 'form', :partial => 'poll'
      end  
    end  
  end

  def ping
    if request.xhr?
      results = ::MiddleMan.worker(session[:job_key]).results.to_hash
      render :update do |page|
        page.call('progressPercent', 'progressbar', results[:progress])        
        page.redirect_to( :action => 'done')   if results[:progress] >= 100
      end
    else
      redirect_to :action => 'index'   
    end
  end

  def done
    worker = MiddleMan.worker(session[:job_key])
    worker.delete
  end 

end
