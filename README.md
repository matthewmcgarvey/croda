# Croda

This was a fun project, but I consider it dead now. I had no idea if it would even be possible to replicate Roda in Crystal when I first started this 5 years.
I am beyond surprised at what I was able to achieve with empty classes and rather simple macros.
I would still like to note some of the major features (from Roda but surprisingly implemented here).

## Plugins

If you look at most of the core classes (`Croda`, `CrodaRequest`, `CrodaResponse`), you'll find them to be practically empty.
All of the functionality of the project comes from the plugins. The most important of which is the the `Base` plugin.
That plugin essentially bootstraps itself and allows for all the other plugins to work. It adds all the basic functionality of a Croda and
someone can handle web requests to some extent without adding any plugins themselves.

Other plugins can be added that extend the functionality of those base objects and can define exactly how they extend it.
They can also require configuration, and crazily (at least from a Crystal context) require other plugins as dependencies at compile time.

I've not seen any other Crystal project use this type of plugin system. This is definitely something I will keep in mind for future projects.

## Tree-Based Routing

Lots of Crystal web routing libraries use tree-based routing. This was the only one to allow dev's to implement their routing dynamically at runtime.
It allowed for path variables, regex, and request method branching. While there are drawbacks (I'll get to it below),
it was 100x simpler code to understand than any of the routers in your favorite crystal shard.

## The whole request cycle in one block

Pretty much in every web framework, there's always the problem of wanting to do something with the request or response and wondering "Where do I put this?"
In which of the many holes in that the framework gives you, are you supposed to slot in your auth, or your request tracing, or handle errors raised, or even routing?
Having everything just right in the one block was like a canvas and everything I could want within arms reach.

## The Reason For Calling It Dead

The mess. Yes, the block is great, but the block is HUGE.
Roda, of course, has this same problem. They get around it by having some plugins that let you define a route block outside the class and link to it from the main route block.
Unfortunately I wasn't able to implement this in Crystal (see the broken NamedRoutes plugin).
If I were able to define a separate routing block, I would also have to find a way to be able to move it out of the main croda file.
Maybe someone else could pick up the torch from here and figure it out.

Another reason is the lack of a good LSP in crystal.
It makes having few objects with many methods difficult to work with. I found myself constantly digging through plugin code searching for things.
It also proved difficult for AI's. as they had to do more work to figure out how the project works and look in plugins for things.

Overall, there were many hurdles, which were interesting, but the small cuts along the way eventually got to me.
