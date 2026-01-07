require "../../spec_helper"

# =============================================================================
# TEST APPS - Grouped by routing method
# =============================================================================

# App for testing #root
class BaseSpec_RootApp < Croda
  route do |r|
    r.root { "home" }
  end
end

# App for testing #on with various argument types
class BaseSpec_OnApp < Croda
  route do |r|
    # String matching with nesting
    r.on "api" do
      r.on "users" do
        r.on String do |username|
          "user: #{username}"
        end
        "users"
      end
      r.on "posts" do
        r.on Int32 do |id|
          "post #{id}"
        end
      end
      r.on "items" do
        r.on Int64 do |id|
          "item #{id}"
        end
      end
    end

    # Regex matching
    r.on /\/version\/v(\d+)/ do |match|
      "version #{match[1]}"
    end

    # Array matching
    r.on ["accounts", "profiles"] do |matched|
      "matched: #{matched}"
    end

    # Bool matching (conditional)
    admin = r.path.includes?("admin")
    r.on admin do
      "admin matched"
    end

    # Partial match test - "test" should not match "testing"
    r.on "test" do
      "test matched"
    end
  end
end

# App for testing #on without argument
class BaseSpec_OnNoArgApp < Croda
  route do |r|
    r.on do
      "always matched"
    end
  end
end

# App for testing #is
class BaseSpec_IsApp < Croda
  route do |r|
    # is without argument (inside on block)
    r.on "api" do
      r.is do
        "api root"
      end
    end

    # is with String argument
    r.is "about" do
      "about page"
    end

    # is with Int32 argument
    r.is Int32 do |id|
      "id: #{id}"
    end
  end
end

# App for testing #get
class BaseSpec_GetApp < Croda
  route do |r|
    # get with String argument
    r.get "users" do
      "users list"
    end

    # get with Int32 argument
    r.get Int32 do |id|
      "get id: #{id}"
    end

    # get without argument (catches all GET)
    r.get { "get response" }
  end
end

# App for testing #post
class BaseSpec_PostApp < Croda
  route do |r|
    # post with String argument
    r.post "create" do
      "created"
    end

    # post without argument (catches all POST)
    r.post { "post response" }
  end
end

# App for testing #redirect
class BaseSpec_RedirectApp < Croda
  route do |r|
    r.on "old" do
      r.redirect "/new"
    end
    r.on "permanent" do
      r.redirect "/new", 301
    end
  end
end

# App for testing #halt, #always, and request accessors
class BaseSpec_ControlFlowApp < Croda
  route do |r|
    r.on "halt" do
      response.status = 401
      r.halt
    end

    r.on "always" do
      r.always { "always runs" }
    end

    r.on "headers" do
      r.headers["X-Custom"]?.to_s
    end

    r.on "method" do
      r.method
    end

    r.on "path" do
      r.path
    end
  end
end

# App for testing #remaining_path and #matched_path
class BaseSpec_PathTrackingApp < Croda
  route do |r|
    r.on "api" do
      r.on "v1" do
        r.on "remaining" do
          "remaining: #{r.remaining_path}"
        end
        r.on "matched" do
          "matched: #{r.matched_path}"
        end
      end
    end
  end
end

# App for testing response methods
class BaseSpec_ResponseApp < Croda
  route do |r|
    r.on "write" do
      response.write("custom body")
      nil
    end

    r.on "status-int" do
      response.status = 201
      "created"
    end

    r.on "status-enum" do
      response.status = HTTP::Status::CREATED
      "created"
    end

    r.on "content-type" do
      response.content_type = "application/json"
      "{\"key\": \"value\"}"
    end

    r.on "no-body" do
      nil
    end
  end
end

# App for testing nested routing with multiple verbs
class BaseSpec_NestedApp < Croda
  route do |r|
    r.on "api" do
      r.on "v1" do
        r.on "users" do
          r.get { "list users" }
          r.post { "create user" }
        end
      end
    end
  end
end

# =============================================================================
# TESTS
# =============================================================================

