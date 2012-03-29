require_relative 'insectdb/version'
require_relative 'insectdb/config'
require_relative 'insectdb/seq_enum'
require_relative 'insectdb/contig'
require_relative 'insectdb/codon'
require 'bundler/setup'
require 'active_record'
require 'parallel'
require 'json'

ActiveRecord::Base.establish_connection(
  Insectdb::Config.database['production']
)

require_relative '../app/models/div'
require_relative '../app/models/mrna'
require_relative '../app/models/reference'
require_relative '../app/models/segment'
require_relative '../app/models/snp'
require_relative '../app/models/mrnas_segments'

require 'zlib'
require 'fileutils'
