class AddBasicAuth < ActiveRecord::Migration
  def self.up
    add_column :persons, :hashed_password, :string
    add_column :persons, :salt, :string
  end

  def self.down
    remove_column :persons, :hashed_password
    remove_column :persons, :salt
  end
end
