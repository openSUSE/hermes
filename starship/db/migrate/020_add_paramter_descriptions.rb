class AddParamterDescriptions < ActiveRecord::Migration
  def self.up
    add_column :parameters, :hr_name, :string
    add_column :msg_types_parameters, :description, :text
  end

  def self.down
    remove_column :parameters, :hr_name
    remove_column :msg_types_parameters, :description
  end
end
