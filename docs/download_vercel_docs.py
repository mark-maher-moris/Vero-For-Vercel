#!/usr/bin/env python3
"""
Vercel Docs Downloader - Enhanced Version

This script downloads documentation from Vercel's docs site using Playwright
to handle client-side rendered content.

Usage:
    python download_vercel_docs.py [--output-dir docs] [--rate-limit 1]
"""

import argparse
import json
import re
import sys
import time
from pathlib import Path
from typing import Dict, List, Set
from urllib.parse import urljoin, urlparse

try:
    from playwright.sync_api import sync_playwright, Page
except ImportError:
    print("Error: Playwright not found.")
    print("Please install it with: pip3 install playwright")
    print("Then run: playwright install chromium")
    sys.exit(1)

# Base URLs for Vercel docs
VERCEL_DOCS_BASE = "https://vercel.com/docs"

# Common Vercel docs paths to scrape
VERCEL_DOC_PATHS = [
    # Sign in with Vercel
    "/sign-in-with-vercel",
    "/sign-in-with-vercel/getting-started",
    "/sign-in-with-vercel/tokens",
    "/sign-in-with-vercel/scopes-and-permissions",
    "/sign-in-with-vercel/authorization-server-api",
    "/sign-in-with-vercel/manage-from-dashboard",
    "/sign-in-with-vercel/consent-page",
    "/sign-in-with-vercel/troubleshooting",
    
    # REST API
    "/rest-api",
    "/rest-api/quickstart",
    "/rest-api/endpoints",
    "/rest-api/authentication",
    "/rest-api/versioning",
    
    # General docs
    "/accounts",
    "/projects",
    "/deployments",
    "/domains",
    "/integrations",
    "/cli",
    "/concepts",
    "/frameworks",
    "/functions",
    "/edge-network",
    "/storage",
    "/analytics",
    "/speed-insights",
]


