class AddDelivery < ActiveRecord::Migration
  def self.up
    Delivery.create( :name => 'Mail' )
    Delivery.create( :name => 'RSS' )
    Delivery.create( :name => 'Jabber Conference Room' )
    Delivery.create( :name => 'Jabber Personal Message' )
  end

  def self.down
    Delivery.find(:all).each{ |d| d.destroy } 
  end
end
