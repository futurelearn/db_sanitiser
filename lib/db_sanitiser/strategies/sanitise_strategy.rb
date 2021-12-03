module DbSanitiser
  module Strategies
    class SanitiseStrategy
      def sanitise_table(table_name, columns_to_sanitise, where_query, allowed_columns, skip_unique_key_checks, skip_foreign_key_checks, indexes_to_drop_and_create)
        return if columns_to_sanitise.empty?

        set_mysql_options(skip_unique_key_checks, skip_foreign_key_checks)
        without_indexes(table_name, indexes_to_drop_and_create) do
          update_values = columns_to_sanitise.to_a.map do |(key, value)|
            "`#{key}` = #{value}"
          end
          scope = active_record_class(table_name)
          scope = scope.where(where_query) if where_query
          scope.update_all(update_values.join(', '))
        end
      ensure
        reset_mysql_options
      end

      def truncate(table_name)
        ActiveRecord::Base.connection.truncate(table_name)
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

      def without_indexes(table_name, indexes_to_drop_and_create)
        return yield if indexes_to_drop_and_create.empty?

        indexes = indexes_to_drop_and_create.map do |index_name|
          connection.indexes(table_name).detect { |i| i.name == index_name }
        end

        indexes.each do |index|
          connection.remove_index(table_name, name: index.name)
        end

        yield

        indexes.each do |index|
          connection.add_index(table_name, index.columns, index_options(index))
        end
      end

      def index_options(index)
        {
          length: index.lengths,
          name: index.name,
          order: index.orders,
          unique: index.unique
        }
      end

      def set_mysql_options(skip_unique_key_checks, skip_foreign_key_checks)
        return unless supports_skip_key_checks?

        connection.execute(%(SET unique_checks=0)) if skip_unique_key_checks
        connection.execute(%(SET foreign_key_checks=0)) if skip_foreign_key_checks
      end

      def reset_mysql_options
        return unless supports_skip_key_checks?

        connection.execute(%(SET foreign_key_checks=1, unique_checks=1))
      end

      def supports_skip_key_checks?
        ActiveRecord::Base.connection_db_config.adapter == 'mysql2'
      end

      def connection
        ActiveRecord::Base.connection
      end

      def active_record_class(table_name)
        Class.new(ActiveRecord::Base) { self.table_name = table_name }
      end
    end
  end
end
