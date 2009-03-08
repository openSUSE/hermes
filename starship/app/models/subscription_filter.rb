class SubscriptionFilter < ActiveRecord::Base
  belongs_to :subscription
  belongs_to :parameter
  
  
  def replaced_filterstring (username)
    return SubscriptionFilter.replaced_filterstring(filterstring, username)
  end
  
  def self.replaced_filterstring (filterstring, username)
    my_filterstring = filterstring.gsub(/\$\{username\}/, "#{username}")
    return my_filterstring
  end
  
  
end
