require 'rubygems'
require 'active_support'
require 'active_support/test_case'

fixtures_path = File.join(File.dirname(__FILE__), 'fixtures')

require File.join(fixtures_path, 'example_model')
require File.join(fixtures_path, 'schema')

Fixtures.create_fixtures(fixtures_path, ActiveRecord::Base.connection.tables)
ExampleModel.index_all
