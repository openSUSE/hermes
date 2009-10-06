class MsgTypesController < ApplicationController

  def index
    if params['filter']
      @filter = params['filter']
      conditions = ["msg_types.msgtype like ?", "%#@filter%"]
    end
    @msg_types = @loggedin_user.starship_messages.count( :include => :msg_type, :group => :msg_type, 
      :conditions => conditions )

    @showtypes = @msg_types.collect {|x| x[0]}

    respond_to do |format|
      format.html # 
      format.xml  { render :xml => @showtypes }
    end
  end
  

  def show
    @msgs_to_show = @loggedin_user.starship_messages.paginate( :page => params[:page], :per_page => 100,
      :conditions => ["msg_type_id =?", params[:id]],
      :order => "id DESC" )
    @msgtype = MsgType.find(params[:id])

    # set all new messages to unread 
    unread_state = MsgState.find( :first, :conditions => "state ='unread'" )
    @msgs_to_show.each do |msg| 
      if msg.msg_state.state == 'new' 
        msg.msg_state = unread_state
        msg.save!
      end
    end

    respond_to do |format|
      format.html # 
      format.xml  { render :xml => @msgs_to_show }
    end
  end
end
