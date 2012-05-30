require 'yaml'

module Insectdb
module Config

  PATHS = {
    :bind => 'data/dm3_basepairs_2L_out'
  }

  def self.open( file )
    YAML::load(
      File.open(
        File.join(
          File.dirname(__FILE__),  file)))
  end

  def self.database
    self.open('database.yml')[ENV['ENV'] || 'test']
  end

  def self.path_to( sym )
    File.join(
      File.dirname(__FILE__),
      '..',
      PATHS[sym]
    )
  end

end
end
