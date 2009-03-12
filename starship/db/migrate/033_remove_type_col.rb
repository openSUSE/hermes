class RemoveTypeCol < ActiveRecord::Migration
  def self.up
    remove_column :starship_messages, :type
  end

  def self.down
    add_column :starship_messages, :type, :string
  end
end
