class AddSentIndex < ActiveRecord::Migration
  def self.up
    add_index "messages_people", ["sent"], :name => "sent_idx"
  end

  def self.down
    remove_index "messages_people", :name => :sent_idx
  end
end
