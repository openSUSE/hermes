class Subscription < ActiveRecord::Base
  belongs_to :person
  belongs_to :msg_type
  belongs_to :delay
  belongs_to :delivery

  has_many :starship_messages, :dependent => :destroy
  has_many :filters, :class_name => "SubscriptionFilter", :dependent => :destroy
  has_many :generated_notifications

  validates_presence_of :delay
  validates_presence_of :delivery
  
  def initialize(attribs={})
    super(attribs)
    self.delay = Delay.find_by_name( 'NO_DELAY' ) unless self.delay.present?
    self.delivery = Delivery.find_by_name( 'Mail' ) unless self.delivery.present?
    self
  end

  def subscription_desc
    if (description)
      return description
    end
   return  "#{msg_type.type_desc} (#{filters.count}  filters)"
  end

  def abstraction_filters
    FILTERABSTRACTIONS.select{|name, abs| abs.valid_msg_types.include? msg_type.msgtype }
  end

end
