class StarshipMessage < ActiveRecord::Base
  belongs_to :notification
  belongs_to :subscription
  belongs_to :msg_type
  belongs_to :msg_state
  belongs_to :person  
end
