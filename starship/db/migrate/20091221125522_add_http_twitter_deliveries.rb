class AddHttpTwitterDeliveries < ActiveRecord::Migration
  def self.up
    Delivery.create( :name => 'HTTP', :public => false )
    Delivery.create( :name => 'Twitter', :public => false )
  end

  def self.down
    Delivery.find_by_name('HTTP').destroy
    Delivery.find_by_name('Twitter').destroy
  end
end
