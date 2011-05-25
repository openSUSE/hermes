class SubscriptionsController < ApplicationController


  def simple
    @person = Person.find session[:userid]
    @hermestitle = "Subscriptions for #{@person.stringid} (#{@person.email})"
    @abstraction_groups = ABSTRACTIONGROUPS
    @abstractions = SUBSCRIPTIONABSTRACTIONS
    @subscribedMsgs = @person.subscriptions.find(:all)

    @avail_deliveries = valid_deliveries;
    @avail_delays = Delay.find(:all, :order => 'id').map {|d| [d.description, d.id]}
  end

  
  def index
    @person = Person.find session[:userid]
    @hermestitle = "Subscriptions for #{@person.stringid} (#{@person.email})"
  
    @subscribedMsgs = @person.subscriptions.find( :all, :include => [:msg_type,:delay,:delivery])
    #@latestMsgs = @person.messages.find(:all, :include => :msg_type, :order => "created DESC", :limit => 10)
  
    @avail_types = MsgType.find(:all, :order => 'description, msgtype DESC')
    @avail_deliveries = valid_deliveries
    @avail_delays = Delay.find(:all)
  
    # Tooltip for the filters of a subscription, to view in the expert overview
    @filter_tooltips = Hash.new
    @subscribedMsgs.each {|subs|
      if subs.filters.count > 0
        subs.filters.each_with_index{|filt,i|
          @filter_tooltips[subs.id] ||= "<table><tr><td></td><td><b>Parameter</b></td><td><b>Operator</b></td><td><b>Value</b></td></tr>"
          @filter_tooltips[subs.id] += "<tr><td>#{i+1}.</td><td>#{filt.parameter.name}</td><td>#{filt.operator}</td><td>#{filt.filterstring}</td></tr>"
        }
        @filter_tooltips[subs.id] += "</table>"
      end
    }
  end
  
  def create
    valid_http_methods :post
    user = Person.find session[:userid]
    sub_param = params[:subscr]
    sub_param[:person_id] = session[:userid]
    sub = Subscription.new(sub_param)
    logger.debug("Creating subscription for #{params["sub_param"]}")
    #      0.upto(params[:filter_count].to_i-1) { |counter|
    #        # set the parameter_id of the _special filter
    #        params["param_id_#{counter}"] ||= (Parameter.find(:first, :conditions => {:name => '_special'})).id
    #        logger.debug("[Create Subscription] add filter: #{params["filter_value_#{counter}"]}")
    #        sub.filters <<  SubscriptionFilter.new( :parameter_id => params["param_id_#{counter}"], :operator => params["filter_operator_#{counter}"],
    #          :filterstring => SubscriptionFilter.replaced_filterstring(params["filter_value_#{counter}"], user.stringid) )
    #      }
    if sub.save
      redirect_to :action => 'edit', :id => sub.id;
    else
      redirect_to_index(sub.errors.full_messages())
      sub.errors.clear()
    end
  end
  
  
  def modify_simple_subscriptions
    valid_http_methods :post
    flash[:success] = ""
    flash[:error] = ""

    user = Person.find session[:userid]
      
    SUBSCRIPTIONABSTRACTIONS.keys.each do | group_id |
      SUBSCRIPTIONABSTRACTIONS[group_id].values.each do | abstraction |
        abstraction.filterabstracts.values.each do | filterabstract |
          # load matching user subscription
          subscription = user.subscribed_to_abstraction(group_id, abstraction.id, filterabstract.id)
          if ( params["#{abstraction.id}||#{filterabstract.id}"])
            if (!subscription)
              logger.debug "Adding subscription for filterabstraction #{abstraction.id}||#{filterabstract.id}"
                
              subscription = Subscription.new(:msg_type_id => MsgType.find(:first, :conditions => "msgtype =  '#{abstraction.msg_type}'").id,
                :person_id => user.id, :delay_id => params["#{abstraction.id}||#{filterabstract.id}||delay"].to_i,
                :delivery_id => params["#{abstraction.id}||#{filterabstract.id}||delivery"].to_i,
                :description => "#{abstraction.summary} / #{filterabstract.summary}")
                
              filterabstract.filters.each do | filter |
                subscription.filters <<  SubscriptionFilter.new( :parameter_id => filter.parameter_id,
                  :operator => filter.operator,
                  :filterstring => SubscriptionFilter.replaced_filterstring(filter.filterstring, user.stringid) )
              end
              if subscription.save
                flash[:success] += "Subscription for #{abstraction.summary} - #{filterabstract.summary} has been added.\n"
              else
                flash[:error] = "Adding new subscription for #{abstraction.summary} - #{filterabstract.summary} failed.\n"
              end
            elsif (params["#{abstraction.id}||#{filterabstract.id}||delay"].to_i != subscription.delay_id ||
                  params["#{abstraction.id}||#{filterabstract.id}||delivery"].to_i != subscription.delivery_id)
              logger.debug "Updating Filterabstract #{abstraction.id}||#{filterabstract.id}"
              subscription.delay_id = params["#{abstraction.id}||#{filterabstract.id}||delay"].to_i
              subscription.delivery_id = params["#{abstraction.id}||#{filterabstract.id}||delivery"].to_i
              if subscription.save
                flash[:success] += "Subscription for #{abstraction.summary} - #{filterabstract.summary} has been updated.\n"
              else
                flash[:error] += "Subscription for #{abstraction.summary} - #{filterabstract.summary} update failed.\n"
              end
            end
          elsif ( !params["#{abstraction.id}||#{filterabstract.id}"] && subscription)
            logger.debug "Removing Filterabstract #{abstraction.id}||#{filterabstract.id}"
            if subscription.destroy
              flash[:success] += "Subscription for #{abstraction.summary} - #{filterabstract.summary} has been removed.\n"
            else
              flash[:error] += "Removing subscription for #{abstraction.summary} - #{filterabstract.summary} failed.\n"
            end
          end
        end
      end
    end
    redirect_to :action => :simple
  end
  
  
  def destroy
    valid_http_methods :delete
    user = Person.find session[:userid]
    curr_subscr = user.subscriptions.find(:first, :conditions => {:id => params[:id]})
    if curr_subscr
      curr_subscr.destroy
      redirect_to_index "Subscription for #{curr_subscr.msg_type.msgtype} deleted"
    else
      redirect_to_index "Only your own subscriptions can be deleted."
    end
  end
  
  
  def edit
    user = Person.find session[:userid]
    @subscr = user.subscriptions.find(params[:id])
    @filters = @subscr.filters
    @availDelay = Delay.find(:all)
    @availDeliveries = valid_deliveries
    @avail_params = @subscr.msg_type.parameters
  end
  
  
  def update
    valid_http_methods :put
    user = Person.find session[:userid]
    @subscr = user.subscriptions.find(params[:id])
    if @subscr.update_attributes params[:subscr]
      @subscr.filters.each { |filt|
        filt.destroy
      }
      0.upto(params[:filter_count].to_i-1) { |counter|
        params["param_id_#{counter}"] ||= (Parameter.find(:first, :conditions => {:name => '_special'})).id
  	    @subscr.filters << SubscriptionFilter.new( :subscription_id => @subscr.id, :parameter_id => params["param_id_#{counter}"], :operator => params["filter_operator_#{counter}"], :filterstring => params["filter_value_#{counter}"] )
  	  }
      redirect_to_index "Subscription updated"
    else
      redirect_to_index(@subscr.errors.full_messages())
      @subscr.errors.clear()
    end
  end
  
  
  def get_type_params
    param_list = MsgType.find(params[:msg_type]).parameters
    #param_list = param_list.map{|param| param.name}
    logger.debug "Available parameters for msg_type #{params[:msg_type]}: #{param_list.inspect}"
    render :partial => 'filter_param', :locals => {:param_list => param_list, :selected => nil}
  end


  def add_filter_line
    param_list = MsgType.find(params[:msg_type]).parameters
    render :partial => 'filter', :locals => {:parameter_list => param_list, :selected_param => nil, :selected_oper => nil, :value => nil }
  end


  def toggle_enabled
    user = Person.find session[:userid]
    @curr_sub = user.subscriptions.find(params[:subs])
    if @curr_sub.enabled
      @curr_sub.enabled = false
      @status = "Disabled"
    else 
      @curr_sub.enabled = true
      @status = "Enabled"
    end
    @curr_sub.save
    render :text => @status
  end


  private

  def valid_deliveries
    person = Person.find session[:userid]
    if person && person.admin
      deliver = Delivery.find(:all, :order => 'id')
    else
      deliver = Delivery.find(:all, :conditions => ["public = 1"], :order => 'id')
    end
    return deliver
  end

  def redirect_to_index(msg = nil)
    flash[:note] = msg
    redirect_to :action => :index
  end
  
end