class VercelDocsDownloader:
    def __init__(self, output_dir: str = "docs", rate_limit: float = 2.0):
        self.output_dir = Path(output_dir)
        self.rate_limit = rate_limit
        self.downloaded: Set[str] = set()
        self.playwright = None
        self.browser = None
        
    def _get_filename_from_url(self, url: str) -> str:
        """Generate filename from URL."""
        parsed = urlparse(url)
        path = parsed.path.strip('/')
        
        if not path:
            return "index.md"
        
        # Replace slashes with hyphens for nested paths
        filename = path.replace('/', '-') + ".md"
        return filename
    
    def _extract_markdown_from_page(self, page: Page, url: str) -> str:
        """Extract markdown content from a rendered page."""
        # Wait for the main content to load
        try:
            # Try different selectors for main content
            selectors = [
                'main article',
                'main',
                '[data-testid="docs-content"]',
                'article',
                '.prose',
                '.content'
            ]
            
            for selector in selectors:
                try:
                    page.wait_for_selector(selector, timeout=5000)
                    break
                except:
                    continue
            
            # Give extra time for dynamic content
            time.sleep(2)
            
        except Exception:
            pass
        
        # Extract content using JavaScript
        content = page.evaluate("""
            () => {
                // Try to find the main content area
                const selectors = [
                    'main article',
                    'main',
                    '[data-testid="docs-content"]',
                    'article',
                    '.prose',
                    '.content',
                    'body'
                ];
                
                let container = null;
                for (const sel of selectors) {
                    container = document.querySelector(sel);
                    if (container) break;
                }
                
                if (!container) return '';
                
                // Get all text content with structure
                let markdown = '';
                
                function processNode(node, depth = 0) {
                    if (node.nodeType === Node.TEXT_NODE) {
                        const text = node.textContent.trim();
                        if (text) return text;
                        return '';
                    }
                    
                    if (node.nodeType !== Node.ELEMENT_NODE) return '';
                    
                    const tag = node.tagName.toLowerCase();
                    let result = '';
                    
                    // Skip navigation, header, footer elements
                    if (['nav', 'header', 'footer', 'script', 'style', 'aside'].includes(tag)) {
                        return '';
                    }
                    
                    // Process based on tag
                    switch(tag) {
                        case 'h1':
                            const h1Text = node.innerText.trim();
                            if (h1Text) result = '# ' + h1Text + '\\n\\n';
                            break;
                        case 'h2':
                            const h2Text = node.innerText.trim();
                            if (h2Text) result = '## ' + h2Text + '\\n\\n';
                            break;
                        case 'h3':
                            const h3Text = node.innerText.trim();
                            if (h3Text) result = '### ' + h3Text + '\\n\\n';
                            break;
                        case 'h4':
                            const h4Text = node.innerText.trim();
                            if (h4Text) result = '#### ' + h4Text + '\\n\\n';
                            break;
                        case 'p':
                            const pText = node.innerText.trim();
                            if (pText) result = pText + '\\n\\n';
                            break;
                        case 'pre':
                            const code = node.innerText.trim();
                            if (code) result = '```\\n' + code + '\\n```\\n\\n';
                            break;
                        case 'code':
                            if (node.parentElement.tagName.toLowerCase() !== 'pre') {
                                const codeText = node.innerText.trim();
                                if (codeText) result = '`' + codeText + '`';
                            }
                            break;
                        case 'ul':
                        case 'ol':
                            for (const li of node.querySelectorAll(':scope > li')) {
                                const liText = li.innerText.trim();
                                if (liText) result += '- ' + liText + '\\n';
                            }
                            result += '\\n';
                            break;
                        case 'a':
                            const href = node.getAttribute('href');
                            const aText = node.innerText.trim();
                            if (href && aText && !href.startsWith('javascript:')) {
                                result = '[' + aText + '](' + href + ')';
                            } else if (aText) {
                                result = aText;
                            }
                            break;
                        default:
                            // Process children
                            for (const child of node.childNodes) {
                                result += processNode(child, depth + 1);
                            }
                    }
                    
                    return result;
                }
                
                // Process the container
                for (const child of container.childNodes) {
                    markdown += processNode(child);
                }
                
                return markdown;
            }
        """)
        
        return content or ""
    
    def _clean_markdown(self, content: str) -> str:
        """Clean up extracted markdown."""
        # Remove excessive newlines
        content = re.sub(r'\n{4,}', '\n\n\n', content)
        # Remove trailing whitespace
        content = re.sub(r' +\n', '\n', content)
        # Clean up code blocks
        content = re.sub(r'```\n\n+', '```\n', content)
        content = re.sub(r'\n\n+```', '\n```', content)
        return content.strip()
    
    def download_page(self, url: str, page: Page) -> bool:
        """Download a single page and save as markdown."""
        if url in self.downloaded:
            return True
        
        print(f"Downloading: {url}")
        
        try:
            page.goto(url, wait_until='networkidle', timeout=30000)
            
            # Wait for content to be fully rendered
            page.wait_for_load_state('domcontentloaded')
            time.sleep(3)  # Extra wait for any dynamic content
            
            # Extract content
            content = self._extract_markdown_from_page(page, url)
            content = self._clean_markdown(content)
            
            if not content or len(content) < 100:
                print(f"  Warning: Limited content extracted ({len(content)} chars)")
            
            # Generate filename
            filename = self._get_filename_from_url(url)
            filepath = self.output_dir / filename
            
            # Add source URL as comment at top
            full_content = f"<!-- Source: {url} -->\n\n{content}"
            
            filepath.write_text(full_content, encoding='utf-8')
            print(f"  Saved to: {filepath} ({len(content)} chars)")
            
            self.downloaded.add(url)
            
            # Rate limiting
            if self.rate_limit > 0:
                time.sleep(self.rate_limit)
            
            return True
            
        except Exception as e:
            print(f"  Error downloading {url}: {e}")
            return False
    
    def download_all(self, paths: List[str] = None) -> Dict[str, bool]:
        """Download all docs using Playwright."""
        if paths is None:
            paths = VERCEL_DOC_PATHS
        
        self.output_dir.mkdir(parents=True, exist_ok=True)
        results = {}
        
        with sync_playwright() as p:
            self.browser = p.chromium.launch(headless=True)
            context = self.browser.new_context(
                user_agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
            )
            page = context.new_page()
            
            try:
                for path in paths:
                    url = urljoin(VERCEL_DOCS_BASE, path)
                    success = self.download_page(url, page)
                    results[path] = success
            finally:
                context.close()
                self.browser.close()
        
        return results


def main():
    parser = argparse.ArgumentParser(
        description="Download Vercel documentation as Markdown files using Playwright"
    )
    parser.add_argument(
        "--output-dir", "-o",
        default="docs",
        help="Output directory for downloaded docs (default: docs)"
    )
    parser.add_argument(
        "--rate-limit", "-r",
        type=float,
        default=2.0,
        help="Seconds between requests (default: 2.0)"
    )
    
    args = parser.parse_args()
    
    downloader = VercelDocsDownloader(
        output_dir=args.output_dir,
        rate_limit=args.rate_limit
    )
    
    print(f"Vercel Docs Downloader (Playwright Edition)")
    print(f"Output directory: {args.output_dir}")
    print(f"Rate limit: {args.rate_limit}s")
    print("-" * 50)
    
    results = downloader.download_all()
    
    print("-" * 50)
    print(f"Downloaded {len(downloader.downloaded)} pages")
    print(f"Success: {sum(1 for v in results.values() if v)}")
    print(f"Failed: {sum(1 for v in results.values() if not v)}")
    
    # Save summary
    summary_file = Path(args.output_dir) / "_download_summary.json"
    with open(summary_file, 'w') as f:
        json.dump({
            "total": len(results),
            "successful": sum(1 for v in results.values() if v),
            "failed": sum(1 for v in results.values() if not v),
            "results": results
        }, f, indent=2)
    print(f"Summary saved to: {summary_file}")


if __name__ == "__main__":
    main()
