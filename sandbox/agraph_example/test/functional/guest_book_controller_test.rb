require File.dirname(__FILE__) + '/../test_helper'
require 'guest_book_controller'

# Re-raise errors caught by the controller.
class GuestBookController; def rescue_action(e) raise e end; end

class GuestBookControllerTest < Test::Unit::TestCase
  def setup
    @controller = GuestBookController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
