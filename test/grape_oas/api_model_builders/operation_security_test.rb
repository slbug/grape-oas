# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  module ApiModelBuilders
    class OperationSecurityTest < Minitest::Test
      def setup
        @api = GrapeOAS::ApiModel::API.new(title: "Test API", version: "1.0")
      end

      def test_uses_security_from_documentation
        api_class = Class.new(Grape::API) do
          format :json
          desc "Secure endpoint", documentation: { security: [{ api_key: [] }] }
          get "secure" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        assert_equal [{ api_key: [] }], op.security
      end

      def test_uses_security_from_auth_option
        api_class = Class.new(Grape::API) do
          format :json
          get "secure", auth: [{ bearer: [] }] do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        assert_equal [{ bearer: [] }], op.security
      end
    end
  end
end
