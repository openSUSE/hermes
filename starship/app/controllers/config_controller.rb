class ConfigController < ApplicationController

def index
  @myUser = session[:user]
  @myUser.name ||= "unknown"
	      
  @subscribedMsgs = @myUser.subscriptions.find( :all, :include => [:msg_type,:delay,:delivery])
  
  @latestMsgsTypes = @subscribedMsgs.map {|msg| msg.msg_type_id}.uniq
  #@latestMsgs = Message.find(:all, :include => :msg_type,
  #  :conditions => ["msg_type_id in (?)", @latestMsgsTypes], :order => "created DESC", :limit => 10)

  #XXX: only shows messages received after user was subscribed, isn't that what was intended?
  @latestMsgs = @myUser.messages.find(:all, :include => :msg_type, :order => "created DESC", :limit => 10)

  @person = session[:user]
  @avail_types = MsgType.find(:all)
  @avail_deliveries = Delivery.find(:all)
  @avail_delays = Delay.find(:all)
  @avail_params = @avail_types[0].parameters
  
  session[:filter_count] = 0

end

def addSubscr
  if request.post?
    sub_param = params[:subscr]
    sub_param[:person_id] = session[:user].id
   
    if Subscription.find(:first, :conditions => sub_param)
      redirect_to_index("Subscription entry already exists.")
    else
      sub = Subscription.new(sub_param)
	  sub.filters <<  SubscriptionFilter.new( :parameter_id => params[:param_id], :operator => 'oneof',:filterstring => params[:filter_value] )
      if sub.save
        redirect_to_index()
      else
        redirect_to_index(sub.errors.full_messages())
        sub.errors.clear()
      end
    end
  else
    @person = session[:user]
    @availTypes = MsgType.find(:all)
    @availDeliveries = Delivery.find(:all)
    @availDelay = Delay.find(:all)
    @availParams = @availTypes[0].parameters
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
  msgtype = MsgType.find(params[:type_id])
  
  render :update do |page|
      page.replace_html 'filter', :partial => 'filter', :object => msgtype.parameters
  end

end

def add_filter

  avail_params = Parameter.find(:all)
  render :update do |page|
    page.insert_html :before, 'submit', :partial => 'new_filter', :locals => { :params => avail_params, :count => session[:filter_count] }
  end

session[:filter_count] += 1

end

end
