class Person < ActiveRecord::Base
  set_table_name "persons"
  has_and_belongs_to_many :messages
  has_many :msg_types, :through => :subscriptions 
  has_many :subscriptions

  def subscribed_to(msgtype)
    not subscriptions.find(:first, :conditions => {:msg_type_id => msgtype}).nil?
  end
end
