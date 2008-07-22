class AddNotificationFilters < ActiveRecord::Migration
  def self.up
    rename_table :msg_type_parameters, :parameters
    
    create_table :subscription_filter do |t|
      t.integer :subscription_id, :null => false
      t.integer :parameter_id, :null => false
      t.string :operator, :null => false
      t.string :filterstring, :null => false
    end
    add_index :subscription_filter, [:subscription_id], :name => "subscription_id"
    add_index :subscription_filter, [:parameter_id], :name => "parameter_id"

    create_table :msg_types_parameters, :id => false do |t|
      t.integer :msg_type_id, :null => false
      t.integer :parameter_id, :null => false
    end
    add_index :msg_types_parameters, [:msg_type_id, :parameter_id],
      :name => "msg_type_parameter_id", :unique => true
  end

  def self.down
    drop_table :msg_types_parameters
    drop_table :subscription_filter

    rename_table :parameter, :msg_type_parameters
  end
end
