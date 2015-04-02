module ActiveRecord
  module Calculations

    def execute_grouped_calculation(operation, column_name, distinct)
      group_attr      = @group_values
      association     = @klass.reflect_on_association(group_attr.first.to_sym)
      associated      = group_attr.size == 1 && association && association.macro == :belongs_to # only count belongs_to associations
      group_fields  = Array(associated ? association.primary_key_name : group_attr)
      group_aliases = []
      group_columns = {}

      group_fields.each do |field|
        group_aliases << column_alias_for(field)
        group_columns[column_alias_for(field)] = column_for(field)
      end

      group = @klass.connection.adapter_name == 'FrontBase' ? group_aliases : group_fields

      if operation == 'count' && column_name == :all
        aggregate_alias = 'count_all'
      else
        aggregate_alias = column_alias_for(operation, column_name)
      end

      relation = except(:group).group(group.join(','))
      relation.select_values = [ operation_over_aggregate_column(aggregate_column(column_name), operation, distinct).as(aggregate_alias) ]
      group_fields.each_index{ |i| relation.select_values << "#{group_fields[i]} AS #{group_aliases[i]}" }

      calculated_data = @klass.connection.select_all(relation.to_sql)

      if association
        key_ids     = calculated_data.collect { |row| row[group_aliases.first] }
        key_records = association.klass.base_class.find(key_ids)
        key_records = Hash[key_records.map { |r| [r.id, r] }]
      end

      ActiveSupport::OrderedHash[calculated_data.map do |row|
          key   = group_aliases.map{|group_alias| type_cast_calculated_value(row[group_alias], group_columns[group_alias])}
          key   = key.first if key.size == 1
          key = key_records[key] if associated
          [key, type_cast_calculated_value(row[aggregate_alias], column_for(column_name), operation)]
        end]

    end
  end
end
