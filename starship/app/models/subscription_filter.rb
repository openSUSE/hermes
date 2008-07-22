class SubscriptionFilter < ActiveRecord::Base
  belongs_to :subscription
  belongs_to :parameter
end
