class AddCommentToMsgTypesPeople < ActiveRecord::Migration
  def self.up
    add_column :msg_types_people, :comment, :text
  end

  def self.down
    remove_column :msg_types_people, :comment
  end
end
