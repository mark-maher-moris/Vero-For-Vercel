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

## Available Endpoints

### Access Groups (11 endpoints)
Manage team access groups

### Aliases (6 endpoints)
Configure deployment aliases

### Artifacts (6 endpoints)
Handle build artifacts and caching

### Authentication (5 endpoints)
SSO and authentication flows

### Billing (3 endpoints)
Billing and invoice information

### Bulk Redirects (7 endpoints)
Project-level redirect rules

### Certs (4 endpoints)
SSL certificate management

### Checks v2 (10 endpoints)
Deployment checks and status

### Connect (6 endpoints)
Secure compute networks

### Deployments (10 endpoints)
Create and manage deployments

### DNS (4 endpoints)
DNS record management

### Domains (6 endpoints)
Domain configuration

### Domains Registrar (16 endpoints)
Domain registration operations

### Drains (6 endpoints)
Log drain configuration

### Edge Cache (4 endpoints)
Cache invalidation

### Edge Config (17 endpoints)
Edge configuration management

### Environment (11 endpoints)
Environment variables

### Feature Flags (19 endpoints)
Feature flag management

### Integrations (10 endpoints)
Third-party integrations

### Logs (1 endpoint)
Deployment logs

### Marketplace (23 endpoints)
Integration marketplace

### Project Routes (8 endpoints)
Routing configuration

### Project Members (3 endpoints)
Team member management

### Projects (27 endpoints)
Project operations

### Rolling Release (7 endpoints)
Release management

### Sandboxes (18 endpoints)
Sandbox environments

### Security (9 endpoints)
Security settings

### Static IPs (1 endpoint)
Static IP configuration

### Teams (14 endpoints)
Team management

### User (4 endpoints)
User information

### Webhooks (4 endpoints)
Webhook configuration
