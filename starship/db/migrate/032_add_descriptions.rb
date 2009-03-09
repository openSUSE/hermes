class AddDescriptions < ActiveRecord::Migration
  def self.up
    add_column :delays, :description, :string, :null => true
    add_column :deliveries, :description, :string, :null => true
    
    execute "update deliveries set description='Web / RSS Newsfeed' where name='RSS'"
    execute "update deliveries set description='E-mail' where name='Mail'"
    execute "update deliveries set description='Jabber Conference Room' where name='Jabber Conference Room'"
    execute "update deliveries set description='Jabber Personal Message' where name='Jabber Personal Message'"
    
    execute "update delays set description='No digest / immediate delivery' where name='NO_DELAY'"
    execute "update delays set description='Group messages and send max. one per minute' where name='PER_MINUTE'"
    execute "update delays set description='Group messages and send max. one per hour' where name='PER_HOUR'"
    execute "update delays set description='Group messages and send max. one per day' where name='PER_DAY'"
    execute "update delays set description='Group messages and send max. one per week' where name='PER_WEEK'"
    execute "update delays set description='Group messages and send max. one per month' where name='PER_MONTH'"
    
    add_column :subscriptions, :description, :string, :null => true
    add_column :subscriptions, :name, :string, :null => true
    add_column :subscriptions, :config, :string, :null => true
    
  end

  def self.down
    remove_column :delays, :description
    remove_column :deliveries, :description
    
    remove_column :subscriptions, :description
    remove_column :subscriptions, :name
    remove_column :subscriptions, :config
  end
end
