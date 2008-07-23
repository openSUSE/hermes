class AddNotiGeneratedTs < ActiveRecord::Migration
  def self.up
    add_column :notifications, :generated, :timestamp
  end

  def self.down
    remove_column :notifications, :generated
  end
end
