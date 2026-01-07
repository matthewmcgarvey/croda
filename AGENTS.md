# AGENTS.md

Guidelines for AI agents working in the Croda codebase.

Croda is a Crystal web framework inspired by Ruby's Roda. It uses a plugin-based
architecture with a routing tree DSL for handling HTTP requests.

## Build and Development Commands

```bash
# Dependencies
shards install                          # Install dependencies
shards update                           # Update dependencies

# Building
crystal build src/croda.cr              # Build the library
crystal build --no-codegen src/croda.cr # Type-check only (no binary)

# Testing
crystal spec                            # Run all tests
crystal spec spec/croda_spec.cr         # Run single test file
crystal spec spec/croda_spec.cr:7       # Run specific test by line
crystal spec --fail-fast                # Stop on first failure

# Formatting
crystal tool format                     # Format all .cr files
crystal tool format --check             # Check without changes
```

## Project Structure

```
src/
  croda.cr              # Main entry, requires all components
  croda/
    croda_plugins.cr    # Plugin registration system
    croda_request.cr    # Request wrapper class
    croda_response.cr   # Response wrapper class
    handler.cr          # HTTP::Handler implementation
    plugins/            # Built-in plugins (base, sessions, flash, cookies,
                        # csrf, json, assets, all_verbs, named_routes, request_body)
  ext/
    throw_catch.cr      # Ruby-style throw/catch for control flow
spec/
  spec_helper.cr        # Test setup
  croda_spec.cr         # Main test file
examples/
  todo/                 # Example todo application
```

## Code Style Guidelines

### Formatting (from .editorconfig)
- Indentation: 2 spaces (no tabs)
- Line endings: LF, Charset: UTF-8
- Final newline required, trim trailing whitespace

### Naming Conventions
| Type              | Convention           | Example                    |
|-------------------|----------------------|----------------------------|
| Classes/Modules   | PascalCase           | `CrodaRequest`, `Sessions` |
| Methods/Variables | snake_case           | `remaining_path`, `halt`   |
| Constants         | SCREAMING_SNAKE_CASE | `DEFAULT_MAX_AGE`          |
| Predicates        | snake_case with `?`  | `empty_path?`, `file?`     |
| Private methods   | snake_case (prefix)  | `assets_serve_file`        |

### Import Order
1. Standard library (`require "http"`, `require "json"`)
2. External shards
3. Relative requires (`require "./ext/throw_catch"`)
4. Wildcard requires last (`require "./croda/*"`)

### Type Annotations
- Explicit types for method parameters when not obvious
- Return type annotations for public API methods
- Use `getter`/`property` macros with type annotations or blocks

### Error Handling
- `raise` with descriptive messages for configuration errors
- Nullable return types (`Type?`) for methods that may not find a result
- `throw :halt` for control flow in request handling (not exceptions)

## Plugin Architecture

Plugins are modules under `Croda::CrodaPlugins` with optional submodules:
- `InstanceMethods` - Mixed into Croda app instances
- `ClassMethods` - Extended onto Croda app classes
- `RequestMethods` - Mixed into CrodaRequest
- `ResponseMethods` - Mixed into CrodaResponse

```crystal
abstract class Croda
  module CrodaPlugins
    module MyPlugin
      module InstanceMethods
        # Methods available on app instance
      end

      module RequestMethods
        # Methods available on request object (r)
      end

      def self.configure(_app : Croda.class, option : String)
        @@option = option
      end
    end

    register_plugin :my_plugin, Croda::CrodaPlugins::MyPlugin
  end
end
```

### Plugin Dependencies
```crystal
macro included
  require_plugin :csrf, :sessions
  require_plugin :csrf, :request_body
end
```

### After Hooks
```crystal
after_hook 50 do  # Lower priority runs first
  # Runs after request handling
end
```

## Testing Conventions

- Spec files mirror source structure: `src/croda/plugins/foo.cr` → `spec/croda/plugins/foo_spec.cr`
- Use `describe` for classes/modules, `context` for methods
- For methods, use only the method name (e.g., `context "#method_name"`)
- Nest additional conditions in nested `context` blocks
- Test app classes must be defined at module level, outside all `describe`/`context`/`it` blocks
- Use `webless` shard for HTTP testing without a real server

```crystal
require "../../spec_helper"

# Test apps defined at module level (outside all blocks)
class FooSpec_MyApp < Croda
  route do |r|
    r.root { "hello" }
  end
end

describe Croda::CrodaPlugins::Foo do
  context "#some_method" do
    it "does something" do
      client = Webless::Client.new { |ctx| FooSpec_MyApp.execute(ctx) }
      response = client.get("/")
      response.body.should eq("hello")
    end

    context "when some condition" do
      it "behaves differently" do
        # ...
      end
    end
  end
end
```

## Common Patterns

### Route Definitions
```crystal
class App < Croda
  plugin :json

  route do |r|
    r.root { "Hello" }           # GET /
    r.on "api" do                # /api/*
      r.get("users") { ... }     # GET /api/users
      r.post("users") { ... }    # POST /api/users
      r.get(Int32) do |id|       # GET /api/:id (integer)
        ...
      end
    end
  end
end
```

### Response Handling
- Return `String` from route blocks to set response body
- Return `nil` to continue routing
- Use `r.redirect(path)` for redirects
- Use `r.halt` or `throw :halt` to stop processing
