# Test script to verify RSS category extraction
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Include the same Get-PropertyValue function from the main script
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

# Test function to extract categories
function Test-CategoryExtraction {
    param([string]$FeedUrl, [string]$FeedName)
    
    Write-Host "`n=== Testing $FeedName ===" -ForegroundColor Green
    Write-Host "URL: $FeedUrl"
    
    try {
        $rssData = Invoke-RestMethod -Uri $FeedUrl -Method Get
        
        # Get first few items from feed
        if (Get-PropertyValue $rssData 'rss.channel.item') {
            $rawItems = Get-PropertyValue $rssData 'rss.channel.item'
        }
        elseif (Get-PropertyValue $rssData 'feed.entry') {
            $rawItems = Get-PropertyValue $rssData 'feed.entry'
        }
        elseif (Get-PropertyValue $rssData 'channel.item') {
            $rawItems = Get-PropertyValue $rssData 'channel.item'
        }
        else {
            Write-Host "Could not find items in feed structure" -ForegroundColor Red
            return
        }
        
        if ($rawItems -isnot [array]) {
            $rawItems = @($rawItems)
        }
        
        # Test first 3 items
        for ($i = 0; $i -lt [Math]::Min(3, $rawItems.Count); $i++) {
            $rawItem = $rawItems[$i]
            
            $title = Get-PropertyValue $rawItem 'title'
            if (-not $title) {
                $title = Get-PropertyValue $rawItem 'title.#text'
            }
            
            Write-Host "`nItem $($i+1): $title" -ForegroundColor Yellow
            
            # Extract categories using the same logic as main script
            $categoryValues = @()
            
            $categoryRaw = Get-PropertyValue $rawItem 'category'
            if ($categoryRaw) {
                Write-Host "  Raw categories: $($categoryRaw | ConvertTo-Json -Compress)"
                
                if ($categoryRaw -is [array]) {
                    foreach ($cat in $categoryRaw) {
                        if ($cat -is [string] -and $cat.Trim()) {
                            $categoryValues += $cat.Trim()
                        }
                        elseif ($cat) {
                            $cleanCat = $cat.ToString().Trim()
                            if ($cleanCat) {
                                $categoryValues += $cleanCat
                            }
                        }
                    }
                }
                elseif ($categoryRaw -is [string] -and $categoryRaw.Trim()) {
                    $categoryValues += $categoryRaw.Trim()
                }
                elseif ($categoryRaw) {
                    $cleanCat = $categoryRaw.ToString().Trim()
                    if ($cleanCat) {
                        $categoryValues += $cleanCat
                    }
                }
            }
            
            # Try direct property access for Atom feeds
            if ($categoryValues.Count -eq 0 -and $rawItem.PSObject.Properties['category']) {
                $categoryProperty = $rawItem.category
                
                if ($categoryProperty -is [array]) {
                    foreach ($cat in $categoryProperty) {
                        if ($cat -is [System.Xml.XmlElement] -and $cat.HasAttribute('term')) {
                            $termValue = $cat.GetAttribute('term').Trim()
                            if ($termValue) {
                                $categoryValues += $termValue
                            }
                        }
                        elseif ($cat -is [System.Xml.XmlElement] -and $cat.InnerText) {
                            $innerValue = $cat.InnerText.Trim()
                            if ($innerValue) {
                                $categoryValues += $innerValue
                            }
                        }
                    }
                }
                elseif ($categoryProperty -is [System.Xml.XmlElement]) {
                    if ($categoryProperty.HasAttribute('term')) {
                        $termValue = $categoryProperty.GetAttribute('term').Trim()
                        if ($termValue) {
                            $categoryValues += $termValue
                        }
                    }
                    elseif ($categoryProperty.InnerText) {
                        $innerValue = $categoryProperty.InnerText.Trim()
                        if ($innerValue) {
                            $categoryValues += $innerValue
                        }
                    }
                }
            }
            
            $finalCategories = ($categoryValues | Where-Object { $_ -and $_.Length -gt 0 }) -join ' '
            
            if ($finalCategories) {
                Write-Host "  ✓ Extracted categories: $finalCategories" -ForegroundColor Green
            } else {
                Write-Host "  ✗ No categories found" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "Error testing $FeedName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Load feed configuration
$feedsConfigPath = "$PSScriptRoot/rss-feeds.json"
$feedsConfig = Get-Content $feedsConfigPath | ConvertFrom-Json

# Test each feed
foreach ($feedConfig in $feedsConfig) {
    Test-CategoryExtraction -FeedUrl $feedConfig.url -FeedName $feedConfig.name
}

Write-Host "`n=== Category Extraction Test Complete ===" -ForegroundColor Green
