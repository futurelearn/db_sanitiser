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

    private

    def run(strategy)
      config = File.read(@file_name)
      dsl = RootDsl.new(strategy)
      dsl.instance_eval(config)
      strategy.after_run(dsl.instance_variable_get('@table_names').to_a)
    end
  end

  class RootDsl
    def initialize(strategy)
      @strategy = strategy
      @table_names = Set.new
    end

    def sanitise_table(table_name, &block)
      @table_names.add(table_name)
      dsl = SanitiseDsl.new(table_name, &block)
      dsl._run(@strategy)
    end

    def delete_all(table_name)
      @table_names.add(table_name)
      dsl = DeleteAllDsl.new(table_name)
      dsl._run(@strategy)
    end
  end

  class SanitiseDsl
    def initialize(table_name, &block)
      @table_name = table_name
      @block = block
      @columns_to_sanitise = {}
      @columns_to_ignore = []
    end

    def _run(strategy)
      instance_eval(&@block)

      strategy.sanitise_table(@table_name, @columns_to_sanitise, @where_query, @columns_to_ignore)
    end

    def string(value)
      "\"#{value}\""
    end

    def sanitise(name, sanitised_value)
      @columns_to_sanitise[name] = sanitised_value
    end

    def where(query)
      @where_query = query
    end

    def ignore(*columns)
      @columns_to_ignore += columns
    end
  end

  class DeleteAllDsl
    def initialize(table_name)
      @table_name = table_name
    end

    def _run(strategy)
      strategy.delete_all(@table_name)
    end
  end
end
