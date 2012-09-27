# Auth::Backend

Authentication backend

## Test interface

For using the ``Auth::Backend`` in tests of other services it is possible to enable a test interface that gives access to a very basic CRUD interface for users that can be reached without any authentication. You should be very careful when using this. All your data is at stake! :scream_cat:!

As an example to access the backend with the enabled test interface via Rack::Client use:

```ruby
client = Rack::Client.new {run Auth::Backend::App.new(test: true)}
```

### Test API

All parameters most be sent form encoded.

#### Add a user

**POST** to ``/_tests_/users``

Possible parameters: ``name``, ``email``, ``password``,
``password_confirmation``, ``admin``.

#### List all users

**GET** to ``/_tests_/users``.

Response is an JSON array.

#### Delete a user

**DELETE** to ``/_tests_/users/:id``
