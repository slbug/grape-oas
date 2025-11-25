# frozen_string_literal: true

# A more comprehensive Grape API for testing OAS generation features
module ComplexApi
  class UserEntity < Grape::Entity
    expose :id, documentation: { type: "Integer", desc: "User ID" }
    expose :name, documentation: { type: "String", desc: "User name" }
    expose :email, documentation: { type: "String", desc: "User email" }
  end

  class App < Grape::API
    format :json

    namespace :users do
      desc "Get a user by ID",
           nickname: "getUserById",
           tags: ["users"],
           entity: UserEntity
      params do
        requires :id, type: Integer, desc: "User ID", documentation: { x: { custom: "value" } }
        optional :include, type: String, documentation: { param_type: "query", desc: "Include related resources" }
      end
      get ":id" do
        { id: params[:id], name: "John Doe" }
      end

      desc "List all users",
           tags: ["users"]
      params do
        optional :page, type: Integer, default: 1, desc: "Page number"
        optional :per_page, type: Integer, default: 20, desc: "Items per page"
      end
      get do
        { users: [] }
      end

      desc "Create a new user",
           tags: ["users"],
           entity: UserEntity
      params do
        requires :name, type: String, desc: "User name", documentation: { param_type: "body" }
        requires :email, type: String, desc: "User email", documentation: { param_type: "body" }
        optional :role, type: String, values: %w[admin user guest], documentation: { param_type: "body" }
      end
      post do
        { id: 1, name: params[:name], email: params[:email] }
      end

      desc "Update a user",
           tags: ["users"],
           entity: UserEntity
      params do
        requires :id, type: Integer, desc: "User ID"
        optional :name, type: String, desc: "User name", documentation: { param_type: "body" }
        optional :email, type: String, desc: "User email", documentation: { param_type: "body" }
      end
      put ":id" do
        { id: params[:id], name: params[:name] }
      end

      desc "Delete a user",
           tags: ["users"]
      params do
        requires :id, type: Integer, desc: "User ID"
      end
      delete ":id" do
        status 204
        nil
      end
    end

    namespace :posts do
      desc "Get all posts",
           tags: ["posts"]
      params do
        optional :user_id, type: Integer, desc: "Filter by user ID"
        optional :status, type: Symbol, values: %i[draft published archived], desc: "Post status"
      end
      get do
        { posts: [] }
      end

      desc "Get a post by ID",
           tags: ["posts"]
      params do
        requires :id, type: Integer, desc: "Post ID"
      end
      get ":id" do
        { id: params[:id], title: "Sample Post" }
      end

      desc "Search posts using contract validation",
           tags: ["posts"]
      contract do
        required(:filter).array(:hash) do
          required(:field).filled(:string)
          required(:value).filled(:string)
        end
        optional(:sort).filled(:string)
      end
      post "search" do
        { posts: [], filters: params[:filter] }
      end
    end

    # Hidden route - should not appear in OAS
    desc "Health check"
    get "health", swagger: { hidden: true } do
      { status: "ok" }
    end
  end
end
