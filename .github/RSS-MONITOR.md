# RSS Feed Monitor

This GitHub workflow automatically monitors RSS feeds and creates GitHub issues requesting new blog posts to be added to the Jekyll site.

## How it works

1. **Scheduled Execution**: Runs daily at 8:00 AM UTC
2. **Manual Trigger**: Can be triggered manually via GitHub Actions
3. **RSS Parsing**: Fetches the latest 3 entries from each configured RSS feed
4. **Issue Creation**: Creates GitHub issues for recent posts (published within the last 7 days)
5. **Content Template**: Generates a markdown template following the site's post structure

## Configuration

Edit `.github/rss-feeds.json` to add or modify RSS feeds:

```json
[
  {
    "name": "GitHub Blog",
    "url": "https://github.blog/feed/",
    "category": "GitHub"
  },
  {
    "name": "VS Code Blog", 
    "url": "https://code.visualstudio.com/feed.xml",
    "category": "VSCode"
  }
]
```

### RSS Feed Object Properties

- `name`: Human-readable name for the feed
- `url`: RSS/Atom feed URL
- `category`: Category tag for organizing content

## Generated Issues

Each issue includes:

- **Title**: "New [Feed Name] post: [Article Title]"
- **Assignee**: @copilot
- **Labels**: `rss-feed`, `content-request`
- **Body**:
  - Feed metadata
  - Suggested filename and frontmatter
  - Complete markdown template
  - Link to original article

## Post Template Structure

Generated posts follow this structure:

```markdown
---
layout: "post"
title: "[Article Title]"
author: "[Author or Feed Name]"
description: "[Article excerpt]..."
excerpt_separator: <!--excerpt_end-->
canonical_url: "[Original URL]"
---

[Article content]<!--excerpt_end-->

[Read the full article]([Original URL])
```

## File Naming Convention

Posts are named: `YYYY-MM-DD-[sanitized-title].md`

Example: `2025-07-01-new-github-copilot-features.md`

## Workflow Permissions

The workflow requires:

- `issues: write` - To create GitHub issues
- `contents: read` - To read repository files

## Customization

To modify the workflow behavior:

1. **Frequency**: Edit the cron schedule in `.github/workflows/rss-monitor.yml`
2. **Item Count**: Change `slice(0, 3)` to fetch more/fewer items
3. **Time Window**: Modify `daysDiff <= 7` to change the recency filter
4. **Issue Template**: Edit the `issueBody` template in the workflow
5. **Post Template**: Modify the `generateMarkdownTemplate` function

## Manual Execution

To run the workflow manually:

1. Go to Actions tab in GitHub
2. Select "RSS Feed Monitor"
3. Click "Run workflow"
4. Click "Run workflow" button

## Troubleshooting

- **No issues created**: Check if RSS feeds are accessible and contain recent posts
- **Permission errors**: Ensure the workflow has proper permissions
- **Invalid feeds**: Verify RSS/Atom feed URLs are correct and accessible
