class AddSpecialParameterValue < ActiveRecord::Migration
  def self.up
    Parameter.create :name => '_special'

    #change the parameter for all existing filters with operator = special
    filter = SubscriptionFilter.find (:all, :conditions => { :operator => 'special'})

    filter.each { |f|
      f.parameter = Parameter.find(:first, :conditions => {:name => '_special'})
      f.save
    }
  
  end

  def self.down
    param = Parameter.find(:first, :conditions => { :name => '_special' } )
    param.destroy

    filter = SubscriptionFilter.find (:all, :conditions =>{ :operator => 'special'})

    filter.each { |f|
      f.parameter = Parameter.find(:first) 
      f.save
    }

  end
end
