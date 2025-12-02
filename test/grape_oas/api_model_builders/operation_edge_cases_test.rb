# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  module ApiModelBuilders
    # Tests for various Operation builder edge cases
    class OperationEdgeCasesTest < Minitest::Test
      def setup
        @api = GrapeOAS::ApiModel::API.new(title: "Test API", version: "1.0")
      end

      # === Operation ID from nickname ===

      def test_operation_id_from_nickname
        api_class = Class.new(Grape::API) do
          format :json
          desc "Get user", nickname: "getUser"
          get "user/:id" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        assert_equal "getUser", op.operation_id
      end

      # === Operation ID auto-generated ===

      def test_operation_id_auto_generated
        api_class = Class.new(Grape::API) do
          format :json
          get "users/:id/posts" do
            []
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        refute_nil op.operation_id
        # Should be generated from path
        assert_match(/get/, op.operation_id)
      end

      # === Tags from options ===

      def test_tags_from_options
        api_class = Class.new(Grape::API) do
          format :json
          desc "User endpoint", tags: %w[users admin]
          get "user" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        assert_includes op.tag_names, "users"
        assert_includes op.tag_names, "admin"
      end

      # === Tags derived from path ===

      def test_tags_derived_from_path
        api_class = Class.new(Grape::API) do
          format :json

          namespace :orders do
            get "/" do
              []
            end
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        assert_includes op.tag_names, "orders"
      end

      # === Multiple HTTP methods same path ===

      def test_multiple_methods_same_path
        api_class = Class.new(Grape::API) do
          format :json

          resource :items do
            get do
              []
            end

            post do
              {}
            end
          end
        end

        get_route = api_class.routes.find { |r| r.request_method == "GET" }
        post_route = api_class.routes.find { |r| r.request_method == "POST" }

        get_op = Operation.new(api: @api, route: get_route).build
        post_op = Operation.new(api: @api, route: post_route).build

        # http_method can be symbol or string depending on implementation
        assert_includes [:get, "get"], get_op.http_method
        assert_includes [:post, "post"], post_op.http_method
        refute_equal get_op.operation_id, post_op.operation_id
      end

      # === All HTTP methods ===

      def test_all_http_methods
        api_class = Class.new(Grape::API) do
          format :json

          get "resource" do
            {}
          end

          post "resource" do
            {}
          end

          put "resource" do
            {}
          end

          patch "resource" do
            {}
          end

          delete "resource" do
            {}
          end

          options "resource" do
            {}
          end

          head "resource" do
            {}
          end
        end

        methods = api_class.routes.map do |r|
          Operation.new(api: @api, route: r).build.http_method.to_s
        end

        assert_includes methods, "get"
        assert_includes methods, "post"
        assert_includes methods, "put"
        assert_includes methods, "patch"
        assert_includes methods, "delete"
        assert_includes methods, "options"
        assert_includes methods, "head"
      end

      # === Nil description handled ===

      def test_nil_description_handled
        api_class = Class.new(Grape::API) do
          format :json
          get "simple" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        # Should not raise, summary can be nil
        assert_nil op.summary
      end

      # === Empty options handled ===

      def test_empty_options_handled
        api_class = Class.new(Grape::API) do
          format :json
          get "minimal" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)

        # Should not raise
        op = builder.build

        refute_nil op
        refute_nil op.http_method
      end

      # === Long path with many segments ===

      def test_long_path_with_many_segments
        api_class = Class.new(Grape::API) do
          format :json

          namespace :api do
            namespace :v1 do
              namespace :organizations do
                route_param :org_id do
                  namespace :teams do
                    route_param :team_id do
                      namespace :members do
                        get ":member_id" do
                          {}
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        refute_nil op
        refute_nil op.operation_id
      end

      # === Unicode in description ===

      def test_unicode_in_description
        api_class = Class.new(Grape::API) do
          format :json
          desc "获取用户 - Get user with émojis 🎉"
          get "user" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        assert_equal "获取用户 - Get user with émojis 🎉", op.summary
      end
    end
  end
end
