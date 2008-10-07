class Person < ActiveRecord::Base
  set_table_name "persons"
  has_and_belongs_to_many :messages
  has_many :msg_types, :through => :subscriptions
  has_many :filters, :through => :subscriptions
  has_many :subscriptions


  def subscribed_to(msgtype)
    not subscriptions.find(:first, :conditions => {:msg_type_id => msgtype}).nil?
  end
   
  
  def subscribed_to_abstraction(group_id, abstraction_id, filter_abstraction_id)    
    abstraction = SUBSCRIPTIONABSTRACTIONS[group_id][abstraction_id]
    
    # use the first subscription of the user that matches all criteria from the abstraction (msgtype, filters)
    subscriptions.find(:all, :conditions => [ "msg_types_people.enabled = 1 and msg_types.msgtype = ?", abstraction.msg_type],
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
  
  
end
