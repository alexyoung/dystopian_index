require 'test/unit'
require 'rubygems'

# Include the application's test_helper
unless defined?(ActiveRecord)
  begin
    require '../../../test/test_helper'
  rescue LoadError
    require 'test_helper'
  end
end

DYSTOPIA_PLUGIN_PATH = File.join(RAILS_ROOT, 'vendor', 'plugins', 'dystopian_index')
fixtures_path = File.join(DYSTOPIA_PLUGIN_PATH, 'test', 'fixtures')

DystopianIndex.config.db_path = File.join(DYSTOPIA_PLUGIN_PATH, 'test', 'fixtures', 'indexes')
DystopianIndex.config.model_directories = [File.join(DYSTOPIA_PLUGIN_PATH, 'test', 'fixtures')]

require File.join(fixtures_path, 'example_model')
require File.join(fixtures_path, 'schema')

Fixtures.create_fixtures(fixtures_path, ActiveRecord::Base.connection.tables)
