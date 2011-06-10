class StatisticsController < ApplicationController

  def index
    @users = Person.count
    @subscriptions = Subscription.count
    cacheid = "hermes_stats"
    @timespan = 7*24
    @notifications_in, @notifications_out, @messages = Rails.cache.fetch(cacheid, :expires_in => 30.minutes) do
      notifications_in = get_notification_rows "notifications", "received", @timespan
      notifications_out = get_notification_rows "generated_notifications", "sent", @timespan
      messages = get_notification_rows "starship_messages", "created", @timespan
      [notifications_in, notifications_out, messages]
    end
    @msg_types = MsgType.find(:all, :order => 'description, msgtype DESC')
    @subscription_stats = get_suscription_rows
  end

  def msg_type
    @timespan = 7*24
    notifications_in = get_notification_rows "notifications", "received", @timespan
    @all_msg_types = MsgType.find(:all, :order => 'description, msgtype DESC')
    @msg_types = params['msg_type']
    @notifications_in_by_type = {}
    @all_msg_types.each do |type|
      @notifications_in_by_type[type.id] = notifications_in.select{|time, n, t| @msg_types.include? t} if @msg_types.include? type.id.to_s
    end
  end


  private

  def get_notification_rows table, date_column, timespan
    notifications = []
    rows = ActiveRecord::Base.connection.execute <<-END_SQL
      SELECT ceil((unix_timestamp( #{date_column} ) - unix_timestamp( NOW() ) ) / 3600), COUNT( #{date_column} )
      #{", msg_type_id" if table == 'notifications'}
      FROM #{table}
      WHERE #{date_column} > "#{timespan.hours.ago.to_s(:db)}"
      AND #{date_column} < "#{Time.now.strftime("%Y-%m-%d %H:00") }"
      GROUP BY DATE_FORMAT( #{date_column}, "%d-%m-%Y %H" )
      ORDER BY #{date_column}
    END_SQL
    rows.each {|row| notifications << row}
    notifications
  end


  def get_suscription_rows
    types = []
    rows = ActiveRecord::Base.connection.execute <<-END_SQL
      SELECT msg_type_id, COUNT( msg_type_id )
      FROM subscriptions
      GROUP BY msg_type_id
      ORDER BY msg_type_id
      LIMIT 7
    END_SQL
    rows.each {|row| types << row}
    types
  end


end
