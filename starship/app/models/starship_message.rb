class StarshipMessage < ActiveRecord::Base
  set_table_name :starship_messages

  belongs_to :subscription
  belongs_to :msg_type
  belongs_to :msg_state
  
end
