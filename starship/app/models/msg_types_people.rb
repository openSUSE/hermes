class MsgTypesPeople < ActiveRecord::Base
  belongs_to :msg_type
  belongs_to :person
  belongs_to :delay
  belongs_to :delivery 
end
