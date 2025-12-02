# frozen_string_literal: true

module GrapeOAS
  module ApiModel
    # Represents a media type (e.g., application/json) in the DTO model for OpenAPI v2/v3.
    # Used for request bodies and responses to specify content type and schema.
    #
    # @see https://swagger.io/specification/
    # @see GrapeOAS::ApiModel::RequestBody, GrapeOAS::ApiModel::Response
    class MediaType < Node
      attr_accessor :mime_type, :schema, :examples, :extensions

      def initialize(mime_type:, schema:, examples: nil, extensions: nil)
        super()
        @mime_type = mime_type
        @schema    = schema
        @examples  = examples
        @extensions = extensions
      end
    end
  end
end
