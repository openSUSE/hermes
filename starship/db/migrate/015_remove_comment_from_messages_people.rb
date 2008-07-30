class RemoveCommentFromMessagesPeople < ActiveRecord::Migration
  def self.up
    remove_column :messages_people, :comment
  end

  def self.down
    add_column :messages_people, :comment, :text
  end
end
