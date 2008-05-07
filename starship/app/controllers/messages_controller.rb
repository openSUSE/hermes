class MessagesController < ApplicationController
  # GET /messages
  # GET /messages.xml

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
	


    @message = Message.find(params[:id])
    @showtypes = MsgType.find :all #, { :include => :messages }

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

  def update

	msg = Message.find(params[:id])
	mess = params[:message]
	msg['comment'] = mess["comment"]
	if msg.save
		redirect_to_msg("Successfully saved comment",msg.id)
	else
		redirect_to_msg(msg.errors.full_messages(),msg.id)
		msg.errors.clear()
	end

  end

  def redirect_to_msg(info=nil,id=nil)
    flash[:notice] = info
    redirect_to :action => 'show', :id => id
  end

end
