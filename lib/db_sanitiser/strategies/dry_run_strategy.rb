module DbSanitiser
  module Strategies
    class DryRunStrategy
      def initialize(io)
        @io = io
      end

      def sanitise_table(table_name, columns_to_sanitise, where_query, allowed_columns, skip_unique_key_checks, skip_foreign_key_checks)
        update_values = columns_to_sanitise.to_a.map do |(key, value)|
          "`#{key}` = #{value}"
        end
        scope = active_record_class(table_name).all
        scope = scope.where(where_query) if where_query
        @io.puts("Disable unique key checks") if skip_unique_key_checks
        @io.puts("Disable foreign key checks") if skip_foreign_key_checks
        @io.puts("Sanitise rows that match: #{scope.to_sql}: #{update_values.join(', ')}")
        @io.puts("Re-enable key checks") if skip_unique_key_checks || skip_foreign_key_checks
      end

      def delete_all(table_name)
        @io.puts("Delete all rows from \"#{table_name}\"")
      end

      def partially_delete(table_name, where_query, allowed_columns)
        @io.puts("Delete rows from \"#{table_name}\" that match: #{where_query}")
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
