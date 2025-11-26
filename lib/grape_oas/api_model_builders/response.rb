# frozen_string_literal: true

require_relative "response_parsers/documentation_responses_parser"
require_relative "response_parsers/http_codes_parser"
require_relative "response_parsers/default_response_parser"

module GrapeOAS
  module ApiModelBuilders
    class Response
      attr_reader :api, :route

      def initialize(api:, route:)
        @api = api
        @route = route
      end

      def build
        response_specs.map { |spec| build_response_from_spec(spec) }
      end

      private

      # Use Strategy pattern to parse responses
      # Parsers are tried in order of priority
      def response_specs
        parser = parsers.find { |p| p.applicable?(route) }
        parser ? parser.parse(route) : []
      end

      # Response parsers in priority order
      # DocumentationResponsesParser has highest priority (most comprehensive)
      # HttpCodesParser handles legacy grape-swagger formats
      # DefaultResponseParser is the fallback
      def parsers
        @parsers ||= [
          ResponseParsers::DocumentationResponsesParser.new,
          ResponseParsers::HttpCodesParser.new,
          ResponseParsers::DefaultResponseParser.new
        ]
      end

      def build_response_from_spec(spec)
        schema = build_schema(spec[:entity])
        media_type = build_media_type(
          mime_type: "application/json",
          schema: schema,
        )

        GrapeOAS::ApiModel::Response.new(
          http_status: spec[:code].to_s,
          description: spec[:message] || "Success",
          media_types: [media_type],
          headers: normalize_headers(spec[:headers]) || headers_from_route,
          extensions: spec[:extensions] || extensions_from_route,
          examples: spec[:examples],
        )
      end

      def extensions_from_route
        ext = route.options[:documentation]&.select { |k, _| k.to_s.start_with?("x-") }
        ext unless ext.nil? || ext.empty?
      end

      def normalize_headers(hdrs)
        return nil if hdrs.nil?
        return hdrs if hdrs.is_a?(Array)
        return nil unless hdrs.is_a?(Hash)

        hdrs.map { |name, h| build_header_schema(name, h) }
      end

      def headers_from_route
        hdrs = route.options.dig(:documentation, :headers) || route.settings.dig(:documentation, :headers)
        return [] unless hdrs.is_a?(Hash)

        hdrs.map { |name, h| build_header_schema(name, h) }
      end

      # Build a header schema, normalizing field names
      def build_header_schema(name, header_spec)
        {
          name: name,
          schema: {
            "type" => header_spec[:type] || header_spec["type"] || "string",
            "description" => header_spec[:description] || header_spec[:desc]
          }.compact
        }
      end

      def build_schema(entity_class)
        schema_args = if entity_class
                        nullable = fetch_nullable_from_entity(entity_class)
                        { type: "object", canonical_name: entity_class.name, nullable: nullable }
                      else
                        { type: "string" }
                      end

        schema = GrapeOAS::ApiModel::Schema.new(**schema_args)
        if entity_class
          enrich_schema_with_entity_doc(schema, entity_class)
          schema = GrapeOAS::Introspectors::EntityIntrospector.new(entity_class).build_schema
        end
        schema
      end

      def fetch_nullable_from_entity(entity_class)
        doc = entity_class.respond_to?(:documentation) ? entity_class.documentation : {}
        doc[:nullable] || doc["nullable"] || false
      rescue StandardError
        false
      end

      def enrich_schema_with_entity_doc(schema, entity_class)
        return schema unless entity_class.respond_to?(:documentation)

        doc = entity_class.documentation
        schema.additional_properties = doc[:additional_properties] if doc.key?(:additional_properties)
        schema.unevaluated_properties = doc[:unevaluated_properties] if doc.key?(:unevaluated_properties)
        defs = doc[:defs] || doc[:$defs]
        schema.defs = defs if defs.is_a?(Hash)
        schema
      rescue StandardError
        schema
      end

      def build_media_type(mime_type:, schema:)
        GrapeOAS::ApiModel::MediaType.new(
          mime_type: mime_type,
          schema: schema,
        )
      end
    end
  end
end
