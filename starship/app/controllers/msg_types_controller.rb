class MsgTypesController < ApplicationController

  def index
    if params['filter']
      @filter = params['filter']
      @msg_types = StarshipMessage.count(:include => :msg_type, :group => :msg_type,
        :conditions => ["msg_types.msgtype like ?", "%#@filter%"])
    else
      @msg_types = StarshipMessage.count(:include => :msg_type, :group => :msg_type)
    end

    @showtypes = @msg_types.collect {|x| x[0]}

    respond_to do |format|
      format.html # 
      format.xml  { render :xml => @showtypes }
    end
  end
  

  def show
    @msgs_to_show = StarshipMessage.paginate(:page => params[:page], :per_page => 100, 
      :conditions => ["msg_type_id =?", params[:id]], :order => "id DESC")
    @msgtype = MsgType.find(params[:id])
    respond_to do |format|
      format.html # 
      format.xml  { render :xml => @msgs_to_show }
    end
  end
end
