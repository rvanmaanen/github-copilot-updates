$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

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
        
        # Clean up any remaining CDATA markers that might be in the text
        if ($currentValue -match '<!\[CDATA\[(.*?)\]\]>') {
            $currentValue = $currentValue -replace '<!\[CDATA\[(.*?)\]\]>', '$1'
        }
    }
    
    # If there are more properties in the path, recurse
    if ($properties.Length -gt 1) {
        return Get-PropertyValue $currentValue $properties[1]
    }
    
    # Otherwise, return the value after HTML decoding and trimming
    if ($currentValue -is [string]) {
        $currentValue = [System.Web.HttpUtility]::HtmlDecode($currentValue)
        $currentValue = $currentValue.Trim()
    }
    return $currentValue
}

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
        
    # Fetch RSS feed
    $rssData = Invoke-RestMethod -Uri $feedConfig.url -Method Get
            
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
        if ($description -match '<.*?>') {
            $description = $description -replace '<.*?>', ''
        }
        $description = $description -replace '[\r\n]+', ' '
        $description = $description -replace '"', '\'''
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
        
        # Determine categories (optional)
        $categoryRaw = Get-PropertyValue $rawItem 'category'
        if (-not $categoryRaw) {
            $categoryRaw = Get-PropertyValue $rawItem 'tags'
        }
        if (-not $categoryRaw) {
            $categoryRaw = @()
        }
        
        # Flatten categories to space-separated string
        $category = if ($categoryRaw -and ($categoryRaw -is [array])) {
            ($categoryRaw | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.ToString() } }) -join ' '
        }
        elseif ($categoryRaw -and ($categoryRaw -is [string])) {
            $categoryRaw
        }
        elseif ($categoryRaw) {
            $categoryRaw.ToString()
        }
        else {
            ''
        }

        $normalizedItem = [PSCustomObject]@{
            title = $title
            link = $link
            pubDate = $pubDate
            description = $description
            author = $author
            category = $category
        }
        
        $items += $normalizedItem
    }

    Write-Host "Found $($items.Count) items in feed: $($feedConfig.name)"
            
    # Get latest items from the last day
    $latestItems = @($items | Where-Object { 
        (((Get-Date) - $_.pubDate).Days -le 1)
    })

    Write-Host "Found $($latestItems.Count) likely new items"
            
    foreach ($item in $latestItems) {
        $title = $item.title
        $link = $item.link
        $pubDate = $item.pubDate
        
        $author = $item.author
        $tags = $item.category

        $filename = "$($pubDate.ToString('yyyy-MM-dd'))-$(Get-SanitizedFilename $title).md"
        $filePath = Join-Path $PSScriptRoot $filename

        $templatePath = Join-Path $PSScriptRoot "template.md"
        if (-not (Test-Path $templatePath)) {
            Write-Host "Template file not found: $templatePath"
            continue
        }
                
        $markdownContent = Get-Content $templatePath -Raw
                
        # Perform string replacements
        $markdownContent = $markdownContent -replace '{{TITLE}}', ($title -replace '"', '\"')
        $markdownContent = $markdownContent -replace '{{AUTHOR}}', $author
        $markdownContent = $markdownContent -replace '{{DESCRIPTION}}', ($description -replace '"', '\"')
        $markdownContent = $markdownContent -replace '{{CANONICAL_URL}}', $link
        $markdownContent = $markdownContent -replace '{{TAGS}}', $tags
        $markdownContent = $markdownContent -replace '{{SUMMARY_HIGHLIGHT}}', 'SUMMARY_CONTENT_HERE'
        $markdownContent = $markdownContent -replace '{{SUMMARY_REMAINDER}}', 'REMAINING_SUMMARY_HERE'

        # Create the file
        Set-Content -Path $filePath -Value $markdownContent -Encoding UTF8 -Force
        Write-Host "Created file: $filename for: $($title)"
    }
}
    
Write-Host "RSS Feed Monitor completed successfully"

