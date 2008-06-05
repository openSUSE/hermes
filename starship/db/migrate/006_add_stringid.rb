class AddStringid < ActiveRecord::Migration
  def self.up
    add_column :persons, :stringid, :string
  end

  def self.down
    remove_column :persons, :stringid
  end
end
