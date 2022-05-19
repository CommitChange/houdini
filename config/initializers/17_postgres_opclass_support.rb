# rubocop:disable all

# These changes add support for PostgreSQL operator classes when creating
# indexes and dumping/loading schemas. Taken from Rails pull request
# https://github.com/rails/rails/pull/19090.
#
# License:
#
# Copyright (c) 2004-2016 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
if Rails.version < '5'
  require 'date'
  require 'set'
  require 'bigdecimal'
  require 'bigdecimal/util'

  # As the Struct definition is changed in this PR/patch we have to first remove
  # the existing one.
  ActiveRecord::ConnectionAdapters.send(:remove_const, :IndexDefinition)

  module ActiveRecord
    module ConnectionAdapters #:nodoc:
      # Abstract representation of an index definition on a table. Instances of
      # this type are typically created and returned by methods in database
      # adapters. e.g. ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter#indexes
      
      # this is needed because opclasses would otherwise be missing
      # from Rails 5.2
      class IndexDefinition < Struct.new(:table, :name, :unique, :columns, :lengths, :orders, :where, :type, :using, :opclasses) #:nodoc:
      end
    end
  end


  module ActiveRecord
    module ConnectionAdapters # :nodoc:
      module SchemaStatements
        # from Rails 5.2
        def options_for_index_columns(options)
          if options.is_a?(Hash)
            options.symbolize_keys
          else
            Hash.new { |hash, column| hash[column] = options }
          end
        end

        # from Rails 5.2
        def quoted_columns_for_index(column_names, **options)
          return [column_names] if column_names.is_a?(String)

          quoted_columns = Hash[column_names.map { |name| [name.to_sym, quote_column_name(name).dup] }]
          add_options_for_index_columns(quoted_columns, options).values
        end

        # from Rails 5.2
        def add_options_for_index_columns(quoted_columns, **options)
          if supports_index_sort_order?
            quoted_columns = add_index_sort_order(quoted_columns, options)
          end

          quoted_columns
        end

        # from Rails 5.2
        def index_column_names(column_names)
          if column_names.is_a?(String) && /\W/.match?(column_names)
            column_names
          else
            Array(column_names)
          end
        end
        
        # from Rails 5.2
        def index_name_options(column_names)
          if column_names.is_a?(String) && /\W/.match?(column_names)
            column_names = column_names.scan(/\w+/).join("_")
          end

          { column: column_names }
        end

        # From rails 5.2 but modified for Rails 4
        def add_index_options(table_name, column_name, options = {}) #:nodoc:
          column_names = index_column_names(column_name)
          index_name   = index_name(table_name, index_name_options(column_names))

          options.assert_valid_keys(:unique, :order, :name, :where, :length, :internal, :using, :algorithm, :type, :opclass)

          index_type = options[:unique] ? "UNIQUE" : ""
          index_type = options[:type].to_s if options.key?(:type)
          index_name = options[:name].to_s if options.key?(:name)
          max_index_length = options.fetch(:internal, false) ? index_name_length : allowed_index_name_length

          if options.key?(:algorithm)
            algorithm = index_algorithms.fetch(options[:algorithm]) {
              raise ArgumentError.new("Algorithm must be one of the following: #{index_algorithms.keys.map(&:inspect).join(', ')}")
            }
          end

          using = "USING #{options[:using]}" if options[:using].present?

          if supports_partial_index?
            index_options = options[:where] ? " WHERE #{options[:where]}" : ""
          end

          if index_name.length > max_index_length
            raise ArgumentError, "Index name '#{index_name}' on table '#{table_name}' is too long; the limit is #{max_index_length} characters"
          end
          if table_exists?(table_name) && index_name_exists?(table_name, index_name, false)
            raise ArgumentError, "Index name '#{index_name}' on table '#{table_name}' already exists"
          end
          index_columns = quoted_columns_for_index(column_names, options).join(", ")

          [index_name, index_type, index_columns, index_options, algorithm, using]
        end
      end
    end
  end

  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        module SchemaStatements
          # Returns an array of indexes for the given table.
          # mostly Rails 6.1 BUT modified to fit Rails 4
          # for example, we don't use a specific schema
          def indexes(table_name)
            result = query(<<-SQL, 'SCHEMA')
              SELECT distinct i.relname, d.indisunique, d.indkey, pg_get_indexdef(d.indexrelid), t.oid
              FROM pg_class t
              INNER JOIN pg_index d ON t.oid = d.indrelid
              INNER JOIN pg_class i ON d.indexrelid = i.oid
              WHERE i.relkind = 'i'
                AND d.indisprimary = 'f'
                AND t.relname = '#{table_name}'
                AND i.relnamespace IN (SELECT oid FROM pg_namespace WHERE nspname = ANY (current_schemas(false)) )
              ORDER BY i.relname
            SQL

            result.map do |row|
              index_name = row[0]
              unique = row[1] == 't'
              indkey = row[2].split(" ")
              inddef = row[3] # index definition
              oid = row[4]

              using, expressions, where = inddef.scan(/ USING (\w+?) \((.+?)\)(?: WHERE (.+))?\z/m).flatten

              orders = {}
              opclasses = {}
              columns  = nil
              if indkey.include?("0")
                # this means the index is not column based but has function or operator involved. For example,
                # one could have an index on `supporters` for `lower(name)`.
                columns = expressions
                
              else
                # the index is column based so we need to find out which columns are involved
                columns = Hash[query(<<~SQL, "SCHEMA")].values_at(*indkey).compact
                  SELECT a.attnum, a.attname
                  FROM pg_attribute a
                  WHERE a.attrelid = #{oid}
                  AND a.attnum IN (#{indkey.join(",")})
                SQL

                # add info on sort order (only desc order is explicitly specified, asc is the default)
                # and non-default opclasses
                expressions.scan(/(?<column>\w+)"?\s?(?<opclass>\w+_ops)?\s?(?<desc>DESC)?\s?(?<nulls>NULLS (?:FIRST|LAST))?/).each do |column, opclass, desc, nulls|
                  opclasses[column] = opclass.to_sym if opclass
                  if nulls
                    orders[column] = [desc, nulls].compact.join(" ")
                  else
                    orders[column] = :desc if desc
                  end
                end
              end
              
              IndexDefinition.new(table_name, index_name, unique, columns, [], orders, where, nil, using.to_sym, opclasses)
            end

            
          end

          # modification of Rails 4 to handle opclasses properly. Not really Rails 5.2 because we ignore the comments
          def add_index(table_name, column_name, options = {}) #:nodoc:
            index_name, index_type, index_columns_and_opclasses, index_options, index_algorithm, index_using = add_index_options(table_name, column_name, options)
            execute "CREATE #{index_type} INDEX #{index_algorithm} #{quote_column_name(index_name)} ON #{quote_table_name(table_name)} #{index_using} (#{index_columns_and_opclasses})#{index_options}"
          end


          # from rails 5.2 this is just for adding opclass to the columns
          def add_options_for_index_columns(quoted_columns, **options)
            quoted_columns = add_index_opclass(quoted_columns, options)
            super
          end

          # from rails 5.2
          def add_index_opclass(quoted_columns, **options)
            opclasses = options_for_index_columns(options[:opclass])
            quoted_columns.each do |name, column|
              column << " #{opclasses[name]}" if opclasses[name].present?
            end
          end
        end
      end
    end
  end

  module ActiveRecord
    class SchemaDumper
      private

        # Rails 4.2 but add the opclasses line
        def indexes(table, stream)
          if (indexes = @connection.indexes(table)).any?
            add_index_statements = indexes.map do |index|
              statement_parts = [
                "add_index #{remove_prefix_and_suffix(index.table).inspect}",
                index.columns.inspect,
                "name: #{index.name.inspect}",
              ]
              statement_parts << 'unique: true' if index.unique

              index_lengths = (index.lengths || []).compact
              statement_parts << "length: #{Hash[index.columns.zip(index.lengths)].inspect}" if index_lengths.any?

              index_orders = index.orders || {}
              statement_parts << "order: #{index.orders.inspect}" if index_orders.any?
              statement_parts << "where: #{index.where.inspect}" if index.where
              statement_parts << "using: #{index.using.inspect}" if index.using
              statement_parts << "type: #{index.type.inspect}" if index.type
              statement_parts << "opclass: #{index.opclasses}" if index.opclasses.present?

              "  #{statement_parts.join(', ')}"
            end

            stream.puts add_index_statements.sort.join("\n")
            stream.puts
          end
        end
    end
  end
else
  console.log("You might not need this code anymore")
end