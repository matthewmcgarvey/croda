# require "../../spec_helper"

# # =============================================================================
# # TEST APPS - All defined at module level, outside all describe/context/it blocks
# # =============================================================================

# # Basic named route app
# class NamedRoutesSpec_BasicApp < Croda
#   plugin :named_routes

#   named_route "hello" do |r|
#     r.get { "hello world" }
#   end

#   route do |r|
#     r.route("hello")
#   end
# end

# # Fall through app - named route doesn't match, continues in calling block
# class NamedRoutesSpec_FallThroughApp < Croda
#   plugin :named_routes

#   named_route "admin" do |r|
#     r.on "admin" do
#       "admin area"
#     end
#   end

#   route do |r|
#     r.route("admin")  # Doesn't match /users, falls through
#     r.on "users" do
#       "users area"
#     end
#   end
# end

# # Remaining path app - tests r.on interaction with named routes
# class NamedRoutesSpec_RemainingPathApp < Croda
#   plugin :named_routes

#   named_route "api_routes" do |r|
#     r.on "users" do
#       "api users"
#     end
#     r.on "posts" do
#       "api posts"
#     end
#   end

#   route do |r|
#     r.on "api" do
#       r.route("api_routes")  # Should see remaining_path after /api
#     end
#   end
# end

# # Multiple named routes app
# class NamedRoutesSpec_MultipleRoutesApp < Croda
#   plugin :named_routes

#   named_route "foo" do |r|
#     r.get { "foo" }
#   end

#   named_route "bar" do |r|
#     r.get { "bar" }
#   end

#   route do |r|
#     r.on "foo" do
#       r.route("foo")
#     end
#     r.on "bar" do
#       r.route("bar")
#     end
#   end
# end

# # Nested named route calls app
# class NamedRoutesSpec_NestedCallApp < Croda
#   plugin :named_routes

#   named_route "inner" do |r|
#     r.get { "inner route" }
#   end

#   named_route "outer" do |r|
#     r.route("inner")
#   end

#   route do |r|
#     r.route("outer")
#   end
# end

# # HTTP verbs app
# class NamedRoutesSpec_VerbsApp < Croda
#   plugin :named_routes

#   named_route "users" do |r|
#     r.get { "list users" }
#     r.post { "create user" }
#   end

#   route do |r|
#     r.on "users" do
#       r.route("users")
#     end
#   end
# end

# # Same route called from multiple places app
# class NamedRoutesSpec_MultipleCallsApp < Croda
#   plugin :named_routes

#   named_route "shared" do |r|
#     r.get { "shared response" }
#   end

#   route do |r|
#     r.on "path1" do
#       r.route("shared")
#     end
#     r.on "path2" do
#       r.route("shared")
#     end
#   end
# end

# # Path matching inside named route app
# class NamedRoutesSpec_PathMatchingApp < Croda
#   plugin :named_routes

#   named_route "items" do |r|
#     r.on Int32 do |id|
#       "item #{id}"
#     end
#     r.is do
#       "items list"
#     end
#   end

#   route do |r|
#     r.on "items" do
#       r.route("items")
#     end
#   end
# end

# # =============================================================================
# # TESTS
# # =============================================================================

# describe Croda::CrodaPlugins::NamedRoutes do
#   describe "RequestMethods" do
#     context "#route" do
#       it "calls a named route and executes its block" do
#         client = Webless::Client.new { |ctx| NamedRoutesSpec_BasicApp.execute(ctx) }
#         response = client.get("/")
#         response.status.should eq(HTTP::Status::OK)
#         response.body.should eq("hello world")
#       end

#       it "returns named route response when it matches" do
#         client = Webless::Client.new { |ctx| NamedRoutesSpec_BasicApp.execute(ctx) }
#         response = client.get("/")
#         response.body.should eq("hello world")
#       end

#       context "when named route doesn't match" do
#         it "falls through to continue in calling block" do
#           client = Webless::Client.new { |ctx| NamedRoutesSpec_FallThroughApp.execute(ctx) }
#           response = client.get("/users")
#           response.status.should eq(HTTP::Status::OK)
#           response.body.should eq("users area")
#         end
#       end

#       context "with multiple named routes" do
#         it "calls the correct named route by name" do
#           client = Webless::Client.new { |ctx| NamedRoutesSpec_MultipleRoutesApp.execute(ctx) }
#           response = client.get("/foo")
#           response.body.should eq("foo")
#         end

#         it "can call different named routes in sequence" do
#           client = Webless::Client.new { |ctx| NamedRoutesSpec_MultipleRoutesApp.execute(ctx) }

#           response1 = client.get("/foo")
#           response1.body.should eq("foo")

#           response2 = client.get("/bar")
#           response2.body.should eq("bar")
#         end
#       end

#       context "with r.on blocks" do
#         it "passes remaining_path to the named route" do
#           client = Webless::Client.new { |ctx| NamedRoutesSpec_RemainingPathApp.execute(ctx) }
#           response = client.get("/api/users")
#           response.status.should eq(HTTP::Status::OK)
#           response.body.should eq("api users")
#         end

#         it "named route sees correct remaining_path after r.on consumes segments" do
#           client = Webless::Client.new { |ctx| NamedRoutesSpec_RemainingPathApp.execute(ctx) }
#           response = client.get("/api/posts")
#           response.body.should eq("api posts")
#         end

#         it "named route can match on the remaining path" do
#           client = Webless::Client.new { |ctx| NamedRoutesSpec_RemainingPathApp.execute(ctx) }
#           response = client.get("/api/users")
#           response.body.should eq("api users")
#         end
#       end

#       context "with HTTP verbs" do
#         it "named route handles GET requests" do
#           client = Webless::Client.new { |ctx| NamedRoutesSpec_VerbsApp.execute(ctx) }
#           response = client.get("/users")
#           response.body.should eq("list users")
#         end

#         it "named route handles POST requests" do
#           client = Webless::Client.new { |ctx| NamedRoutesSpec_VerbsApp.execute(ctx) }
#           response = client.post("/users")
#           response.body.should eq("create user")
#         end

#         it "named route can distinguish between HTTP methods" do
#           client = Webless::Client.new { |ctx| NamedRoutesSpec_VerbsApp.execute(ctx) }

#           get_response = client.get("/users")
#           get_response.body.should eq("list users")

#           post_response = client.post("/users")
#           post_response.body.should eq("create user")
#         end
#       end

#       context "with nested named route calls" do
#         it "named route can call another named route" do
#           client = Webless::Client.new { |ctx| NamedRoutesSpec_NestedCallApp.execute(ctx) }
#           response = client.get("/")
#           response.body.should eq("inner route")
#         end
#       end

#       context "when called multiple times" do
#         it "same named route invoked from different code paths" do
#           client = Webless::Client.new { |ctx| NamedRoutesSpec_MultipleCallsApp.execute(ctx) }

#           response1 = client.get("/path1")
#           response1.body.should eq("shared response")

#           response2 = client.get("/path2")
#           response2.body.should eq("shared response")
#         end
#       end

#       context "with path matching inside named route" do
#         it "named route can use r.on to match segments" do
#           client = Webless::Client.new { |ctx| NamedRoutesSpec_PathMatchingApp.execute(ctx) }
#           response = client.get("/items/42")
#           response.body.should eq("item 42")
#         end

#         it "named route can use r.is to require exact match" do
#           client = Webless::Client.new { |ctx| NamedRoutesSpec_PathMatchingApp.execute(ctx) }
#           response = client.get("/items")
#           response.body.should eq("items list")
#         end
#       end
#     end
#   end
# end
