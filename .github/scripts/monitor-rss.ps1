param(
    [Parameter(Mandatory = $true)]
    [string]$GitHubToken,
    
    [Parameter(Mandatory = $true)]
    [string]$Repository
)

function New-GitHubIssue {
    param(
        [string]$Title,
        [string]$Body,
        [string]$Token,
        [string]$Repo
    )
    
    $issueData = @{
        title     = $Title
        body      = $Body
        assignees = @()
        labels    = @('rss-feed', 'content-request')
    } | ConvertTo-Json -Depth 3
    
    $headers = @{
        'Authorization' = "token $Token"
        'Accept'        = 'application/vnd.github.v3+json'
        'Content-Type'  = 'application/json'
    }
    
    $uri = "https://api.github.com/repos/$Repo/issues"
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $issueData
        return $response
    }
    catch {
        Write-Host "Failed to create issue: $_"
        throw
    }
}

function Get-SanitizedFilename {
    param([string]$Title)
    
    return $Title.ToLower() -replace '[^a-z0-9\s-]', '' -replace '\s+', '-' -replace '-+', '-'
}

try {
    Write-Host "Starting RSS Feed Monitor..."
    
    # Read RSS feeds configuration
    $feedsConfigPath = "$PSScriptRoot/../rss-feeds.json"
    if (-not (Test-Path $feedsConfigPath)) {
        Write-Host "RSS feeds configuration file not found: $feedsConfigPath"
        exit 1
    }
    
    $feedsConfig = Get-Content $feedsConfigPath | ConvertFrom-Json
    
    foreach ($feedConfig in $feedsConfig) {
        Write-Host "Processing feed: $($feedConfig.name)"
        
        try {
            # Fetch RSS feed
            $items = Invoke-RestMethod -Uri $feedConfig.url -Method Get
            
            Write-Host "Found $($items.Count) items in feed: $($feedConfig.name)"
            
            # Get latest 3 items
            $latestItems = $items | Where-Object { (((Get-Date) - ([datetime] $_.pubDate)).Days -le 1) }

            Write-Host "Found $($latestItems.Count) likely new items"
            
            foreach ($item in $latestItems) {
                # Parse publication date
                $pubDate = $null
                if ($item.pubDate) {
                    $pubDate = [datetime]$item.pubDate
                }
                elseif ($item.published) {
                    $pubDate = [datetime]$item.published
                }
                else {
                    Write-Host "No publication date found for item: $($item.title)"
                    continue
                }
                
                $title = if ($item.title.'#text') { $item.title.'#text' } else { $item.title }
                $link = if ($item.link.href) { $item.link.href } else { $item.link }
                $pubDate = $pubDate
                $description = if ($item.description) { $item.description } else { $item.summary }
                $author = if ($item.author) { $item.author } else { $item.'dc:creator' }
                $tags = if ($item.category) { $item.category } else { @() }

                $filename = "$($pubDate.ToString('yyyy-MM-dd'))-$(Get-SanitizedFilename $itemObj.title).md"

                # Create issue
                $issueTitle = "New $($feedConfig.name) post: $($itemObj.title)"
                $issueBody = @"
**New post detected in $($feedConfig.name) feed:**
Please create a new markdown file called ``$($filename)`` in the ``_news`` directory with the front-matter below. 
To create the contents below the file, fetch the canonical_url from the link provided and use the content of that page to create a summary with a maximum length of 500 characters.
Make sure the most important information of the summary is included in the first 200 characters. Place a <!--excerpt_end--> after the first 200 characters to separate the excerpt from the rest of the summary. 
Below the summary, add a link to the original post.

**Front-Matter:**
``````markdown
layout: "post"
title: "$($title -replace '"', '\"')"
author: "$author"
description: "$($description -replace '"', '\"')..."
excerpt_separator: <!--excerpt_end-->
canonical_url: "$($link)"
tags: "$tags"
``````

"@
                    
                try {
                    #$issue = New-GitHubIssue -Title $issueTitle -Body $issueBody -Token $GitHubToken -Repo $Repository
                    Write-Host "Created issue #$($issue.number) for: $($itemObj.title)"
                }
                catch {
                    Write-Host "Failed to create issue for $($itemObj.title): $_"
                }
            }
        }
        catch {
            Write-Host "Failed to process feed $($feedConfig.name): $_"
        }
    }
    
    Write-Host "RSS Feed Monitor completed successfully"
}
catch {
    Write-Host "RSS Feed Monitor failed: $_"
    exit 1
}
