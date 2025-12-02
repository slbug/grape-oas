# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  module ApiModelBuilders
    # Tests for security edge cases including multiple schemes, scopes, and overrides
    class OperationSecurityEdgeCasesTest < Minitest::Test
      def setup
        @api = GrapeOAS::ApiModel::API.new(title: "Test API", version: "1.0")
      end

      # === Multiple security schemes (AND) ===

      def test_multiple_security_schemes_required
        api_class = Class.new(Grape::API) do
          format :json
          desc "Requires both API key AND OAuth2",
               documentation: { security: [{ api_key: [], oauth2: ["read"] }] }
          get "dual_auth" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        assert_equal [{ api_key: [], oauth2: ["read"] }], op.security
      end

      # === Alternative security schemes (OR) ===

      def test_alternative_security_schemes
        api_class = Class.new(Grape::API) do
          format :json
          desc "Can use EITHER API key OR OAuth2",
               documentation: { security: [{ api_key: [] }, { oauth2: ["read"] }] }
          get "either_auth" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        assert_equal [{ api_key: [] }, { oauth2: ["read"] }], op.security
      end

      # === OAuth2 with multiple scopes ===

      def test_oauth2_with_multiple_scopes
        api_class = Class.new(Grape::API) do
          format :json
          desc "OAuth2 with multiple scopes",
               documentation: { security: [{ oauth2: %w[read write admin] }] }
          get "multi_scope" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        assert_equal [{ oauth2: %w[read write admin] }], op.security
      end

      # === Empty security (public endpoint override) ===

      def test_empty_security_disables_auth
        api_class = Class.new(Grape::API) do
          format :json
          desc "Public endpoint", documentation: { security: [] }
          get "public" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        assert_equal [], op.security
      end

      # === Security with symbol keys ===

      def test_security_with_symbol_keys
        api_class = Class.new(Grape::API) do
          format :json
          desc "Symbol key security",
               documentation: { security: [{ bearer_auth: [] }] }
          get "symbol_auth" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        refute_nil op.security
        assert_equal 1, op.security.length
      end

      # === Security with string keys ===

      def test_security_with_string_keys
        api_class = Class.new(Grape::API) do
          format :json
          desc "String key security",
               documentation: { security: [{ "api_key" => [] }] }
          get "string_auth" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        refute_nil op.security
        assert_equal 1, op.security.length
      end

      # === Complex mixed security (3 schemes) ===

      def test_complex_mixed_security
        api_class = Class.new(Grape::API) do
          format :json
          desc "Complex mixed security",
               documentation: {
                 security: [
                   { api_key: [], basic_auth: [] },    # Requires both
                   { oauth2: %w[read write] },          # OR OAuth2 with scopes
                   { bearer_token: [] }                 # OR bearer token
                 ]
               }
          get "complex_auth" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        assert_equal 3, op.security.length
      end

      # === Security scope with special characters ===

      def test_security_scope_with_special_chars
        api_class = Class.new(Grape::API) do
          format :json
          desc "Special scope characters",
               documentation: {
                 security: [{ oauth2: ["user:read", "user:write", "admin/*"] }]
               }
          get "special_scopes" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        assert_equal [{ oauth2: ["user:read", "user:write", "admin/*"] }], op.security
      end

      # === OpenID Connect security ===

      def test_openid_connect_security
        api_class = Class.new(Grape::API) do
          format :json
          desc "OIDC security",
               documentation: { security: [{ openIdConnect: ["openid", "profile"] }] }
          get "oidc_auth" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        assert_equal [{ openIdConnect: ["openid", "profile"] }], op.security
      end

      # === Nil security (gets converted to empty array) ===

      def test_nil_security_converted_to_empty
        api_class = Class.new(Grape::API) do
          format :json
          desc "Nil security", documentation: { security: nil }
          get "nil_auth" do
            {}
          end
        end

        route = api_class.routes.first
        builder = Operation.new(api: @api, route: route)
        op = builder.build

        # nil gets converted to empty array (same as explicitly public)
        assert_equal [], op.security
      end
    end
  end
end
