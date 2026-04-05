# Domains on Vercel

Vercel provides built-in domain management for your projects. You can use Vercel's free `vercel.app` domains or add your own custom domains.

## Custom Domains

To add a custom domain:
1. Go to your project dashboard
2. Navigate to Settings > Domains
3. Enter your domain and click Add
4. Configure DNS records as instructed

## Features

- **Automatic HTTPS**: SSL certificates are provisioned automatically
- **Branch Previews**: Each deployment gets a unique preview URL
- **Wildcard Domains**: Support for `*.yourdomain.com`
- **Transfer Tool**: Easily transfer domains between projects

## Domain Configuration

- **A Record**: Point to `76.76.21.21`
- **CNAME Record**: For subdomains, point to `cname.vercel-dns.com`

## DNS

Vercel offers managed DNS for domains purchased through Vercel or transferred to Vercel.
