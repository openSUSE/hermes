class NotificationParameter < ActiveRecord::Base
  belongs_to :notification
  belongs_to :type, :class_name => "Parameter", :foreign_key => :parameter_id
end
