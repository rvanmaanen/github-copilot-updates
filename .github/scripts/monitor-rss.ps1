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

function Get-FrontMatterValue {
    param([string]$Value)
    
    if (-not $Value) {
        return $Value
    }
    
    # Clean up the value for front matter usage
    $cleanValue = $Value -replace '<[^>]+>', ''                 # Remove HTML tags
    $cleanValue = $cleanValue -replace '[\r\n]+', ' '           # Replace line breaks with spaces
    $cleanValue = $cleanValue -replace '"', '\'''               # Replace double quotes with single quotes
    $cleanValue = $cleanValue -replace ': ', ' - '              # Replace colons with dashes
    $cleanValue = $cleanValue -replace 'https?://[^\s]+', ''    # Remove URLs
    $cleanValue = $cleanValue -replace '\s+Read the full article', '.'
    $cleanValue = $cleanValue -replace '(.*)\s+The post .+? appeared first on .*', '$1'
    $cleanValue = $cleanValue -replace '\s+', ' '               # Replace multiple spaces with single space
    $cleanValue = $cleanValue.Trim()                            # Remove leading/trailing whitespace
    
    return $cleanValue
}

function Get-XmlElementValue {
    param(
        [System.Xml.XmlNode]$Element,
        [string]$AttributeName = $null
    )
    
    if ($null -eq $Element) {
        return $null
    }
    
    # If looking for a specific attribute, return that
    if ($AttributeName) {
        return $Element.GetAttribute($AttributeName)
    }
    
    # Get the text content, handling CDATA sections
    $value = $Element.InnerText
    
    # Clean up the value
    if ($value) {
        $value = [System.Web.HttpUtility]::HtmlDecode($value)
        $value = $value.Trim()
    }
    
    return $value
}

function Get-ElementByName {
    param(
        [System.Xml.XmlNode]$ParentNode,
        [string]$ElementName
    )
    
    # First try direct child selection
    $element = $ParentNode.SelectSingleNode($ElementName)
    if ($element) {
        return $element
    }
    
    # If not found, search through child nodes for local name match
    foreach ($child in $ParentNode.ChildNodes) {
        if ($child.LocalName -eq $ElementName) {
            return $child
        }
    }
    
    return $null
}

