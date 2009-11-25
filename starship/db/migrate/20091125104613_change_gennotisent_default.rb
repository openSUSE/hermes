class ChangeGennotisentDefault < ActiveRecord::Migration
  def self.up
    change_column :generated_notifications, :sent, :datetime , :default => 0
    change_column :notifications, :generated, :datetime , :default => 0
  end

  def self.down
    change_column :generated_notifications, :sent, :datetime 
    change_column :notifications, :generated, :datetime
  end
end
