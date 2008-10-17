class RenameToSubscriptions < ActiveRecord::Migration
  def self.up
    rename_table( 'msg_types_people', 'subscriptions' )
  end

  def self.down
    rename_table( 'subscriptions', 'msg_types_people' )
  end
end
