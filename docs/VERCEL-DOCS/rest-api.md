# Using the REST API

Interact programmatically with your Vercel account using the SDK or direct HTTP requests. You can deploy new versions of web applications, manage custom domains, retrieve information about deployments, and manage secrets and environment variables for projects.

The API supports any programming language or framework that can send HTTP requests.

## API basics

The API is exposed as an HTTP/1 and HTTP/2 service over SSL. All endpoints live under the URL https://api.vercel.com and follow the REST architecture.

```
https://api.vercel.com
```

## Authentication

Vercel Access Tokens are required to authenticate and use the Vercel API. Include the token in the Authorization header:

```
Authorization: Bearer <TOKEN>
```

Create and manage Access Tokens in your [account settings](https://vercel.com/account/tokens).

## Accessing team resources

By default, you can access resources in your personal account. To access resources owned by a team, append the Team ID as a query string:

```
https://api.vercel.com/v6/deployments?teamId=[teamID]
```

## Rate limits

The API limits the number of calls you can make over a period of time. Rate limits are specified via response headers: X-RateLimit-Limit, X-RateLimit-Remaining, and X-RateLimit-Reset. See the [limits documentation](https://vercel.com/docs/limits) for details.

## Endpoints

Browse all available REST API endpoints grouped by category.

- [Access-groups - 11 endpoints](https://vercel.com/docs/rest-api/access-groups/reads-an-access-group)
- [Aliases - 6 endpoints](https://vercel.com/docs/rest-api/aliases/list-deployment-aliases)
- [Artifacts - 6 endpoints](https://vercel.com/docs/rest-api/artifacts/record-an-artifacts-cache-usage-event)
- [Authentication - 5 endpoints](https://vercel.com/docs/rest-api/authentication/sso-token-exchange)
- [Billing - 3 endpoints](https://vercel.com/docs/rest-api/billing/list-focus-billing-charges)
- [Bulk-redirects - 7 endpoints](https://vercel.com/docs/rest-api/bulk-redirects/gets-project-level-redirects)
- [Certs - 4 endpoints](https://vercel.com/docs/rest-api/certs/get-cert-by-id)
- [Checks-v2 - 10 endpoints](https://vercel.com/docs/rest-api/checks-v2/list-all-checks-for-a-project)
- [Connect - 6 endpoints](https://vercel.com/docs/rest-api/connect/list-secure-compute-networks)
- [Deployments - 10 endpoints](https://vercel.com/docs/rest-api/deployments/get-deployment-events)
- [DNS - 4 endpoints](https://vercel.com/docs/rest-api/dns/list-existing-dns-records)
- [Domains - 6 endpoints](https://vercel.com/docs/rest-api/domains/get-a-domain-s-configuration)
- [Domains-registrar - 16 endpoints](https://vercel.com/docs/rest-api/domains-registrar/get-supported-tlds)
- [Drains - 6 endpoints](https://vercel.com/docs/rest-api/drains/retrieve-a-list-of-all-drains)
- [Edge-cache - 4 endpoints](https://vercel.com/docs/rest-api/edge-cache/invalidate-by-tag)
- [Edge-config - 17 endpoints](https://vercel.com/docs/rest-api/edge-config/get-edge-configs)
- [Environment - 11 endpoints](https://vercel.com/docs/rest-api/environment/lists-all-shared-environment-variables-for-a-team)
- [Feature-flags - 19 endpoints](https://vercel.com/docs/rest-api/feature-flags/list-flags)
- [Integrations - 10 endpoints](https://vercel.com/docs/rest-api/deployments/update-deployment-integration-action)
- [Logs - 1 endpoint](https://vercel.com/docs/rest-api/logs/get-logs-for-a-deployment)
- [Marketplace - 23 endpoints](https://vercel.com/docs/rest-api/marketplace/update-installation)
- [Project-routes - 8 endpoints](https://vercel.com/docs/rest-api/project-routes/get-project-routing-rules)
- [Projectmembers - 3 endpoints](https://vercel.com/docs/rest-api/projectmembers/list-project-members)
- [Projects - 27 endpoints](https://vercel.com/docs/rest-api/projects/retrieve-a-list-of-projects)
- [Rolling-release - 7 endpoints](https://vercel.com/docs/rest-api/rolling-release/get-rolling-release-billing-status)
- [Sandboxes - 18 endpoints](https://vercel.com/docs/rest-api/sandboxes/list-sandboxes)
- [Security - 9 endpoints](https://vercel.com/docs/rest-api/security/update-attack-challenge-mode)
- [Static-ips - 1 endpoint](https://vercel.com/docs/rest-api/connect/configures-static-ips-for-a-project)
- [Teams - 14 endpoints](https://vercel.com/docs/rest-api/teams/list-team-members)
- [User - 4 endpoints](https://vercel.com/docs/rest-api/user/list-user-events)
- [Webhooks - 4 endpoints](https://vercel.com/docs/rest-api/webhooks/get-a-list-of-webhooks)
