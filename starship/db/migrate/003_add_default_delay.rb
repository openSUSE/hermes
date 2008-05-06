
class AddDefaultDelay < ActiveRecord::Migration

  def self.up
    add_column "msg_types", "defaultdelay", :integer
  end

  def self.down
    remove_column "msg_types", "defaultdelay"
  end


end
