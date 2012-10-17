require 'yaml'

module Insectdb
module Config

  PATHS = {
    :bind             => 'data/dm3_basepairs_2L_out',
    :segmentGain      => 'data/segment_gain.csv',
    :segmentInclusion => 'data/incl_changes_for_segments',
    :seqs             => 'db/seed/seq',
    :segments         => 'db/seed/annotation/segment',
    :mrnas            => 'db/seed/annotation/mrna',
    :genes            => 'db/seed/annotation/gene',
    :genes_mrnas      => 'db/seed/annotation/genes_mrnas',
    :mrnas_segments   => 'db/seed/annotation/mrnas_segments'
  }

  def self.open( file )
    YAML::load(
      File.open(
        File.join(
          File.dirname(__FILE__),  file)))
  end

  def self.database(env)
    self.open('database.yml')[env]
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
