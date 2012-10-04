require 'insectdb'
require 'database_cleaner'
require 'mocha_standalone'

DatabaseCleaner.strategy = :transaction

ENV['ENV'] = 'test'
