require File.dirname(__FILE__) + '/../test_helper'

class MsgTypesControllerTest < ActionController::TestCase

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:msg_types)
    assert assigns(:showtypes)
  end


  def test_should_get_show
    get :show
    assert_response :success
    assert assigns(:msgs_to_show)
    assert assigns(:showtypes)
    assert assigns (:msgtype)
  end

end
