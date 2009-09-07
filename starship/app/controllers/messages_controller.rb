class MessagesController < ApplicationController

  skip_before_filter :authenticate, :only => ["show"]

  # Shows all messages from all feeds the current user is subscribed to
  def index
    @messages = StarshipMessage.paginate( :page => params[:page], :per_page => 50, 
                                       :conditions => ["person_id=?", @loggedin_user.id ], :order => "id DESC" )
  end

  # TODO: check if it's a message from a private subscription
  def show
    @message = StarshipMessage.find( :first, :conditions => ["id=?", params[:id]] )
    if @message.nil?
      render :text => "No message found", :layout => "application"
      return
    end

    # set message to read
    if @message.msg_state.state == 'new' || @message.msg_state.state == 'unread'
       read_state = MsgState.find( :first, :conditions => "state ='read'" )
       @message.msg_state = read_state
       @message.save!
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @message }
    end
  end

end
