class Subscription < ActiveRecord::Base
  belongs_to :person
  belongs_to :msg_type
  belongs_to :delay
  belongs_to :delivery

  has_many :starship_messages
  has_many :filters, :class_name => "SubscriptionFilter", :dependent => :destroy
  has_many :generated_notifications

  validates_presence_of :delay
  validates_presence_of :delivery
  
  
  def subscription_desc
    if (description)
      return description
    end
   return  "#{msg_type.type_desc} (#{filters.count}  filters)"
    
  end
  
end
