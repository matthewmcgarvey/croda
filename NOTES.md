# Notes

General notes. Not documentation but might contain helpful things.

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
