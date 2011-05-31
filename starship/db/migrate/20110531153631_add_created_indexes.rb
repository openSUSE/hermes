class AddCreatedIndexes < ActiveRecord::Migration
  def self.up
    add_index :starship_messages, :created
  end

  def self.down
    remove_index :starship_messages, :created
  end
end
