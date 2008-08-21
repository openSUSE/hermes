class Notification < ActiveRecord::Base
  has_many :notification_parameters, :dependent => :destroy
end
