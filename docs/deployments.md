# Deployments

Deployments on Vercel are the result of building and uploading your project. Each deployment gets:

- A unique URL for preview and testing
- Automatic HTTPS with SSL certificate
- Edge network distribution
- Support for serverless functions

## Deployment Types

- **Production**: Live site with custom domain
- **Preview**: Every push gets a unique preview URL
- **Development**: Local development with `vercel dev`

## Deployment Process

1. Push code to Git repository
2. Vercel detects changes and triggers build
3. Build completes and assets are uploaded
4. Deployment is distributed to edge network
5. Preview URL is generated

## Deployment Features

- **Instant Rollback**: Revert to previous deployments
- **Branch Previews**: Test changes before merging
- **Deployment Protection**: Password protection, SSO
- **Git Integration**: Deploy from GitHub, GitLab, Bitbucket
