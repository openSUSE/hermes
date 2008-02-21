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

ActiveRecord::Schema.define() do

  create_table "addresses", :force => true do |t|
    t.integer "msg_id",                                   :null => false
    t.integer "person_id",                                :null => false
    t.string  "header",    :limit => 0, :default => "to", :null => false
  end

  add_index "addresses", ["msg_id", "person_id", "header"], :name => "msg_id"

  create_table "messages", :force => true do |t|
    t.integer   "msg_type_id",                               :null => false
    t.string    "sender"
    t.string    "subject",     :limit => 128
    t.text      "body"
    t.integer   "delay",       :limit => 4,   :default => 0, :null => false
    t.timestamp "created",                                   :null => false
    t.timestamp "sent",                                      :null => false
  end

  add_index "messages", ["msg_type_id"], :name => "fk_messages_msgtype"
  add_index "messages", ["sender"], :name => "sender"
  add_index "messages", ["delay"], :name => "delay"
  add_index "messages", ["created", "sent"], :name => "created"

  create_table "msg_types", :force => true do |t|
    t.string    "msgtype", :limit => 64
    t.timestamp "added",                 :null => false
  end

  add_index "msg_types", ["msgtype"], :name => "msgtype"

  create_table "persons", :force => true do |t|
    t.string "email"
    t.string "name"
  end

end
