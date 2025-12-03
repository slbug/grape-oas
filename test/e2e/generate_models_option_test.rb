# frozen_string_literal: true

require "test_helper"

# Define entities at top level to avoid namespaced definition names
class ModelsTestUnusedEntity < Grape::Entity
  expose :id, documentation: { type: Integer }
  expose :name, documentation: { type: String }
end

class ModelsTestUsedEntity < Grape::Entity
  expose :title, documentation: { type: String }
end

class ModelsTestAnotherEntity < Grape::Entity
  expose :code, documentation: { type: String }
  expose :value, documentation: { type: Integer }
end

module GrapeOAS
  class GenerateModelsOptionTest < Minitest::Test
    class SampleAPI < Grape::API
      format :json

      desc "Get item",
           success: { code: 200, model: ModelsTestUsedEntity }
      get "item" do
        {}
      end
    end

    def test_oas2_includes_preregistered_models_in_definitions
      schema = GrapeOAS.generate(
        app: SampleAPI,
        schema_type: :oas2,
        models: [ModelsTestUnusedEntity, ModelsTestAnotherEntity],
      )

      definitions = schema["definitions"]

      # Should include the used entity from endpoint response
      assert definitions.key?("ModelsTestUsedEntity"), "Should include UsedEntity from endpoint"

      # Should include pre-registered entities even though not used in endpoints
      assert definitions.key?("ModelsTestUnusedEntity"), "Should include pre-registered UnusedEntity"
      assert definitions.key?("ModelsTestAnotherEntity"), "Should include pre-registered AnotherEntity"

      # Verify pre-registered entity has correct properties
      unused_def = definitions["ModelsTestUnusedEntity"]

      assert_equal "object", unused_def["type"]
      assert unused_def["properties"].key?("id")
      assert unused_def["properties"].key?("name")
    end

    def test_oas3_includes_preregistered_models_in_schemas
      schema = GrapeOAS.generate(
        app: SampleAPI,
        schema_type: :oas3,
        models: [ModelsTestUnusedEntity],
      )

      schemas = schema.dig("components", "schemas")

      # Should include the used entity from endpoint response
      assert schemas.key?("ModelsTestUsedEntity"), "Should include UsedEntity from endpoint"

      # Should include pre-registered entity
      assert schemas.key?("ModelsTestUnusedEntity"), "Should include pre-registered UnusedEntity"

      # Verify properties
      unused_schema = schemas["ModelsTestUnusedEntity"]

      assert_equal "object", unused_schema["type"]
      assert unused_schema["properties"].key?("id")
      assert unused_schema["properties"].key?("name")
    end

    def test_models_option_accepts_string_class_names
      schema = GrapeOAS.generate(
        app: SampleAPI,
        schema_type: :oas2,
        models: ["ModelsTestUnusedEntity"],
      )

      definitions = schema["definitions"]

      assert definitions.key?("ModelsTestUnusedEntity"), "Should resolve string class name"
    end

    def test_models_option_handles_empty_array
      schema = GrapeOAS.generate(
        app: SampleAPI,
        schema_type: :oas2,
        models: [],
      )

      # Should still work with empty models array - endpoint entity should be included
      assert schema["definitions"].key?("ModelsTestUsedEntity"), "Should include UsedEntity from endpoint"
    end

    def test_models_option_handles_nil
      schema = GrapeOAS.generate(
        app: SampleAPI,
        schema_type: :oas2,
        models: nil,
      )

      # Should still work with nil models - endpoint entity should be included
      assert schema["definitions"].key?("ModelsTestUsedEntity"), "Should include UsedEntity from endpoint"
    end
  end
end
