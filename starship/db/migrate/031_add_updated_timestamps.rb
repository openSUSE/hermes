class AddUpdatedTimestamps < ActiveRecord::Migration
  def self.up
    add_column :subscriptions, :updated_at, :datetime, :null => true 
    add_column :starship_messages, :subscription_id, :integer, :null => false 
    
    drop_table :messages
    drop_table :messages_people
    
  end

  def self.down
    remove_column :subscriptions, :updated_at
    remove_column :starship_messages, :subscription_id
    
    create_table "messages", :force => true do |t|
      t.integer   "msg_type_id",                :null => false
      t.string    "sender"
      t.string    "subject",     :limit => 128
      t.text      "body"
      t.timestamp "created",                    :null => false
    end
  
    add_index "messages", ["msg_type_id"], :name => "fk_messages_msgtype"
    add_index "messages", ["sender"], :name => "sender"
    add_index "messages", ["created"], :name => "created"
  
    create_table "messages_people", :force => true do |t|
      t.integer   "message_id"
      t.integer   "person_id",                                 :null => false
      t.string    "header",     :limit => 16,:default => "to", :null => false
      t.integer   "delay",      :limit => 4, :default => 0
      t.timestamp "sent",                                      :null => false
    end
  
    add_index "messages_people", ["message_id", "person_id", "header"], :name => "msg_id"
    
    
  end
end
