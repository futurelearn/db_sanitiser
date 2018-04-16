module DbSanitiser
  module Strategies
    class SanitiseStrategy
      def sanitise_table(table_name, columns_to_sanitise, where_query, allowed_columns)
        return if columns_to_sanitise.empty?
        update_values = columns_to_sanitise.to_a.map do |(key, value)|
          "`#{key}` = #{value}"
        end
        scope = active_record_class(table_name)
        scope = scope.where(where_query) if where_query
        scope.update_all(update_values.join(', '))
      end

      def delete_all(table_name)
        active_record_class(table_name).delete_all
      end

      def partially_delete(table_name, where_query, allowed_columns)
        active_record_class(table_name).where(where_query).delete_all
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
