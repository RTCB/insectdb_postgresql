ENV['ENV'] = 'test'

require 'insectdb'
require 'database_cleaner'
require 'mocha/api'
require 'factory_girl'
require_relative 'factories'

RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.include FactoryGirl::Syntax::Methods

end
