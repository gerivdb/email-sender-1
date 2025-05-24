# Simple module for extracted information management
# Using ASCII characters only to avoid encoding issues

# Module variables
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = "1.0.0"
$script:ModuleName = "SimpleExtractedInfoModule"
$script:ModuleData = @{
    Counters = @{
        InfoCreated = 0
        CollectionCreated = 0
    }
    Config = @{
        DefaultFormat = "Json"
        DefaultLanguage = "en"
    }
}

# Base functions
function New-BaseExtractedInfo {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Position = 0)]
        [string]$Source = "",
        
        [Parameter(Position = 1)]
        [string]$ExtractorName = ""
    )
    
    $script:ModuleData.Counters.InfoCreated++
    
    $info = @{
        Id = [guid]::NewGuid().ToString()
        Source = $Source
        ExtractedAt = [datetime]::Now
        ExtractorName = $ExtractorName
        Metadata = @{}
        ProcessingState = "Raw"
        ConfidenceScore = 0
        IsValid = $false
        _Type = "BaseExtractedInfo"
    }
    
    $info.Metadata["_CreatedBy"] = $script:ModuleName
    $info.Metadata["_CreatedAt"] = [datetime]::Now.ToString("o")
    $info.Metadata["_Version"] = $script:ModuleVersion
    
    return $info
}

function Add-ExtractedInfoMetadata {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [hashtable]$Info,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Key,
        
        [Parameter(Mandatory = $true, Position = 2)]
        [object]$Value
    )
    
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "Invalid extracted info object"
    }
    
    $Info.Metadata[$Key] = $Value
    $Info.Metadata["_LastModified"] = [datetime]::Now.ToString("o")
    
    return $Info
}

function Get-ExtractedInfoMetadata {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [hashtable]$Info,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Key
    )
    
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "Invalid extracted info object"
    }
    
    if ($Info.Metadata.ContainsKey($Key)) {
        return $Info.Metadata[$Key]
    }
    
    return $null
}

function Get-ExtractedInfoSummary {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [hashtable]$Info
    )
    
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "Invalid extracted info object"
    }
    
    $summary = "ID: $($Info.Id), Source: $($Info.Source), Extracted: $($Info.ExtractedAt), State: $($Info.ProcessingState), Confidence: $($Info.ConfidenceScore)%"
    
    return $summary
}

# Collection functions
function New-ExtractedInfoCollection {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Position = 0)]
        [string]$Name = "Collection"
    )
    
    $script:ModuleData.Counters.CollectionCreated++
    
    $collection = @{
        Name = $Name
        CreatedAt = [datetime]::Now
        Items = @()
        Metadata = @{}
        _Type = "ExtractedInfoCollection"
    }
    
    $collection.Metadata["_CreatedBy"] = $script:ModuleName
    $collection.Metadata["_CreatedAt"] = [datetime]::Now.ToString("o")
    $collection.Metadata["_Version"] = $script:ModuleVersion
    
    return $collection
}

function Add-ExtractedInfoToCollection {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Collection,
        
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [hashtable[]]$Info
    )
    
    begin {
        if ($null -eq $Collection -or $Collection._Type -ne "ExtractedInfoCollection") {
            throw "Invalid collection object"
        }
    }
    
    process {
        foreach ($item in $Info) {
            if ($null -eq $item -or -not $item.ContainsKey("_Type")) {
                Write-Warning "Invalid item skipped"
                continue
            }
            
            $Collection.Items += $item
            $Collection.Metadata["_LastModified"] = [datetime]::Now.ToString("o")
            $Collection.Metadata["_ItemCount"] = $Collection.Items.Count
        }
    }
    
    end {
        return $Collection
    }
}

