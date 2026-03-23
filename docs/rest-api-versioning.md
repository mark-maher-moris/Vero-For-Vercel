# REST API Versioning

The Vercel REST API is versioned to ensure backward compatibility while allowing for new features and improvements.

## API Versions

The current API version is v6. Different endpoints may have different version requirements. Check the specific endpoint documentation for version requirements.

## Version in URL

Include the version in the API URL:

```
https://api.vercel.com/v6/deployments
```

## Breaking Changes

When breaking changes are introduced, a new API version is released. Older versions are supported for a reasonable deprecation period.

## Migration

When migrating to a new API version:

1. Review the changelog for breaking changes
2. Update your API calls to use the new version
3. Test thoroughly before deploying to production
4. Monitor for any errors or unexpected behavior

## Deprecation Policy

Vercel maintains deprecated API versions for at least 6 months after announcing deprecation.### Production Deployment

Deployment

Domains

Status

Created

Source
