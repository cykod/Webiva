# Copyright (C) 2009 Pascal Rettig.


# From use_db plugin
class Fixtures
  alias_method :rails_delete_existing_fixtures, :delete_existing_fixtures
  def delete_existing_fixtures
    m = get_model
    connection = m.connection
    connection.delete "DELETE FROM #{m.table_name}", 'Fixture Delete'
  end

  alias_method :rails_insert_fixtures, :insert_fixtures
  def insert_fixtures
    m = get_model
    connection = m.connection
    values.each do |fixture|
      connection.execute "INSERT INTO #{m.table_name} (#{fixture.key_list}) VALUES (#{fixture.value_list})", 'Fixture Insert'
    end
  end
  
private
  def get_model
    klass = eval(@class_name)
    return klass
  rescue
    return nil
  end
  
end