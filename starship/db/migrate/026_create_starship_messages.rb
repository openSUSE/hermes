class CreateStarshipMessages < ActiveRecord::Migration
  def self.up
    create_table "starship_messages", :force => true do |t|
      t.integer "notification_id", :null => false
      t.string  "sender"
      t.string  "user",     :null => false
      t.string  "type",     :null => false
      t.string  "subject"
      t.string  "replyto"
      t.text    "body"
      t.timestamp "created"
    end
    add_index "starship_messages", "notification_id"
    add_index "starship_messages", "user"
    add_index "starship_messages", "type"

  end

  def self.down
    drop_table :starship_messages

    remove_index :starship_messages, :notification_id
    remove_index :starship_messages, :user
    remove_index :starship_messages, :type
  end
end
