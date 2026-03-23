# Vercel Functions

Vercel Functions let you run server-side code without managing servers. They adapt automatically to user demand, handle connections to APIs and databases, and offer enhanced concurrency through [fluid compute](https://vercel.com/docs/fluid-compute). This makes them well suited for AI workloads or any I/O-bound tasks that require efficient scaling.

When you deploy your application, Vercel automatically sets up the tools and optimizations for your chosen framework. It ensures low latency by routing traffic through Vercel's CDN, and placing your functions in a specific region when you need more control over [data locality](https://vercel.com/docs/functions).

## Key Features

- **Serverless**: No server management required
- **Auto-scaling**: Automatically scales with demand
- **Edge-deployed**: Runs close to your users for low latency
- **Framework-agnostic**: Works with Next.js, Astro, SvelteKit, and more

## Use Cases

- API endpoints
- AI/ML inference
- Database queries
- Authentication
- Webhooks
