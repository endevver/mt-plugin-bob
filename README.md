# Bob the Rebuilder, a plugin for Movable Type

When publishing an Entry in Movable Type, the related templates are also
published: the entry, a category archive, monthly archive, and main index, for
example. Often in large multiblog installs, however, circumstances arise where
some templates aren't republished when needed.

Bob the Rebuilder provides a way to republish a blog or website (or a part of a
blog or website) on a recurring schedule. For example, create a job to
republish an entire blog every 24 hours, or create a job to republish all index
archives every 10 minutes. An unlimited number of jobs can be created to
republish any blog (or part of it) according to a number of set frequency
choices.


# Prerequisites

* Movable Type 5.1+
* `run-periodic-tasks` must be running


# Installation

To install this plugin follow the instructions found here:

http://tinyurl.com/easy-plugin-install


# Configuration

Bob the Rebuilder is configured at the System level (Tools > Rebuilder). "Jobs"
are used to rebuild a website/blog or part of a website/blog on a schedule, and
can be enabled or disabled as needed.

"Create a rebuilder job" to get started: specify a website or blog, what you
want to republish, its frequency, and save it. Done!

It's important to be aware of the load you may be placing on the server -- many
jobs each republishing an entire blog every few minutes is goint to take a lot
of resources. Planning site architecture is outside of the scope of this
document, but the goal should be to publish efficiently. Only publish what
*needs* to be republished, and republish as little as possible.

Tip: if a blog's archives need to be republished, republish each archive type
with a different job using a different schedule. Weekly, Monthly, and Yearly
archives almost definitely don't need to be published every few minutes or
hours, however a category archive may need much greater frequency.


# Support

This plugin is not an official Six Apart release, and as such support from Six
Apart for this plugin is not available.

Authors: Six Apart, Endevver
Copyright: 2009-2013 Six Apart Ltd.
License: MIT
