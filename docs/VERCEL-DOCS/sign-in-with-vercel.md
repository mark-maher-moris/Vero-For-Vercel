# Sign in with Vercel

Sign in with Vercel lets people use their Vercel account to log in to your application. Your application doesn't need to handle passwords, create accounts, or manage user sessions. Instead it asks Vercel for proof of identity using the Vercel Identity Provider (IdP), so you can authenticate users without managing their credentials.

## How it Works

1. User clicks "Sign in with Vercel" button in your app
2. User is redirected to Vercel's authorization page
3. User reviews permissions and clicks Allow
4. Vercel redirects back to your app with an authorization code
5. Your app exchanges the code for tokens
6. Your app uses tokens to identify the user

## Documentation

- [Getting Started](https://vercel.com/docs/sign-in-with-vercel/getting-started) - Implementation guide with Next.js
- [Tokens](https://vercel.com/docs/sign-in-with-vercel/tokens) - ID Token, Access Token, Refresh Token
- [Scopes and Permissions](https://vercel.com/docs/sign-in-with-vercel/scopes-and-permissions) - Available scopes
- [Authorization Server API](https://vercel.com/docs/sign-in-with-vercel/authorization-server-api) - OAuth endpoints
