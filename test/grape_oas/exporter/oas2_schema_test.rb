# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  module Exporter
    class OAS2SchemaTest < Minitest::Test
      def test_merges_extensions_into_output
        schema = ApiModel::Schema.new(
          type: "string",
          extensions: { "x-nullable" => true, "x-deprecated" => "Use 'status' instead" },
        )

        result = OAS2::Schema.new(schema).build

        assert_equal "string", result["type"]
        assert result["x-nullable"]
        assert_equal "Use 'status' instead", result["x-deprecated"]
      end

      def test_extensions_on_object_schema
        schema = ApiModel::Schema.new(
          type: "object",
          extensions: { "x-custom" => { "key" => "value" } },
        )
        schema.add_property("name", ApiModel::Schema.new(type: "string"))

        result = OAS2::Schema.new(schema).build

        assert_equal "object", result["type"]
        assert_equal({ "key" => "value" }, result["x-custom"])
        assert result["properties"]["name"]
      end

      def test_nil_extensions_does_not_add_keys
        schema = ApiModel::Schema.new(type: "integer")

        result = OAS2::Schema.new(schema).build

        assert_equal "integer", result["type"]
        refute result.key?("x-nullable")
      end
    end
  end
end
