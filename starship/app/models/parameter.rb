class Parameter < ActiveRecord::Base
  has_many :filters, :class_name => "SubscriptionFilter"
  has_and_belongs_to_many :msg_types
  has_one :notification_parameter
end
