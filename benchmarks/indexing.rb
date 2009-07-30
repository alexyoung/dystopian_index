require 'test_helper'
require File.join(File.dirname(__FILE__), '..', 'test', 'test_helper')
require 'benchmark'
require 'faker'

def clear!
 ExampleModel.clear_dystopian_index!
 ExampleModel.delete_all
 DystopianIndex.config.disabled = false
end

def fake_record
  ExampleModel.create :name => Faker::Name.name, :content => Faker::Lorem.paragraph
end

count = 500

puts "Running benchmarks.  Please make a cup of tea or coffee."
clear!

#
# Benchmark #1
#

bm = Benchmark.measure do
  count.times do
    fake_record 
  end
end

puts "[with indexing enabled] #{count} records created in: #{bm}"
clear!

#
# Benchmark #2
#

DystopianIndex.config.disabled = true

bm = Benchmark.measure do
  count.times do
    fake_record 
  end
end

puts "[with indexing disabled] #{count} records created in: #{bm}"
clear!

#
# Benchmark #3
#

DystopianIndex.config.disabled = true

db = Rufus::Tokyo::Dystopia::Core.new ExampleModel.dystopian_config[:db]

bm = Benchmark.measure do
  count.times do
    model = fake_record 
    db.store model.id, model.dystopian_payload 
  end
end

db.close

puts "[with a single dystopia connection] #{count} records created in: #{bm}"
