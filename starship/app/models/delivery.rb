class Delivery < ActiveRecord::Base
  has_many :subscriptions
end
