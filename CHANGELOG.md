# 0.0.29

* Updates dependencies

# 0.0.28

* Moves invitations to a per app basis

# 0.0.27

* Updates rack
* Updates json

# 0.0.26

* Fixes missing redirects back to OAuth apps after login with Facebook

# 0.0.25

* Fixes bug for user invitations when logging in with Facebook

# 0.0.24

* Makes an invitation mandatory to login

# 0.0.23

* Adds user invitations

# 0.0.22

* Adds login with Facebook
* Disables login with username/password in production
* Disabled sign ups in production

# 0.0.21

* Improves test helpers
* Makes it possible to login to the canvas-app on meta server

# 0.0.20

* Adds search to the user administration

# 0.0.19

* Adds Newrelic monitoring and ping middleware
* Fixes Rakefile for db migrations
* Makes the threading bug workaround only kick in when Postgres is used

# 0.0.18

* Fixes a threading bug with our ActiveRecord setup

# 0.0.17

* Explicitly use thin on Heroku

# 0.0.16

* Let the server run threaded to make circular requests possible

# 0.0.15

* Fixes bug in the test helpers to make tests work after the switch to an in memory db.
* Fixes bug that causes the batch venue identity endpoint to not return 404 status codes when users were not found

# 0.0.14

* Updates dependencies
* Moves tests to in-memory DB that gets automatically migrated on each test run

# 0.0.13

* Fixes bug when working with legacy sessions

# 0.0.12

* Makes it possible as an admin to impersonate other users
* Fixes random bugs on Heroku by switching from Webrick to Thin
* Refactors galaxy-spiral to spiral-galaxy in the README

# 0.0.11

* Renames galaxy-spiral to spiral-galaxy
* Stops deleting apps from happening when cancelling the confirmation
* Adds a spiral-galaxy OAuth token for metaserver
* Adds a devcenter-backend OAuth token for metaserver

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
