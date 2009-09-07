class Notification < ActiveRecord::Base
  has_many :notification_parameters, :dependent => :destroy
  has_many :starship_messages
  belongs_to :msg_type
  belongs_to :generated_notification
end
