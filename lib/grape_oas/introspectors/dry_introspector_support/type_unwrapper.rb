# frozen_string_literal: true

module GrapeOAS
  module Introspectors
    module DryIntrospectorSupport
      # Unwraps Dry::Types to extract primitives and member types.
      module TypeUnwrapper
        # Maximum depth for unwrapping nested Dry::Types (prevents infinite loops)
        MAX_DEPTH = 5

        module_function

        def derive_primitive_and_member(dry_type)
          core = unwrap(dry_type)

          return [Array, core.type.member] if array_member_type?(core)
          return [Array, core.member] if array_with_member?(core)

          primitive = core.respond_to?(:primitive) ? core.primitive : nil
          [primitive, nil]
        end

        def unwrap(dry_type)
          current = dry_type
          depth = 0

          while current.respond_to?(:type) && depth < MAX_DEPTH
            inner = current.type
            break if inner.equal?(current)

            current = inner
            depth += 1
          end

          current
        end

        # Detect if type is a meaningful Dry::Types::Sum (union type like TypeA | TypeB)
        # Returns false for nullable sums (nil | String) which are created by maybe()
        def sum_type?(dry_type)
          return false unless defined?(Dry::Types::Sum)
          return false unless dry_type.is_a?(Dry::Types::Sum) || dry_type.class.name&.include?("Sum")

          # Check if this is a "schema sum" (both sides are Hash schemas)
          # vs a "nullable sum" (one side is NilClass from maybe())
          schema_sum?(dry_type)
        end

        # Check if Sum type represents a union of schemas (not just nullable)
        def schema_sum?(sum_type)
          return false unless sum_type.respond_to?(:left) && sum_type.respond_to?(:right)

          types = extract_sum_types(sum_type)

          # Filter out NilClass types (from maybe())
          non_nil_types = types.reject { |t| nil_type?(t) }

          # It's a schema sum if we have 2+ non-nil types and at least one is a Hash schema
          non_nil_types.length >= 2 && non_nil_types.any? { |t| hash_schema?(t) }
        end

        # Check if type is a nil type (from maybe())
        def nil_type?(dry_type)
          return true if dry_type.respond_to?(:primitive) && dry_type.primitive == NilClass

          # Check wrapped type
          unwrapped = unwrap(dry_type)
          unwrapped.respond_to?(:primitive) && unwrapped.primitive == NilClass
        end

        # Check if type is a Hash schema (has keys)
        def hash_schema?(dry_type)
          return true if dry_type.respond_to?(:keys) && dry_type.keys.any?

          unwrapped = unwrap(dry_type)
          unwrapped.respond_to?(:keys) && unwrapped.keys.any?
        end

        # Recursively extract all types from a Sum type tree
        # A | B | C becomes Sum(Sum(A, B), C), so we need to traverse the tree
        def extract_sum_types(dry_type, types = [])
          if dry_type.respond_to?(:left) && dry_type.respond_to?(:right)
            extract_sum_types(dry_type.left, types)
            extract_sum_types(dry_type.right, types)
          else
            types << dry_type
          end
          types
        end

        def array_member_type?(core)
          defined?(Dry::Types::Array::Member) &&
            core.respond_to?(:type) &&
            core.type.is_a?(Dry::Types::Array::Member)
        end
        private_class_method :array_member_type?

        def array_with_member?(core)
          core.respond_to?(:member) &&
            core.respond_to?(:primitive) &&
            core.primitive == Array
        end
        private_class_method :array_with_member?
      end
    end
  end
end
