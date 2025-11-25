# frozen_string_literal: true

module GrapeOAS
  module Exporter
    class OAS30Schema < OAS3Schema
      private

      def openapi_version
        "3.0.0"
      end
    end
  end
end
