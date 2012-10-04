require 'yaml'

module Insectdb
module Config

  PATHS = {
    :bind             => 'data/dm3_basepairs_2L_out',
    :segmentGain      => 'data/segment_gain.csv',
    :segmentInclusion => 'data/incl_changes_for_segments',
    :segments         => 'db/seed/annotation/segments',
    :mrnas            => 'db/seed/annotation/mrnas',
    :genes            => 'db/seed/annotation/genes',
    'genes_mrnas'     => 'db/seed/annotation/genes_mrnas',
    'mrnas_segments'  => 'db/seed/annotation/mrnas_segments'
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