function Get-ExtractedInfoFromCollection {
    [CmdletBinding(DefaultParameterSetName = "ById")]
    [OutputType([hashtable[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Collection,
        
        [Parameter(ParameterSetName = "ById")]
        [string]$Id,
        
        [Parameter(ParameterSetName = "ByFilter")]
        [string]$Source
    )
    
    if ($null -eq $Collection -or $Collection._Type -ne "ExtractedInfoCollection") {
        throw "Invalid collection object"
    }
    
    if ($PSCmdlet.ParameterSetName -eq "ByFilter" -and [string]::IsNullOrEmpty($Source)) {
        return $Collection.Items
    }
    
    if ($PSCmdlet.ParameterSetName -eq "ById" -and -not [string]::IsNullOrEmpty($Id)) {
        foreach ($item in $Collection.Items) {
            if ($item.Id -eq $Id) {
                return @($item)
            }
        }
        return @()
    }
    
    $result = @($Collection.Items)
    
    if (-not [string]::IsNullOrEmpty($Source)) {
        $result = @($result | Where-Object { $_.Source -eq $Source })
    }
    
    return $result
}

# Serialization functions
function ConvertTo-ExtractedInfoJson {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$InputObject,
        
        [Parameter(Position = 1)]
        [int]$Depth = 10
    )
    
    try {
        # Use built-in ConvertTo-Json cmdlet
        $json = Microsoft.PowerShell.Utility\ConvertTo-Json -InputObject $InputObject -Depth $Depth -Compress:$false
        return $json
    }
    catch {
        throw "Error converting object to JSON: $_"
    }
}

function ConvertFrom-ExtractedInfoJson {
    [CmdletBinding()]
    [OutputType([object])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Json
    )
    
    try {
        # Use built-in ConvertFrom-Json cmdlet
        $obj = Microsoft.PowerShell.Utility\ConvertFrom-Json -InputObject $Json
        return $obj
    }
    catch {
        throw "Error converting JSON to object: $_"
    }
}

function Save-ExtractedInfoToFile {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [hashtable]$Info,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$FilePath,
        
        [Parameter(Position = 2)]
        [string]$Format = "Json"
    )
    
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "Invalid extracted info object"
    }
    
    try {
        switch ($Format.ToLower()) {
            "json" {
                $json = ConvertTo-ExtractedInfoJson -InputObject $Info -Depth 10
                [System.IO.File]::WriteAllText($FilePath, $json)
            }
            default {
                throw "Unsupported format: $Format"
            }
        }
        
        return $true
    }
    catch {
        Write-Error "Error saving to file: $_"
        return $false
    }
}

function Import-ExtractedInfoFromFile {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$FilePath,
        
        [Parameter(Position = 1)]
        [string]$Format = "Json"
    )
    
    if (-not (Test-Path -Path $FilePath)) {
        throw "File not found: $FilePath"
    }
    
    try {
        switch ($Format.ToLower()) {
            "json" {
                $json = [System.IO.File]::ReadAllText($FilePath)
                $obj = ConvertFrom-ExtractedInfoJson -Json $json
                
                # Convert PSCustomObject to hashtable
                $info = @{}
                foreach ($prop in $obj.PSObject.Properties) {
                    if ($prop.Name -eq "Metadata") {
                        $metadata = @{}
                        foreach ($metaProp in $obj.Metadata.PSObject.Properties) {
                            $metadata[$metaProp.Name] = $metaProp.Value
                        }
                        $info[$prop.Name] = $metadata
                    }
                    else {
                        $info[$prop.Name] = $prop.Value
                    }
                }
                
                return $info
            }
            default {
                throw "Unsupported format: $Format"
            }
        }
    }
    catch {
        Write-Error "Error loading from file: $_"
        return $null
    }
}

# Validation functions
function Test-ExtractedInfo {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [hashtable]$Info
    )
    
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "Invalid extracted info object"
    }
    
    $isValid = $true
    
    # Basic validation
    if ([string]::IsNullOrWhiteSpace($Info.Id)) {
        $isValid = $false
    }
    
    if ([string]::IsNullOrWhiteSpace($Info.Source)) {
        $isValid = $false
    }
    
    if ($Info.ConfidenceScore -lt 0 -or $Info.ConfidenceScore -gt 100) {
        $isValid = $false
    }
    
    # Update the IsValid property
    $Info.IsValid = $isValid
    
    return $isValid
}

# Export module members
Export-ModuleMember -Function @(
    # Base functions
    'New-BaseExtractedInfo',
    'Add-ExtractedInfoMetadata',
    'Get-ExtractedInfoMetadata',
    'Get-ExtractedInfoSummary',
    
    # Collection functions
    'New-ExtractedInfoCollection',
    'Add-ExtractedInfoToCollection',
    'Get-ExtractedInfoFromCollection',
    
    # Serialization functions
    'ConvertTo-ExtractedInfoJson',
    'ConvertFrom-ExtractedInfoJson',
    'Save-ExtractedInfoToFile',
    'Import-ExtractedInfoFromFile',
    
    # Validation functions
    'Test-ExtractedInfo'
)

