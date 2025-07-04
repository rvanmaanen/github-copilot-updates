# $headers = @{
#     "Content-Type" = "application/json"
#     "Authorization" = "Bearer "
# }

# $body = Get-Content "C:\Projects\github-copilot-updates\.github\scripts\request.json" -Raw

# do {
# $response = Invoke-RestMethod -Uri "https://models.github.ai/inference/chat/completions" `
#                               -Method Post `
#                               -Headers $headers `
#                               -Body $body

#                               $response.choices[0].message.content
#                               sleep 1
# } while($true)

function Get-RSSFeed {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url
    )
    
    try {
        # Download the RSS feed
        $rssContent = Invoke-RestMethod -Uri $Url -Method Get
        
        # Initialize array to store feed items
        $feedItems = @()
        
        # Parse each item in the RSS feed
        foreach ($item in $rssContent.rss.channel.item) {
            # Handle categories - convert to space-separated string
            $categories = ""
            if ($item.category) {
                if ($item.category -is [array]) {
                    $categories = $item.category -join " "
                } else {
                    $categories = $item.category
                }
            }
            
            # Handle author field (could be in different XML elements)
            $author = ""
            if ($item.author) {
                $author = $item.author
            } elseif ($item.'dc:creator') {
                $author = $item.'dc:creator'
            } elseif ($item.creator) {
                $author = $item.creator
            }
            
            # Handle description (could be description or content:encoded)
            $description = ""
            if ($item.description) {
                $description = $item.description
            } elseif ($item.'content:encoded') {
                $description = $item.'content:encoded'
            }
            
            # Handle date parsing
            $date = $null
            if ($item.pubDate) {
                try {
                    $date = [DateTime]::Parse($item.pubDate)
                } catch {
                    $date = $item.pubDate
                }
            }
            
            # Handle URL (could be link or guid)
            $url = ""
            if ($item.link) {
                $url = $item.link
            } elseif ($item.guid -and $item.guid.'#text') {
                $url = $item.guid.'#text'
            } elseif ($item.guid) {
                $url = $item.guid
            }
            
            # Create custom object for this feed item
            $feedItem = [PSCustomObject]@{
                Author = $author
                Title = $item.title
                Description = $description
                Date = $date
                Categories = $categories
                Url = $url
            }
            
            $feedItems += $feedItem
        }
        
        return $feedItems
    }
    catch {
        Write-Error "Failed to parse RSS feed from $Url. Error: $($_.Exception.Message)"
        return @()
    }
}

Get-RSSFeed -Url "https://github.blog/feed/"