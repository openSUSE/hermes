class FeedsController < ApplicationController
  skip_before_filter :require_auth, :only => ["show", "index", "person"]

  
  # person feed for one user which is a merger of all his feed subscriptions 
  def person
    user = Person.find_by_stringid params[:person]
    if user.nil?
      render :template => 'error.html.erb', :status => 404
      return
    end
    
    @items = user.starship_messages.paginate( :page => params[:page], :per_page => 100,
      :order => "id DESC" )
    @title = "All feed messages for user " + params[:person]
    render_feed()
  end


  # displaying list of public feeds here, does not need authentication
  def index
    feed_user = Person.find_or_initialize_by_stringid( CONFIG['feed_user'] )
    @feed_subscriptions = feed_user.subscriptions.find( 
      :all, :conditions => [ "deliveries.name = 'RSS'"], 
      :include => [:msg_type, :delay, :delivery])
  end
  
  
  # list the configured feeds of a single user
  def personal
    user = Person.find session[:userid]
    @feed_subscriptions = user.subscriptions.find( 
      :all, :conditions => [ "deliveries.name = 'RSS'"], 
      :include => [:msg_type, :delay, :delivery])
  end


  # shows a feed either as RSS or web list. 
  # params[:id] is a comma seperated id list
  def show
    @subscriptions = Subscription.find(:all, :conditions => ["id IN (#{params[:id]})"])
    if (@subscriptions.empty?)
      flash[:error] = "Feed with id: #{params[:id]} not found"
      redirect_to :action => :index
      return
      
      # TODO: remove those ids from the id list that are private if the requester != owner
      #elsif (@subscription.private && @subscription.person.id != session[:userid])
      #flash[:error] = "Feed with id: #{params[:id]} is marked as private by it's owner"
      #redirect_to :action => :index
    end
    
    @items = StarshipMessage.paginate( :page => params[:page], :per_page => 100,
      :order => "id DESC",
      :conditions => ["subscription_id IN (#{params[:id]})"] )
    @title = @subscriptions.collect {|s| s.subscription_desc }.join(", ")
    @feed_id = params[:id]
    render_feed()
  end


  private

  def render_feed
    respond_to do |format|
      format.html  { render :template => 'feeds/show' }
      format.rdf  { render :template => 'feeds/show', :layout => false }
      #format.atom  { render :layout => false }
    end
  end

end
