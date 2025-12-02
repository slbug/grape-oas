# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  module ApiModelBuilders
    # Tests for parameter location determination (path vs query vs body vs formData)
    class RequestParamsLocationTest < Minitest::Test
      def setup
        @api = GrapeOAS::ApiModel::API.new(title: "Test API", version: "1.0")
      end

      # === Path parameter location ===

      def test_path_parameter_location
        api_class = Class.new(Grape::API) do
          format :json
          params do
            requires :id, type: Integer
          end
          get ":id" do
            {}
          end
        end

        route = api_class.routes.first
        op = build_operation(route, api_class)

        path_params = op.parameters.select { |p| p.location == "path" }
        assert_equal 1, path_params.length
        assert_equal "id", path_params.first.name
      end

      # === Query parameter location for GET ===

      def test_query_parameter_location_for_get
        api_class = Class.new(Grape::API) do
          format :json
          params do
            optional :page, type: Integer
            optional :per_page, type: Integer
          end
          get "items" do
            []
          end
        end

        route = api_class.routes.first
        op = build_operation(route, api_class)

        query_params = op.parameters.select { |p| p.location == "query" }
        assert_equal 2, query_params.length
      end

      # === Body parameter via nested params (bracket notation) ===

      def test_body_params_via_nested_notation
        api_class = Class.new(Grape::API) do
          format :json
          params do
            requires :user, type: Hash do
              requires :name, type: String
              requires :email, type: String
            end
          end
          post "users" do
            {}
          end
        end

        route = api_class.routes.first
        op = build_operation(route, api_class)

        # Nested params go to request body
        refute_nil op.request_body
      end

      # === Mixed path and query params ===

      def test_mixed_path_and_query_params
        api_class = Class.new(Grape::API) do
          format :json
          params do
            requires :user_id, type: Integer
            optional :include_deleted, type: Grape::API::Boolean
          end
          get ":user_id/posts" do
            []
          end
        end

        route = api_class.routes.first
        op = build_operation(route, api_class)

        path_params = op.parameters.select { |p| p.location == "path" }
        query_params = op.parameters.select { |p| p.location == "query" }

        assert path_params.any? { |p| p.name == "user_id" }
        assert query_params.any? { |p| p.name == "include_deleted" }
      end

      # === PUT with path and nested body params ===

      def test_put_with_path_and_nested_body_params
        api_class = Class.new(Grape::API) do
          format :json
          params do
            requires :id, type: Integer
            requires :user, type: Hash do
              requires :name, type: String
              optional :email, type: String
            end
          end
          put ":id" do
            {}
          end
        end

        route = api_class.routes.first
        op = build_operation(route, api_class)

        path_params = op.parameters.select { |p| p.location == "path" }
        assert path_params.any? { |p| p.name == "id" }

        # Nested params go to request body
        refute_nil op.request_body
      end

      # === DELETE with path param only ===

      def test_delete_with_path_param
        api_class = Class.new(Grape::API) do
          format :json
          params do
            requires :id, type: Integer
          end
          delete ":id" do
            {}
          end
        end

        route = api_class.routes.first
        op = build_operation(route, api_class)

        path_params = op.parameters.select { |p| p.location == "path" }
        assert_equal 1, path_params.length
        assert_equal "id", path_params.first.name
      end

      # === Explicit param_type body ===

      def test_explicit_param_type_body
        api_class = Class.new(Grape::API) do
          format :json
          params do
            requires :payload, type: Hash, documentation: { param_type: "body" }
          end
          post "webhook" do
            {}
          end
        end

        route = api_class.routes.first
        op = build_operation(route, api_class)

        refute_nil op.request_body
      end

      # === Explicit param_type query ===

      def test_explicit_param_type_query
        api_class = Class.new(Grape::API) do
          format :json
          params do
            requires :filter, type: String, documentation: { param_type: "query" }
          end
          post "search" do
            []
          end
        end

        route = api_class.routes.first
        op = build_operation(route, api_class)

        query_params = op.parameters.select { |p| p.location == "query" }
        assert query_params.any? { |p| p.name == "filter" }
      end

      # === Header parameter location ===

      def test_header_parameter_location
        api_class = Class.new(Grape::API) do
          format :json
          params do
            requires :authorization, type: String, documentation: { param_type: "header" }
          end
          get "protected" do
            {}
          end
        end

        route = api_class.routes.first
        op = build_operation(route, api_class)

        header_params = op.parameters.select { |p| p.location == "header" }
        assert header_params.any? { |p| p.name == "authorization" }
      end

      # === Multiple path params in nested route ===

      def test_multiple_path_params
        api_class = Class.new(Grape::API) do
          format :json
          params do
            requires :org_id, type: Integer
            requires :team_id, type: Integer
            requires :user_id, type: Integer
          end
          get ":org_id/teams/:team_id/users/:user_id" do
            {}
          end
        end

        route = api_class.routes.first
        op = build_operation(route, api_class)

        path_params = op.parameters.select { |p| p.location == "path" }
        path_names = path_params.map(&:name)

        assert_includes path_names, "org_id"
        assert_includes path_names, "team_id"
        assert_includes path_names, "user_id"
      end

      private

      def build_operation(route, app)
        Operation.new(api: @api, route: route, app: app).build
      end
    end
  end
end
