# Copyright (c) 2008 [Sur http://expressica.com]

class CreateSimpleCaptchaData < ActiveRecord::Migration
  def self.up
    create_table :simple_captcha_data do |t|
      t.column :key, :string, :limit => 40
      t.column :value, :string, :limit => 6
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :simple_captcha_data
  end
end
