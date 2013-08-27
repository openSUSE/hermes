class Subscription < ActiveRecord::Base
  belongs_to :person
  belongs_to :msg_type
  belongs_to :delay
  belongs_to :delivery

  has_many :starship_messages, :dependent => :destroy
  has_many :filters, :class_name => "SubscriptionFilter", :dependent => :destroy
  has_many :generated_notifications

  validates_presence_of :delay
  validates_presence_of :delivery

  attr_accessible :msg_type_id, :person_id, :delay_id, :delivery_id, :description

  def initialize(attribs={})
    super(attribs)
    self.delay = Delay.find_by_name( 'NO_DELAY' ) unless self.delay.present?
    self.delivery = Delivery.find_by_name( 'Mail' ) unless self.delivery.present?
    self
  end


  def has_starship_messages?
    return (self.starship_messages.find(:first, :select => :id) != nil)
  end

  def subscription_desc
    if (description)
      return description
    end
    return  "#{msg_type.type_desc} (#{filters.count}  filters)"
  end


  def abstraction_filter_templates
    FILTERABSTRACTIONS.select{|name, abs| abs.valid_msg_types.include? msg_type.msgtype }
  end


  def uses_abstraction_filter? id, username
    afilters = abstraction_filter_templates.select{|k,v| k == id}.first.last.filters
    uses_abstraction_filter = !afilters.blank?
    afilters.each do |afilter|
      if filters.select{|f| f.parameter_id == afilter.parameter_id &&
            f.operator == afilter.operator && 
            f.filterstring == SubscriptionFilter.replaced_filterstring(afilter.filterstring, username) }.blank?
        uses_abstraction_filter = false
      end
    end
    uses_abstraction_filter
  end


  # return the included filters minus that ones that were covered by an abstraction filter
  def non_abstraction_filters username
    non_abstraction_filters = filters
    abstraction_filter_templates.each do |filter_template|
      afilters = filter_template.last.filters
      uses_abstraction_filter = !afilters.blank?
      used_filters = []
      afilters.each do |afilter|
        used_filters = filters.select{|f| f.parameter_id == afilter.parameter_id &&
            f.operator == afilter.operator && 
            f.filterstring == SubscriptionFilter.replaced_filterstring(afilter.filterstring, username) }
        uses_abstraction_filter = false if used_filters.blank?
      end
      non_abstraction_filters -= used_filters if uses_abstraction_filter
    end
    non_abstraction_filters
  end


  def add_filter parameter_id, operator, value, username
    value = SubscriptionFilter.replaced_filterstring(value, username)
    if (filters.select{|filter| filter.parameter_id.to_s == parameter_id &&
            filter.operator == operator && filter.filterstring == value}.blank?)
      filters << SubscriptionFilter.new( :subscription_id => id,
        :parameter_id => parameter_id, :operator => operator,
        :filterstring => value )
    end
  end

end
