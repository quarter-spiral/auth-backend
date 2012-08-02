# auth-backend

A backend to authenticate and sign up users.

## Details

The authentication process is using [OAuth 2](http://tools.ietf.org/html/draft-ietf-oauth-v2) to authenticate users within the system. The auth-backend works as the *Authorization Server* in this setup, all back- end front-ends are *Consumers*. *Resource Owner Password Credentials* is the only supported *Authorization Grant Type*.

### Resource Owner Password Credentials

Our goal is to authenticate users based on the data we get from the venues they are playing the game on. At the point when the user gets the game from our system he already has ganted access to that game on the venue (Facebook allow dialog, etc) and we don't want him to have to deal with any other authentication from that point on. For that reason we are using the venue specific mechanisms to provide an internal venue user ID to our system to authenticate the user. The *Resource Owner Password Credentials* on OAuth 2 consists of a ``username`` and a ``password``. We use a venue identifier as the ``username`` and the data the venue is providing us to authenticate as the ``password``.

#### An Example: Facebook

Facebook provides what they call a signed request with every request they do to our canvas app. A signed request is a request parameter that consits of some data about the request (including the Facebook ID of the current user) and a HMAC SHA-256 signature of that information signed by the Facebook application's secret. Read more [here](https://developers.facebook.com/docs/authentication/signed_request/).

A complete signed request might look like this:

```
vlXgu64BQGFSQrY0ZcJBZASMvYvTHu9GQ0YM9rjPSso.eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsIjAiOiJwYXlsb2FkIn0
```

This provides all the information we need (the user's Facebook ID) in a way that we can make sure it's legit (using the application's secret which we know but which is not available to attackers).

So the *Resource Owner Password Credentials* for that request would look like this:

```
username: facebook
password: vlXgu64BQGFSQrY0ZcJBZASMvYvTHu9GQ0YM9rjPSso.eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsIjAiOiJwYXlsb2FkIn0
```

tbc