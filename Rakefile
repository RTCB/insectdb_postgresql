require 'yaml'
require 'logger'
require 'active_record'

def camel_case( string )
  return string if (string !~ /_/) && (string =~ /[A-Z]+.*/)
  string.split('_').map{|e| e.capitalize}.join
end

desc "Start yard doc server"
task :yard do
  `rm -rf .yardoc && yard server --reload`
end

desc "Run ctags"
task :tag do
  `ctags -R --exclude=.git --exclude=log *`
end

desc "Pull the latest version from repository"
task :pull do
  `git pull origin`
end

task :load do
  require_relative 'lib/insectdb'
end

namespace :env do
  task :test do
    ENV['ENV'] = 'test'
  end

  task :production do
    ENV['ENV'] = 'production'
  end

  task :dev do
    ENV['ENV'] = 'development'
  end
end

task :test => ['env:test', 'db:configure_connection'] do
  require 'autotest'
  Autotest.parse_options()
  Autotest.runner.run
end

namespace :i do
  task :dev   => ['env:dev', 'db:configure_connection', 'irb']
  task :pro   => ['env:production',  'db:configure_connection', 'irb']
  task :test  => ['env:test',  'db:configure_connection', 'irb']

  task :irb do
    require 'irb'
    require_relative 'lib/insectdb'
    ARGV.clear
    IRB.start
  end
end

namespace :db do

  task :environment do
    ENV['DATABASE_ENV'] = ENV['ENV'] || 'production'
    MIGRATIONS_DIR = 'db/migrate'
  end

  task :configuration => :environment do
    @config = YAML.load_file('config/database.yml')[ENV['DATABASE_ENV']]
  end

  task :configure_connection => :configuration do
    ActiveRecord::Base.establish_connection @config
    ActiveRecord::Base.logger = Logger.new STDOUT if @config['logger']
  end

  task :maintenance_connection => :configuration do
    @config['maintenance_db'] = @config['database']
    @config['database'] = 'postgres'
    ActiveRecord::Base.establish_connection @config
    ActiveRecord::Base.logger = Logger.new STDOUT if @config['logger']
  end

  desc 'Create the database from config/database.yml for the current DATABASE_ENV'
  task :create => :configure_connection do
    options = {:charset => 'utf8', :collation => 'utf8_unicode_ci'}
    ActiveRecord::Base.establish_connection(@config.merge('database' => nil))
    ActiveRecord::Base.connection.create_database(@config['database'], options)
    ActiveRecord::Base.establish_connection(@config)
  end

  desc 'Drops the database for the current DATABASE_ENV'
  task :drop => :maintenance_connection do
    ActiveRecord::Base.connection.drop_database @config['maintenance_db']
  end

  desc 'Create new migration'
  task :create_migration, :name do |t, args|
    filename = Time.now.strftime("%Y%m%d%H%M%S") + "_" + args[:name]
    File.open("db/migrate/#{filename}.rb",'w') do |f|
      f << "class #{camel_case(args[:name])} < ActiveRecord::Migration\nend"
    end
  end

  desc 'Migrate the database (options: VERSION=x, VERBOSE=false).'
  task :migrate => :configure_connection do
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate(MIGRATIONS_DIR, ENV['VERSION'] ? ENV['VERSION'].to_i : nil)
  end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
  task :rollback, [:steps] => :configure_connection do |t, args|
    args.with_defaults(:steps => 1)
    step = args[:steps].to_i
    ActiveRecord::Migrator.rollback MIGRATIONS_DIR, step
  end

  desc "Retrieves the current schema version number"
  task :version => :configure_connection do
    puts "Current version: #{ActiveRecord::Migrator.current_version}"
  end

  namespace :seed do

    task :seqs => ['load', 'configure_connection'] do
      Insectdb::Seed.seqs
    end

    task :segments => ['load', 'configure_connection'] do
      Insectdb::Seed.segments
    end

    task :mrnas => ['load', 'configure_connection'] do
      Insectdb::Seed.mrnas
    end

    task :genes => ['load', 'configure_connection'] do
      Insectdb::Seed.genes
    end

    task :mrnas_segments => ['load', 'configure_connection'] do
      Insectdb::Seed.mrnas_segments
    end

    task :genes_mrnas => ['load', 'configure_connection'] do
      Insectdb::Seed.genes_mrnas
    end

    task :clean_segments => ['load', 'configure_connection'] do
      Insectdb::Segment.clean
    end

    task :clean_mrnas => ['load', 'configure_connection'] do
      Insectdb::Mrna.clean
    end

    task :set_ref_seqs => ['load', 'configure_connection'] do
      Insectdb::Mrna.set_ref_seq
    end

    task :all => ['load',
                  'seqs',
                  'segments',
                  'mrnas',
                  'genes',
                  'mrnas_segments',
                  'genes_mrnas',
                  'clean_segments',
                  'clean_mrnas',
                  'set_ref_seqs'
    ]

  end

  namespace :test do
    desc "Drop test DB"
    task :drop => ['env:test', 'db:drop']

    desc "Create & Migrate test DB"
    task :prepare => ['env:test', 'db:create', 'db:migrate']
  end

  namespace :dev do
    desc "Drop dev DB"
    task :drop => ['env:dev', 'db:drop']

    desc "Create & Migrate dev DB"
    task :prepare => ['env:dev', 'db:create', 'db:migrate']
  end
end
