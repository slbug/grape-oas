# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  module ApiModelBuilders
    # Tests for deprecated endpoint handling
    class OperationDeprecatedTest < Minitest::Test
      def setup
        @api = GrapeOAS::ApiModel::API.new(title: "Test API", version: "1.0")
      end

      # === Deprecated via desc option ===

      def test_deprecated_via_desc_option
        api_class = Class.new(Grape::API) do
          format :json
          desc "Old endpoint", deprecated: true
          get "old" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        assert op.deprecated, "Operation should be deprecated"
      end

      # === Not deprecated by default ===

      def test_not_deprecated_by_default
        api_class = Class.new(Grape::API) do
          format :json
          desc "Current endpoint"
          get "current" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        refute op.deprecated, "Operation should not be deprecated by default"
      end

      # === Deprecated explicitly false ===

      def test_deprecated_explicitly_false
        api_class = Class.new(Grape::API) do
          format :json
          desc "Active endpoint", deprecated: false
          get "active" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        refute op.deprecated, "Operation should not be deprecated when explicitly false"
      end

      # === Deprecated via documentation option ===

      def test_deprecated_via_documentation
        api_class = Class.new(Grape::API) do
          format :json
          desc "Deprecated via docs", documentation: { deprecated: true }
          get "deprecated_docs" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        assert op.deprecated, "Operation should be deprecated via documentation option"
      end

      # === Deprecated with deprecation message extension ===

      def test_deprecated_with_message_extension
        api_class = Class.new(Grape::API) do
          format :json
          desc "Deprecated with message",
               deprecated: true,
               documentation: { "x-deprecation-reason" => "Use /v2/endpoint instead" }
          get "old_with_message" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        assert op.deprecated
        refute_nil op.extensions
        assert_equal "Use /v2/endpoint instead", op.extensions["x-deprecation-reason"]
      end

      # === Deprecated endpoint with sunset header ===

      def test_deprecated_with_sunset_extension
        api_class = Class.new(Grape::API) do
          format :json
          desc "Sunset scheduled",
               deprecated: true,
               documentation: { "x-sunset-date" => "2025-12-31" }
          get "sunsetting" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        assert op.deprecated
        assert_equal "2025-12-31", op.extensions["x-sunset-date"]
      end

      # === Multiple deprecated endpoints ===

      def test_multiple_deprecated_endpoints
        api_class = Class.new(Grape::API) do
          format :json

          desc "Old v1", deprecated: true
          get "v1/resource" do
            {}
          end

          desc "Current v2"
          get "v2/resource" do
            {}
          end
        end

        routes = api_class.routes
        v1_route = routes.find { |r| r.path.include?("v1") }
        v2_route = routes.find { |r| r.path.include?("v2") }

        v1_op = Operation.new(api: @api, route: v1_route).build
        v2_op = Operation.new(api: @api, route: v2_route).build

        assert v1_op.deprecated, "v1 should be deprecated"
        refute v2_op.deprecated, "v2 should not be deprecated"
      end
    end
  end
end
