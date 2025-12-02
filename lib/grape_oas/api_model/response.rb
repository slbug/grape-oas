# frozen_string_literal: true

module GrapeOAS
  module ApiModel
    # Represents an HTTP response in the DTO model for OpenAPI v2/v3.
    # Used to describe possible responses for an operation, including status, content, and headers.
    #
    # @see https://swagger.io/specification/
    # @see GrapeOAS::ApiModel::Operation
    class Response < Node
      attr_accessor :http_status, :description, :media_types, :headers, :extensions, :examples

      def initialize(http_status:, description:, media_types: [], headers: [], extensions: nil, examples: nil)
        super()
        @http_status = http_status.to_s
        @description = description
        @media_types = Array(media_types)
        @headers     = Array(headers)
        @extensions  = extensions
        @examples    = examples
      end

      def add_media_type(media_type)
        @media_types << media_type
      end
    end
  end
end
