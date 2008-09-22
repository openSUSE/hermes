class AddAdminFlagToPerson < ActiveRecord::Migration
  def self.up
    add_column :persons, :admin, :boolean, :default => 0
  end

  def self.down
    remove_column :persons, :admin
  end
end
