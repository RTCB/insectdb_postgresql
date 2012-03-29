require 'yaml'

module Insectdb
  module Config
    def self.open( file )
      YAML::load(
        File.open(
          File.join(
            File.dirname(__FILE__), '..', '..', 'config', file)))
    end

    def self.database
      self.open('database.yml')
    end
  end
end
