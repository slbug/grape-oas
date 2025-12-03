# frozen_string_literal: true

require "test_helper"
require "grape_oas/rake/oas_tasks"
require "rake"

class RakeTasksTestAPI < Grape::API
  format :json

  desc "Get item"
  get "item" do
    {}
  end
end

module GrapeOAS
  module Rake
    class OasTasksTest < Minitest::Test
      def setup
        ::Rake::Task.clear
        @original_env = ENV.to_h
      end

      def teardown
        ENV.replace(@original_env)
      end

      def test_defines_generate_task
        OasTasks.new(RakeTasksTestAPI)

        assert ::Rake::Task.task_defined?("oas:generate")
      end

      def test_defines_validate_task
        OasTasks.new(RakeTasksTestAPI)

        assert ::Rake::Task.task_defined?("oas:validate")
      end

      def test_accepts_string_class_name
        OasTasks.new("RakeTasksTestAPI")

        assert ::Rake::Task.task_defined?("oas:generate")
      end

      def test_accepts_options
        tasks = OasTasks.new(RakeTasksTestAPI, schema_type: :oas31, title: "Test API")

        assert_equal :oas31, tasks.options[:schema_type]
        assert_equal "Test API", tasks.options[:title]
      end

      def test_generate_task_outputs_to_stdout
        OasTasks.new(RakeTasksTestAPI)

        output = capture_io do
          ::Rake::Task["oas:generate"].invoke
        end.first

        parsed = JSON.parse(output)

        assert parsed.key?("openapi") || parsed.key?("swagger")
        assert parsed.key?("paths")
      end

      def test_generate_task_outputs_to_file
        OasTasks.new(RakeTasksTestAPI)

        Dir.mktmpdir do |dir|
          output_path = File.join(dir, "openapi.json")
          ENV["output"] = output_path

          capture_io do
            ::Rake::Task["oas:generate"].invoke
          end

          assert_path_exists output_path
          parsed = JSON.parse(File.read(output_path))

          assert parsed.key?("paths")
        end
      end

      def test_generate_task_respects_version_env
        OasTasks.new(RakeTasksTestAPI)
        ENV["version"] = "oas2"

        output = capture_io do
          ::Rake::Task["oas:generate"].invoke
        end.first

        parsed = JSON.parse(output)

        assert_equal "2.0", parsed["swagger"]
      end

      def test_generate_task_outputs_yaml_format
        OasTasks.new(RakeTasksTestAPI)
        ENV["format"] = "yaml"

        output = capture_io do
          ::Rake::Task["oas:generate"].invoke
        end.first

        assert output.include?("openapi:") || output.include?("swagger:")
      end
    end
  end
end
