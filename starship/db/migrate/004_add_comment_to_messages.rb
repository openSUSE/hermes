class AddCommentToMessages < ActiveRecord::Migration
  def self.up
    add_column :messages, :comment, :text
  end

  def self.down
    remove_column :messages, :comment
  end
end
