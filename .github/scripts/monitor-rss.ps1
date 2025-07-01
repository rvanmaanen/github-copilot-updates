param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    
    [Parameter(Mandatory=$true)]
    [string]$Repository
)

# Function to create GitHub issue
function New-GitHubIssue {
    param(
        [string]$Title,
        [string]$Body,
        [string]$Token,
        [string]$Repo
    )
    
    $issueData = @{
        title = $Title
        body = $Body
        assignees = @('copilot')
        labels = @('rss-feed', 'content-request')
    } | ConvertTo-Json -Depth 3
    
    $headers = @{
        'Authorization' = "token $Token"
        'Accept' = 'application/vnd.github.v3+json'
        'Content-Type' = 'application/json'
    }
    
    $uri = "https://api.github.com/repos/$Repo/issues"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $issueData
        return $response
    }
    catch {
        Write-Error "Failed to create issue: $_"
        throw
    }
}

# Function to sanitize filename
function Get-SanitizedFilename {
    param([string]$Title)
    
    return $Title.ToLower() -replace '[^a-z0-9\s-]', '' -replace '\s+', '-' -replace '-+', '-'
}

# Function to format date
function Get-FormattedDate {
    param([datetime]$Date)
    
    return $Date.ToString('yyyy-MM-dd')
}

# Function to generate markdown template
function New-MarkdownTemplate {
    param(
        [object]$Item,
        [string]$FeedName,
        [string]$Category
    )
    
    $publishDate = [datetime]$Item.pubDate
    $filename = "$(Get-FormattedDate $publishDate)-$(Get-SanitizedFilename $Item.title).md"
    
    $description = if ($Item.contentSnippet) { 
        $Item.contentSnippet.Substring(0, [Math]::Min(200, $Item.contentSnippet.Length))
    } elseif ($Item.content) {
        $Item.content.Substring(0, [Math]::Min(200, $Item.content.Length))
    } else { 
        $Item.title 
    }
    
    $author = if ($Item.creator) { $Item.creator } else { $FeedName }
    
    $frontMatter = @"
---
layout: "post"
title: "$($Item.title -replace '"', '\"')"
author: "$author"
description: "$($description -replace '"', '\"')..."
excerpt_separator: <!--excerpt_end-->
canonical_url: "$($Item.link)"
---
"@
    
    $contentBody = if ($Item.contentSnippet) { $Item.contentSnippet } elseif ($Item.content) { $Item.content } else { $Item.title }
    $content = "$contentBody<!--excerpt_end-->`n`n[Read the full article]($($Item.link))"
    
    return @{
        filename = $filename
        content = "$frontMatter`n`n$content"
    }
}

# Main execution
try {
    Write-Host "Starting RSS Feed Monitor..."
    
    # Read RSS feeds configuration
    $feedsConfigPath = ".github/rss-feeds.json"
    if (-not (Test-Path $feedsConfigPath)) {
        Write-Error "RSS feeds configuration file not found: $feedsConfigPath"
        exit 1
    }
    
    $feedsConfig = Get-Content $feedsConfigPath | ConvertFrom-Json
    
    foreach ($feedConfig in $feedsConfig) {
        Write-Host "Processing feed: $($feedConfig.name)"
        
        try {
            # Fetch RSS feed
            $response = Invoke-RestMethod -Uri $feedConfig.url -Method Get
            
            # Parse XML if needed (some feeds return XML directly)
            if ($response -is [string]) {
                $response = [xml]$response
            }
            
            # Extract items from RSS feed
            $items = @()
            if ($response.rss.channel.item) {
                $items = $response.rss.channel.item
            } elseif ($response.feed.entry) {
                # Atom feed
                $items = $response.feed.entry
            }

            Write-Information "Found $($items.Count) items in feed: $($feedConfig.name)"
            
            # Get latest 3 items
            $latestItems = $items | Select-Object -First 3
            
            foreach ($item in $latestItems) {
                # Parse publication date
                $pubDate = $null
                if ($item.pubDate) {
                    $pubDate = [datetime]$item.pubDate
                } elseif ($item.published) {
                    $pubDate = [datetime]$item.published
                } else {
                    Write-Warning "No publication date found for item: $($item.title)"
                    continue
                }
                
                $today = Get-Date
                $daysDiff = ($today - $pubDate).Days
                
                # Only process items published within the last 7 days
                if ($daysDiff -le 7) {
                    # Create markdown template
                    $itemObj = @{
                        title = if ($item.title.'#text') { $item.title.'#text' } else { $item.title }
                        link = if ($item.link.href) { $item.link.href } else { $item.link }
                        pubDate = $pubDate
                        contentSnippet = if ($item.description) { $item.description } else { $item.summary }
                        content = if ($item.description) { $item.description } else { $item.summary }
                        creator = if ($item.author) { $item.author } else { $item.'dc:creator' }
                    }
                    
                    $template = New-MarkdownTemplate -Item $itemObj -FeedName $feedConfig.name -Category $feedConfig.category
                    
                    # Create issue
                    $issueTitle = "New $($feedConfig.name) post: $($itemObj.title)"
                    $issueBody = @"
## New RSS Feed Item Request

**Feed:** $($feedConfig.name)
**Category:** $($feedConfig.category)
**Published:** $($pubDate.ToString('yyyy-MM-dd HH:mm:ss'))
**Link:** $($itemObj.link)

### Requested Action
Please create a new markdown file in the ``_posts`` directory with the following content:

**Filename:** ``_posts/$($template.filename)``

**Content:**
````markdown
$($template.content)
````

### Original Description
$($itemObj.contentSnippet)

---
*This issue was automatically created by the RSS Feed Monitor workflow.*
"@
                    
                    try {
                        $issue = New-GitHubIssue -Title $issueTitle -Body $issueBody -Token $GitHubToken -Repo $Repository
                        Write-Host "Created issue #$($issue.number) for: $($itemObj.title)"
                    }
                    catch {
                        Write-Error "Failed to create issue for $($itemObj.title): $_"
                    }
                }
                else {
                    Write-Host "Skipping $($item.title) (published $daysDiff days ago)"
                }
            }
        }
        catch {
            Write-Error "Failed to process feed $($feedConfig.name): $_"
        }
    }
    
    Write-Host "RSS Feed Monitor completed successfully"
}
catch {
    Write-Error "RSS Feed Monitor failed: $_"
    exit 1
}
