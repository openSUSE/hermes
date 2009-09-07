class AddGeneratedNotificationIndex < ActiveRecord::Migration
  def self.up
    add_index :generated_notifications, :notification_id
  end

  def self.down
    remove_index :generated_notifications, :notification_id
  end
end
