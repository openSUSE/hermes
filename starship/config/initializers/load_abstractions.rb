## parse xml files from config/guiabstractions
gem 'libxml-ruby', '>= 0.8.3'
require 'xml'


# hashes with key: element-id, value object
abstractions = Hash.new
filterabstractions = Hash.new
abstractiongroups = Hash.new

## skip automatically in rake db:migrate
if (ENV['RAILS_ENV'])
  Dir["#{RAILS_ROOT}/config/guiabstractions/*.xml"].each { |file|
    begin 
      
      parser = XML::Parser.file( file )
                                                         
      doc = parser.parse
      
      doc.find("//filterabstract").each do | node | 
        filter_abstraction = FilterAbstract.new()
        filter_abstraction.id = node["id"]
                                                         
        filter_abstraction.summary = node.find_first("summary").content
        filter_abstraction.description = node.find_first("description").content
        filter_abstraction.filters = Array.new
        node.find("filter").each do | filternode |
          filter = SubscriptionFilter.new
          filter.operator = filternode["operator"]
          filter.filterstring = filternode["value"]
          db_parameter = Parameter.find(:all, 
                                        :conditions => "name='" + filternode["parameter"]+ "'").first
          if (db_parameter.nil?)
            db_parameter = Parameter.new
            db_parameter.name = filternode["parameter"]
            db_parameter.save
            puts "Created parameter #{db_parameter.name} because it's used in an abstraction."
          end
          filter.parameter_id = db_parameter.id
          filter_abstraction.filters << filter
        end
        filterabstractions[filter_abstraction.id] = filter_abstraction
      end

      doc.find("//group").each do | node | 
        group_id = node["id"]
        abstractiongroups[group_id] = node.find_first("name").content
        abstractions[group_id] = Hash.new
        
        subscounter = 0

        node.find("subscription").each do | subscription_node | 
          abstraction = SubscriptionAbstract.new()
          abstraction.summary = subscription_node.find_first("summary").content
          abstraction.description = subscription_node.find_first("description").content
          abstraction.msg_type = subscription_node.find_first("msg_type")["name"]
          abstraction.sort_key = subscounter += 1

          if ((msg_type = MsgType.find(:first, :conditions => "msgtype =  '#{abstraction.msg_type}'")).nil?)
            msg_type = MsgType.new
            msg_type.msgtype = abstraction.msg_type
            msg_type.added = Time.now
            puts "Created msg_type #{abstraction.msg_type} because it's used in an abstraction."
          end
          msg_type.save
          abstraction.id = subscription_node["id"]
          abstraction.filterabstracts = Hash.new
          
          #add filter abstractions
          subscription_node.find("checkable").each do | checkable_node |
            filterabstract_name = checkable_node["filterabstract"]
            abstraction.filterabstracts[filterabstract_name] = filterabstractions[filterabstract_name]
            # add connection msg_type <-> parameter
            filterabstractions[filterabstract_name].filters.each do |subsfilter|
              if (msg_type.parameters.find(:first, :conditions => ["parameter_id= ?", subsfilter.parameter_id]).nil?)
                msg_type.parameters << Parameter.find(:first, :conditions => ["id= ?", subsfilter.parameter_id])
              end
            end
          end
          msg_type.save
          abstractions[group_id][abstraction.id] = abstraction
        end
        
      end
    
      puts "Loaded gui abstraction from #{file}"
    rescue Exception => e
      puts "Error parsing #{file}: #{e.to_s}"
    end
  }
 
  FILTERABSTRACTIONS = filterabstractions 
  SUBSCRIPTIONABSTRACTIONS = abstractions
  ABSTRACTIONGROUPS = abstractiongroups
end
