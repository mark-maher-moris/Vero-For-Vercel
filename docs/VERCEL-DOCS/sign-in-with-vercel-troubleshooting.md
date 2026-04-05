# Troubleshooting Sign in with Vercel

When users try to authorize your app, several errors can occur. Common troubleshooting steps include:

- Checking that all required parameters are included in your requests
- Verifying your app configuration in the dashboard
- Reviewing the [Authorization Server API](https://vercel.com/docs/sign-in-with-vercel/authorization-server-api) documentation
- Checking the [Getting Started](https://vercel.com/docs/sign-in-with-vercel/getting-started) guide for implementation examples

## Common Errors

### Missing or invalid client_id
Ensure your client_id is correctly set and matches the one in your dashboard.

### Missing or invalid redirect_uri
The redirect_uri must match exactly what you configured in the dashboard.

### Missing response_type
Must include `response_type=code` in your authorization request.

### Invalid code_challenge
The code_challenge must be a valid SHA-256 hash of your code_verifier.

### Invalid code_challenge_method
Must be set to `S256`.

## Error handling patterns

Implement proper error handling in your callback route to catch and display meaningful error messages to users.

### Production Deployment

Deployment

Domains

Status

Created

Source
