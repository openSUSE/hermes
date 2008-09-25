class MsgTypeParameter < ActiveRecord::Base
  set_table_name :msg_types_parameters
  belongs_to :parameter
  belongs_to :msg_type
end
