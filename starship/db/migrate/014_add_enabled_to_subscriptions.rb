class AddEnabledToSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :msg_types_people, :enabled, :boolean, :default=>true
  end

  def self.down
    remove_column :msg_types_people, :enabled
  end
end
