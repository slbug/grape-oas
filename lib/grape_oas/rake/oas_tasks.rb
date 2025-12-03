# frozen_string_literal: true

require "rake"
require "rake/tasklib"
require "json"

module GrapeOAS
  module Rake
    # Rake tasks for generating and validating OpenAPI documentation.
    #
    # @example Usage in Rakefile
    #   require 'grape_oas/rake/oas_tasks'
    #   GrapeOAS::Rake::OasTasks.new(MyAPI)
    #
    # @example With options
    #   GrapeOAS::Rake::OasTasks.new(MyAPI, schema_type: :oas31, title: "My API")
    #
    class OasTasks < ::Rake::TaskLib
      attr_reader :api_class, :options

      # @param api_class [Class, String] The Grape API class or its name as a string
      # @param options [Hash] Options passed to GrapeOAS.generate
      def initialize(api_class, **options)
        super()

        if api_class.is_a?(String)
          @api_class_name = api_class
        else
          @api_class = api_class
        end

        @options = options
        define_tasks
      end

      private

      def resolved_api_class
        @resolved_api_class ||= @api_class || @api_class_name.constantize
      end

      # Returns :environment if the task exists, otherwise an empty array
      # This allows the tasks to work both in Rails (with :environment) and standalone
      def environment_task
        ::Rake::Task.task_defined?(:environment) ? :environment : []
      end

      def define_tasks
        namespace :oas do
          define_generate_task
          define_validate_task
        end
      end

      def define_generate_task
        desc <<~DESC
          Generate OpenAPI documentation
          Params (usage: KEY=value):
            output   - Output file path (default: stdout)
            format   - Output format: json or yaml (default: json)
            version  - OpenAPI version: oas2, oas3, oas31 (default: from options or oas3)
        DESC
        task generate: environment_task do
          schema = generate_schema
          output = format_output(schema)

          if output_file
            File.write(output_file, output)
            $stdout.puts "OpenAPI spec written to #{output_file}"
          else
            $stdout.puts output
          end
        end
      end

      def define_validate_task
        desc <<~DESC
          Validate OpenAPI documentation using swagger-cli
          Params (usage: KEY=value):
            version  - OpenAPI version: oas2, oas3, oas31 (default: from options or oas3)
        DESC
        task validate: environment_task do
          require "tempfile"

          schema = generate_schema
          output = JSON.pretty_generate(schema)

          Tempfile.create(["openapi", ".json"]) do |f|
            f.write(output)
            f.flush

            if system("which swagger-cli > /dev/null 2>&1")
              success = system("swagger-cli validate #{f.path}")
              exit(1) unless success
            else
              warn "swagger-cli not found. Install with: npm install -g @apidevtools/swagger-cli"
              exit(1)
            end
          end
        end
      end

      def generate_schema
        schema_type = ENV.fetch("version", nil)&.to_sym || options[:schema_type] || :oas3
        GrapeOAS.generate(app: resolved_api_class, schema_type: schema_type, **options)
      end

      def format_output(schema)
        case output_format
        when "yaml"
          require "yaml"
          schema.to_yaml
        else
          JSON.pretty_generate(schema)
        end
      end

      def output_file
        ENV.fetch("output", nil)
      end

      def output_format
        ENV.fetch("format", "json")
      end
    end
  end
end
