# REST API Quickstart

Get started with the Vercel REST API in minutes.

## Prerequisites

- A Vercel account
- An Access Token from your [account settings](https://vercel.com/account/tokens)

## Make Your First Request

```bash
curl -H "Authorization: Bearer <TOKEN>" \
  https://api.vercel.com/v6/deployments
```

## SDKs

Vercel provides official SDKs for popular languages:

- [Node.js](https://www.npmjs.com/package/vercel)
- [Python](https://github.com/vercel/vercel-python-sdk)

## Next Steps

- Explore the [API Reference](https://vercel.com/docs/rest-api/endpoints)
- Learn about [Authentication](https://vercel.com/docs/rest-api/authentication)
- Understand [API Versioning](https://vercel.com/docs/rest-api/versioning)

# REST API Endpoints

The Vercel REST API provides endpoints for managing deployments, domains, projects, and more.

## Base URL

```
https://api.vercel.com
```

## Endpoint Categories

- **Deployments**: Create, list, and manage deployments
- **Projects**: Manage project settings and configuration
- **Domains**: Configure custom domains
- **Teams**: Manage team members and settings
- **User**: Access user information

## Authentication

All endpoints require authentication via Bearer token:

```
Authorization: Bearer <TOKEN>
```

## Rate Limits

The API has rate limits that vary by endpoint. Check the `X-RateLimit-*` headers in responses.

### Production Deployment

Deployment

Domains

Status

Created

Source
