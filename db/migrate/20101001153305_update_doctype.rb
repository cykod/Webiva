class UpdateDoctype < ActiveRecord::Migration
  def self.up
    self.connection.execute "UPDATE site_templates SET doctype = '<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">' WHERE doctype IS NULL"
  end

  def self.down
    self.connection.execute "UPDATE site_templates SET doctype = NULL WHERE doctype = '<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">'"
  end
end
