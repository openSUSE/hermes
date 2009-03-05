## parse xml files from config/guiabstractions
require 'xml/smart'

# hashes with key: element-id, value object
abstractions = Hash.new
filterabstractions = Hash.new
abstractiongroups = Hash.new

Dir["#{RAILS_ROOT}/config/guiabstractions/*.xml"].each { |file|
  begin 
    xml = XML::Smart.open(file)
    
    xml.root.find("//filterabstract").each do | node | 
      filter_abstraction = FilterAbstract.new()
      filter_abstraction.id = node.find("@id").first.value
      filter_abstraction.summary = node.find("summary").first.text
      filter_abstraction.description = node.find("description").first.text
      filter_abstraction.filters = Array.new
      node.find("filter").each do | filternode |
        filter = SubscriptionFilter.new
        filter.operator = filternode.find("@operator").first.value
        filter.filterstring = filternode.find("@value").first.value
        db_parameter = Parameter.find(:all, 
                              :conditions => "name='" + filternode.find("@parameter").first.value + "'").first
        if (db_parameter.nil?)
          db_parameter = Parameter.new
          db_parameter.name = filternode.find("@parameter").first.value
          db_parameter.save
          puts "Created parameter #{db_parameter.name} because it's used in an abstraction."
        end
        filter.parameter_id = db_parameter.id
        filter_abstraction.filters << filter
      end
      
      filterabstractions[node.find("@id").first.value] = filter_abstraction
    end
    
    xml.find("//group").each do | node | 
      group_id = node.find("@id").first.value
      abstractiongroups[group_id] = node.find("name").first.text
      abstractions[group_id] = Hash.new

      node.find("subscription").each do | subscription_node | 
        abstraction = SubscriptionAbstract.new()
        abstraction.summary = subscription_node.find("summary").first.text
        abstraction.description = subscription_node.find("description").first.text
        abstraction.msg_type = subscription_node.find("msg_type/@name").first.value
        
        if (MsgType.find(:first, :conditions => "msgtype =  '#{abstraction.msg_type}'").nil?)
          msg_type = MsgType.new
          msg_type.msgtype = abstraction.msg_type
          msg_type.added = Time.now
          msg_type.save
          puts "Created msg_type #{abstraction.msg_type} because it's used in an abstraction."
        end
        
        abstraction.id = subscription_node.find("@id").first.value
        abstraction.filterabstracts = Hash.new
        
        #add filter abstractions
        subscription_node.find("checkable").each do | checkable_node |
          filterabstract_name = checkable_node.find("@filterabstract").first.value
          abstraction.filterabstracts[filterabstract_name] = filterabstractions[filterabstract_name]
        end
        abstractions[group_id][abstraction.id] = abstraction
      end
      
    end
  
    puts "Loaded gui abstraction from #{file}"
  rescue Exception => e
    puts "Error parsing #{file}: #{e.to_s}"
  end
}

SUBSCRIPTIONABSTRACTIONS = abstractions
ABSTRACTIONGROUPS = abstractiongroups