module DbSanitiser
  module Strategies
    class ValidateStrategy
      ACTIVERECORD_META_TABLES = %w(schema_migrations ar_internal_metadata)

      def sanitise_table(table_name, columns_to_sanitise, where_query, allowed_columns, skip_unique_key_checks, skip_foreign_key_checks, indexes_to_drop_and_create)
        ar_class = active_record_class(table_name)
        columns = columns_to_sanitise.keys + allowed_columns

        validate_columns_are_accounted_for(ar_class, table_name, columns)
        validate_indexes_exist(table_name, indexes_to_drop_and_create)
      end

      def truncate(table_name)
      end

      def delete_all(table_name)
      end

      def partially_delete(table_name, where_query, allowed_columns)
        ar_class = active_record_class(table_name)

        validate_columns_are_accounted_for(ar_class, table_name, allowed_columns)
      end

      def after_run(processed_tables)
        tables_in_db = ActiveRecord::Base.connection.tables
        tables_not_accounted_for = tables_in_db - ACTIVERECORD_META_TABLES - processed_tables
        unless tables_not_accounted_for.empty?
          fail "Please add db_sanitiser config for these tables: #{tables_not_accounted_for.inspect}"
        end
      end

      private

      def active_record_class(table_name)
        Class.new(ActiveRecord::Base) { self.table_name = table_name }
      end

      def validate_columns_are_accounted_for(active_record_class, table_name, columns)
        columns_not_accounted_for = active_record_class.column_names - columns
        unless columns_not_accounted_for.empty?
          fail "Please add db_sanitiser config for these columns in '#{table_name}': #{columns_not_accounted_for.inspect}"
        end

        unknown_columns = columns - active_record_class.column_names
        unless unknown_columns.empty?
          fail "You have db_sanitiser config for these columns in '#{table_name}', but they don't exist in the database: #{unknown_columns.inspect}"
        end
      end

      def validate_indexes_exist(table_name, indexes_to_drop_and_create)
        indexes_to_drop_and_create.each do |index_name|
          unless ActiveRecord::Base.connection.indexes(table_name).detect { |i| i.name == index_name }
            fail "The index `#{index_name}` was set to be dropped and recreated, but does not match any index in the schema"
          end
        end
      end
    end
  end
end
