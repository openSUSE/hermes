class ConfigController < ApplicationController

		@@user = 0
	def index
		@@user = Person.find(126)
		@myUser = @@user
		
		if ! @myUser.name
		  @myUser.name = "unknown";
		end
		
		id = @@user.id
		@subscribedMsgs = MsgTypesPeople.find( :all, :conditions => { :person_id => id }, 
		                                       :include => [:msg_type,:delay,:delivery])
	end

	def addSubscr
		if request.post?
			sub_param = params[:subscr]
			sub_param[:person_id] = @@user.id
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


end
