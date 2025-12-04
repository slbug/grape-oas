# frozen_string_literal: true

module GrapeOAS
  module Exporter
    module Concerns
      # Shared tag-building logic for OAS2 and OAS3 schema exporters.
      # Extracts tag definitions from operations and normalizes tag formats.
      module TagBuilder
        def build_tags
          used_tag_names = collect_used_tag_names
          seen_names = Set.new
          tags = Array(@api.tag_defs).filter_map do |tag|
            normalized = normalize_tag(tag)
            tag_name = normalized["name"]
            # Only include tags that are actually used by operations and not already seen
            next if seen_names.include?(tag_name) || !used_tag_names.include?(tag_name)

            seen_names << tag_name
            normalized
          end
          tags.empty? ? nil : tags
        end

        def normalize_tag(tag)
          if tag.is_a?(Hash)
            # Convert symbol keys to string keys
            tag.transform_keys(&:to_s)
          elsif tag.respond_to?(:name)
            h = { "name" => tag.name.to_s }
            h["description"] = tag.description if tag.respond_to?(:description)
            h
          else
            name = tag.to_s
            desc = if defined?(ActiveSupport::Inflector)
                     "Operations about #{ActiveSupport::Inflector.pluralize(name)}"
                   else
                     "Operations about #{name}s"
                   end
            { "name" => name, "description" => desc }
          end
        end

        def collect_used_tag_names
          used_tags = Set.new
          @api.paths.each do |path|
            path.operations.each do |op|
              Array(op.tag_names).each { |t| used_tags << t }
            end
          end
          used_tags
        end
      end
    end
  end
end
