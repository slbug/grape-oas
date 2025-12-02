# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  module ApiModelBuilders
    # Tests for response headers handling
    class ResponseHeadersTest < Minitest::Test
      def setup
        @api = GrapeOAS::ApiModel::API.new(title: "Test API", version: "1.0")
      end

      # === Single header on success response ===

      def test_single_header_on_success
        api_class = Class.new(Grape::API) do
          format :json
          desc "Get items",
               documentation: {
                 headers: { "X-Rate-Limit" => { description: "Rate limit remaining" } }
               }
          get "items" do
            []
          end
        end

        route = api_class.routes.first
        builder = Response.new(api: @api, route: route)
        responses = builder.build

        success_response = responses.find { |r| r.http_status == "200" }

        refute_nil success_response
        refute_empty success_response.headers
        assert_equal "X-Rate-Limit", success_response.headers.first[:name]
      end

      # === Multiple headers ===

      def test_multiple_headers
        api_class = Class.new(Grape::API) do
          format :json
          desc "Get paginated items",
               documentation: {
                 headers: {
                   "X-Total-Count" => { description: "Total number of items" },
                   "X-Page" => { description: "Current page number" },
                   "X-Per-Page" => { description: "Items per page" }
                 }
               }
          get "paginated" do
            []
          end
        end

        route = api_class.routes.first
        builder = Response.new(api: @api, route: route)
        responses = builder.build

        success_response = responses.find { |r| r.http_status == "200" }

        refute_nil success_response
        assert_equal 3, success_response.headers.length
      end

      # === Header with type ===

      def test_header_with_type
        api_class = Class.new(Grape::API) do
          format :json
          desc "Get item",
               documentation: {
                 headers: {
                   "X-Request-Id" => { description: "Request ID", type: "string" }
                 }
               }
          get "item" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Response.new(api: @api, route: route)
        responses = builder.build

        success_response = responses.find { |r| r.http_status == "200" }

        refute_nil success_response
        refute_empty success_response.headers

        header = success_response.headers.first

        assert_equal "X-Request-Id", header[:name]
        assert_equal "string", header[:schema]["type"]
      end

      # === Integer header type ===

      def test_header_with_integer_type
        api_class = Class.new(Grape::API) do
          format :json
          desc "Get count",
               documentation: {
                 headers: {
                   "X-Total" => { description: "Total count", type: "integer" }
                 }
               }
          get "count" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Response.new(api: @api, route: route)
        responses = builder.build

        success_response = responses.find { |r| r.http_status == "200" }
        header = success_response.headers.first

        assert_equal "integer", header[:schema]["type"]
      end

      # === Headers on http_codes response ===

      def test_headers_on_http_codes_response
        api_class = Class.new(Grape::API) do
          format :json
          desc "Create item",
               http_codes: [
                 {
                   code: 201,
                   message: "Created",
                   headers: {
                     "Location" => { description: "URL of created resource" }
                   }
                 }
               ]
          post "items" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Response.new(api: @api, route: route)
        responses = builder.build

        created_response = responses.find { |r| r.http_status == "201" }

        refute_nil created_response, "Should have 201 response"
        refute_empty created_response.headers

        header = created_response.headers.first

        assert_equal "Location", header[:name]
      end

      # === Empty headers hash ===

      def test_empty_headers_hash
        api_class = Class.new(Grape::API) do
          format :json
          desc "No headers", documentation: { headers: {} }
          get "no_headers" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Response.new(api: @api, route: route)
        responses = builder.build

        success_response = responses.find { |r| r.http_status == "200" }

        refute_nil success_response
        assert_empty success_response.headers
      end

      # === Standard HTTP headers ===

      def test_standard_http_headers
        api_class = Class.new(Grape::API) do
          format :json
          desc "Standard headers",
               documentation: {
                 headers: {
                   "Cache-Control" => { description: "Cache directive" },
                   "ETag" => { description: "Resource version" },
                   "Last-Modified" => { description: "Last modification timestamp" }
                 }
               }
          get "cached" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Response.new(api: @api, route: route)
        responses = builder.build

        success_response = responses.find { |r| r.http_status == "200" }

        refute_nil success_response
        assert_equal 3, success_response.headers.length

        header_names = success_response.headers.map { |h| h[:name] }

        assert_includes header_names, "Cache-Control"
        assert_includes header_names, "ETag"
        assert_includes header_names, "Last-Modified"
      end

      # === Header description fallback to desc ===

      def test_header_description_fallback_to_desc
        api_class = Class.new(Grape::API) do
          format :json
          desc "With desc key",
               documentation: {
                 headers: {
                   "X-Fallback" => { desc: "Fallback description" }
                 }
               }
          get "fallback" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Response.new(api: @api, route: route)
        responses = builder.build

        success_response = responses.find { |r| r.http_status == "200" }
        header = success_response.headers.first

        assert_equal "Fallback description", header[:schema]["description"]
      end

      # === Header with string key for type ===

      def test_header_with_string_keys
        api_class = Class.new(Grape::API) do
          format :json
          desc "String keys",
               documentation: {
                 headers: {
                   "X-String-Keys" => { "type" => "integer", "description" => "String keys" }
                 }
               }
          get "string_keys" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Response.new(api: @api, route: route)
        responses = builder.build

        success_response = responses.find { |r| r.http_status == "200" }
        header = success_response.headers.first

        assert_equal "integer", header[:schema]["type"]
        assert_equal "String keys", header[:schema]["description"]
      end
    end
  end
end
