# frozen_string_literal: true

module GrapeOAS
  module ApiModel
    # Represents a request body in the DTO model for OpenAPI v2/v3.
    # Used to describe the payload of HTTP requests, including content type and schema.
    #
    # @see https://swagger.io/specification/
    # @see GrapeOAS::ApiModel::Operation
    class RequestBody < Node
      attr_accessor :description, :required, :media_types, :extensions, :body_name

      def initialize(description: nil, required: false, media_types: [], extensions: nil, body_name: nil)
        super()
        @description = description
        @required    = required
        @media_types = Array(media_types)
        @extensions  = extensions
        @body_name   = body_name
      end

      def add_media_type(media_type)
        @media_types << media_type
      end
    end
  end
end
