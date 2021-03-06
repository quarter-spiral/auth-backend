# 0.0.54 / 2013-09-03

* Fixes some API issues for EW notifications

# 0.0.53 / 2013-08-31

* Adds venue identity administration

# 0.0.52 / 2013-08-19

* Forces SSL/HTTPS

# 0.0.51 / 2013-08-18

* Logs users in automatically after signups
* When signing in with OAuth and signing up for a new account users are send back afterwards
* Makes tos acceptance part of the signup page

# 0.0.50 / 2013-08-18

* Optionally adds automatic authorization for apps
* Adds favicon

# 0.0.49 / 2013-08-12

* Adds getsentry.com exception tracking
* Adds getsentry error tracker
* Adds request id tracker
* Updates to newest service-client to carry request ids through service calls

# 0.0.48 / 2013-08-08

* small copy and layout tweaks to make signup / login more clear

# 0.0.47 / 2013-07-31

* Makes test helper viable to create admin users
* Fixes bcrypt dependency

# 0.0.46 / 2013-07-26

* Improves error messages on profile changes

# 0.0.45 / 2013-07-25

* Fixes profile fields
* Adds venue identities on signups
* Enables signups and logins with username/password again

# 0.0.44 / 2013-07-22

* Adds Firebase token administration to users' edit page
* Adds admin field to private user info
* Creates a new Firebase token 24h before the existing token expires

# 0.0.43  / 2013-07-15

*  Adds facebook friends on login with FB

# 0.0.42 / 2013-07-04

* Fixes namespace error when logging out

# 0.0.41 / 2013-07-04

* Fixes problem on production

# 0.0.40 / 2013-07-04

* Adds firebase tokens to token owner introspection

# 0.0.39 / 2013-07-01

* Bumps padrino dependency to avoid errors
* minor tweak to the auth interface

# 0.0.38 / 2013-06-21

* much improved UI

# 0.0.37 / 2013-06-05

* Fixes bug when deleted users are in someone's network of friends

# 0.0.36 / 2013-06-05

* Fixes bug that caused TOS acceptance to always fail

# 0.0.35 / 2013-05-05

* Users must now accept the current TOS before doing anything in the system

# 0.0.34 / 2013-04-08

* changed IE specific link to google to use https
* Changed presentation of most pages

# 0.0.33 / 2013-04-08

* Fixes some issues with auth tokens, etc

# 0.0.32 / 2013-04-07

* Switches to Unicorn
* Pins Ruby version on Heroku

# 0.0.31 / 2013-04-07

* Updates oauth2 provider

# 0.0.30

* Updates activerecord
* Fixes encoding issue with has_secure_password and sqlite
* Adds authorization

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
