require_relative 'insectdb/version'
require_relative '../config/config'
require_relative 'insectdb/seq_enum'
require_relative 'insectdb/sequence'
require_relative 'insectdb/codon'
require_relative 'insectdb/common'
require_relative 'insectdb/segment_gain'
require_relative 'insectdb/segment_inclusion'
require_relative 'insectdb/routines'
require_relative 'insectdb/seed'
require_relative 'insectdb/mutation'

require_relative 'insectdb/mutation_count/ermakova'
require_relative 'insectdb/mutation_count/leushkin'
require_relative 'insectdb/mutation_count/routine'

require_relative 'insectdb/tests/pn_ps_dn_ds'
require '/home/anzaika/projects/my_ruby_extensions/lib/my_ruby_extensions'
require 'bundler/setup'
require 'active_record'
require 'parallel'
require 'matrix'
require 'zlib'
require 'fileutils'

if ENV['ENV'] == 'test'
  ActiveRecord::Base.establish_connection(Insectdb::Config.database(ENV['ENV']))
end

require_relative '../app/models/mrna'
require_relative '../app/models/gene'
require_relative '../app/models/reference'
require_relative '../app/models/div'
require_relative '../app/models/segment'
require_relative '../app/models/snp'
require_relative '../app/models/mrnas_segments'
require_relative '../app/models/genes_mrnas'

