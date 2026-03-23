# Scopes and Permissions

Scopes define what data is included in the ID Token and whether to issue a Refresh Token. Permissions control what APIs and team resources an [Access Token](https://vercel.com/docs/sign-in-with-vercel/tokens) can interact with.

## Scopes

The following scopes are available:

| Scope | Description | Provides |
|-------|-------------|----------|
| `openid` | Required scope for OpenID Connect authentication | [ID Token](https://vercel.com/docs/sign-in-with-vercel/tokens) |
| `email` | Access to user's email address | [ID Token](https://vercel.com/docs/sign-in-with-vercel/tokens) with email claim |
| `profile` | Access to user's profile information (name, username, picture) | [ID Token](https://vercel.com/docs/sign-in-with-vercel/tokens) with profile claims |
| `offline_access` | Permission to receive a Refresh Token | [Refresh Token](https://vercel.com/docs/sign-in-with-vercel/tokens) |

## Permissions

Permissions for issuing API requests and interacting with team resources are currently in private beta.

## Usage

When making the authorization request, include the desired scopes in the `scope` parameter as a space-separated list:

```
scope=openid email profile offline_access
```

At minimum, you must request the `openid` scope. Include `offline_access` if you need to refresh tokens without requiring the user to sign in again.

### Production Deployment

Deployment

Domains

Status

Created

Source
