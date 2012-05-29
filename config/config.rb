require 'yaml'

module Insectdb
module Config

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
      self._path_to[sym]
    )
  end

  # Private: returns path to any data file necessary for computations.
  #
  # Path should be relative to the project directory root.
  def self._path_to
    {
      :bind => 'data/dm3_basepairs_2L_out'
    }
  end

end
end
