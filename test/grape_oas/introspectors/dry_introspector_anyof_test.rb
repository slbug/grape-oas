# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  module Introspectors
    # Tests for anyOf support (Sum types) in DryIntrospector
    class DryIntrospectorAnyOfTest < Minitest::Test
      # Define test types
      module Types
        include Dry.Types()

        CatType = Types::Hash.schema(
          meow_volume: Types::Integer,
          whiskers: Types::String
        )

        DogType = Types::Hash.schema(
          bark_volume: Types::Integer,
          breed: Types::String
        )

        ElephantType = Types::Hash.schema(
          trunk_length: Types::Integer,
          tusk_size: Types::String
        )

        TwoAnimalType = CatType | DogType
        ThreeAnimalType = CatType | DogType | ElephantType
      end

      # === Two-type Sum ===

      class TwoTypeSumContract < Dry::Validation::Contract
        params do
          required(:animal).filled(Types::TwoAnimalType)
        end
      end

      def test_two_type_sum_generates_any_of
        schema = DryIntrospector.build(TwoTypeSumContract)
        animal_schema = schema.properties["animal"]

        refute_nil animal_schema.any_of, "Should generate anyOf"
        assert_equal 2, animal_schema.any_of.length
      end

      def test_two_type_sum_first_item_has_cat_properties
        schema = DryIntrospector.build(TwoTypeSumContract)
        animal_schema = schema.properties["animal"]

        cat_schema = animal_schema.any_of[0]
        assert_equal "object", cat_schema.type
        assert_includes cat_schema.properties.keys, "meow_volume"
        assert_includes cat_schema.properties.keys, "whiskers"
      end

      def test_two_type_sum_second_item_has_dog_properties
        schema = DryIntrospector.build(TwoTypeSumContract)
        animal_schema = schema.properties["animal"]

        dog_schema = animal_schema.any_of[1]
        assert_equal "object", dog_schema.type
        assert_includes dog_schema.properties.keys, "bark_volume"
        assert_includes dog_schema.properties.keys, "breed"
      end

      # === Three-type Sum ===

      class ThreeTypeSumContract < Dry::Validation::Contract
        params do
          required(:animal).filled(Types::ThreeAnimalType)
        end
      end

      def test_three_type_sum_generates_any_of_with_three_items
        schema = DryIntrospector.build(ThreeTypeSumContract)
        animal_schema = schema.properties["animal"]

        refute_nil animal_schema.any_of
        assert_equal 3, animal_schema.any_of.length
      end

      def test_three_type_sum_has_all_properties
        schema = DryIntrospector.build(ThreeTypeSumContract)
        animal_schema = schema.properties["animal"]

        all_props = animal_schema.any_of.flat_map { |s| s.properties.keys }
        assert_includes all_props, "meow_volume"
        assert_includes all_props, "bark_volume"
        assert_includes all_props, "trunk_length"
      end

      # === Property types ===

      def test_nested_property_types_are_correct
        schema = DryIntrospector.build(TwoTypeSumContract)
        cat_schema = schema.properties["animal"].any_of[0]

        assert_equal "integer", cat_schema.properties["meow_volume"].type
        assert_equal "string", cat_schema.properties["whiskers"].type
      end

      # === Contract with multiple fields ===

      class MixedContract < Dry::Validation::Contract
        params do
          required(:name).filled(:string)
          required(:pet).filled(Types::TwoAnimalType)
          required(:age).filled(:integer)
        end
      end

      def test_sum_type_with_other_fields
        schema = DryIntrospector.build(MixedContract)

        # Regular fields
        assert_equal "string", schema.properties["name"].type
        assert_equal "integer", schema.properties["age"].type

        # Sum type field
        refute_nil schema.properties["pet"].any_of
        assert_equal 2, schema.properties["pet"].any_of.length
      end

      # === TypeUnwrapper tests ===

      def test_sum_type_detection
        assert DryIntrospectorSupport::TypeUnwrapper.sum_type?(Types::TwoAnimalType)
        assert DryIntrospectorSupport::TypeUnwrapper.sum_type?(Types::ThreeAnimalType)
        refute DryIntrospectorSupport::TypeUnwrapper.sum_type?(Types::CatType)
      end

      def test_extract_sum_types_two_types
        types = DryIntrospectorSupport::TypeUnwrapper.extract_sum_types(Types::TwoAnimalType)
        assert_equal 2, types.length
      end

      def test_extract_sum_types_three_types
        types = DryIntrospectorSupport::TypeUnwrapper.extract_sum_types(Types::ThreeAnimalType)
        assert_equal 3, types.length
      end
    end
  end
end
