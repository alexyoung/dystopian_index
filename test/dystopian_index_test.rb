require File.join(File.dirname(__FILE__), 'test_helper')

class DystopianIndexTest < ActiveSupport::TestCase
  def setup
    ExampleModel.clear_dystopian_index!
    ExampleModel.index_all
  end

  test "search" do
    assert_equal 1, ExampleModel.search('alex').size
  end

  test "pagination" do
    assert_equal 2, ExampleModel.search('based', :per_page => 2, :page => 1).size
  end

  # The example model has order_by enabled
  test "sorting" do
    results = ExampleModel.search('based')
    assert results.first.created_at < results.last.created_at
  end

  test "deletion removes records from index" do
    assert !ExampleModel.search('alex').empty?
    ExampleModel.search('alex').each { |m| m.destroy }
    assert ExampleModel.search('alex').empty?
  end

  test "searching for nil should return nil" do
    assert_equal ExampleModel.search(nil), nil
  end
end
