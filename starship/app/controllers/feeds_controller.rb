class FeedsController < ApplicationController
  skip_before_filter :authenticate, :only => ["personal"]

  def personal
    user = Person.find_by_stringid params[:person]
    if user.nil?
      render :template => 'error.html.erb', :status => 404
      return
    end

    @items = user.starship_messages.find :all, :limit => 100, :order => "created desc"
  end


  # We could also show the genaral feeds here, also for non-logged in people
  def index
    # TODO: maybe we want mail delivered subscriptions also to be archived and viewable here?
    # TODO: How do I put the select{} into the find() ?
    @feed_subscriptions = session[:user].subscriptions.find( 
      :all, :include => [:msg_type,:delay,:delivery]).select{|s| s.delivery.name = 'RSS' }     
  end


  # shows a feed either as RSS or web list. 
  def show
    @subscription = Subscription.find(:all, :conditions => ["id =?", params[:id]]).first
    if (@subscription.nil?)
      flash[:error] = "Feed with id: #{params[:id]} not found"
      redirect_to :action => :index
     elsif (@subscription.private && @subscription.person != session[:user])
      flash[:error] = "Feed with id: #{params[:id]} is marked as private by it's owner"
      redirect_to :action => :index
    end
    
    
  end



end
