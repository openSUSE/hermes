## parse xml files from config/guiabstractions
require 'xml/smart'

# hashes with key: element-id, value object
abstractions = {}
filterabstractions = {}
abstractiongroups = {}

Dir["#{RAILS_ROOT}/config/guiabstractions/*.xml"].each { |file|
  begin 
    xml = XML::Smart.open(file)
    
    xml.root.find("//filterabstract").each do | node | 
      filter_abstraction = FilterAbstract.new()
      filter_abstraction.summary = node.find("summary").first.text
      filter_abstraction.description = node.find("description").first.text
      filter_abstraction.filters = Array.new
      node.find("filter").each do | filternode |
        filter = SubscriptionFilter.new
        filter.operator = filternode.find("@operator").first.value
        filter.filterstring = filternode.find("@value").first.value
        filter.parameter_id = Parameter.find(:all, 
                              :conditions => "name='" + filternode.find("@parameter").first.value + "'").first.id
        filter_abstraction.filters << filter
      end
      
      filterabstractions[node.find("@id").first.value] = filter_abstraction
    end
    
    xml.find("//group").each do | node | 
      group_id = node.find("@id").first.value
      abstractiongroups[group_id] = node.find("name").first.text
      abstractions[group_id] = Array.new

      node.find("subscription").each do | subscription_node | 
        abstraction = SubscriptionAbstract.new()
        abstraction.summary = subscription_node.find("summary").first.text
        abstraction.description = subscription_node.find("description").first.text
        abstraction.msg_type = subscription_node.find("msg_type/@name").first.value
        abstraction.filterabstracts = Array.new
        
        #add filter abstractions
        subscription_node.find("checkable").each do | checkable_node |
          abstraction.filterabstracts << filterabstractions[checkable_node.find("@filterabstract").first.value]
        end
        abstractions[group_id] << abstraction
      end
      
    end
  
    puts "Loaded gui abstraction from #{file}"
  rescue Exception => e
    puts "Error parsing #{file}: #{e.to_s}"
  end
}

debugger

SUBSCRIPTIONABSTRACTIONS = abstractions
ABSTRACTIONGROUPS = abstractiongroups