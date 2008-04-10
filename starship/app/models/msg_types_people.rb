class MsgTypesPeople < ActiveRecord::Base
  set_table_name "msg_types_people"
  belongs_to :msg_type
  belongs_to :person
  belongs_to :delay
  belongs_to :delivery 
end
