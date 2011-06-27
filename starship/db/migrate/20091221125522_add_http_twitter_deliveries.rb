class AddHttpTwitterDeliveries < ActiveRecord::Migration
  def self.up
    Delivery.create( :name => 'HTTP' )
    Delivery.create( :name => 'Twitter' )
  end

  def self.down
    Delivery.find_by_name('HTTP').destroy
    Delivery.find_by_name('Twitter').destroy
  end
end
