# Notes

General notes. Not documentation but might contain helpful things.

## Jan 02, 2023

New year, still thinking about how to serialize and validate request data.

Still like how Rust was doing it. Something like

```crystal
r.json(UserData)
r.query_params(SearchFilters)
r.form(CreateUser)
````

I don't want it to just return that type, though. If I did that,
we'd either have to raise exceptions on invalid data, or the model would have to provide
and API for it. I don't want to do those things, so I'd prefer `r.json(UserData)` return something
like a `Croda::Json(UserData)` and that type be like Rust's `Result` object and have a type for
each place request data can come from.

## Dec 23, 2022

I'm inspired by Actix's [extractors](https://actix.rs/docs/extractors).
Not that they're method parameters, but just typesafe request data extraction.

## Dec 8, 2022

I've been struggling with a better implementation of the named_routes plugin or a replacement.
I don't like the way it's currently implemented with if-statements and calling `previous_def`.
It feels very inneffecient. I've been looking at Roda's hash_branches plugin, but I don't see a way
to implement that in Crystal. Mainly I want this so that I don't have to do `r.on(...)` first thing
and the plugin matches based on the next path part.

I've been thinking about why Roda doesn't use or even mention that you can create methods and call them
even easier than using a plugin. Personally, I switched to it and away from using the named_routes plugin.
The best I can come up with is that it's main benefit (beyond the implicit `r.on(...)`) is the indirection.
With the routes plugins, the parent route block doesn't have to know anything about the child blocks that
may or may not handle the request. By just using methods, I have to add the method, but I also have to
update the parent block to call this new method.

If I want the indirection _and_ the dynamic, but effecient routing, how do I do that?
And do I want indirection? How does that help the codebase of my app, long term?

## March 31, 2022

Wanting to switch to making a real product with this (CryHook).
I found an random app out there that uses Roda just to see what a project looks like https://github.com/skoona/HomieMonitor.
It shows me that I really want to add in the `named_routes` plugin. That way it doesn't have to be one big route tree.

## March 30, 2022

Tried to go down the route of a `Croda` class _extending_ `HTTP::Handler` instead of _including_ it.
That doesn't work since `HTTP::Handler` defines an instance-level property.

The solution I went with is to add a generic `Croda::Handler` that takes in the `Croda` class.
That way, the lifecycle of user's apps are for the request and I don't have to worry about memoization on the instance
and can guarantee that the request and response aren't nil.

I was fixated on doing it Roda's way, but this way works too. It will be even cleaner in the future once I wrap creating the server as well.

## March 18, 2022

Fixing the hooks for Flash and Session plugins revealed a larger problem.
On several plugins, I'm adding functionality to the app instance and some of it is even memoized.
The flash plugin is a good example where I'm memoizing the flash store.
On doing that, I realized that the app instance is not for the the life of the request like I believe Roda is.
I should hav known this, since middleware are instantiated in the middleware list, but it was overlooked.
Just thinking through my options:

- Have resetting plugins built in to avoid this
- Create something below the middleware level that is instantiated on each request and move everything there
- Move anything that could be persisted across requests into the request instance methods
  - There can still be app instance methods, but they call methods on the request and would not be memoized
  - The session plugin does this already

FIXED: moved memoization to request instance, though it makes the code a little uglier
