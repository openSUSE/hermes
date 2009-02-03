class StarshipMessageState < ActiveRecord::Migration
  def self.up

    create_table "msg_states", :force => true do |t|
      t.string  "state",     :limit => 64
      t.string  "description"
    end

    add_column :starship_messages, :msg_type_id, :integer, :null => false 
    add_column :starship_messages, :msg_state_id, :integer

    MsgState.create( :state => 'new', :description => 'This message was never displayed nor read' )
    MsgState.create( :state => 'unread', :description => 'This message was not yet read' )
    MsgState.create( :state => 'read', :description => 'This message was read' )
    MsgState.create( :state => 'deleted', :description => 'This message was deleted and will go away forever soon' )
  end

  def self.down
    remove_column :starship_messages, :msg_type_id
    remove_column :starship_messages, :msg_state_id
    drop_table :msg_states
  end
end
