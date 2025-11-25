# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  module ApiModelBuilders
    class OperationExtensionsTest < Minitest::Test
      def test_extensions_and_security_passthrough_in_oas3_export
        op = ApiModel::Operation.new(
          http_method: :get,
          operation_id: "op1",
          security: [{ api_key: [] }],
          extensions: { "x-foo" => "bar" },
        )

        exported = GrapeOAS::Exporter::OAS3::Operation.new(op).build

        assert_equal [{ api_key: [] }], exported["security"]
        assert_equal "bar", exported["x-foo"]
      end

      def test_extensions_and_security_passthrough_in_oas2_export
        op = ApiModel::Operation.new(
          http_method: :get,
          operation_id: "op1",
          security: [{ api_key: [] }],
          extensions: { "x-foo" => "bar" },
        )

        exported = GrapeOAS::Exporter::OAS2::Operation.new(op).build

        assert_equal [{ api_key: [] }], exported["security"]
        assert_equal "bar", exported["x-foo"]
      end
    end
  end
end
