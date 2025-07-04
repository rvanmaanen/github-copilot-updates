$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Invoke-ChatCompletion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Token,
        [Parameter(Mandatory = $true)]
        [string]$Model,
        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    $headers = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $Token"
    }

    $body = @{
        "model"    = $Model
        "messages" = @(
            @{
                "role"    = "system"
                "content" = "You are an assistant for a website that aggregates articles about software development for a news website. You will receive a description of an article and you need to right a short summary of that description. Make sure to include the author's name in that summary. The summary should not be more than 200 characters long."
            },
            @{
                "role"    = "user"
                "content" = $Description
            }
        )
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri "https://models.github.ai/inference/chat/completions" `
        -Method Post `
        -Headers $headers `
        -Body $body

    return $response.choices[0].message.content
}

function Get-SanitizedFilename {
    param([string]$Title)
    
    return $Title -replace '[^A-Za-z0-9\s-]', '' -replace '\s+', '-' -replace '-+', '-'
}

function Get-PropertyValue {
    param(
        [object]$Object,
        [string]$PropertyPath
    )
    
    if ($null -eq $Object) {
        return $null
    }
    
    # Split the property path and get the first property
    $properties = $PropertyPath -split '\.', 2
    $currentProp = $properties[0]
    
    # Check if the current property exists
    if (-not $Object.PSObject.Properties[$currentProp]) {
        return $null
    }
    
    $currentValue = $Object.PSObject.Properties[$currentProp].Value
    
    # If the value is an XmlElement, get its innermost value
    if ($currentValue -is [System.Xml.XmlElement]) {
        if ($currentValue.HasChildNodes) {
            $values = @()
            foreach ($child in $currentValue.ChildNodes) {
                if ($child.NodeType -eq 'Text') {
                    $values += $child.Value
                }
                elseif ($child.NodeType -eq 'Element') {
                    # For nested elements, get their text content
                    $childText = $child.InnerText
                    if ($childText) {
                        $values += $childText
                    }
                }
            }
            if ($values.Count -gt 0) {
                $currentValue = ($values -join ' ').Trim()
            }
            else {
                $currentValue = $currentValue.InnerText
            }
        }
        else {
            $currentValue = $currentValue.InnerText
        }
    }
    
    # If there are more properties in the path, recurse
    if ($properties.Length -gt 1) {
        return Get-PropertyValue $currentValue $properties[1]
    }
    
    # Return the value after cleaning
    if ($currentValue -is [string]) {
        $currentValue = [System.Web.HttpUtility]::HtmlDecode($currentValue)

        if ($currentValue -match '<!\[CDATA\[(.*?)\]\]>') {
            $currentValue = $currentValue -replace '<!\[CDATA\[(.*?)\]\]>', '$1'
        }

        if ($currentValue -match '<.*?>') {
            $currentValue = $currentValue -replace '<.*?>', ''
        }

        $currentValue = $currentValue.Trim()
    }
    return $currentValue
}

  
function Invoke-RssFeedsProcessor {
    param(
        [Parameter(Mandatory = $true)]
        [object]$FeedConfig,
        [Parameter(Mandatory = $true)]
        [string]$Token,
        [Parameter(Mandatory = $true)]
        [string]$Model,
        [Parameter(Mandatory = $false)]
        [switch]$Recreate,
        [Parameter(Mandatory = $true)]
        [string]$OutputDir
    )

    Write-Host "Processing feed: $($feedConfig.name)"
        
    # Fetch RSS feed with retry logic (3 attempts, exponential backoff)
    $maxAttempts = 3
    $attempt = 0
    $success = $false
    $rssData = $null
    while (-not $success -and $attempt -lt $maxAttempts) {
        try {
            $rssData = Invoke-RestMethod -Uri $feedConfig.url -Method Get
            $success = $true
        }
        catch {
            $attempt++
            if ($attempt -lt $maxAttempts) {
                $delay = [math]::Pow(2, $attempt) # 2, 4 seconds
                Write-Host "Attempt $attempt failed. Retrying in $delay seconds..."
                Start-Sleep -Seconds $delay
            }
            else {
                Write-Host "Failed to fetch RSS feed after $maxAttempts attempts: $($feedConfig.url)"
                throw $_
            }
        }
    }
                
    # Convert items to an array that always has the same structure
    $items = @()
        
    # Handle different RSS/Atom feed structures
    if (Get-PropertyValue $rssData 'rss.channel.item') {
        # RSS 2.0 format
        $rawItems = Get-PropertyValue $rssData 'rss.channel.item'
    }
    elseif (Get-PropertyValue $rssData 'feed.entry') {
        # Atom format
        $rawItems = Get-PropertyValue $rssData 'feed.entry'
    }
    elseif (Get-PropertyValue $rssData 'channel.item') {
        # RSS without rss wrapper
        $rawItems = Get-PropertyValue $rssData 'channel.item'
    }
    elseif (Get-PropertyValue $rssData 'item') {
        # Direct items array
        $rawItems = Get-PropertyValue $rssData 'item'
    }
    elseif (Get-PropertyValue $rssData 'entry') {
        # Direct entries array
        $rawItems = Get-PropertyValue $rssData 'entry'
    }
    else {
        # Fallback - try to use the data directly
        $rawItems = $rssData
    }
        
    # Ensure we have an array
    if ($rawItems -isnot [array]) {
        $rawItems = @($rawItems)
    }
        
    # Normalize each item to a consistent structure
    foreach ($rawItem in $rawItems) {
        # Determine title (required)
        $title = Get-PropertyValue $rawItem 'title.#text'
        if (-not $title) {
            $title = Get-PropertyValue $rawItem 'title'
        }
        if (-not $title) {
            throw "No title found for RSS item. Raw item: $($rawItem | ConvertTo-Json -Depth 2)"
        }

        $title = $title -replace '[\r\n]+', ' '
        $title = $title -replace '"', '\''' 
        $title = $title -replace ': ', ' - '
        $title = $title.Trim()
            
        # Determine link (required)
        $link = Get-PropertyValue $rawItem 'link.href'
        if (-not $link) {
            $link = Get-PropertyValue $rawItem 'link'
        }
        if (-not $link) {
            $link = Get-PropertyValue $rawItem 'url'
        }
        if (-not $link) {
            throw "No link found for RSS item '$title'. Raw item: $($rawItem | ConvertTo-Json -Depth 2)"
        }
            
        # Determine publication date (required)
        $pubDateRaw = Get-PropertyValue $rawItem 'pubDate'
        if (-not $pubDateRaw) {
            $pubDateRaw = Get-PropertyValue $rawItem 'published'
        }
        if (-not $pubDateRaw) {
            $pubDateRaw = Get-PropertyValue $rawItem 'updated'
        }
        if (-not $pubDateRaw) {
            $pubDateRaw = Get-PropertyValue $rawItem 'date'
        }
        if (-not $pubDateRaw) {
            throw "No publication date found for RSS item '$title'. Raw item: $($rawItem | ConvertTo-Json -Depth 2)"
        }
            
        # Convert to DateTime during normalization
        try {
            $pubDate = [datetime]$pubDateRaw
        }
        catch {
            throw "Failed to parse publication date '$pubDateRaw' for RSS item '$title'. Error: $($_.Exception.Message)"
        }
            
        # Determine description (required)
        $description = Get-PropertyValue $rawItem 'description.#text'
        if (-not $description) {
            $description = Get-PropertyValue $rawItem 'description'
        }
        if (-not $description) {
            $description = Get-PropertyValue $rawItem 'summary.#text'
        }
        if (-not $description) {
            $description = Get-PropertyValue $rawItem 'summary'
        }
        if (-not $description) {
            $description = Get-PropertyValue $rawItem 'content.#text'
        }
        if (-not $description) {
            $description = Get-PropertyValue $rawItem 'content'
        }
        if (-not $description) {
            throw "No description/summary found for RSS item '$title'. Raw item: $($rawItem | ConvertTo-Json -Depth 2)"
        }

        $description = $description -replace '[\r\n]+', ' '
        $description = $description -replace '"', '\''' 
        $description = $description -replace ': ', ' - '
        $description = $description.Trim()

        # Determine author (required)
        $authorRaw = Get-PropertyValue $rawItem 'creator'
        if (-not $authorRaw) {
            $authorRaw = Get-PropertyValue $rawItem 'author.name'
        }
        if (-not $authorRaw) {
            $authorRaw = Get-PropertyValue $rawItem 'author'
        }
        if (-not $authorRaw) {
            $authorRaw = Get-PropertyValue $rawItem 'dc:creator'
        }
        if (-not $authorRaw) {
            throw "No author found for RSS item '$title'. Raw item: $($rawItem | ConvertTo-Json -Depth 2)"
        }
            
        # Flatten author to space-separated string
        $author = if ($authorRaw -is [array]) {
            ($authorRaw | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.ToString() } }) -join ' '
        }
        elseif ($authorRaw -is [string]) {
            $authorRaw
        }
        else {
            $authorRaw.ToString()
        }
        
        # Remove URLs from author string and clean up spacing
        $author = $author -replace 'https?://[^\s]+', ''  # Remove URLs
        $author = $author -replace '\s+', ' '             # Replace multiple spaces with single space
        $author = $author.Trim()                          # Remove leading/trailing whitespace

        # Determine categories (optional)
        $categoryValues = @()
        
        # Debug: Show raw category data
        Write-Host "Debug: Processing categories for item '$title'" -ForegroundColor Cyan
        
        # Skip Get-PropertyValue for categories as it's returning literal "category" instead of content
        # Try direct property access first - this works correctly
        if ($rawItem.PSObject.Properties['category']) {
            Write-Host "Debug: Trying direct property access for categories" -ForegroundColor Cyan
            $categoryProperty = $rawItem.category
            Write-Host "Debug: Direct category property type: $($categoryProperty.GetType().Name)" -ForegroundColor Cyan
            
            if ($categoryProperty -is [array]) {
                Write-Host "Debug: Direct category property is array with $($categoryProperty.Count) items" -ForegroundColor Cyan
                foreach ($cat in $categoryProperty) {
                    Write-Host "Debug: Direct category item: '$cat' (Type: $($cat.GetType().Name))" -ForegroundColor Cyan
                    if ($cat -is [System.Xml.XmlElement] -and $cat.HasAttribute('term')) {
                        $termValue = $cat.GetAttribute('term').Trim()
                        Write-Host "Debug: Found term attribute: '$termValue'" -ForegroundColor Cyan
                        if ($termValue) {
                            $categoryValues += $termValue
                        }
                    }
                    elseif ($cat -is [System.Xml.XmlElement] -and $cat.InnerText) {
                        $innerValue = $cat.InnerText.Trim()
                        Write-Host "Debug: Found inner text: '$innerValue'" -ForegroundColor Cyan
                        if ($innerValue) {
                            $categoryValues += $innerValue
                        }
                    }
                    elseif ($cat -is [System.Xml.XmlElement]) {
                        Write-Host "Debug: XML Element name: '$($cat.Name)', InnerText: '$($cat.InnerText)', OuterXml: '$($cat.OuterXml)'" -ForegroundColor Cyan
                        # Try to get the CDATA content or text content
                        if ($cat.FirstChild -and $cat.FirstChild.NodeType -eq 'CDATA') {
                            $cdataValue = $cat.FirstChild.Value.Trim()
                            Write-Host "Debug: Found CDATA: '$cdataValue'" -ForegroundColor Cyan
                            if ($cdataValue) {
                                $categoryValues += $cdataValue
                            }
                        }
                        elseif ($cat.InnerText.Trim()) {
                            $innerValue = $cat.InnerText.Trim()
                            Write-Host "Debug: Using InnerText: '$innerValue'" -ForegroundColor Cyan
                            $categoryValues += $innerValue
                        }
                    }
                }
            }
            elseif ($categoryProperty -is [System.Xml.XmlElement]) {
                Write-Host "Debug: Single XML element category" -ForegroundColor Cyan
                if ($categoryProperty.HasAttribute('term')) {
                    $termValue = $categoryProperty.GetAttribute('term').Trim()
                    Write-Host "Debug: Found term attribute: '$termValue'" -ForegroundColor Cyan
                    if ($termValue) {
                        $categoryValues += $termValue
                    }
                }
                elseif ($categoryProperty.InnerText) {
                    $innerValue = $categoryProperty.InnerText.Trim()
                    Write-Host "Debug: Found inner text: '$innerValue'" -ForegroundColor Cyan
                    if ($innerValue) {
                        $categoryValues += $innerValue
                    }
                }
            }
        }
        
        # Fallback to tags if no categories found
        if ($categoryValues.Count -eq 0) {
            $tagRaw = Get-PropertyValue $rawItem 'tags'
            if ($tagRaw) {
                if ($tagRaw -is [array]) {
                    $categoryValues = $tagRaw | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ }
                } else {
                    $cleanTag = $tagRaw.ToString().Trim()
                    if ($cleanTag) {
                        $categoryValues = @($cleanTag)
                    }
                }
            }
        }
        
        Write-Host "Debug: Final extracted category values: [$($categoryValues -join '], [')]" -ForegroundColor Cyan
        
        # Always ensure we have the feed category in the list if it's not already there
        if ($feedConfig.category -and $categoryValues -notcontains $feedConfig.category) {
            $categoryValues += $feedConfig.category
            Write-Host "Debug: Added feed category '$($feedConfig.category)' to category values" -ForegroundColor Cyan
        }
        
        # Join categories with spaces, removing any empty values
        $category = ($categoryValues | Where-Object { $_ -and $_.Length -gt 0 }) -join ' '
        
        # Fallback to feed category if still empty (shouldn't happen now)
        if (-not $category -or $category.Length -eq 0) {
            $category = $feedConfig.category
            Write-Host "No categories found in RSS item '$title', using feed category: $category"
        } else {
            Write-Host "Final categories for '$title': [$category]" -ForegroundColor Green
        }

        $normalizedItem = [PSCustomObject]@{
            title       = $title
            link        = $link
            pubDate     = $pubDate
            description = $description
            author      = $author
            category    = $category
        }
            
        $items += $normalizedItem
    }

    Write-Host "Found $($items.Count) items in feed: $($feedConfig.name)"
                
    # Get latest items from the last day
    $latestItems = @($items)

    # $latestItems = @($items | Where-Object { 
    #         (((Get-Date) - $_.pubDate).Days -le 1)
    #     })

    Write-Host "Found $($latestItems.Count) likely new items"
                
    foreach ($item in $latestItems) {
        $title = $item.title
        $link = $item.link
        $pubDate = $item.pubDate
        $author = $item.author
        $tags = $item.category

        $filename = "$($pubDate.ToString('yyyy-MM-dd'))-$(Get-SanitizedFilename $title).md"
        $filePath = Join-Path $OutputDir $filename

        # If file exists and -Recreate is not specified, skip to next item
        if ((Test-Path $filePath) -and (-not $Recreate)) {
            Write-Host "Skipping file as it already exists: $filename."
            continue
        }

        $templatePath = Join-Path $PSScriptRoot "template.md"
        if (-not (Test-Path $templatePath)) {
            Write-Host "Template file not found: $templatePath"
            continue
        }
                    
        $markdownContent = Get-Content $templatePath -Raw
                    
        $descriptionSummary = Invoke-ChatCompletion `
            -Token $Token `
            -Model $Model `
            -Description ($item.description + "`n`nAuthor: $author")

        # Insert <!--excerpt_end--> before 'The post ... appeared first on ...' in the description
        $descriptionWithExcerpt = $description -replace '(?m)(?= The post .+? appeared first on .+?\.)', '<!--excerpt_end-->'

        # Perform string replacements
        $markdownContent = $markdownContent -replace '{{TITLE}}', $title
        $markdownContent = $markdownContent -replace '{{AUTHOR}}', $author
        $markdownContent = $markdownContent -replace '{{DESCRIPTION}}', $descriptionSummary
        $markdownContent = $markdownContent -replace '{{CANONICAL_URL}}', $link
        $markdownContent = $markdownContent -replace '{{TAGS}}', $tags
        $markdownContent = $markdownContent -replace '{{FEEDNAME}}', $feedConfig.name
        $markdownContent = $markdownContent -replace '{{FEEDURL}}', $feedConfig.url
        $markdownContent = $markdownContent -replace '{{CONTENT}}', $descriptionWithExcerpt

        # Create the file
        Set-Content -Path $filePath -Value $markdownContent -Encoding UTF8 -Force
        Write-Host "Created file: $filename for: $($title). Waiting 5 seconds to avoid rate limiting..."
        exit;
        Start-Sleep -Seconds 5
    }
}

Write-Host "Starting RSS Feed Monitor..."

$feedsConfigPath = "$PSScriptRoot/rss-feeds.json"
if (-not (Test-Path $feedsConfigPath)) {
    Write-Host "RSS feeds configuration file not found: $feedsConfigPath"
    exit 1
}
    
$feedsConfig = Get-Content $feedsConfigPath | ConvertFrom-Json

foreach ($feedConfig in $feedsConfig) {
    Invoke-RssFeedsProcessor `
        -FeedConfig $feedConfig `
        -Token $env:GITHUB_AI_TOKEN `
        -Model "openai/gpt-4.1" `
        -OutputDir "$PSScriptRoot/../../_news" `
        -Recreate
}

Write-Host "RSS Feed Monitor completed successfully"
