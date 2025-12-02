# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  module Introspectors
    # Tests for polymorphism support (allOf, inheritance) in DryIntrospector
    class DryIntrospectorPolymorphismTest < Minitest::Test
      # === Basic inheritance ===

      class PetContract < Dry::Validation::Contract
        params do
          required(:pet_type).filled(:string)
          required(:name).filled(:string)
        end
      end

      class CatContract < PetContract
        params do
          required(:hunting_skill).filled(:string)
        end
      end

      class DogContract < PetContract
        params do
          required(:breed).filled(:string)
          required(:pack_size).filled(:integer)
        end
      end

      def test_parent_contract_builds_flat_schema
        schema = DryIntrospector.build(PetContract)

        assert_equal "object", schema.type
        assert_nil schema.all_of
        assert_includes schema.properties.keys, "pet_type"
        assert_includes schema.properties.keys, "name"
      end

      def test_child_contract_uses_all_of
        schema = DryIntrospector.build(CatContract)

        refute_nil schema.all_of, "Child contract should use allOf"
        assert_equal 2, schema.all_of.length
      end

      def test_child_all_of_first_item_is_parent
        schema = DryIntrospector.build(CatContract)

        parent_schema = schema.all_of[0]
        assert_equal PetContract.name, parent_schema.canonical_name
        assert_includes parent_schema.properties.keys, "pet_type"
        assert_includes parent_schema.properties.keys, "name"
      end

      def test_child_all_of_second_item_has_child_only_properties
        schema = DryIntrospector.build(CatContract)

        child_schema = schema.all_of[1]
        assert_includes child_schema.properties.keys, "hunting_skill"
        refute_includes child_schema.properties.keys, "pet_type"
        refute_includes child_schema.properties.keys, "name"
      end

      def test_another_child_contract_uses_all_of
        schema = DryIntrospector.build(DogContract)

        refute_nil schema.all_of
        assert_equal 2, schema.all_of.length

        child_schema = schema.all_of[1]
        assert_includes child_schema.properties.keys, "breed"
        assert_includes child_schema.properties.keys, "pack_size"
        refute_includes child_schema.properties.keys, "pet_type"
        refute_includes child_schema.properties.keys, "name"
      end

      # === Multi-level inheritance ===

      class AnimalContract < Dry::Validation::Contract
        params do
          required(:species).filled(:string)
          required(:age).filled(:integer)
        end
      end

      class MammalContract < AnimalContract
        params do
          required(:fur_color).filled(:string)
        end
      end

      def test_multi_level_inheritance
        schema = DryIntrospector.build(MammalContract)

        refute_nil schema.all_of
        # Should reference Animal (immediate parent)
        parent_schema = schema.all_of[0]
        assert_equal AnimalContract.name, parent_schema.canonical_name
      end

      # === No inheritance (regular contract) ===

      class StandaloneContract < Dry::Validation::Contract
        params do
          required(:id).filled(:integer)
          required(:email).filled(:string)
        end
      end

      def test_standalone_contract_builds_flat_schema
        schema = DryIntrospector.build(StandaloneContract)

        assert_nil schema.all_of
        assert_equal "object", schema.type
        assert_includes schema.properties.keys, "id"
        assert_includes schema.properties.keys, "email"
      end

      # === Required fields propagation ===

      class RequiredParentContract < Dry::Validation::Contract
        params do
          required(:required_field).filled(:string)
          optional(:optional_field).maybe(:string)
        end
      end

      class RequiredChildContract < RequiredParentContract
        params do
          required(:child_required).filled(:string)
          optional(:child_optional).maybe(:string)
        end
      end

      def test_required_fields_in_parent
        schema = DryIntrospector.build(RequiredChildContract)

        parent_schema = schema.all_of[0]
        assert_includes parent_schema.required, "required_field"
        refute_includes parent_schema.required, "optional_field"
      end

      def test_required_fields_in_child_only_schema
        schema = DryIntrospector.build(RequiredChildContract)

        child_schema = schema.all_of[1]
        assert_includes child_schema.required, "child_required"
        refute_includes child_schema.required, "child_optional"
      end

      # === Canonical name ===

      def test_child_schema_has_canonical_name
        schema = DryIntrospector.build(CatContract)

        assert_equal CatContract.name, schema.canonical_name
      end

      def test_parent_schema_has_canonical_name
        schema = DryIntrospector.build(CatContract)

        parent_schema = schema.all_of[0]
        assert_equal PetContract.name, parent_schema.canonical_name
      end
    end
  end
end
