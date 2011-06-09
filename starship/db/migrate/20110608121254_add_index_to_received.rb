class AddIndexToReceived < ActiveRecord::Migration
  def self.up
    add_index :notifications, :received
  end

  def self.down
    remove_index :notifications, :received
  end
end
