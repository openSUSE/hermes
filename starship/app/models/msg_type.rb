class MsgType < ActiveRecord::Base
  has_many :messages
  has_many :people, :through => :subscriptions
  has_many :subscriptions
  #has_and_belongs_to_many :parameters
  has_many :msg_type_parameters
  has_many :parameters, :through => :msg_type_parameters

  def self.search( search, page, perpage )
      paginate :per_page => perpage, :page => page,
               :conditions => ['msgtype like ?', "%#{search}%"]
  end
  
  def self.bytype( type, page, perpage )
      paginate :per_page => perpage, :page => page,
               :conditions => ['msgtype = ?', "%#{type}%"]
  end
  
  def type_desc
    return description.nil? ? msgtype : description
  end

end
