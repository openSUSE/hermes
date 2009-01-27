class NotiInbox < ActiveRecord::Base
  belongs_to :msg_types
  has_many :noti_inbox_params
  table_name :noti_inbox
end
