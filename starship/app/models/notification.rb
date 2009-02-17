class Notification < ActiveRecord::Base
  has_many :notification_parameters, :dependent => :destroy
  belongs_to :msg_type
  belongs_to :generated_notification
end
