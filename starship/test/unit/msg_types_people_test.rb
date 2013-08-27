require_relative '../test_helper'

class MsgTypesPeopleTest < ActiveSupport::TestCase
  # Replace this with your real tests.

  def test_should_create_a_subscription
    subscr = Subscription.new(:msg_type_id => '4', :person_id => '4', :delay_id => '1', :delivery_id => '2', 
                            :comment => 'foobar', :private => false, :enabled => true)
    assert subscr.save
  end

  def test_should_have_3_fixtures
    assert_equal 3, Subscription.count
  end

  def test_should_delete_a_subscription
    subscr = Subscription.find(1)
    assert subscr.destroy
  end

  def test_should_have_delivery
    subscr = Subscription.new(:msg_type_id => '5', :person_id => '5', :delay_id => '1', 
                            :comment => 'foobar', :private => false, :enabled => true)
    assert !subscr.save
  end

  def test_should_have_delay
    subscr = Subscription.new(:msg_type_id => '6', :person_id => '6', :delivery_id => '3',
                            :comment => 'foobar', :private => false, :enabled => true)
    assert !subscr.save
  end

end




