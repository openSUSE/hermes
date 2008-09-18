class SubscriptionsController < ApplicationController


def index
  @person = session[:user]
  @person.name ||= "unknown"

  @subscribedMsgs = @person.subscriptions.find( :all, :include => [:msg_type,:delay,:delivery])
  @latestMsgs = @person.messages.find(:all, :include => :msg_type, :order => "created DESC", :limit => 10)

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
        params["param_id_#{counter}"] ||= 0
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
            params["param_id_#{counter}"] ||= 0
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
