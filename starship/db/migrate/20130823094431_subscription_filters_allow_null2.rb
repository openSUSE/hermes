class SubscriptionFiltersAllowNull2 < ActiveRecord::Migration
  def change
    change_column :subscription_filters, :operator, :string, :null => true
    change_column :subscription_filters, :filterstring, :string, :null => true
  end
end
