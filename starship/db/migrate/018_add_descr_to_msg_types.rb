class AddDescrToMsgTypes < ActiveRecord::Migration
  def self.up
    add_column :msg_types, :description, :text
  end

  def self.down
    remove_column :msg_types, :description
  end
end
