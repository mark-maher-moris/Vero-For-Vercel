# Vercel Storage Overview

Vercel offers a suite of managed, serverless storage products that integrate with your frontend framework:

- [Vercel Blob](https://vercel.com/docs/vercel-blob): Large file storage for images, videos, and other static assets
- [Vercel Edge Config](https://vercel.com/docs/edge-config): Global, low-latency data store for configuration and feature flags
- [Vercel Marketplace](https://vercel.com/docs/marketplace-storage): Find Postgres, KV, NoSQL, and other databases from providers like Neon, Upstash, and AWS

## Choosing a Storage Product

- **Vercel Blob**: Best for storing files like images, videos, PDFs
- **Edge Config**: Best for configuration data, feature flags, A/B testing
- **Marketplace**: Best for structured data, relational databases, caching

## Best Practices

- Locate your data close to your functions
- Optimize for high cache hit rates
- Use appropriate storage for your data type
