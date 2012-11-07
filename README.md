# Auth::Backend

Authentication backend

## User API

### Get all venue identities of a user

#### Request

**GET** to ``/api/v1/user/:UUID:/identities``

##### Parameters

- **UUID** [REQUIRED]: The UUID of the player you want to retrieve the venue IDs about.

##### Body

Empty.

#### Response

##### Body

JSON encoded object like this:

```javascript
{
  "uuid": "12347890",
  "venues": {
    "facebook": {
      "id": "12345",
      "name": "Peter S"
    },
    "galaxy-spiral": {
       "id": "67890",
       "name": "P Smith"
    }
  }
}
```

### Get all venue identities of a batch of users at once

#### Request

**GET** to ``/api/v1/user/batch/identities``

##### Body

JSON encoded array of UUIDs like this:

```javascript
["12345", "3264877", "43298854297"]
```

#### Response

JSON encoded object like this:

```javascript
{
  "12345": {
    "uuid": "12347890",
    "venues": {
      "facebook": {
        "id": "12345",
        "name": "Peter S"
      },
      "galaxy-spiral": {
         "id": "67890",
         "name": "P Smith"
      }
    }
  },
  "3264877": {
    "uuid": "4578934569",
    "venues": {
      "facebook": {
        "id": "238957",
        "name": "Sam Samson"
      }
    }
  },
  "43298854297": {
    "uuid": "0972648",
    "venues": {
    }
  }
}
```

## OAuth API

Besides the normal web flow there is an API to obtain a new OAuth
token, get basic information about a token owner or verify a token.

### Get a new OAuth token

You can request an OAuth token for either a user or a registered app.

#### Users

##### Request

**POST** to ``/api/v1/token``

Use HTTP basic auth to authenticate the user on who's behalf the token is issued.

##### Response

The response comes as JSON like this:

```javascript
{
  "token": "abcdef1234567890"
}
```

#### Apps

##### Request

**POST** to ``/api/v1/token/app``

Use HTTP basic auth and pass the app's id in as the username and the
app's secret as the password.

##### Response

The response comes as JSON like this:

```javascript
{
  "token": "abcdef1234567890"
}
```

#### Venues

Apps can request an OAuth token for a user identified by it's ID on any supported venue. These requests must be authenticated by an app's OAuth token.

If there is no user associated for the given venue and venue ID a new one will be created and associated with that venue ID.

##### Request

**POST** to ``/api/v1/token/venue/:VENUE:``

###### Parameters

- **VENUE** [REQUIRED]: The id of the venue (e.g. ``facebook`` or ``galaxy-spiral``)

###### Body

The request body is a JSON encoded hash like this:

```javascript
{
  "venue-id": "1234567",
  "name": "Peter Smith",
  "email": "peter@example.com"
}
```

``venue-id`` and ``name`` are mandatory keys.

##### Response

The response comes as JSON like this:

```javascript
{
  "token": "abcdef1234567890"
}
```

### Get or create UUIDs of a batch of users identified by their venue information

Used to translate a batch of users on a venue to their identities in our system. E.g. get the QS identity of a bunch of facebook friends of a user.

#### Request

**POST** to ``/api/v1/uuids/batch``

##### Body

JSON encoded object of venue information like this:

```javascript
{
  "facebook": [
    {
      "venue-id": "1234567",
      "name": "Peter Smith",
      "email": "peter@example.com"
    },
    {
      "venue-id": "4395798",
      "name": "Sam Jackson",
      "email": "sam@example.com"
    }
  ]
}
```

#### Response

##### Body

A JSON encoded object mapping venue ids to QS UUIDs like this:

```javascript
{
  "1234567": "726762439",
  "4395798": "348897438"
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
  "type": "user",
  "uuid":  "71e276f0-eb8d-012f-66ce-58b035f5cdfb"
}
```


### Verify if a token is valid

#### Request

**GET** to ``/api/v1/verify``

Authenticate the request with your OAuth token via OAuth2 bearer
credentials.

#### Response

If the token is valid the response body will be empty and the status
code will be 200.


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

### Test Helpers

With the ``Auth::Backend::TestHelpers`` class comes also a collection of convenient tools to setup the auth-backend within other project's test suites.

Use it like this:

```ruby
host     = 'http://auth-backend.dev'
auth_app = Auth::Backend::App.new(test: true)

require 'auth-backend/test_helpers'
auth_helpers = Auth::Backend::TestHelpers.new(app)
token = auth_helpers.new
```
