module DbSanitiser
  module Dsl
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

      def truncate(table_name)
        @table_names.add(table_name)
        dsl = TruncateDsl.new(table_name)
        dsl._run(@strategy)
      end

      def delete_all(table_name)
        @table_names.add(table_name)
        dsl = DeleteAllDsl.new(table_name)
        dsl._run(@strategy)
      end

      def partially_delete(table_name, &block)
        @table_names.add(table_name)
        dsl = DeletePartialDsl.new(table_name, &block)
        dsl._run(@strategy)
      end
    end

    class SanitiseDsl
      def initialize(table_name, &block)
        @table_name = table_name
        @block = block
        @columns_to_sanitise = {}
        @columns_to_allow = []
        @indexes_to_drop_and_create = []
      end

      def _run(strategy)
        instance_eval(&@block)

        strategy.sanitise_table(@table_name, @columns_to_sanitise, @where_query, @columns_to_allow, @skip_unique_key_checks, @skip_foreign_key_checks, @indexes_to_drop_and_create)
      end

      def string(value)
        "\"#{value}\""
      end

      def skip_unique_key_checks
        @skip_unique_key_checks = true
      end

      def skip_foreign_key_checks
        @skip_foreign_key_checks = true
      end

      def drop_and_create_index(name, columns, options={})
        @indexes_to_drop_and_create << [name, columns, options]
      end

      def sanitise(name, sanitised_value)
        @columns_to_sanitise[name] = sanitised_value
      end

      def where(query)
        @where_query = query
      end

      def allow(*columns)
        @columns_to_allow += columns
      end
    end

    class TruncateDsl
      def initialize(table_name)
        @table_name = table_name
      end

      def _run(strategy)
        strategy.truncate(@table_name)
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

    class DeletePartialDsl
      def initialize(table_name, &block)
        @table_name = table_name
        @block = block
        @columns_to_allow = []
      end

      def where(query)
        @where_query = query
      end

      def allow(*columns)
        @columns_to_allow += columns
      end

      def _run(strategy)
        instance_eval(&@block)

        strategy.partially_delete(@table_name, @where_query, @columns_to_allow)
      end
    end
  end
end
