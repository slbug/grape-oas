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
  end
end
