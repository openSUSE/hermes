class Delivery < ActiveRecord::Base
  has_many :msg_types_people
end