function Get-FeedItems {
    param(
        [System.Xml.XmlDocument]$XmlDoc
    )
    
    # Check if the document has a default namespace (like Atom feeds)
    $rootNamespace = $XmlDoc.DocumentElement.NamespaceURI
    
    if ($rootNamespace -eq "http://www.w3.org/2005/Atom") {
        # For Atom feeds with default namespace, we need to use namespace-aware queries
        $nsmgr = New-Object System.Xml.XmlNamespaceManager($XmlDoc.NameTable)
        $nsmgr.AddNamespace("atom", "http://www.w3.org/2005/Atom")
        $items = $XmlDoc.SelectNodes('//atom:entry', $nsmgr)
        Write-Host "Found $($items.Count) Atom entries using namespace manager"
    }
    elseif ($rootNamespace -and $rootNamespace -ne "") {
        # For other namespaced feeds, create a namespace manager
        $nsmgr = New-Object System.Xml.XmlNamespaceManager($XmlDoc.NameTable)
        $nsmgr.AddNamespace("ns", $rootNamespace)
        $items = $XmlDoc.SelectNodes('//ns:item', $nsmgr)
        if ($items.Count -eq 0) {
            $items = $XmlDoc.SelectNodes('//ns:entry', $nsmgr)
        }
        Write-Host "Found $($items.Count) items using namespace manager for $rootNamespace"
    }
    else {
        # For RSS feeds without namespace or simple XML
        $items = @()
        
        # RSS 2.0: /rss/channel/item
        $rssItems = $XmlDoc.SelectNodes('//rss/channel/item')
        if ($rssItems.Count -gt 0) {
            $items = $rssItems
        }
        # RSS without rss wrapper: /channel/item  
        elseif ($XmlDoc.SelectNodes('//channel/item').Count -gt 0) {
            $items = $XmlDoc.SelectNodes('//channel/item')
        }
        # Atom: /feed/entry
        elseif ($XmlDoc.SelectNodes('//feed/entry').Count -gt 0) {
            $items = $XmlDoc.SelectNodes('//feed/entry')
        }
        # Direct items
        elseif ($XmlDoc.SelectNodes('//item').Count -gt 0) {
            $items = $XmlDoc.SelectNodes('//item')
        }
        # Direct entries
        elseif ($XmlDoc.SelectNodes('//entry').Count -gt 0) {
            $items = $XmlDoc.SelectNodes('//entry')
        }
        
        Write-Host "Found $($items.Count) items without namespace"
    }
    
    if ($items.Count -eq 0) {
        Write-Warning "No items found in feed. Root element: $($XmlDoc.DocumentElement.Name), Namespace: $rootNamespace"
        return @()
    }
    
    return $items
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
    $xmlDoc = $null
    
    while (-not $success -and $attempt -lt $maxAttempts) {
        try {
            $xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.Load($feedConfig.url)
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
                
    # Get items from the XML document
    $rawItems = Get-FeedItems -XmlDoc $xmlDoc
    
    # Ensure we have an array and get count safely
    if ($rawItems -is [array]) {
        $itemCount = $rawItems.Count
    }
    elseif ($rawItems) {
        $itemCount = 1
        $rawItems = @($rawItems)
    }
    else {
        throw "No items found in RSS feed: $($feedConfig.url)"
    }
    
    Write-Host "Found $itemCount items in XML feed"
    
    # Convert items to normalized structure
    $items = @()
    # Normalize each item to a consistent structure
    foreach ($rawItem in $rawItems) {
        # Extract title (required)
        $title = Get-XmlElementValue (Get-ElementByName $rawItem 'title')
        if (-not $title) {
            throw "No title found for RSS item. Raw item: $($rawItem.OuterXml)"
        }

        # Extract link (required)
        $link = $null
        $linkNode = Get-ElementByName $rawItem 'link'
        if ($linkNode) {
            # For Atom feeds, link might have href attribute
            $link = Get-XmlElementValue $linkNode 'href'
            if (-not $link) {
                # For RSS feeds, link is the text content
                $link = Get-XmlElementValue $linkNode
            }
        }
        
        # Fallback to other link fields
        if (-not $link) {
            $link = Get-XmlElementValue (Get-ElementByName $rawItem 'url')
        }
        
        if (-not $link) {
            throw "No link found for RSS item '$title'. Raw item: $($rawItem.OuterXml)"
        }
            
        # Extract publication date (required)
        $pubDateRaw = $null
        $dateFields = @('pubDate', 'published', 'updated', 'date')
        foreach ($field in $dateFields) {
            $dateNode = Get-ElementByName $rawItem $field
            if ($dateNode) {
                $pubDateRaw = Get-XmlElementValue $dateNode
                break
            }
        }
        
        if (-not $pubDateRaw) {
            throw "No publication date found for RSS item '$title'. Raw item: $($rawItem.OuterXml)"
        }
            
        # Convert to DateTime
        try {
            $pubDate = [datetime]$pubDateRaw
        }
        catch {
            throw "Failed to parse publication date '$pubDateRaw' for RSS item '$title'. Error: $($_.Exception.Message)"
        }
            
        # Extract description (required)
        $description = $null
        $descFields = @('description', 'summary', 'content')
        foreach ($field in $descFields) {
            $descNode = Get-ElementByName $rawItem $field
            if ($descNode) {
                $description = Get-XmlElementValue $descNode
                break
            }
        }
        
        if (-not $description) {
            throw "No description/summary found for RSS item '$title'. Raw item: $($rawItem.OuterXml)"
        }

        # Extract author (required)
        $author = $null
        
        # Try simple field names first (no namespace)
        $authorFields = @('creator', 'author')
        foreach ($field in $authorFields) {
            $authorNode = Get-ElementByName $rawItem $field
            if ($authorNode) {
                $author = Get-XmlElementValue $authorNode
                break
            }
            # Also try author/name for Atom feeds
            if (-not $author -and $field -eq 'author') {
                $authorNameNode = Get-ElementByName $authorNode 'name'
                if ($authorNameNode) {
                    $author = Get-XmlElementValue $authorNameNode
                }
            }
        }
        
        # If still no author, try to find dc:creator by searching through child nodes
        if (-not $author) {
            foreach ($childNode in $rawItem.ChildNodes) {
                if ($childNode.LocalName -eq 'creator' -and $childNode.NamespaceURI -eq 'http://purl.org/dc/elements/1.1/') {
                    $author = Get-XmlElementValue $childNode
                    break
                }
            }
        }
        
        if (-not $author) {
            throw "No author found for RSS item '$title'. Raw item: $($rawItem.OuterXml)"
        }

        # Extract categories
        $categoryValues = @()
        
        # Get all category elements
        foreach ($childNode in $rawItem.ChildNodes) {
            if ($childNode.LocalName -eq 'category') {
                $catValue = $null
                # For Atom feeds, category might have term attribute
                $catValue = Get-XmlElementValue $childNode 'term'
                if (-not $catValue) {
                    # For RSS feeds, category is the text content
                    $catValue = Get-XmlElementValue $childNode
                }
                if ($catValue) {
                    # Replace spaces with underscores instead of HTML encoding
                    $underscoreCatValue = $catValue.Trim() -replace '\s+', '_'
                    $categoryValues += $underscoreCatValue
                }
            }
        }

        # Fallback to tags if no categories found
        if ($categoryValues.Count -eq 0) {
            foreach ($childNode in $rawItem.ChildNodes) {
                if ($childNode.LocalName -eq 'tag' -or $childNode.LocalName -eq 'tags') {
                    $tagValue = Get-XmlElementValue $childNode
                    if ($tagValue) {
                        $underscoreTagValue = $tagValue.Trim() -replace '\s+', '_'
                        $categoryValues += $underscoreTagValue
                    }
                }
            }
        }
        
        # Always ensure we have the feed category
        if ($feedConfig.category -and $categoryValues -notcontains $feedConfig.category) {
            $categoryValues += $feedConfig.category
        }
        
        # Join categories with spaces
        $category = ($categoryValues | Where-Object { $_ -and $_.Length -gt 0 }) -join ' '
        
        # Fallback to feed category if still empty
        if (-not $category -or $category.Length -eq 0) {
            $category = $feedConfig.category
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
    $latestItems = @($items | Where-Object { 
            (((Get-Date) - $_.pubDate).Days -le 365)
        })

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
            
        $title = Get-FrontMatterValue $title
        $author = Get-FrontMatterValue $author
        $description = Get-FrontMatterValue $item.description
        $descriptionSummary = $description -replace ' The post .*? first on .*', ''
        if ($descriptionSummary.Length -gt 100) {
            $descriptionSummary = $descriptionSummary.Substring(0, [Math]::Min(100, $descriptionSummary.Length)) + '...' # Truncate to 100 characters
        }
        $descriptionSummary = $descriptionSummary.Trim()
                
        # $descriptionSummary = Invoke-ChatCompletion `
        #     -Token $Token `
        #     -Model $Model `
        #     -Description ($description + "`n`nAuthor: $author")

        #remove html tags from content
        $content = $item.description -replace '<[^>]+>', ''
        $content = $content -replace '\s+Read the full article', '.<!--excerpt_end-->'
        $content = $content -replace '(.*)\s+The post .+? appeared first on .*', '$1<!--excerpt_end-->'
        $content = $content -replace '\[…\]', '[...]'
        $content = $content -replace '\s+', ' '

        # Perform string replacements
        $markdownContent = $markdownContent -replace '{{TITLE}}', $title
        $markdownContent = $markdownContent -replace '{{AUTHOR}}', $author
        $markdownContent = $markdownContent -replace '{{DESCRIPTION}}', $descriptionSummary
        $markdownContent = $markdownContent -replace '{{CANONICAL_URL}}', $link
        $markdownContent = $markdownContent -replace '{{TAGS}}', $tags
        $markdownContent = $markdownContent -replace '{{FEEDNAME}}', $feedConfig.name
        $markdownContent = $markdownContent -replace '{{FEEDURL}}', $feedConfig.url
        $markdownContent = $markdownContent -replace '{{CONTENT}}', $content

        # Create the file
        Set-Content -Path $filePath -Value $markdownContent -Encoding UTF8 -Force
        Write-Host "Created file: $filename for: $($title). Waiting 5 seconds to avoid rate limiting..."
        #Start-Sleep -Seconds 5
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
