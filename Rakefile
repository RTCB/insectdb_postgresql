require 'yaml'
require 'logger'
require 'active_record'

desc "Start yard doc server"
task :yard do
  `rm -rf .yardoc && yard server --reload`
end

desc "Execute ctags on all code"
task :tag do
  `ctags -R --exclude=.git --exclude=log *`
end

desc "Pull the latest version from repository"
task :pull do
  `git pull origin`
end

namespace :env do
  task :test do
    ENV['DATABASE_ENV'] = 'test'
  end
end

namespace :db do

  namespace :test do
    task :prepare => 'env:test' do
      Rake::Task['db:migrate'].invoke
    end
  end

  task :environment do
    DATABASE_ENV = ENV['DATABASE_ENV'] || 'production'
    MIGRATIONS_DIR = 'db/migrate'
  end

  task :configuration => :environment do
    @config = YAML.load_file('config/database.yml')[DATABASE_ENV]
  end

  task :configure_connection => :configuration do
    ActiveRecord::Base.establish_connection @config
    ActiveRecord::Base.logger = Logger.new STDOUT if @config['logger']
  end

  desc 'Create the database from config/database.yml for the current DATABASE_ENV'
  task :create => :configure_connection do
    create_database @config
  end

  desc 'Drops the database for the current DATABASE_ENV'
  task :drop => :configure_connection do
    ActiveRecord::Base.connection.drop_database @config['database']
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
end
