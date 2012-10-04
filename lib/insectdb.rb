require_relative 'insectdb/version'
require_relative '../config/config'
require_relative 'insectdb/seq_enum'
require_relative 'insectdb/contig'
require_relative 'insectdb/codon'
require_relative 'insectdb/common'
require_relative 'insectdb/segment_gain'
require_relative 'insectdb/segment_inclusion'
require_relative 'insectdb/routines'
require_relative 'insectdb/seed'
require '/home/anzaika/loc_projects/my_ruby_extensions/lib/my_ruby_extensions'
require 'bundler/setup'
require 'active_record'
require 'parallel'
require 'json'
require 'matrix'

ActiveRecord::Base.establish_connection(
  Insectdb::Config.database
)

require_relative '../app/models/mrna'
require_relative '../app/models/reference'
require_relative '../app/models/div'
require_relative '../app/models/segment'
require_relative '../app/models/snp'
require_relative '../app/models/mrnas_segments'

require 'zlib'
require 'fileutils'
