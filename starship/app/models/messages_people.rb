class MessagesPeople < ActiveRecord::Base
  belongs_to :people
  belongs_to :messages
end
