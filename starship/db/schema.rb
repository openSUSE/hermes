# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20091221125522) do

  create_table "delays", :force => true do |t|
    t.string  "name",        :limit => 64
    t.integer "seconds"
    t.string  "description"
  end

  add_index "delays", ["name"], :name => "name"

  create_table "deliveries", :force => true do |t|
    t.string  "name",        :limit => 64, :default => "",   :null => false
    t.string  "description"
    t.boolean "public",                    :default => true
  end

  add_index "deliveries", ["name"], :name => "name"

  create_table "delivery_attributes", :force => true do |t|
    t.integer "delivery_id", :null => false
    t.string  "attribute"
    t.string  "value"
  end

  create_table "generated_notifications", :force => true do |t|
    t.integer  "notification_id", :null => false
    t.integer  "subscription_id", :null => false
    t.datetime "created_at"
    t.datetime "sent"
  end

  add_index "generated_notifications", ["notification_id"], :name => "index_generated_notifications_on_notification_id"

  create_table "msg_states", :force => true do |t|
    t.string "state",       :limit => 64
    t.string "description"
  end

  create_table "msg_types", :force => true do |t|
    t.string   "msgtype",      :limit => 64
    t.datetime "added",                      :null => false
    t.integer  "defaultdelay"
    t.text     "description"
  end

  add_index "msg_types", ["msgtype"], :name => "msgtype"

  create_table "msg_types_parameters", :force => true do |t|
    t.integer "msg_type_id",  :null => false
    t.integer "parameter_id", :null => false
    t.text    "description"
  end

  add_index "msg_types_parameters", ["msg_type_id", "parameter_id"], :name => "msg_type_parameter_id", :unique => true

  create_table "notification_parameters", :force => true do |t|
    t.integer "notification_id", :null => false
    t.integer "parameter_id"
    t.text    "value"
  end

  add_index "notification_parameters", ["notification_id"], :name => "index_notification_parameters_on_notification_id"
  add_index "notification_parameters", ["parameter_id"], :name => "index_notification_parameters_on_msg_type_parameter_id"

  create_table "notifications", :force => true do |t|
    t.integer  "msg_type_id",               :null => false
    t.datetime "received"
    t.string   "sender",      :limit => 64
    t.datetime "generated"
  end

  add_index "notifications", ["generated"], :name => "index_notifications_on_generated"

  create_table "parameters", :force => true do |t|
    t.string "name",    :limit => 64
    t.string "hr_name"
  end

  create_table "persons", :force => true do |t|
    t.string  "email"
    t.string  "name"
    t.string  "jid"
    t.string  "stringid"
    t.boolean "admin",           :default => false
    t.string  "hashed_password"
    t.string  "salt"
  end

  add_index "persons", ["stringid"], :name => "index_persons_on_stringid"

  create_table "starship_messages", :force => true do |t|
    t.integer  "notification_id",                :null => false
    t.string   "sender"
    t.integer  "person_id"
    t.string   "subject"
    t.string   "replyto"
    t.text     "body"
    t.datetime "created"
    t.integer  "msg_type_id",                    :null => false
    t.integer  "msg_state_id",    :default => 1
    t.integer  "subscription_id",                :null => false
  end

  add_index "starship_messages", ["notification_id"], :name => "index_starship_messages_on_notification_id"
  add_index "starship_messages", ["person_id"], :name => "index_starship_messages_on_user"
  add_index "starship_messages", ["subscription_id"], :name => "index_starship_messages_on_subscription_id"

  create_table "subscription_filters", :force => true do |t|
    t.integer "subscription_id", :null => false
    t.integer "parameter_id",    :null => false
    t.string  "operator",        :null => false
    t.string  "filterstring",    :null => false
  end

  add_index "subscription_filters", ["parameter_id"], :name => "parameter_id"
  add_index "subscription_filters", ["subscription_id"], :name => "subscription_id"

  create_table "subscriptions", :force => true do |t|
    t.integer  "msg_type_id",                   :null => false
    t.integer  "person_id",                     :null => false
    t.integer  "delay_id"
    t.integer  "delivery_id"
    t.text     "comment"
    t.boolean  "private"
    t.boolean  "enabled",     :default => true
    t.datetime "updated_at"
    t.string   "description"
    t.string   "name"
    t.string   "config"
  end

  add_index "subscriptions", ["person_id", "msg_type_id"], :name => "person_id"

end
