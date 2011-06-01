class StatisticsController < ApplicationController

  def index
    @users = Person.find :all
    @subscriptions = Subscription.find :all
    cacheid = "hermes_stats"
    @timespan = 744
    @notifications_in, @notifications_out, @messages = Rails.cache.fetch(cacheid, :expires_in => 2.seconds) do
      notifications_in = get_notification_rows "notifications", "generated", @timespan
      notifications_out = get_notification_rows "generated_notifications", "sent", @timespan
      messages = get_notification_rows "starship_messages", "created", @timespan
      [notifications_in, notifications_out, messages]
    end
  end


  private

  def get_notification_rows table, date_column, timespan
    notifications = []
    rows = ActiveRecord::Base.connection.execute <<-END_SQL
      SELECT round((unix_timestamp( #{date_column} ) - unix_timestamp( NOW() ) ) / 3600), COUNT( #{date_column} )
      FROM #{table}
      WHERE #{date_column} > "#{timespan.hours.ago.to_s(:db)}"
      GROUP BY DATE_FORMAT( #{date_column}, "%d-%m-%Y %H" )
    END_SQL
    rows.each {|row| notifications << row}
    notifications
  end

end
