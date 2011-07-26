require 'nokogiri'

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
    @ids = params[:id].split(',').map {|s| s.to_i}
    @subscriptions = Subscription.find(:all, :conditions => { :id => @ids } )
    if (@subscriptions.empty?)
      flash[:error] = "Feed with id: #{params[:id]} not found"
      redirect_to :action => :index
      return
      
      # TODO: remove those ids from the id list that are private if the requester != owner
      #elsif (@subscription.private && @subscription.person.id != session[:userid])
      #flash[:error] = "Feed with id: #{params[:id]} is marked as private by it's owner"
      #redirect_to :action => :index
    end
    
    @title = @subscriptions.collect {|s| s.subscription_desc }.join(", ")
    @feed_id = params[:id]

    respond_to do |format|
      format.html do 
         @items = StarshipMessage.paginate( :page => params[:page], :per_page => 100,
           :order => "id DESC", :conditions => { :subscription_id => @ids } )
         render :template => 'feeds/show' and return
        end
      format.rdf do
         @items = StarshipMessage.find(:all, :select => :id, :order => "id DESC", :limit => 100, 
                                       :conditions => { :subscription_id => @ids } )
         @items = StarshipMessage.find(:all, :conditions => { :id => @items.map{|i| i.id } })
         builder = nil
         builder = Nokogiri::XML::Builder.new do |xml|
           xml.rss(:version=>"2.0") do
             xml.channel do
               xml.title(@title)
               xml.link url_for :only_path => false, :controller => 'feeds', :action => "index"
               xml.description("openSUSE Hermes RSS Feed for subscription: #{@title}")
               xml.language('en-us')
               @items.each do |item|
                 xml.item do
                   xml.title(item.subject)
                   xml.description "<pre>" + CGI.escapeHTML(item.body) + "</pre>"
                   xml.author(item.sender)
                   xml.pubDate(item.created.xmlschema)
                   path = url_for :only_path => false, :controller => 'messages', :action => "show", :id => item.id
                   xml.link path
                   xml.guid path
                end
              end
            end
          end
        end
        render :text => builder.to_xml
      end
    end
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
