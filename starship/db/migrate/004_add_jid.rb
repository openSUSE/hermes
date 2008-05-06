
class AddJid < ActiveRecord::Migration

  def self.up
    add_column "persons", "jid", :string
  end

  def self.down
    remove_column "persons", "jid"
  end


end
