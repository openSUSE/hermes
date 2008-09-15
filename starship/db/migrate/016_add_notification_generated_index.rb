class AddNotificationGeneratedIndex < ActiveRecord::Migration
  def self.up
    add_index :notifications, :generated
  end

  def self.down
    remove_index :notifications, :generated
  end
end
