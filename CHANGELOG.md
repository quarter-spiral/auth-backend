# 0.0.10

* Adds OAuth credentials for the playercenter on metaserver
* Destroys venue identities of a user along with him
* Fixes a bug which caused authentication errors in graph due to transactions
* Adds an endpoint to attach venue identities to users
* Fixes some wrong URLs in the README

# 0.0.9

* Adds batch UUID retrieval endpoint for venue identified users
* Fixes venue token creation without an email address
* Adds a ``player`` role in the graph to each user created via the venue token endpoint
* Adds venue identity API endpoint
* Improves API error method for unauthenticated requests

# 0.0.8

* Fixes a problem to read request bodies when running on an actual web server

# 0.0.7

* Adds an API endpoint to create OAuth tokens for players authenticated by a Mission Kontrol app and identified by the data the venue provides (e.g. ID on that venue and a name)

# 0.0.6

* Makes it possible to expire OAuth tokens with the test helpers

# 0.0.5

* Adds a nice UI theme
* Improves the test helpers for use by other projects
* Fixes a bug in the metaserver OAuth app setup

# 0.0.4

* Adds API endpoint to create OAuth tokens for OAuth apps

# 0.0.3

* Adds test helpers
* README improvements

# 0.0.2

* The beginning
