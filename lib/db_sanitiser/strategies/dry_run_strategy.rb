module DbSanitiser
  module Strategies
    class DryRunStrategy
      def initialize(io)
        @io = io
      end

      def sanitise_table(table_name, columns_to_sanitise, where_query, ignored_columns)
        update_values = columns_to_sanitise.to_a.map do |(key, value)|
          "`#{key}` = #{value}"
        end
        scope = active_record_class(table_name).all
        scope = scope.where(where_query) if where_query
        @io.puts("Sanitise rows that match: #{scope.to_sql}: #{update_values.join(', ')}")
      end

      def delete_all(table_name)
        @io.puts("Delete all rows from \"#{table_name}\"")
      end

      def after_run(processed_tables)
      end

      private

      def active_record_class(table_name)
        Class.new(ActiveRecord::Base) { self.table_name = table_name }
      end
    end
  end
end
