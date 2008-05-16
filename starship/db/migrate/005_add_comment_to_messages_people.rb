class AddCommentToMessagesPeople < ActiveRecord::Migration
  def self.up
    add_column :messages_people, :comment, :text
  end

  def self.down
    remove_column :messages_people, :comment
  end
end
