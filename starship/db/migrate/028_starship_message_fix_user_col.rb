class StarshipMessageFixUserCol < ActiveRecord::Migration
  def self.up
    rename_column :starship_messages, :user, :user_id
    change_column :starship_messages, :user_id, :integer 
  end

  def self.down
    change_column :starship_messages, :user_id, :string
    rename_column :starship_messages, :user_id, :user
  end
end
