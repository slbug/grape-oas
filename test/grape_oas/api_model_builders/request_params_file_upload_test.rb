# frozen_string_literal: true

require "test_helper"

module GrapeOAS
  module ApiModelBuilders
    # Tests for file upload parameter handling
    class RequestParamsFileUploadTest < Minitest::Test
      def setup
        @api = GrapeOAS::ApiModel::API.new(title: "Test API", version: "1.0")
      end

      # === File type parameter ===

      def test_file_type_parameter
        api_class = Class.new(Grape::API) do
          format :json
          params do
            requires :document, type: File
          end
          post "upload" do
            {}
          end
        end

        route = api_class.routes.first
        builder = RequestParams.new(api: @api, route: route)
        body_schema, params = builder.build

        # File type should be recognized
        # It may be in body or as formData depending on implementation
        doc_param = params.find { |p| p.name == "document" }
        doc_prop = body_schema.properties["document"]

        # At least one should exist
        assert(doc_param || doc_prop, "File parameter should exist")

        if doc_param
          assert_equal "file", doc_param.schema.type
        elsif doc_prop
          assert_equal "file", doc_prop.type
        end
      end

      # === Rack::Multipart::UploadedFile type ===

      def test_rack_multipart_uploaded_file_type
        skip "Rack::Multipart::UploadedFile may not be loaded" unless defined?(Rack::Multipart::UploadedFile)

        api_class = Class.new(Grape::API) do
          format :json
          params do
            requires :file, type: Rack::Multipart::UploadedFile
          end
          post "upload" do
            {}
          end
        end

        route = api_class.routes.first
        builder = RequestParams.new(api: @api, route: route)
        body_schema, params = builder.build

        file_param = params.find { |p| p.name == "file" }
        file_prop = body_schema.properties["file"]

        assert(file_param || file_prop, "Rack file parameter should exist")
      end

      # === Multiple file uploads ===

      def test_multiple_file_parameters
        api_class = Class.new(Grape::API) do
          format :json
          params do
            requires :avatar, type: File, documentation: { desc: "Profile picture" }
            optional :resume, type: File, documentation: { desc: "Resume document" }
          end
          post "profile" do
            {}
          end
        end

        route = api_class.routes.first
        builder = RequestParams.new(api: @api, route: route)
        body_schema, params = builder.build

        # Should have both file parameters
        param_names = params.map(&:name)
        prop_names = body_schema.properties.keys

        all_names = param_names + prop_names

        assert_includes all_names, "avatar"
        assert_includes all_names, "resume"
      end

      # === File with other parameters ===

      def test_file_with_metadata_parameters
        api_class = Class.new(Grape::API) do
          format :json
          params do
            requires :file, type: File
            requires :name, type: String
            optional :description, type: String
          end
          post "documents" do
            {}
          end
        end

        route = api_class.routes.first
        builder = RequestParams.new(api: @api, route: route)
        body_schema, params = builder.build

        param_names = params.map(&:name)
        prop_names = body_schema.properties.keys
        all_names = param_names + prop_names

        assert_includes all_names, "file"
        assert_includes all_names, "name"
        assert_includes all_names, "description"
      end

      # === Array of files ===

      def test_array_of_files
        api_class = Class.new(Grape::API) do
          format :json
          params do
            requires :files, type: Array[File], documentation: { param_type: "body" }
          end
          post "bulk-upload" do
            {}
          end
        end

        route = api_class.routes.first
        builder = RequestParams.new(api: @api, route: route)
        body_schema, _params = builder.build

        files_prop = body_schema.properties["files"]

        refute_nil files_prop, "Files array property should exist"
        assert_equal "array", files_prop.type
      end
    end
  end
end
