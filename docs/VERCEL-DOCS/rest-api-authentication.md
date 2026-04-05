# REST API Authentication

Vercel Access Tokens are required to authenticate and use the Vercel API. Include the token in the Authorization header:

```
Authorization: Bearer <TOKEN>
```

Create and manage Access Tokens in your [account settings](https://vercel.com/account/tokens).

## Creating Access Tokens

1. Go to your Vercel dashboard
2. Navigate to Account Settings
3. Select "Tokens" from the sidebar
4. Click "Create Token"
5. Give your token a name and select the appropriate scope
6. Copy the token (you won't be able to see it again)

## Using Access Tokens

Include the token in the Authorization header of your API requests:

```bash
curl -H "Authorization: Bearer <TOKEN>" https://api.vercel.com/v6/deployments
```

## Token Security

- Never commit tokens to version control
- Use environment variables to store tokens
- Rotate tokens regularly
- Delete tokens that are no longer needed### Production Deployment

Deployment

Domains

Status

Created

Source
