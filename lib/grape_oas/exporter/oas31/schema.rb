# frozen_string_literal: true

module GrapeOAS
  module Exporter
    module OAS31
      # OAS3.1-specific Schema exporter
      # Differs from OAS3 by preferring `examples` over deprecated `example`.
      class Schema < OAS3::Schema
        def openapi_version
          "3.1.0"
        end

        private

        def build
          hash = super

          # swap example -> examples if present
          if hash.key?("example")
            ex = hash.delete("example")
            hash["examples"] ||= ex
          end
          hash
        end
      end
    end
  end
end
