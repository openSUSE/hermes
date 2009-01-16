class AddGeneratedNotifications < ActiveRecord::Migration
  def self.up
    create_table "generated_notifications", :force => true do |t|
      t.integer "notification_id",    :null => false
      t.integer "subscription_id",    :null => false
      t.timestamp "created_at"
      t.timestamp "sent"
    end

    add_index :generated_notifications, :sent
  end

  def self.down
    drop_table "generated_notifications"
    remove_index :generated_notifications, :sent
  end
end
