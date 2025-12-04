# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  class GenerateNamespaceFilterTest < Minitest::Test
    class SampleAPI < Grape::API
      format :json

      namespace :users do
        desc "List all users"
        get do
          []
        end

        desc "Get a user"
        params do
          requires :id, type: Integer, desc: "User ID"
        end
        get ":id" do
          { id: params[:id] }
        end

        namespace :posts do
          desc "Get user posts"
          get do
            []
          end
        end
      end

      namespace :posts do
        desc "List all posts"
        get do
          []
        end

        desc "Get a post"
        params do
          requires :id, type: Integer, desc: "Post ID"
        end
        get ":id" do
          { id: params[:id] }
        end
      end

      desc "Get root"
      get do
        {}
      end
    end

    def test_namespace_filter_includes_only_matching_paths
      schema = GrapeOAS.generate(app: SampleAPI, schema_type: :oas3, namespace: "users")

      paths = schema["paths"].keys

      assert_includes paths, "/users"
      assert_includes paths, "/users/{id}"
      assert_includes paths, "/users/posts"
      refute_includes paths, "/posts"
      refute_includes paths, "/posts/{id}"
      refute_includes paths, "/"
    end

    def test_namespace_filter_with_leading_slash
      schema = GrapeOAS.generate(app: SampleAPI, schema_type: :oas3, namespace: "/posts")

      paths = schema["paths"].keys

      assert_includes paths, "/posts"
      assert_includes paths, "/posts/{id}"
      refute_includes paths, "/users"
      refute_includes paths, "/users/posts"
    end

    def test_no_namespace_filter_includes_all_paths
      schema = GrapeOAS.generate(app: SampleAPI, schema_type: :oas3)

      paths = schema["paths"].keys

      assert_includes paths, "/"
      assert_includes paths, "/users"
      assert_includes paths, "/users/{id}"
      assert_includes paths, "/users/posts"
      assert_includes paths, "/posts"
      assert_includes paths, "/posts/{id}"
    end

    def test_namespace_filter_works_with_oas2
      schema = GrapeOAS.generate(app: SampleAPI, schema_type: :oas2, namespace: "users")

      paths = schema["paths"].keys

      assert_includes paths, "/users"
      assert_includes paths, "/users/{id}"
      refute_includes paths, "/posts"
    end

    def test_namespace_filter_works_with_oas31
      schema = GrapeOAS.generate(app: SampleAPI, schema_type: :oas31, namespace: "posts")

      paths = schema["paths"].keys

      assert_includes paths, "/posts"
      assert_includes paths, "/posts/{id}"
      refute_includes paths, "/users"
    end

    # === Tag filtering tests ===

    def test_namespace_filter_filters_tags
      schema = GrapeOAS.generate(app: SampleAPI, schema_type: :oas3, namespace: "users")

      tag_names = schema["tags"]&.map { |t| t["name"] }

      assert_includes tag_names, "users"
      refute_includes tag_names, "posts"
    end

    def test_predefined_tags_filtered_by_namespace
      schema = GrapeOAS.generate(
        app: SampleAPI,
        schema_type: :oas3,
        namespace: "users",
        tags: [
          { name: "users", description: "User management" },
          { name: "posts", description: "Post management" },
          { name: "admin", description: "Admin operations" }
        ],
      )

      tags = schema["tags"]
      tag_names = tags&.map { |t| t["name"] }

      # Only "users" tag should be included (used by filtered operations)
      assert_equal ["users"], tag_names

      # Should use the pre-defined description, not auto-generated
      users_tag = tags.find { |t| t["name"] == "users" }

      assert_equal "User management", users_tag["description"]
    end

    def test_predefined_tags_with_symbol_keys
      schema = GrapeOAS.generate(
        app: SampleAPI,
        schema_type: :oas3,
        tags: [
          { name: "users", description: "User management" },
          { name: "posts", description: "Post management" }
        ],
      )

      tags = schema["tags"]
      users_tag = tags.find { |t| t["name"] == "users" }

      # Symbol keys should be converted to string keys
      assert_equal "User management", users_tag["description"]
    end

    def test_unused_predefined_tags_excluded
      schema = GrapeOAS.generate(
        app: SampleAPI,
        schema_type: :oas3,
        tags: [
          { name: "users", description: "User management" },
          { name: "posts", description: "Post management" },
          { name: "admin", description: "Admin operations" } # Not used by any endpoint
        ],
      )

      tag_names = schema["tags"]&.map { |t| t["name"] }

      assert_includes tag_names, "users"
      assert_includes tag_names, "posts"
      refute_includes tag_names, "admin" # Should be excluded since no operations use it
    end

    # === Schema/definitions filtering tests ===

    class UserEntity < Grape::Entity
      expose :id, documentation: { type: Integer }
      expose :name, documentation: { type: String }
    end

    class PostEntity < Grape::Entity
      expose :id, documentation: { type: Integer }
      expose :title, documentation: { type: String }
    end

    class EntityAPI < Grape::API
      format :json

      namespace :users do
        desc "Get user" do
          success UserEntity
        end
        get ":id" do
        end
      end

      namespace :posts do
        desc "Get post" do
          success PostEntity
        end
        get ":id" do
        end
      end
    end

    def test_namespace_filter_filters_schemas
      schema = GrapeOAS.generate(app: EntityAPI, schema_type: :oas3, namespace: "users")

      schema_names = schema.dig("components", "schemas")&.keys || []

      # Schema names include module path
      assert schema_names.any? { |n| n.include?("UserEntity") }
      refute schema_names.any? { |n| n.include?("PostEntity") }
    end

    def test_no_namespace_filter_includes_all_schemas
      schema = GrapeOAS.generate(app: EntityAPI, schema_type: :oas3)

      schema_names = schema.dig("components", "schemas")&.keys || []

      # Schema names include module path
      assert schema_names.any? { |n| n.include?("UserEntity") }
      assert schema_names.any? { |n| n.include?("PostEntity") }
    end
  end
end
