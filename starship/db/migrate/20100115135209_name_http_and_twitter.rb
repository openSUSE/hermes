class NameHttpAndTwitter < ActiveRecord::Migration
  def self.up
    Delivery.update_all( "description='HTTP-GET (fixme)'", "name='HTTP'" )
    Delivery.update_all( "description='Twitter (fixme)'", "name='Twitter'" )
  end

  def self.down
    Delivery.update_all( "description=''", "name='HTTP'" )
    Delivery.update_all( "description=''", "name='Twitter'" )
  end
end
