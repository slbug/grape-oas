# frozen_string_literal: true

module GrapeOAS
  module Exporter
    module OAS3
      class Paths
        def initialize(source, ref_tracker = nil, nullable_keyword: true)
          @source = source
          @ref_tracker = ref_tracker
          @nullable_keyword = nullable_keyword
        end

        def build
          if api?(@source)
            build_paths(@source)
          else
            build_path_item(@source)
          end
        end

        private

        def api?(obj)
          obj.respond_to?(:paths)
        end

        def build_paths(api)
          paths = {}
          api.paths.each do |path|
            paths[path.template] = build_path_item(path)
          end
          paths
        end

        def build_path_item(path)
          item = {}
          path.operations.each do |op|
            item[op.http_method] = Operation.new(op, @ref_tracker, nullable_keyword: @nullable_keyword).build
          end
          item
        end
      end
    end
  end
end
