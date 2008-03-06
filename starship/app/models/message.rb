class Message < ActiveRecord::Base
  belongs_to :msg_type
  has_and_belongs_to_many :persons
end
