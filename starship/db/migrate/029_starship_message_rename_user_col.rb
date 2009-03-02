class StarshipMessageRenameUserCol < ActiveRecord::Migration
  def self.up
    rename_column :starship_messages, :user_id, :person_id
  end

  def self.down
    rename_column :starship_messages, :person_id, :user_id
  end
end
