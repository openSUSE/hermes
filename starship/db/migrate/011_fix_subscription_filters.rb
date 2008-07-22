class FixSubscriptionFilters < ActiveRecord::Migration
  def self.up
    rename_table :subscription_filter, :subscription_filters
  end

  def self.down
    rename_table :subscription_filters, :subscription_filter
  end
end
