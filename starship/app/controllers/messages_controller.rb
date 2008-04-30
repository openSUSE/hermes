class MessagesController < ApplicationController
  # GET /messages
  # GET /messages.xml

  def index
    @message_view = true

    if params[:menu] == "expanded"
	@menu_expand = true
    else
	@menu_expand = false
    end	
	
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
    @message_view = true

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

  # GET /messages/1/add_comment

  def add_comment
    @message = Message.find(params[:msg])
	

  end
end