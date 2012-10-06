require 'yaml'
require 'logger'
require 'active_record'

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

namespace :env do
  task :test do
    ENV['ENV'] = 'test'
  end

  task :production do
    ENV['ENV'] = 'production'
  end

  task :development do
    ENV['ENV'] = 'development'
  end
end

namespace :i do

  task :dev  => ['env:development', 'db:configure_connection', 'irb']
  task :test => ['env:test',        'db:configure_connection', 'irb']
  task :pro  => ['env:production',  'db:configure_connection', 'irb']

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

  # This task seeds the database with sequence and annotation data.
  desc 'Seed database with data'
  task :seed => :configure_connection do
    require_relative 'lib/insectdb'
    Insectdb::Seed.run
  end

  desc 'Drops the database for the current DATABASE_ENV'
  task :drop => :maintenance_connection do
    ActiveRecord::Base.connection.drop_database @config['maintenance_db']
  end

  desc 'Migrate the database (options: VERSION=x, VERBOSE=false).'
  task :migrate => :configure_connection do
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate(MIGRATIONS_DIR, ENV['VERSION'] ? ENV['VERSION'].to_i : nil)
  end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
  task :rollback => :configure_connection do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    ActiveRecord::Migrator.rollback MIGRATIONS_DIR, step
  end

  desc "Retrieves the current schema version number"
  task :version => :configure_connection do
    puts "Current version: #{ActiveRecord::Migrator.current_version}"
  end

  namespace :test do
    task :env do
      ENV['ENV'] = 'test'
    end

    task :connect => ['env', 'db:configure_connection']

    desc "Prepare test DB"
    task :prepare => ['connect', 'db:drop', 'db:create', 'db:migrate']
  end

end
