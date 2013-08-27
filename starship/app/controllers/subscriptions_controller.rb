class SubscriptionsController < ApplicationController


  def simple
    @person = Person.find session[:userid]
    @hermestitle = "Subscriptions for #{@person.stringid} (#{@person.email})"
    @abstraction_groups = ABSTRACTIONGROUPS
    @abstractions = SUBSCRIPTIONABSTRACTIONS
    @subscribedMsgs = @person.subscriptions.all()

    @avail_deliveries = valid_deliveries;
    @avail_delays = Delay.all(:order => 'id').map {|d| [d.description, d.id]}
  end

  
  def index
    @person = Person.find session[:userid]
    @hermestitle = "Subscriptions for #{@person.stringid} (#{@person.email})"
  
    @subscribedMsgs = @person.subscriptions.all( :include => [:msg_type,:delay,:delivery])
    #@latestMsgs = @person.messages.all( :include => :msg_type, :order => "created DESC", :limit => 10)
  
    @avail_types = MsgType.all( :order => 'description, msgtype DESC')
    @avail_deliveries = valid_deliveries
    @avail_delays = Delay.all()
  
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
    sub_param = params[:subscr]
    sub_param[:person_id] = session[:userid]
    sub = Subscription.new(sub_param)
    if sub.save
      redirect_to :action => 'edit', :id => sub.id;
    else
      redirect_to_index(sub.errors.full_messages())
      sub.errors.clear()
    end
  end
  
  
  def modify_simple_subscriptions
    #valid_http_methods :post
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
                
              subscription = Subscription.new(:msg_type_id => MsgType.first(:conditions => "msgtype =  '#{abstraction.msg_type}'").id,
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
    #valid_http_methods :delete
    user = Person.find session[:userid]
    curr_subscr = user.subscriptions.first(:conditions => {:id => params[:id]})
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
    @availDelay = Delay.all()
    @availDeliveries = valid_deliveries
    @avail_params = @subscr.msg_type.parameters
    # pick out the abstraction filters
    @filters = @subscr.non_abstraction_filters user.stringid
  end
  
  
  def update
    #valid_http_methods :put
    user = Person.find session[:userid]
    @subscr = user.subscriptions.find(params[:id])
    if @subscr.update_attributes params[:subscr]
      @subscr.filters.destroy
      @subscr.filters = []
      0.upto(params[:filter_count].to_i - 1) { |counter|
        @subscr.add_filter params["param_id_#{counter}"],
          params["filter_operator_#{counter}"], params["filter_value_#{counter}"], user.stringid
  	  }
      # set abstraction filters
      if params[:abstraction_filter]
        params[:abstraction_filter].each do |filter|
          afilters = @subscr.abstraction_filter_templates.select{|k,v| k == filter}.first.last.filters
          afilters.each do |afilter|
            @subscr.add_filter afilter.parameter_id, afilter.operator, afilter.filterstring, user.stringid
          end
        end
      end
      redirect_to_index "Subscription updated"
    else
      redirect_to_index(@subscr.errors.full_messages())
      @subscr.errors.clear()
    end
  end
  
  
  def get_type_params
    param_list = MsgType.find(params[:msg_type]).parameters
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
    debugger
    @curr_sub.save
    respond_to do |format|
     format.html {
       redirect_to subscriptions_path
      }
     format.js {
        render
     }
    end
  end


  private

  def valid_deliveries
    person = Person.find session[:userid]
    if person && person.admin
      deliver = Delivery.all(:order => 'id')
    else
      deliver = Delivery.all(:conditions => ["public = 1"], :order => 'id')
    end
    return deliver
  end

  def redirect_to_index(msg = nil)
    flash[:note] = msg
    redirect_to :action => :index
  end
  
end
