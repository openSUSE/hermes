class AddDeliveriesAttribs < ActiveRecord::Migration
  def self.up
    create_table "delivery_attributes", :force => true do |t|
      t.integer "delivery_id", :null => false
      t.string "attribute"
      t.string "value"
    end
  end

  def self.down
    drop_table :delivery_attributes
  end
end
