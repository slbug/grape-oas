# frozen_string_literal: true

module GrapeOAS
  module Exporter
    module OAS3
      class Schema
        def initialize(schema, ref_tracker = nil, nullable_keyword: true)
          @schema = schema
          @ref_tracker = ref_tracker
          @nullable_keyword = nullable_keyword
        end

        def build
          return {} unless @schema

          schema_hash = {}
          schema_hash["type"] = nullable_type
          schema_hash["format"] = @schema.format
          schema_hash["description"] = @schema.description
          schema_hash["properties"] = build_properties(@schema.properties)
          schema_hash["items"] = @schema.items ? build_schema_or_ref(@schema.items) : nil
          schema_hash["required"] = @schema.required if @schema.required && !@schema.required.empty?
          schema_hash["enum"] = @schema.enum if @schema.enum
          schema_hash["example"] = @schema.examples if @schema.examples
          schema_hash.merge!(@schema.extensions) if @schema.extensions
          schema_hash["additionalProperties"] = @schema.additional_properties unless @schema.additional_properties.nil?
          if !@nullable_keyword && !@schema.unevaluated_properties.nil?
            schema_hash["unevaluatedProperties"] = @schema.unevaluated_properties
          end
          if !@nullable_keyword && @schema.defs && !@schema.defs.empty?
            schema_hash["$defs"] = @schema.defs
          end
          apply_numeric_constraints(schema_hash)
          apply_string_constraints(schema_hash)
          apply_array_constraints(schema_hash)
          schema_hash.compact
        end

        private

        def nullable_type
          return @schema.type unless @schema.respond_to?(:nullable) && @schema.nullable

          if @nullable_keyword
            # OAS3.0 style
            type_hash = { "type" => @schema.type, "nullable" => true }
            return type_hash["type"] if @schema.type.nil?
            return type_hash["type"] if @schema.type.is_a?(Array)
            type_hash["type"]
          else
            base = Array(@schema.type || "string")
            (base | ["null"])
          end
        end

        def build_properties(properties)
          return nil unless properties

          properties.each_with_object({}) do |(name, prop_schema), h|
            h[name] = build_schema_or_ref(prop_schema)
          end
        end

        def build_schema_or_ref(schema)
          if schema.respond_to?(:canonical_name) && schema.canonical_name
            @ref_tracker << schema.canonical_name if @ref_tracker
            ref_name = schema.canonical_name.gsub("::", "_")
            { "$ref" => "#/components/schemas/#{ref_name}" }
          else
            Schema.new(schema, @ref_tracker, nullable_keyword: @nullable_keyword).build
          end
        end

        def apply_numeric_constraints(hash)
          hash["minimum"] = @schema.minimum if @schema.minimum
          hash["maximum"] = @schema.maximum if @schema.maximum
          hash["exclusiveMinimum"] = @schema.exclusive_minimum if @schema.exclusive_minimum
          hash["exclusiveMaximum"] = @schema.exclusive_maximum if @schema.exclusive_maximum
        end

        def apply_string_constraints(hash)
          hash["minLength"] = @schema.min_length if @schema.min_length
          hash["maxLength"] = @schema.max_length if @schema.max_length
          hash["pattern"] = @schema.pattern if @schema.pattern
        end

        def apply_array_constraints(hash)
          hash["minItems"] = @schema.min_items if @schema.min_items
          hash["maxItems"] = @schema.max_items if @schema.max_items
        end
      end
    end
  end
end
