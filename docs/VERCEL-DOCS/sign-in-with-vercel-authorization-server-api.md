# Authorization Server API

The Authorization Server API exposes a set of endpoints which are used by your application for obtaining, refreshing, revoking, and introspecting tokens, as well querying user info:

| Endpoint | URL | Description |
|----------|-----|-------------|
| Authorization | `https://vercel.com/oauth/authorize` | Initiates OAuth flow |
| Token | `https://api.vercel.com/login/oauth/token` | Exchange code for tokens |
| Revoke | `https://api.vercel.com/login/oauth/token/revoke` | Revoke tokens |
| Introspect | `https://api.vercel.com/login/oauth/token/introspect` | Validate tokens |
| User Info | `https://api.vercel.com/login/oauth/userinfo` | Get user information |

These endpoints and other features of the authorization server are advertised at the following well-known URL:

```
https://vercel.com/.well-known/openid-configuration
```

Created

Source
