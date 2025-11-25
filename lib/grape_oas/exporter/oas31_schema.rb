# frozen_string_literal: true

module GrapeOAS
  module Exporter
    class OAS31Schema < OAS3Schema
      def generate
        super.merge("$schema" => "https://spec.openapis.org/oas/3.1/draft/2021-05")
      end

      private

      def openapi_version
        "3.1.0"
      end

      def nullable_keyword?
        false
      end
    end
  end
end
