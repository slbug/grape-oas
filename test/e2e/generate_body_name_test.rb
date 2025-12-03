# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  class GenerateBodyNameTest < Minitest::Test
    class SampleAPI < Grape::API
      format :json

      desc "Create item with default body name"
      params do
        requires :item, type: Hash do
          requires :name, type: String
        end
      end
      post "items" do
        {}
      end

      desc "Create order with custom body name", body_name: "order_payload"
      params do
        requires :order, type: Hash do
          requires :product_id, type: Integer
          requires :quantity, type: Integer
        end
      end
      post "orders" do
        {}
      end

      # body_name implies params should go to body (no need for param_type: "body")
      desc "Create user with body_name", body_name: "user_data"
      params do
        requires :name, type: String
        requires :email, type: String
      end
      post "users" do
        {}
      end
    end

    def test_oas2_default_body_name_from_operation
      schema = GrapeOAS.generate(app: SampleAPI, schema_type: :oas2)

      post_items = schema.dig("paths", "/items", "post")
      body_param = post_items["parameters"].find { |p| p["in"] == "body" }

      assert body_param, "Should have body parameter"
      # Without explicit body_name, grape-oas derives name from operation_id
      assert_equal "post_items_Request", body_param["name"], "Default body name should be derived from operation_id"
    end

    def test_oas2_custom_body_name
      schema = GrapeOAS.generate(app: SampleAPI, schema_type: :oas2)

      post_orders = schema.dig("paths", "/orders", "post")
      body_param = post_orders["parameters"].find { |p| p["in"] == "body" }

      assert body_param, "Should have body parameter"
      assert_equal "order_payload", body_param["name"], "Should use custom body_name from desc"
    end

    def test_oas3_ignores_body_name
      # OAS3 doesn't have named body parameters - it uses requestBody
      schema = GrapeOAS.generate(app: SampleAPI, schema_type: :oas3)

      post_orders = schema.dig("paths", "/orders", "post")

      # OAS3 uses requestBody, not parameters with in=body
      assert post_orders["requestBody"], "Should have requestBody"
      refute post_orders["requestBody"].key?("name"), "OAS3 requestBody should not have name field"
    end

    def test_oas2_body_name_implies_body_params
      schema = GrapeOAS.generate(app: SampleAPI, schema_type: :oas2)

      post_users = schema.dig("paths", "/users", "post")
      body_param = post_users["parameters"].find { |p| p["in"] == "body" }

      assert body_param, "body_name should implicitly make params body params"
      assert_equal "user_data", body_param["name"], "Should use custom body_name"

      # Verify there are no query params (all went to body)
      query_params = post_users["parameters"].select { |p| p["in"] == "query" }

      assert_empty query_params, "All params should be in body when body_name is set"
    end
  end
end
