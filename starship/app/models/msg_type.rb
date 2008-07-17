class MsgType < ActiveRecord::Base
  has_many :messages
  has_many :people, :through => :subscriptions
  has_many :subscriptions

  def self.search( search, page, perpage )
      paginate :per_page => perpage, :page => page,
               :conditions => ['msgtype like ?', "%#{search}%"],
               :include => :messages
  end
  
  def self.bytype( type, page, perpage )
      paginate :per_page => perpage, :page => page,
               :conditions => ['msgtype = ?', "%#{type}%"],
               :include => :messages
  end
  
end
