class AddNotification < ActiveRecord::Migration
  def self.up
    create_table "notifications", :force => true do |t|
      t.integer "msg_type_id",    :null => false
      t.timestamp "received"
      t.string    "sender",       :limit => 64
    end
    
    create_table "notification_parameters", :force => true do |t|
      t.integer "notification_id", :null => false
      t.integer "msg_type_parameter_id"
      t.string  "value"
    end
    add_index "notification_parameters", "notification_id"
    add_index "notification_parameters", "msg_type_parameter_id"

    create_table "msg_type_parameters", :force => true do |t|
      t.string  "name", :limit => 64
    end
  end

  def self.down
    drop_table :notifications
    drop_table :notification_parameters
    drop_table :msg_type_parameters
  end
end
