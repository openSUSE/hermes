class Parameter < ActiveRecord::Base
  has_many :filters, :class_name => "SubscriptionFilter"
  #has_and_belongs_to_many :msg_types
  has_many :msg_type_parameters
  has_many :parameters, :through => :msg_type_parameters
  has_one :notification_parameter
  

  def param_desc
    return hr_name.nil? ? name : hr_name
  end
  
end