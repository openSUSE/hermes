class RenameColNotiParameters < ActiveRecord::Migration
  def self.up
    rename_column "notification_parameters", "msg_type_parameter_id", "parameter_id"
  end

  def self.down
    rename_column "notification_parameters", "parameter_id", "msg_type_parameter_id"
  end
end
