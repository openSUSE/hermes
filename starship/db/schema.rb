# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 3) do

  create_table "delays", :force => true do |t|
    t.string  "name",    :limit => 64
    t.integer "seconds"
  end

  add_index "delays", ["name"], :name => "name"

  create_table "deliveries", :force => true do |t|
    t.string "name", :limit => 64, :default => "", :null => false
  end

  add_index "deliveries", ["name"], :name => "name"

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
    t.string    "header",     :limit => 0, :default => "to", :null => false
    t.integer   "delay",      :limit => 4, :default => 0
    t.timestamp "sent",                                      :null => false
  end

  add_index "messages_people", ["message_id", "person_id", "header"], :name => "msg_id"

  create_table "msg_types", :force => true do |t|
    t.string    "msgtype",      :limit => 64
    t.timestamp "added",                      :null => false
    t.integer   "defaultdelay"
  end

  add_index "msg_types", ["msgtype"], :name => "msgtype"

  create_table "msg_types_people", :force => true do |t|
    t.integer "msg_type_id", :null => false
    t.integer "person_id",   :null => false
    t.integer "delay_id"
    t.integer "delivery_id"
  end

  add_index "msg_types_people", ["person_id", "msg_type_id"], :name => "person_id"

  create_table "persons", :force => true do |t|
    t.string "email"
    t.string "name"
  end

end
