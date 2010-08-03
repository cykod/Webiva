
class WizardModel < HashModel

  def self.wizard_url
    { :controller => '/structure', :action => 'wizard', :path => self.name.underscore }
  end

  def strict?; true; end # :nodoc:

  # override to setup default values
  def set_defaults; end

  def wizard_partial; '/structure/wizard_form'; end

  # Must define a run_wizard method
  # def run_wizard; end
end
