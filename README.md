# Auth::Backend

Authentication backend

## OAuth API

Besides the normal web flow there is an API to obtain a new OAuth
token and get basic information about a token owner.

### Get a new OAuth token

#### Request

**POST** to ``/api/v1/token``

Use HTTP basic auth to authenticate the user on who's behalf the token
is issued.

#### Response

The response comes as JSON like this:

```javascript
{
  "token": "abcdef1234567890"
}
```

### Get information about a token owner

#### Request

**GET** to ``/api/v1/me``

Authenticate the request with your OAuth token via OAuth2 bearer
credentials.

#### Response

The response comes as JSON like tis:

```javascript
{
  "name":  "John",
  "email": "john@example.com",
  "uuid":  "71e276f0-eb8d-012f-66ce-58b035f5cdfb"
}
```

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
