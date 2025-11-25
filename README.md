# GrapeOAS

A Ruby gem for generating OpenAPI (Swagger) documentation for Grape APIs.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'grape-oas'
```

And then execute:

    $ bundle install

## Usage

```ruby
class API < Grape::API
  format :json

  # Mount the docs endpoint (JSON only). Switch version with ?oas=2|3|3.1
  add_oas_documentation(
    host: "api.example.com",
    base_path: "/v1",
    schemes: ["https"],
    info: { title: "My API", version: "1.0" },
    security_definitions: {
      api_key: { type: "apiKey", name: "X-API-Key", in: "header" }
    },
    security: [{ api_key: [] }]
  )

  desc "Get a widget",
       documentation: {
         # OpenAPI 3.1 JSON Schema extras
         additional_properties: false,
         unevaluated_properties: false,
         defs: { WidgetRef: { type: "string" } },
         nullable: true
       }
  params do
    optional :id, type: Integer, documentation: { nullable: true }
  end
  get :widget do
    { id: params[:id], name: "Sample" }
  end
end

# Generate manually
GrapeOAS.generate(app: API, schema_type: :oas31)
```

Notes for OpenAPI 3.1 users
- `documentation[:nullable]` on params marks the schema as `type: [..,"null"]`.
- `documentation[:additional_properties]` and `documentation[:unevaluated_properties]` are emitted for 3.1 only.
- `documentation[:defs]` or `[:$defs]` are passed through to `$defs` in 3.1 output.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/numbata/grape-oas.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
