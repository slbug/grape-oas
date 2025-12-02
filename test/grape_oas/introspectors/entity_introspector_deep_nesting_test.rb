# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  module Introspectors
    # Tests for deeply nested and recursive entity structures
    class EntityIntrospectorDeepNestingTest < Minitest::Test
      # === 4-level deep nesting ===

      class Level4Entity < Grape::Entity
        expose :value, documentation: { type: String }
      end

      class Level3Entity < Grape::Entity
        expose :name, documentation: { type: String }
        expose :level4, using: Level4Entity, documentation: { type: Level4Entity }
      end

      class Level2Entity < Grape::Entity
        expose :name, documentation: { type: String }
        expose :level3, using: Level3Entity, documentation: { type: Level3Entity }
      end

      class Level1Entity < Grape::Entity
        expose :name, documentation: { type: String }
        expose :level2, using: Level2Entity, documentation: { type: Level2Entity }
      end

      def test_four_level_deep_entity_nesting
        schema = EntityIntrospector.new(Level1Entity).build_schema

        assert_equal "object", schema.type
        assert_includes schema.properties.keys, "level2"

        level2 = schema.properties["level2"]

        assert_equal "object", level2.type
        assert_includes level2.properties.keys, "level3"

        level3 = level2.properties["level3"]

        assert_equal "object", level3.type
        assert_includes level3.properties.keys, "level4"

        level4 = level3.properties["level4"]

        assert_equal "object", level4.type
        assert_includes level4.properties.keys, "value"
      end

      # === Same property name at each level ===

      class PartsLevel3 < Grape::Entity
        expose :parts, documentation: { type: String }
      end

      class PartsLevel2 < Grape::Entity
        expose :parts, using: PartsLevel3, documentation: { type: PartsLevel3 }
      end

      class PartsLevel1 < Grape::Entity
        expose :parts, using: PartsLevel2, documentation: { type: PartsLevel2 }
      end

      def test_same_property_name_at_each_level
        schema = EntityIntrospector.new(PartsLevel1).build_schema

        assert_equal "object", schema.type
        assert_includes schema.properties.keys, "parts"

        level1_parts = schema.properties["parts"]

        assert_equal "object", level1_parts.type
        assert_includes level1_parts.properties.keys, "parts"

        level2_parts = level1_parts.properties["parts"]

        assert_equal "object", level2_parts.type
        assert_includes level2_parts.properties.keys, "parts"
      end

      # === Direct self-reference (recursive) ===

      class RecursiveEntity < Grape::Entity
        expose :name, documentation: { type: String }
        expose :children, using: "GrapeOAS::Introspectors::EntityIntrospectorDeepNestingTest::RecursiveEntity",
                          documentation: { type: String, is_array: true }
      end

      def test_recursive_self_reference_handles_cycle
        # Should not infinite loop
        schema = EntityIntrospector.new(RecursiveEntity).build_schema

        assert_equal "object", schema.type
        assert_includes schema.properties.keys, "name"
        assert_includes schema.properties.keys, "children"
      end

      # === Mutual recursion (A -> B -> A) ===

      class MutualA < Grape::Entity
        expose :name, documentation: { type: String }
        expose :b_ref, using: "GrapeOAS::Introspectors::EntityIntrospectorDeepNestingTest::MutualB",
                       documentation: { type: String }
      end

      class MutualB < Grape::Entity
        expose :value, documentation: { type: Integer }
        expose :a_ref, using: "GrapeOAS::Introspectors::EntityIntrospectorDeepNestingTest::MutualA",
                       documentation: { type: String }
      end

      def test_mutual_recursion_handles_cycle
        # Should not infinite loop
        schema_a = EntityIntrospector.new(MutualA).build_schema

        assert_equal "object", schema_a.type
        assert_includes schema_a.properties.keys, "name"
        assert_includes schema_a.properties.keys, "b_ref"

        schema_b = EntityIntrospector.new(MutualB).build_schema

        assert_equal "object", schema_b.type
        assert_includes schema_b.properties.keys, "value"
        assert_includes schema_b.properties.keys, "a_ref"
      end

      # === Array of nested entities at each level ===

      class NestedArrayLevel2 < Grape::Entity
        expose :items, documentation: { type: String, is_array: true }
      end

      class NestedArrayLevel1 < Grape::Entity
        expose :collections, using: NestedArrayLevel2, documentation: { type: NestedArrayLevel2, is_array: true }
      end

      def test_arrays_at_multiple_levels
        schema = EntityIntrospector.new(NestedArrayLevel1).build_schema

        assert_equal "object", schema.type

        collections = schema.properties["collections"]

        assert_equal "array", collections.type
        assert_equal "object", collections.items.type
      end

      # === Mixed nesting (hash, array, entity) ===

      class MixedNestedEntity < Grape::Entity
        expose :config, documentation: { type: Hash }
        expose :tags, documentation: { type: Array }
        expose :metadata, documentation: { type: "object" }
      end

      def test_mixed_type_nesting
        schema = EntityIntrospector.new(MixedNestedEntity).build_schema

        assert_equal "object", schema.type
        assert_includes schema.properties.keys, "config"
        assert_includes schema.properties.keys, "tags"
        assert_includes schema.properties.keys, "metadata"

        assert_equal "object", schema.properties["config"].type
        assert_equal "array", schema.properties["tags"].type
        assert_equal "object", schema.properties["metadata"].type
      end

      # === Empty nested entity ===

      class EmptyNestedEntity < Grape::Entity
        # No exposures
      end

      class ParentOfEmptyEntity < Grape::Entity
        expose :name, documentation: { type: String }
        expose :empty, using: EmptyNestedEntity, documentation: { type: EmptyNestedEntity }
      end

      def test_nested_empty_entity
        schema = EntityIntrospector.new(ParentOfEmptyEntity).build_schema

        assert_equal "object", schema.type
        assert_includes schema.properties.keys, "name"
        assert_includes schema.properties.keys, "empty"

        empty = schema.properties["empty"]

        assert_equal "object", empty.type
        assert_empty empty.properties
      end
    end
  end
end
