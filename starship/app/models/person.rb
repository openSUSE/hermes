class Person < ActiveRecord::Base
  set_table_name "persons"
  has_and_belongs_to_many :messages
end