describe Croda::CrodaPlugins::Base do
  describe "RequestMethods" do
    context "#root" do
      it "matches GET /" do
        client = Webless::Client.new { |ctx| BaseSpec_RootApp.execute(ctx) }
        response = client.get("/")
        response.status.should eq(HTTP::Status::OK)
        response.body.should eq("home")
      end

      it "does not match other paths" do
        client = Webless::Client.new { |ctx| BaseSpec_RootApp.execute(ctx) }
        response = client.get("/other")
        response.status.should eq(HTTP::Status::NOT_FOUND)
      end

      it "does not match POST /" do
        client = Webless::Client.new { |ctx| BaseSpec_RootApp.execute(ctx) }
        response = client.post("/")
        response.status.should eq(HTTP::Status::NOT_FOUND)
      end
    end

    context "#on" do
      context "without argument" do
        it "always matches and halts" do
          client = Webless::Client.new { |ctx| BaseSpec_OnNoArgApp.execute(ctx) }
          response = client.get("/anything")
          response.body.should eq("always matched")
        end
      end

      context "with String argument" do
        it "matches exact segment" do
          client = Webless::Client.new { |ctx| BaseSpec_OnApp.execute(ctx) }
          response = client.get("/api/users")
          response.body.should eq("users")
        end

        it "matches nested segments" do
          client = Webless::Client.new { |ctx| BaseSpec_OnApp.execute(ctx) }
          response = client.get("/api/posts/123")
          response.body.should eq("post 123")
        end

        it "does not match partial segments" do
          client = Webless::Client.new { |ctx| BaseSpec_OnApp.execute(ctx) }
          response = client.get("/testing")
          response.status.should eq(HTTP::Status::NOT_FOUND)
        end

        it "does not match when segment not present" do
          client = Webless::Client.new { |ctx| BaseSpec_OnApp.execute(ctx) }
          response = client.get("/other")
          response.status.should eq(HTTP::Status::NOT_FOUND)
        end
      end

      context "with Int32.class argument" do
        it "matches integer segment and yields value" do
          client = Webless::Client.new { |ctx| BaseSpec_OnApp.execute(ctx) }
          response = client.get("/api/posts/123")
          response.body.should eq("post 123")
        end

        it "does not match non-integer segments" do
          client = Webless::Client.new { |ctx| BaseSpec_OnApp.execute(ctx) }
          response = client.get("/api/posts/abc")
          response.status.should eq(HTTP::Status::NOT_FOUND)
        end
      end

      context "with Int64.class argument" do
        it "matches integer segment and yields Int64 value" do
          client = Webless::Client.new { |ctx| BaseSpec_OnApp.execute(ctx) }
          response = client.get("/api/items/999999999999")
          response.body.should eq("item 999999999999")
        end
      end

      context "with String.class argument" do
        it "captures any string segment" do
          client = Webless::Client.new { |ctx| BaseSpec_OnApp.execute(ctx) }
          response = client.get("/api/users/john")
          response.body.should eq("user: john")
        end

        it "captures segment with special characters" do
          client = Webless::Client.new { |ctx| BaseSpec_OnApp.execute(ctx) }
          response = client.get("/api/users/jane-doe")
          response.body.should eq("user: jane-doe")
        end
      end

      context "with Regex argument" do
        it "matches regex pattern and yields MatchData" do
          client = Webless::Client.new { |ctx| BaseSpec_OnApp.execute(ctx) }
          response = client.get("/version/v2")
          response.body.should eq("version 2")
        end

        it "does not match when pattern fails" do
          client = Webless::Client.new { |ctx| BaseSpec_OnApp.execute(ctx) }
          response = client.get("/version/vX")
          response.status.should eq(HTTP::Status::NOT_FOUND)
        end
      end

      context "with Array(String) argument" do
        it "matches first matching segment" do
          client = Webless::Client.new { |ctx| BaseSpec_OnApp.execute(ctx) }
          response = client.get("/accounts")
          response.body.should eq("matched: accounts")
        end

        it "matches any segment in array" do
          client = Webless::Client.new { |ctx| BaseSpec_OnApp.execute(ctx) }
          response = client.get("/profiles")
          response.body.should eq("matched: profiles")
        end

        it "does not match segments not in array" do
          client = Webless::Client.new { |ctx| BaseSpec_OnApp.execute(ctx) }
          response = client.get("/other")
          response.status.should eq(HTTP::Status::NOT_FOUND)
        end
      end

      context "with Bool argument" do
        it "matches when condition is true" do
          client = Webless::Client.new { |ctx| BaseSpec_OnApp.execute(ctx) }
          response = client.get("/admin/panel")
          response.body.should eq("admin matched")
        end

        it "does not match when condition is false" do
          client = Webless::Client.new { |ctx| BaseSpec_OnApp.execute(ctx) }
          response = client.get("/user/panel")
          response.status.should eq(HTTP::Status::NOT_FOUND)
        end
      end
    end

    context "#is" do
      context "without argument" do
        it "matches when remaining path is empty" do
          client = Webless::Client.new { |ctx| BaseSpec_IsApp.execute(ctx) }
          response = client.get("/api")
          response.body.should eq("api root")
        end

        it "does not match with trailing segments" do
          client = Webless::Client.new { |ctx| BaseSpec_IsApp.execute(ctx) }
          response = client.get("/api/users")
          response.status.should eq(HTTP::Status::NOT_FOUND)
        end
      end

      context "with String argument" do
        it "matches exact complete path" do
          client = Webless::Client.new { |ctx| BaseSpec_IsApp.execute(ctx) }
          response = client.get("/about")
          response.body.should eq("about page")
        end

        it "does not match with trailing segments" do
          client = Webless::Client.new { |ctx| BaseSpec_IsApp.execute(ctx) }
          response = client.get("/about/team")
          response.status.should eq(HTTP::Status::NOT_FOUND)
        end
      end

      context "with Int32.class argument" do
        it "matches when path is just an integer" do
          client = Webless::Client.new { |ctx| BaseSpec_IsApp.execute(ctx) }
          response = client.get("/42")
          response.body.should eq("id: 42")
        end

        it "does not match with trailing segments" do
          client = Webless::Client.new { |ctx| BaseSpec_IsApp.execute(ctx) }
          response = client.get("/42/edit")
          response.status.should eq(HTTP::Status::NOT_FOUND)
        end
      end
    end

    context "#get" do
      context "without argument" do
        it "matches GET requests" do
          client = Webless::Client.new { |ctx| BaseSpec_GetApp.execute(ctx) }
          response = client.get("/")
          response.body.should eq("get response")
        end

        it "does not match POST requests" do
          client = Webless::Client.new { |ctx| BaseSpec_GetApp.execute(ctx) }
          response = client.post("/")
          response.status.should eq(HTTP::Status::NOT_FOUND)
        end
      end

      context "with String argument" do
        it "matches GET with exact path" do
          client = Webless::Client.new { |ctx| BaseSpec_GetApp.execute(ctx) }
          response = client.get("/users")
          response.body.should eq("users list")
        end

        it "does not match POST with same path" do
          client = Webless::Client.new { |ctx| BaseSpec_GetApp.execute(ctx) }
          response = client.post("/users")
          response.status.should eq(HTTP::Status::NOT_FOUND)
        end

        it "requires empty path after match (falls through to next route)" do
          client = Webless::Client.new { |ctx| BaseSpec_GetApp.execute(ctx) }
          response = client.get("/users/123")
          # Falls through to catch-all r.get since path isn't empty after "users"
          response.body.should eq("get response")
        end
      end

      context "with Int32.class argument" do
        it "matches GET with integer parameter" do
          client = Webless::Client.new { |ctx| BaseSpec_GetApp.execute(ctx) }
          response = client.get("/42")
          response.body.should eq("get id: 42")
        end

        it "requires empty path after match (falls through to next route)" do
          client = Webless::Client.new { |ctx| BaseSpec_GetApp.execute(ctx) }
          response = client.get("/42/edit")
          # Falls through to catch-all r.get since path isn't empty after integer
          response.body.should eq("get response")
        end
      end
    end

    context "#post" do
      context "without argument" do
        it "matches POST requests" do
          client = Webless::Client.new { |ctx| BaseSpec_PostApp.execute(ctx) }
          response = client.post("/")
          response.body.should eq("post response")
        end

        it "does not match GET requests" do
          client = Webless::Client.new { |ctx| BaseSpec_PostApp.execute(ctx) }
          response = client.get("/")
          response.status.should eq(HTTP::Status::NOT_FOUND)
        end
      end

      context "with String argument" do
        it "matches POST with exact path" do
          client = Webless::Client.new { |ctx| BaseSpec_PostApp.execute(ctx) }
          response = client.post("/create")
          response.body.should eq("created")
        end

        it "requires empty path after match (falls through to next route)" do
          client = Webless::Client.new { |ctx| BaseSpec_PostApp.execute(ctx) }
          response = client.post("/create/new")
          # Falls through to catch-all r.post since path isn't empty after "create"
          response.body.should eq("post response")
        end
      end
    end

    context "#redirect" do
      it "sets Location header and uses 302 by default" do
        client = Webless::Client.new { |ctx| BaseSpec_RedirectApp.execute(ctx) }
        response = client.get("/old")
        response.status.should eq(HTTP::Status::FOUND)
        response.headers["Location"].should eq("/new")
      end

      it "accepts custom status code" do
        client = Webless::Client.new { |ctx| BaseSpec_RedirectApp.execute(ctx) }
        response = client.get("/permanent")
        response.status.code.should eq(301)
        response.headers["Location"].should eq("/new")
      end
    end

    context "#halt" do
      it "stops routing and prevents further execution" do
        client = Webless::Client.new { |ctx| BaseSpec_ControlFlowApp.execute(ctx) }
        response = client.get("/halt")
        response.status.code.should eq(401)
        response.body.should eq("")
      end
    end

    context "#always" do
      it "always executes and halts" do
        client = Webless::Client.new { |ctx| BaseSpec_ControlFlowApp.execute(ctx) }
        response = client.get("/always")
        response.body.should eq("always runs")
      end
    end

    context "#remaining_path" do
      it "is empty when path is fully consumed" do
        client = Webless::Client.new { |ctx| BaseSpec_PathTrackingApp.execute(ctx) }
        response = client.get("/api/v1/remaining")
        response.body.should eq("remaining: ")
      end

      it "contains unconsumed path segments" do
        client = Webless::Client.new { |ctx| BaseSpec_PathTrackingApp.execute(ctx) }
        response = client.get("/api/v1/remaining/users")
        response.body.should eq("remaining: /users")
      end
    end

    context "#matched_path" do
      it "shows consumed portion of path" do
        client = Webless::Client.new { |ctx| BaseSpec_PathTrackingApp.execute(ctx) }
        response = client.get("/api/v1/matched")
        response.body.should eq("matched: /api/v1/matched")
      end
    end

    context "#headers" do
      it "returns request headers" do
        client = Webless::Client.new { |ctx| BaseSpec_ControlFlowApp.execute(ctx) }
        response = client.get("/headers", HTTP::Headers{"X-Custom" => "value"})
        response.body.should eq("value")
      end
    end

    context "#method" do
      it "returns request method" do
        client = Webless::Client.new { |ctx| BaseSpec_ControlFlowApp.execute(ctx) }
        response = client.post("/method")
        response.body.should eq("POST")
      end
    end

    context "#path" do
      it "returns full request path" do
        client = Webless::Client.new { |ctx| BaseSpec_ControlFlowApp.execute(ctx) }
        response = client.get("/path")
        response.body.should eq("/path")
      end
    end
  end

  describe "ResponseMethods" do
    context "#write" do
      it "sets response body" do
        client = Webless::Client.new { |ctx| BaseSpec_ResponseApp.execute(ctx) }
        response = client.get("/write")
        response.body.should eq("custom body")
      end
    end

    context "#status=" do
      it "accepts Int32" do
        client = Webless::Client.new { |ctx| BaseSpec_ResponseApp.execute(ctx) }
        response = client.get("/status-int")
        response.status.code.should eq(201)
      end

      it "accepts HTTP::Status enum" do
        client = Webless::Client.new { |ctx| BaseSpec_ResponseApp.execute(ctx) }
        response = client.get("/status-enum")
        response.status.should eq(HTTP::Status::CREATED)
      end
    end

    context "#content_type=" do
      it "sets Content-Type header" do
        client = Webless::Client.new { |ctx| BaseSpec_ResponseApp.execute(ctx) }
        response = client.get("/content-type")
        response.headers["Content-Type"].should eq("application/json")
      end
    end

    context "#finish" do
      it "returns 200 when body is set" do
        client = Webless::Client.new { |ctx| BaseSpec_ResponseApp.execute(ctx) }
        response = client.get("/write")
        response.status.should eq(HTTP::Status::OK)
      end

      it "returns 404 when no body is set" do
        client = Webless::Client.new { |ctx| BaseSpec_ResponseApp.execute(ctx) }
        response = client.get("/no-body")
        response.status.should eq(HTTP::Status::NOT_FOUND)
      end

      it "sets default Content-Type to text/html" do
        client = Webless::Client.new { |ctx| BaseSpec_RootApp.execute(ctx) }
        response = client.get("/")
        response.headers["Content-Type"].should eq("text/html")
      end

      it "does not override existing Content-Type" do
        client = Webless::Client.new { |ctx| BaseSpec_ResponseApp.execute(ctx) }
        response = client.get("/content-type")
        response.headers["Content-Type"].should eq("application/json")
      end
    end
  end

  describe "InstanceMethods" do
    it "executes routes and finishes response" do
      client = Webless::Client.new { |ctx| BaseSpec_NestedApp.execute(ctx) }
      response = client.get("/api/v1/users")
      response.status.should eq(HTTP::Status::OK)
      response.body.should eq("list users")
    end
  end
end
