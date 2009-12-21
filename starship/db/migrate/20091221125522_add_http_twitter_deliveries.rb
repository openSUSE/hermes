class AddHttpTwitterDeliveries < ActiveRecord::Migration
  def self.up
    Delivery.create( :name => 'HTTP', :public => false )
    Delivery.create( :name => 'Twitter', :public => false )
  end

  def self.down
    Delivery.find(:name => 'HTTP' ).each{ |d| d.destroy }
    Delivery.find(:name => 'Twitter').each{ |d| d.destroy }
  end
end
