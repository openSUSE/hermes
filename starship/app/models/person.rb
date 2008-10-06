class Person < ActiveRecord::Base
  set_table_name "persons"
  has_and_belongs_to_many :messages
  has_many :msg_types, :through => :subscriptions 
  has_many :subscriptions

  def subscribed_to(msgtype)
    not subscriptions.find(:first, :conditions => {:msg_type_id => msgtype}).nil?
  end
  
  
  
  def subscribed_to_abstraction(group_id, abstraction_id, filter_abstraction_id)    
    abstraction = SUBSCRIPTIONABSTRACTIONS[group_id][abstraction_id]
    
    # use the first subscription of the user that matches all criteria from the abstraction (msgtype, filters)
    subscriptions.find(:all, :conditions => [ "msg_types.msgtype = ?", abstraction.msg_type],
      :include => [:delay,:delivery,:msg_type] ).each do | subscription | 
        
       #TODO: take the first of these subscriptions that has the same filters as the filterabstract 
        
      logger.debug "Found matching subscription for #{abstraction.msg_type}: #{filter_abstraction_id}" 
        
      return true
    end
    

    return false
  end
  
  
end
