class SubscriptionFiltersAllowNull < ActiveRecord::Migration
  def change
    change_column :subscription_filters, :subscription_id, :integer, :null => true
    change_column :subscription_filters, :parameter_id, :integer, :null => true
  end
end
