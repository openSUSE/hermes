class Person < ActiveRecord::Base
  set_table_name "persons"
  has_and_belongs_to_many :messages
  has_and_belongs_to_many :msg_types
end
