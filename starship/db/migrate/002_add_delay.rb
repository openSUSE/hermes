class AddDelay < ActiveRecord::Migration
  def self.up
    Delay.create( :name => 'NO_DELAY'    ) 
    Delay.create( :name => 'PER_MINUTE'  ) 
    Delay.create( :name => 'PER_HOUR'    ) 
    Delay.create( :name => 'PER_DAY'     ) 
    Delay.create( :name => 'PER_WEEK'    ) 
    Delay.create( :name => 'PER_MONTH'   ) 
  end

  def self.down
    Delay.find(:all).each{ |d| d.destroy } 
  end
end
