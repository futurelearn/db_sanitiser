require "db_sanitiser/version"
require 'db_sanitiser/runner'

module DbSanitiser
  def self.sanitise(file_name)
    Runner.new(file_name).sanitise
  end

  def self.validate(file_name)
    Runner.new(file_name).validate
  end
end
