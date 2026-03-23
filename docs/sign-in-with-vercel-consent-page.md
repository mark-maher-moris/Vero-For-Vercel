# Consent Page

When users sign in to your application for the first time, Vercel shows them a consent page that displays:

- Your app's name and logo
- The permissions your app requests
- Two actions: Allow or Cancel

Users review these permissions before deciding whether to authorize your app.

## When Users Click Allow

After clicking Allow, the user is redirected to your callback URL with:
- An authorization code (in the `code` query parameter)
- The original `state` parameter (for CSRF verification)

Your app should exchange the code for tokens using the Token Endpoint.

## When Users Click Cancel

If the user clicks Cancel, they are redirected to your callback URL with an error:
- `error=access_denied`
- `error_description=The+user+denied+the+request`

Your app should handle this gracefully and show an appropriate message.

## Returning Users

Users who have already authorized your app won't see the consent page again. They'll be immediately redirected back to your app with a new authorization code.

## Customizing Your App

To customize how your app appears on the consent page:
1. Go to your app settings in the Vercel dashboard
2. Upload a logo
3. Set the app name and description### Production Deployment

Deployment

Domains

Status

Created

Source
