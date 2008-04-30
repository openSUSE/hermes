class MsgTypesController < ApplicationController
  # GET /msgtypes
  # GET /msgtypes.xml

  def index
    @showtypes = MsgType.search( '%', params[:page], 30 )
    respond_to do |format|
      format.html # 
      format.xml  { render :xml => @showtypes }
    end
    
  end
  # GET /msgtypes/foobar
  # GET /msgtypes/foobar.xml

  def show
    @showtype = MsgType.find( :first,
                              :conditions => "msg_types.id = #{params[:id]}", 
                              :include => :messages )
    respond_to do |format|
      format.html # 
      format.xml  { render :xml => @showtypes }
    end
  end
end