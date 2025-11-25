# frozen_string_literal: true

module GrapeOAS
  class EntityIntrospector
    PRIMITIVE_MAPPING = {
      "integer" => "integer",
      "float" => "number",
      "bigdecimal" => "number",
      "string" => "string",
      "boolean" => "boolean"
    }.freeze

    def initialize(entity_class)
      @entity_class = entity_class
    end

    def build_schema
      schema = ApiModel::Schema.new(
        type: "object",
        canonical_name: @entity_class.name,
        description: entity_doc[:desc] || entity_doc[:description],
      )

      exposures.each do |exposure|
        next unless exposed?(exposure)

        name = exposure.key.to_s
        doc = exposure.documentation || {}

        if exposure.respond_to?(:for_merge) && exposure.for_merge
          merged_schema = schema_for_merge(exposure, doc)
          merged_schema.properties.each do |n, ps|
            schema.add_property(n, ps, required: merged_schema.required.include?(n))
          end
          next
        end

        prop_schema = schema_for_exposure(exposure, doc)
        is_array = doc[:is_array] || doc["is_array"]

        prop_schema = ApiModel::Schema.new(type: "array", items: prop_schema) if is_array

        schema.add_property(name, prop_schema, required: doc[:required])
      end

      schema
    end

    private

    def entity_doc
      @entity_class.respond_to?(:documentation) ? (@entity_class.documentation || {}) : {}
    rescue StandardError
      {}
    end

    def exposures
      return [] unless @entity_class.respond_to?(:root_exposures)
      root = @entity_class.root_exposures
      list = root.instance_variable_get(:@exposures) || []
      Array(list)
    rescue StandardError
      []
    end
    def schema_for_exposure(exposure, doc)
      opts = exposure.instance_variable_get(:@options) || {}
      type = doc[:type] || doc["type"] || opts[:using]
      nullable = doc[:nullable] || doc["nullable"] || false
      enum = doc[:values] || doc["values"]
      desc = doc[:desc] || doc["desc"]
      fmt  = doc[:format] || doc["format"]
      example = doc[:example] || doc["example"]
      x_ext = doc.select { |k, _| k.to_s.start_with?("x-") }

      schema = case type
               when Array
                 inner = schema_for_type(type.first)
                 ApiModel::Schema.new(type: "array", items: inner)
               when Hash
                  ApiModel::Schema.new(type: "object")
               else
                 schema_for_type(type)
               end
      schema ||= ApiModel::Schema.new(type: "string")
      schema.nullable = nullable
      schema.enum = enum if enum
      schema.description = desc if desc
      schema.format = fmt if fmt
      schema.examples = example if schema.respond_to?(:examples=) && example
      schema.additional_properties = doc[:additional_properties] if doc.key?(:additional_properties)
      schema.unevaluated_properties = doc[:unevaluated_properties] if doc.key?(:unevaluated_properties)
      defs = doc[:defs] || doc[:$defs]
      schema.defs = defs if defs.is_a?(Hash)
      if x_ext.any? && schema.respond_to?(:extensions=)
        schema.extensions = x_ext
      end
      schema
    end

    def exposed?(exposure)
      conditions = exposure.instance_variable_get(:@conditions) || []
      return true if conditions.empty?
      # If conditional exposure, keep it but mark nullable to reflect optionality
      true
    rescue StandardError
      true
    end

    def schema_for_type(type)
      case type
      when nil
        ApiModel::Schema.new(type: "string")
      when Class
        if defined?(Grape::Entity) && type <= Grape::Entity
          EntityIntrospector.new(type).build_schema
        elsif type == Integer
          ApiModel::Schema.new(type: "integer")
        elsif type == Float || type == BigDecimal
          ApiModel::Schema.new(type: "number")
        elsif type == TrueClass || type == FalseClass
          ApiModel::Schema.new(type: "boolean")
        elsif type == Array
          ApiModel::Schema.new(type: "array")
        elsif type == Hash
          ApiModel::Schema.new(type: "object")
        else
          ApiModel::Schema.new(type: "string")
        end
      when String, Symbol
        t = PRIMITIVE_MAPPING[type.to_s.downcase] || "string"
        ApiModel::Schema.new(type: t)
      else
        ApiModel::Schema.new(type: "string")
      end
    end

    def schema_for_merge(exposure, doc)
      merged = ApiModel::Schema.new(type: "object")
      nested = exposures_from_merge(exposure)
      nested.each do |child|
        child_doc = child.documentation || {}
        prop_schema = schema_for_exposure(child, child_doc)
        merged.add_property(child.key.to_s, prop_schema, required: child_doc[:required])
      end
      merged
    end

    def exposures_from_merge(exposure)
      exp = exposure.instance_variable_get(:@for_merge)
      return [] unless exp
      if exp.respond_to?(:exposures)
        exp.exposures
      else
        list = exp.instance_variable_get(:@exposures)
        Array(list)
      end
    rescue StandardError
      []
    end
  end
end
