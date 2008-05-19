class MessagesController < ApplicationController
  # GET /messages
  # GET /messages.xml

	@@user = Person.find(1)
  def index

	
    @showtypes = MsgType.search( params[:search], params[:page], 50 )
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @showtypes }
    end
  end

  # GET /messages/1
  # GET /messages/1.xml

  def show
	
	@to_save_comment = Array.new

    @message = Message.find(params[:id])
    @showtypes = MsgType.find :all #, { :include => :messages }

	subscribed = MsgTypesPeople.find( :all, :conditions => { :person_id => @@user.id , 
											:msg_type_id => @message.msg_type_id})

	if subscribed.size > 0
		@is_subscribed = true
		@to_save_comment = MessagesPeople.find( :first, :conditions => { :person_id => @@user.id ,     
                                            :message_id => @message.id})
	end

    if params[:menu] == "expanded"
	@menu_expand = true
    else
	@menu_expand = false
    end	

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @message }
    end
  end

  # GET /messages/1/update

  def save_comment

	postArg = params[:comm]
	msg = Message.find(postArg['message_id'])
	puts "The post ARGS are: #{postArg}"
	msgs_to_save_comment = MessagesPeople.find( :all, :conditions => { :person_id => @@user.id ,
                                            :message_id => msg.id})	

	for entry in msgs_to_save_comment
		entry['comment'] = postArg['comment']
		entry.save
	end

	redirect_to_msg("Successfully saved comment",msg.id)

#	redirect_to_msg(msg.errors.full_messages(),msg.id)
#	msg.errors.clear()

  end

  def redirect_to_msg(info=nil,id=nil)
    flash[:notice] = info
    redirect_to :action => 'show', :id => id
  end

end
