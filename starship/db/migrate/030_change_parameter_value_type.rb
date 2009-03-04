class ChangeParameterValueType < ActiveRecord::Migration
  def self.up
    change_column :notification_parameters, :value, :text
  end

  def self.down
    change_column :notification_parameters, :value, :string
  end
end
