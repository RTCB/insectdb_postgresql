require 'insectdb'
require 'database_cleaner'
require 'mocha_standalone'

RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

end

ENV['ENV'] = 'test'
