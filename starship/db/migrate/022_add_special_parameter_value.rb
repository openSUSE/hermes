class AddSpecialParameterValue < ActiveRecord::Migration
  def self.up
   Parameter.create :name => '_special'
  end

  def self.down
    param = Parameter.find(:first, :conditions => { :name => '_special' } )
    param.destroy
  end
end
