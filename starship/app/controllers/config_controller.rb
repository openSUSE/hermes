class ConfigController < ApplicationController

def index
  user = session[:user]
  @myUser = user
	   
  if ! @myUser.name
    @myUser.name = "unknown";
  end
	      
  id = user.id
  @subscribedMsgs = MsgTypesPeople.find( :all, :conditions => { :person_id => id }, 
		                         :include => [:msg_type,:delay,:delivery])
  @latestMsgsTypes = Array.new
  @latestMsgs = Array.new

  for subs in @subscribedMsgs
    @latestMsgsTypes << subs.msg_type.id
  end

  @latestMsgsTypes.uniq

  @latestMsgs = Message.find (:all, :conditions => ["msg_type_id in (?)", @latestMsgsTypes] , :order => "created DESC", :limit => 10)

end

def addSubscr
  if request.post?
    sub_param = params[:subscr]
    sub_param[:person_id] = session[:user].id
    valid = MsgTypesPeople.find(:all, :conditions => { :person_id => sub_param[:person_id], :delay_id => sub_param[:delay_id],:delivery_id => sub_param[:delivery_id], :msg_type_id => sub_param[:msg_type_id] })
    if valid.size >= 1
      redirect_to_index("Subscription entry already exists.")
    else
      sub = MsgTypesPeople.new(sub_param)
      if sub.save
        redirect_to_index()
      else
        redirect_to_index(sub.errors.full_messages())
        sub.errors.clear()
      end
    end
  else
    @person = Person.find(params[:user])
    @availTypes = MsgType.find(:all)
    @availDeliveries = Delivery.find(:all)
    @availDelay = Delay.find(:all)
  end
end
	
def redirect_to_index(msg = nil)
  flash[:notice] = msg
  redirect_to :action => :index
end

def delSubscr
  curr_subscr = MsgTypesPeople.find(params[:id])

  MsgTypesPeople.delete(curr_subscr)
  redirect_to_index()

end

def editSubscr
  @subscr = MsgTypesPeople.find(params[:id])

  if request.post?

    sub_param = params[:subscr]
    @subscr.delay_id = sub_param[:delay_id]
    @subscr.delivery_id = sub_param[:delivery_id]
    @subscr.comment = sub_param[:comment]

    if @subscr.save
      redirect_to_index()
    else
      redirect_to_index(@subscr.errors.full_messages())
      @subscr.errors.clear()
    end

  else

    @msgs_for_type = Message.find (:all, :conditions => { :msg_type_id => @subscr.msg_type_id })

    @availDeliveries = Delivery.find(:all)
    @availDelay = Delay.find(:all)

  end

end

end
