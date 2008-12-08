require 'digest/sha1'

class Person < ActiveRecord::Base
  set_table_name "persons"
  has_and_belongs_to_many :messages
  has_many :msg_types, :through => :subscriptions
  has_many :filters, :through => :subscriptions
  has_many :subscriptions

  attr_protected :id, :salt
  attr_accessor :password, :password_confirmation

  # this contains code (basic auth) from 
  # http://www.aidanf.net/rails_user_authentication_tutorial

  def subscribed_to(msgtype)
    not subscriptions.find(:first, :conditions => {:msg_type_id => msgtype}).nil?
  end
   
  
  def subscribed_to_abstraction(group_id, abstraction_id, filter_abstraction_id)    
    abstraction = SUBSCRIPTIONABSTRACTIONS[group_id][abstraction_id]
    
    # use the first subscription of the user that matches all criteria from the abstraction (msgtype, filters)
    subscriptions.find(:all, :conditions => [ "subscriptions.enabled = 1 and msg_types.msgtype = ?", abstraction.msg_type],
      :include => [:msg_type] ).each do | subscription | 
        hits = 0
        abstraction.filterabstracts[filter_abstraction_id].filters.each do | filter |
          #logger.debug "Checking for filter #{filter.inspect} in user subscription : #{subscription.filters.inspect}" 
          
          if ( not subscription.filters.find(:first, :conditions => {:parameter_id => filter.parameter_id, 
            :operator => filter.operator, :filterstring => filter.filterstring}).nil? )
            hits += 1
          end
        end
        if (hits == abstraction.filterabstracts[filter_abstraction_id].filters.size)
          #logger.debug "We have one: #{subscription.inspect}"
          return subscription
        end
    end

    return false
  end

  def self.authenticate(login, pass)
    u=find(:first, :conditions=>["stringid = ?", login])
    return nil if u.nil?
    return u if Person.encrypt(pass, u.salt)==u.hashed_password
    nil
  end  

  def password=(pass)
    @password=pass
    self.salt = Person.random_string(10) if !self.salt?
    self.hashed_password = Person.encrypt(@password, self.salt)
  end




protected

  def self.encrypt(pass, salt)
    Digest::SHA1.hexdigest(pass+salt)
  end

  def self.random_string(len)
    #generat a random password consisting of strings and digits
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end
  
end
