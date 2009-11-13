class AddDeliveryPublicFlag < ActiveRecord::Migration
  def self.up
    add_column :deliveries, :public, :boolean, :default => true
  end

  def self.down
    remove_column :deliveries, :public
  end
end
