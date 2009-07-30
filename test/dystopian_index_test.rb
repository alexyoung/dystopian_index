require 'test_helper'
require File.join(File.dirname(__FILE__), 'test_helper')

class DystopianIndexTest < ActiveSupport::TestCase
  test "search" do
    assert_equal 1, ExampleModel.search('alex').size
  end

  test "pagination" do
    assert_equal 2, ExampleModel.search('based', :per_page => 2, :page => 1).size
  end
end
