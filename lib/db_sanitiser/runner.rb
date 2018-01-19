require_relative 'dsl'
require_relative 'strategies'

module DbSanitiser
  class Runner
    def initialize(file_name)
      @file_name = file_name
    end

    def sanitise
      run(Strategies::SanitiseStrategy.new)
    end

    def validate
      run(Strategies::ValidateStrategy.new)
    end

    def dry_run(io)
      run(Strategies::DryRunStrategy.new(io))
    end

    private

    def run(strategy)
      config = File.read(@file_name)
      dsl = Dsl::RootDsl.new(strategy)
      dsl.instance_eval(config)
      strategy.after_run(dsl.instance_variable_get('@table_names').to_a)
    end
  end
end
