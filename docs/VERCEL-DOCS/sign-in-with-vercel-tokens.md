# Tokens

There are three tokens your application will work with when using Sign in with Vercel:
- **ID Token**: A signed JWT that contains information about the user
- **Access Token**: Grants permission to access Vercel resources
- **Refresh Token**: Allows getting new Access Tokens without re-signing in

## ID Token

The ID Token is a signed JWT that contains information about the user who is signing in. When using ID Token claims, your application should both decode the token and verify its signature against the [public JWKS endpoint](https://vercel.com/.well-known/jwks) to ensure authenticity. The ID Token does not give access to Vercel resources, it only proves the user's identity.

Example ID Token payload:
```json
{
  "iss": "https://vercel.com",
  "sub": "345e869043f1e55f8bdc837c",
  "aud": "cl_be6c3c8b9f340d4a20feefab2862a49a",
  "exp": 1519948800,
  "iat": 1519945200,
  "nbf": 1519945200,
  "jti": "50e67781-c8b6-4391-98d1-89d755bb095a",
  "name": "John Doe",
  "preferred_username": "john-doe",
  "picture": "https://api.vercel.com/www/avatar/00159aa4c88348dedc91a456b457d1baa48df6d",
  "email": "user@example.com",
  "nonce": "a4a522fa63f9cea6eeb1"
}
```

Created

Source
