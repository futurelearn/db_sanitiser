module DbSanitiser
  class Runner
    def initialize(file_name)
      @file_name = file_name
    end

    def sanitise
      config = File.read(@file_name)
      dsl = RootDsl.new
      dsl.instance_eval(config)
    end
  end

  class RootDsl
    def sanitise_table(table_name, &block)
      dsl = SanitiseDsl.new(table_name, &block)
      dsl._run
    end
  end

  class SanitiseDsl
    def initialize(table_name, &block)
      @table_name = table_name
      @block = block
      @columns_to_sanitise = {}
    end

    def _run
      instance_eval(&@block)

      update_values = @columns_to_sanitise.to_a.map do |(key, value)|
        "`#{key}` = #{value}"
      end
      scope = active_record_class
      scope = scope.where(@where_query) if @where_query
      scope.update_all(update_values.join(', '))
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

    private

    def active_record_class
      table_name = @table_name
      @ar_class ||= Class.new(ActiveRecord::Base) { self.table_name = table_name }
    end
  end
end
