# Manage Sign in with Vercel from the Dashboard

## Create an App

To manage any third-party apps, or create a new one yourself, you need to create an App. An App acts as an intermediary that requests and manages access to resources on behalf of the user.

To create an App:
1. Navigate to your team's **Settings** section in the sidebar
2. Scroll down and select **Apps**, and click **Create**
3. Choose a name for your app
4. Choose a slug for your app (automatically generated from the name)
5. Optionally add a logo for your app
6. Click **Save**

## Choose Your Client Authentication Method

The client authentication method determines how your app will authenticate with the Vercel Authorization Server:

- **client_secret_basic**: Credentials in Authorization header
- **client_secret_post**: Credentials in request body
- **client_secret_jwt**: JWT-based authentication
- **none**: For public clients (PKCE required)

## Generate a Client Secret

Client secrets are used to authenticate your app. You can generate a client secret by clicking the **Generate** button.

You can have up to two active client secrets at a time for rotation without downtime.

## Configure the Authorization Callback URL

The authorization callback URL is where Vercel redirects users after they authorize your app.

To add a callback URL:
1. Navigate to the Manage page for your app
2. Scroll to **Authorization Callback URLs**
3. Enter your callback URL
4. Click **Add**

For local development, add `http://localhost:3000/api/auth/callback`
For production, add `https://your-domain.com/api/auth/callback`

## Configure Necessary Permissions

Select the scopes your app needs from the dashboard:
- **openid**: Required for all apps
- **email**: Access to user email
- **profile**: Access to user profile
- **offline_access**: For refresh tokens

### Production Deployment

Deployment

Domains

Status

Created

Source
