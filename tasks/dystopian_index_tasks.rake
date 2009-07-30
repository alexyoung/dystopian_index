require File.join(RAILS_ROOT, 'config', 'environment')

namespace :dystopia do
  desc "Indexes all models"
  task :index do
    DystopianIndex.index_all
  end

  desc "Runs benchmarks"
  task :benchmarks do
    Dir["#{File.dirname(__FILE__)}/../benchmarks/*.rb"].each do |file|
      load file
    end
  end
end
