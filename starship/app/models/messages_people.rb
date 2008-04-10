class MessagesPeople < ActiveRecord::Base
  set_table_name :messages_people
  belongs_to :person
  belongs_to :message
end
