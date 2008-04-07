class MessagesController < ApplicationController
  # GET /messages
  # GET /messages.xml

  def index

  @message_view = true

	if params[:type]
#		@showtype = MsgType.find :all, :conditions => { :msg_type_id => params[:type] }
		@showtype = MsgType.find params[:type], { :include => :messages }
	end
	if params[:menu] == "expanded"
		@menu_expand = true
	else
		@menu_expand = false
	end	
	
    @showtypes = MsgType.find :all, { :include => :messages }
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @showtypes }
    end
  end

  # GET /messages/1
  # GET /messages/1.xml

  def show
    @message = Message.find(params[:id])
    @showtypes = MsgType.find :all, { :include => :messages }

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

  # POST /messages
  # POST /messages.xml
  def create
    @message = Message.new(params[:message])

    respond_to do |format|
      if @message.save
        flash[:notice] = 'Message was successfully created.'
        format.html { redirect_to(@message) }
        format.xml  { render :xml => @message, :status => :created, :location => @message }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @message.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /messages/1
  # PUT /messages/1.xml
  def update
    @message = Message.find(params[:id])

    respond_to do |format|
      if @message.update_attributes(params[:message])
        flash[:notice] = 'Message was successfully updated.'
        format.html { redirect_to(@message) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @message.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /messages/1
  # DELETE /messages/1.xml
  def destroy
    @message = Message.find(params[:id])
    @message.destroy

    respond_to do |format|
      format.html { redirect_to(messages_url) }
      format.xml  { head :ok }
    end
  end
end
