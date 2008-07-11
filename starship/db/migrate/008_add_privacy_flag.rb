class AddPrivacyFlag < ActiveRecord::Migration
  def self.up
    add_column :msg_types_people, :private, :boolean
  end

  def self.down
    remove_column :msg_types_people, :private
  end
end
