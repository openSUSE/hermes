class MsgTypesController < ApplicationController
  # GET /msgtypes
  # GET /msgtypes.xml

  def index

    @message_view = true

	if ! params['msgtype'].nil?
		if ! params['msgtype']['search'].empty?
			puts "seraching for : #{params['msgtype']['search']}"
	#		search_string = params['msgtype']['search']
			
	#		if serach_string.include?('*')
			
			@showtypes = MsgType.find( :all, :conditions => "msg_types.msgtype = '#{params['msgtype']['search']}'")
		else
			@showtypes = MsgType.find :all #, { :include => :messages }
		end
	else
		@showtypes = MsgType.find :all #, { :include => :messages }
	end
		

    respond_to do |format|
      format.html # 
      format.xml  { render :xml => @showtypes }
    end
    
  end
  # GET /msgtypes/foobar
  # GET /msgtypes/foobar.xml

  def show

	@message_view = true

    @showtypes = MsgType.find :all #, { :include => :messages }
    @showtype = MsgType.find( :first,
                             :conditions => "msg_types.id = #{params[:id]}", 
                            :include => :messages )



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
