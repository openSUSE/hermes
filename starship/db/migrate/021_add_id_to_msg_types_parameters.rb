class AddIdToMsgTypesParameters < ActiveRecord::Migration
  def self.up
    add_column :msg_types_parameters, :id, :primary_key, :auto_increment => true, :null => false
  end

  def self.down
    remove_column :msg_types_parameters, :id
  end
end
