# frozen_string_literal: true

module GrapeOAS
  module Exporter
    module OAS3
      class Response
        def initialize(responses, ref_tracker = nil, nullable_keyword: true)
          @responses = responses
          @ref_tracker = ref_tracker
          @nullable_keyword = nullable_keyword
        end

        def build
          @responses.each_with_object({}) do |resp, h|
            h[resp.http_status] = {
              "description" => resp.description || "Response",
              "headers" => build_headers(resp.headers),
              "content" => build_content(resp.media_types)
            }.compact
            h[resp.http_status].merge!(resp.extensions) if resp.extensions
            h[resp.http_status]["examples"] = resp.examples if resp.examples
          end
        end

        private

        def build_headers(headers)
          return nil unless headers && !headers.empty?
          headers.each_with_object({}) do |hdr, h|
            name = hdr[:name] || hdr["name"] || hdr[:key] || hdr["key"]
            next unless name
            h[name] = (hdr[:schema] || hdr["schema"] || { "schema" => { "type" => "string" } })
          end
        end

        def build_content(media_types)
          return nil unless media_types

          media_types.each_with_object({}) do |mt, h|
            h[mt.mime_type] = {
              "schema" => Schema.new(mt.schema, @ref_tracker, nullable_keyword: @nullable_keyword).build,
              "examples" => mt.examples
            }.compact
          end
        end
      end
    end
  end
end
