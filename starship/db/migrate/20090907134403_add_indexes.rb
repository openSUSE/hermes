class AddIndexes < ActiveRecord::Migration
  def self.up
    add_index :starship_messages, :subscription_id
    add_index :persons, :stringid
  end

  def self.down
    remove_index :starship_messages, :subscription_id
    remove_index :persons, :stringid
  end
end
