class MessagesController < ApplicationController

  def index
    @messages = StarshipMessage.find( :all, :readonly )
  end
  # GET /messages/1
  # GET /messages/1.xml

  def show
    @message = StarshipMessage.find(params[:id])
    user = session[:user]

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
  def redirect_to_msg(info=nil,id=nil)
    flash[:notice] = info
    redirect_to :action => 'show', :id => id
  end

end
