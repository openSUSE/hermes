class ConfigController < ApplicationController

def index
  @person = session[:user]
  @person.name ||= "unknown"

  @subscribedMsgs = @person.subscriptions.find( :all, :include => [:msg_type,:delay,:delivery])
  @latestMsgs = @person.messages.find(:all, :include => :msg_type, :order => "created DESC", :limit => 10)

  @avail_types = MsgType.find(:all)
  @avail_deliveries = Delivery.find(:all)
  @avail_delays = Delay.find(:all)
end

def add_subscr
  if request.post?
    sub_param = params[:subscr]
    sub_param[:person_id] = session[:user].id

    if Subscription.find(:first, :conditions => sub_param)
      redirect_to_index("Subscription entry already exists.")
    else
      sub = Subscription.new(sub_param)
      0.upto(params[:filter_count].to_i-1) { |counter|
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

def delSubscr
  curr_subscr = session[:user].subscriptions.find(:first, :conditions => {:id => params[:id]})

  if curr_subscr
    curr_subscr.destroy
    redirect_to_index "Subscription for #{curr_subscr.msg_type.msgtype} deleted"
  else
    redirect_to_index "Only your own subscriptions can be deleted."
  end
end

def editSubscr
  @subscr = Subscription.find(params[:id])

  if request.post?
    if @subscr.update_attributes params[:subscr]
      redirect_to_index()
    else
      redirect_to_index(@subscr.errors.full_messages())
      @subscr.errors.clear()
    end
  else
    @msgs_for_type = @subscr.messages.find(:all, :include => :msg_type)
    @availDelay = Delay.find(:all)
    @availDeliveries = Delivery.find(:all)
  end
end

def get_type_params
  param_list = MsgType.find(params[:msg_type]).parameters
  render :partial => 'filter', :locals => {:param_list => param_list}
end

end
