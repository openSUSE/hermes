class AddIndexToPersonId < ActiveRecord::Migration
  def self.up
    add_index :starship_messages, :person_id
  end

  def self.down
    remove_index :starship_messages, :person_id
  end
end
