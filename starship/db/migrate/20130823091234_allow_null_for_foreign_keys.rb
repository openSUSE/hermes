class AllowNullForForeignKeys < ActiveRecord::Migration
  def change
    change_column :subscriptions, :msg_type_id, :integer, :null => true
    change_column :subscriptions, :person_id, :integer, :null => true
  end
end
