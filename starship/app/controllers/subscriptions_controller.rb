class SubscriptionsController < ApplicationController


def simple
  @person = session[:user]
  @hermestitle = "Subscriptions for #{session[:user].stringid} (#{session[:user].email})"
  @abstraction_groups = ABSTRACTIONGROUPS
  @abstractions = SUBSCRIPTIONABSTRACTIONS
  @subscribedMsgs = @person.subscriptions.find( :all)
  @avail_deliveries = Delivery.find(:all, :order => 'id').map {|d| [d.name, d.id]}
  @avail_delays = Delay.find(:all, :order => 'id').map {|d| [d.name, d.id]}
end


def index
  @person = session[:user]
  @hermestitle = "Subscriptions for #{session[:user].stringid} (#{session[:user].email})"

  @subscribedMsgs = @person.subscriptions.find( :all, :include => [:msg_type,:delay,:delivery])
  #@latestMsgs = @person.messages.find(:all, :include => :msg_type, :order => "created DESC", :limit => 10)

  @avail_types = MsgType.find(:all)
  @avail_deliveries = Delivery.find(:all)
  @avail_delays = Delay.find(:all)
end


def create
  if request.post?

    sub_param = params[:subscr]
    sub_param[:person_id] = session[:user].id

    if Subscription.find(:first, :conditions => sub_param)
      redirect_to_index("Subscription entry already exists.")
    else
      sub = Subscription.new(sub_param)
      0.upto(params[:filter_count].to_i-1) { |counter|
        # with the special operator no parameter_id is set
        # needs to be a valid parameter_id, otherwise the filters wont evaluated by hermes
        # same in update function
        params["param_id_#{counter}"] ||= (Parameter.find(:first, :conditions => {:name => '_special'})).id
        logger.debug("[Create Subscription] #{params["filter_value_#{counter}"]}")
        sub.filters <<  SubscriptionFilter.new( :parameter_id => params["param_id_#{counter}"], :operator => params["filter_operator_#{counter}"],:filterstring => params["filter_value_#{counter}"] )
      }
      if sub.save
        redirect_to_index()
      else
        redirect_to_index(sub.errors.full_messages())
        sub.errors.clear()
      end
    end
  end
end


def modify_simple_subscriptions
  if request.post?
    flash[:success] = ""
    
    SUBSCRIPTIONABSTRACTIONS.keys.each do | group_id | 
      SUBSCRIPTIONABSTRACTIONS[group_id].values.each do | abstraction |
        abstraction.filterabstracts.values.each do | filterabstract | 
          # load matching user subscription
          subscription = session[:user].subscribed_to_abstraction(group_id, abstraction.id, filterabstract.id)   
          if ( params["#{abstraction.id}||#{filterabstract.id}"])
            if (!subscription)
              logger.debug "Adding Filterabstract #{abstraction.id}||#{filterabstract.id}"
              
              subscription = Subscription.new(:msg_type_id => MsgType.find(:first, :conditions => "msgtype =  '#{abstraction.msg_type}'").id, 
                :person_id => session[:user].id, :delay_id => params["#{abstraction.id}||#{filterabstract.id}||delay"].to_i, 
                :delivery_id => params["#{abstraction.id}||#{filterabstract.id}||delivery"].to_i)
              
              filterabstract.filters.each do | filter |
                subscription.filters <<  SubscriptionFilter.new( :parameter_id => filter.parameter_id, 
                  :operator => filter.operator, :filterstring => filter.filterstring )
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
end



def redirect_to_index(msg = nil)
  flash[:notice] = msg
  redirect_to :action => :index
end


def destroy
  if request.delete?
    curr_subscr = session[:user].subscriptions.find(:first, :conditions => {:id => params[:id]})

    if curr_subscr
      curr_subscr.destroy
      redirect_to_index "Subscription for #{curr_subscr.msg_type.msgtype} deleted"
    else
      redirect_to_index "Only your own subscriptions can be deleted."
    end
  end
end


def edit
  @subscr = Subscription.find(params[:id])
  @filters = @subscr.filters
  @msgs_for_type = @subscr.messages.find(:all, :include => :msg_type)
  @availDelay = Delay.find(:all)
  @availDeliveries = Delivery.find(:all)
  @avail_params = @subscr.msg_type.parameters
end


def update
  if request.put?
    @subscr = Subscription.find(params[:id])
    if @subscr.update_attributes params[:subscr]
      @subscr.filters.each { |filt| 
        filt.destroy
      }
      0.upto(params[:filter_count].to_i-1) { |counter|
            params["param_id_#{counter}"] ||= (Parameter.find(:first, :conditions => {:name => '_special'})).id
	    @subscr.filters << SubscriptionFilter.new( :subscription_id => @subscr.id, :parameter_id => params["param_id_#{counter}"], :operator => params["filter_operator_#{counter}"], :filterstring => params["filter_value_#{counter}"] )
	  }
      redirect_to_index()
    else
      redirect_to_index(@subscr.errors.full_messages())
      @subscr.errors.clear()
    end
  end
end


def get_type_params
  param_list = MsgType.find(params[:msg_type]).parameters
  render :partial => 'filter_param', :locals => {:param_list => param_list}
end


def disable
  @curr_sub_index = params[:id]
  @curr_sub = Subscription.find(params[:subs])
  @status
  if @curr_sub.enabled
    @curr_sub.enabled = false
    @status = "Disabled"
  else 
    @curr_sub.enabled = true
    @status = "Enabled"
  end
  @curr_sub.save

end

end
