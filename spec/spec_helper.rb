require "bundler/setup"
require "db_sanitiser"
require 'pathname'
require 'yaml'
require 'mysql2'
require 'active_record'
require 'database_cleaner'

raise "By default DbSanitiser should not be enabled" if DbSanitiser.enabled?

include ActiveRecord::Tasks

DB_DIR = Pathname.new(__FILE__).dirname.expand_path.join('db')
DB_CONFIG = YAML.load_file(DB_DIR.join('config.yml').to_s)

ActiveRecord::Base.configurations = DB_CONFIG
DatabaseTasks.database_configuration = DB_CONFIG
DatabaseTasks.db_dir = DB_DIR.to_s
DatabaseTasks.env = 'test'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    DatabaseTasks.drop_current
    DatabaseTasks.create_current
    ActiveRecord::Schema.verbose = false
    DatabaseTasks.load_schema_current
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.clean
  end

  config.before(:each) do
    DbSanitiser.enable!
  end
end
