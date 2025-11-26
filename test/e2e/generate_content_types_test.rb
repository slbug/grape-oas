# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  # Verifies we carry through custom content types/formatters to all OAS versions.
  class GenerateContentTypesTest < Minitest::Test
    class API < Grape::API
      # Map custom formats to mime types
      content_type :xml, "application/xml;charset=utf-8"
      formatter :xml, Grape::Formatter::Txt

      content_type :xml_saml_metadata, "application/samlmetadata+xml"
      formatter :xml_saml_metadata, Grape::Formatter::Txt

      default_format :xml

      desc "SAML metadata"
      get "/meta" do
        "metadata"
      end
    end

    def test_oas2_uses_route_content_types
      schema = GrapeOAS.generate(app: API, schema_type: :oas2)
      op = schema.dig("paths", "/meta", "get")

      expected = ["application/xml;charset=utf-8", "application/samlmetadata+xml"]

      assert_equal expected.sort, Array(op["produces"]).sort
      assert_equal expected.sort, Array(op["consumes"]).sort
    end

    def test_oas3_uses_route_content_types
      schema = GrapeOAS.generate(app: API, schema_type: :oas3)
      content = schema.dig("paths", "/meta", "get", "responses", "200", "content")

      expected = ["application/xml;charset=utf-8", "application/samlmetadata+xml"]

      assert_equal expected.sort, content.keys.sort
    end

    def test_oas31_uses_route_content_types
      schema = GrapeOAS.generate(app: API, schema_type: :oas31)
      content = schema.dig("paths", "/meta", "get", "responses", "200", "content")

      expected = ["application/xml;charset=utf-8", "application/samlmetadata+xml"]

      assert_equal expected.sort, content.keys.sort
    end
  end
end
