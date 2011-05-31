class StatisticsController < ApplicationController

  def index
    @users = Person.find :all
    @subscriptions = Subscription.find :all

    cacheid = "hermes_statistics"
    @timespan = 168
    @notifications_graph, @messages_graph = Rails.cache.fetch(cacheid, :expires_in => 2.hours) do
      notifications = []
      messages = []
      @timespan.downto(1).each do |time|
        notifications << [time, Notification.find(:all, :conditions => { :received => time.hours.ago..(time-1).hours.ago }).count]
        messages << [time, StarshipMessage.find(:all, :conditions => { :created => time.hours.ago..(time-1).hours.ago }).count]
      end
      [notifications, messages]
    end

  end

end
