class MsgTypesController < ApplicationController
  # GET /msgtypes
  # GET /msgtypes.xml

  def index
    @message_view = true

    if params['filter']
      @filter = params['filter']
      @msg_types = Message.count(:include => :msg_type, :group => :msg_type,
        :conditions => ["msg_types.msgtype like ?", "%#@filter%"])
    else
      @msg_types = Message.count(:group => :msg_type)
    end

    #FIXME: @showtypes is needed in application.rb.erb layout
    @showtypes = @msg_types.collect {|x| x[0]}

    respond_to do |format|
      format.html # 
      format.xml  { render :xml => @showtypes }
    end
  end
  # GET /msgtypes/foobar
  # GET /msgtypes/foobar.xml

  def show

    @message_view = true
    @showtypes = MsgType.find :all

#    @showtype = MsgType.find( :first, :include => :messages,
#      :conditions => ["msg_types.id = ?", params[:id]])

    @msgs_to_show = Message.paginate(:page => params[:page], :per_page => 10, :conditions => ["msg_type_id =?", params[:id]])
    @msgtype = MsgType.find(params[:id])

    if params[:menu] == "expanded"
      @menu_expand = true
    else
      @menu_expand = false
    end	

    respond_to do |format|
      format.html # 
      format.xml  { render :xml => @showtypes }
    end
  end
end
