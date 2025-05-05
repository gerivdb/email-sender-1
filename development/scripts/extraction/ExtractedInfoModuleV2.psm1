# ExtractedInfoModuleV2.psm1
# Module for managing extracted information
# ASCII only, no special characters

# Module variables
$script:ModuleRoot = $PSScriptRoot
$script:ModuleVersion = "1.0.0"
$script:ModuleName = "ExtractedInfoModuleV2"

# Initialize module data
$script:ModuleData = @{
    # Counters
    Counters = @{
        InfoCreated       = 0
        CollectionCreated = 0
    }

    # Configuration
    Config   = @{
        DefaultFormat   = "Json"
        DefaultLanguage = "en"
    }
}

# Base functions
function New-ExtractedInfo {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Position = 0)]
        [string]$Source = "",

        [Parameter(Position = 1)]
        [string]$ExtractorName = ""
    )

    # Increment counter
    $script:ModuleData.Counters.InfoCreated++

    # Create extracted info object
    $info = @{
        Id              = [guid]::NewGuid().ToString()
        Source          = $Source
        ExtractedAt     = [datetime]::Now
        ExtractorName   = $ExtractorName
        Metadata        = @{}
        ProcessingState = "Raw"
        ConfidenceScore = 0
        IsValid         = $false
        _Type           = "ExtractedInfo"
    }

    # Add system metadata
    $info.Metadata["_CreatedBy"] = $script:ModuleName
    $info.Metadata["_CreatedAt"] = [datetime]::Now.ToString("o")
    $info.Metadata["_Version"] = $script:ModuleVersion

    return $info
}

function New-TextExtractedInfo {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Position = 0)]
        [string]$Source = "",

        [Parameter(Position = 1)]
        [string]$ExtractorName = "",

        [Parameter(Position = 2)]
        [string]$Text = "",

        [Parameter(Position = 3)]
        [string]$Language = "en"
    )

    # Create base info
    $info = New-ExtractedInfo -Source $Source -ExtractorName $ExtractorName

    # Add text-specific properties
    $info._Type = "TextExtractedInfo"
    $info.Text = $Text
    $info.Language = $Language
    $info.CharacterCount = $Text.Length
    $info.WordCount = if ($Text) { ($Text -split '\s+').Count } else { 0 }

    return $info
}

function New-StructuredDataExtractedInfo {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Position = 0)]
        [string]$Source = "",

        [Parameter(Position = 1)]
        [string]$ExtractorName = "",

        [Parameter(Position = 2)]
        [object]$Data = $null,

        [Parameter(Position = 3)]
        [string]$DataFormat = "Hashtable"
    )

    # Create base info
    $info = New-ExtractedInfo -Source $Source -ExtractorName $ExtractorName

    # Add structured data specific properties
    $info._Type = "StructuredDataExtractedInfo"
    $info.Data = $Data
    $info.DataFormat = $DataFormat
    $info.DataItemCount = if ($Data -is [hashtable]) { $Data.Count } elseif ($Data -is [array]) { $Data.Length } else { 1 }
    $info.IsNested = $false
    $info.MaxDepth = 1

    # Check if data is nested
    if ($Data -is [hashtable]) {
        foreach ($value in $Data.Values) {
            if ($value -is [hashtable] -or $value -is [array]) {
                $info.IsNested = $true
                $info.MaxDepth = 2
                break
            }
        }
    }

    return $info
}

function New-MediaExtractedInfo {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Position = 0)]
        [string]$Source = "",

        [Parameter(Position = 1)]
        [string]$ExtractorName = "",

        [Parameter(Position = 2)]
        [string]$MediaPath = "",

        [Parameter(Position = 3)]
        [string]$MediaType = "Unknown"
    )

    # Create base info
    $info = New-ExtractedInfo -Source $Source -ExtractorName $ExtractorName

    # Add media-specific properties
    $info._Type = "MediaExtractedInfo"
    $info.MediaPath = $MediaPath
    $info.MediaType = $MediaType
    $info.FileSize = if (Test-Path $MediaPath) { (Get-Item $MediaPath).Length } else { 0 }
    $info.FileCreatedDate = if (Test-Path $MediaPath) { (Get-Item $MediaPath).CreationTime } else { [datetime]::Now }

    return $info
}

function Copy-ExtractedInfo {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [hashtable]$Info
    )

    # Verify that the input is a valid extracted info object
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "Invalid extracted info object"
    }

    # Create a new hashtable for the copy
    $copy = @{}

    # Copy all top-level properties except Metadata
    foreach ($key in $Info.Keys) {
        if ($key -ne "Metadata") {
            $copy[$key] = $Info[$key]
        }
    }

    # Create a new metadata hashtable and copy all metadata
    $copy.Metadata = @{}
    foreach ($key in $Info.Metadata.Keys) {
        $copy.Metadata[$key] = $Info.Metadata[$key]
    }

    # Add copy-specific metadata
    $copy.Metadata["_IsCopy"] = $true
    $copy.Metadata["_CopiedAt"] = [datetime]::Now.ToString("o")
    $copy.Metadata["_OriginalId"] = $Info.Id

    # Generate a new ID for the copy
    $copy.Id = [guid]::NewGuid().ToString()

    return $copy
}

# Metadata functions
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

    # Verify that the input is a valid extracted info object
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "Invalid extracted info object"
    }

    # Add or update the metadata
    $Info.Metadata[$Key] = $Value

    # Add system metadata to track changes
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

    # Verify that the input is a valid extracted info object
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "Invalid extracted info object"
    }

    # Return the metadata value if it exists
    if ($Info.Metadata.ContainsKey($Key)) {
        return $Info.Metadata[$Key]
    }

    return $null
}

function Remove-ExtractedInfoMetadata {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [hashtable]$Info,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Key
    )

    # Verify that the input is a valid extracted info object
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "Invalid extracted info object"
    }

    # Remove the metadata if it exists
    if ($Info.Metadata.ContainsKey($Key)) {
        $Info.Metadata.Remove($Key)

        # Add system metadata to track changes
        $Info.Metadata["_LastModified"] = [datetime]::Now.ToString("o")
    }

    return $Info
}

function Get-ExtractedInfoSummary {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [hashtable]$Info
    )

    # Verify that the input is a valid extracted info object
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "Invalid extracted info object"
    }

    # Create a basic summary
    $summary = "ID: $($Info.Id), Source: $($Info.Source), Extracted: $($Info.ExtractedAt), State: $($Info.ProcessingState), Confidence: $($Info.ConfidenceScore)%"

    # Add type-specific information
    switch ($Info._Type) {
        "TextExtractedInfo" {
            $summary += ", Text: $($Info.CharacterCount) characters, $($Info.WordCount) words"
        }
        "StructuredDataExtractedInfo" {
            $summary += ", Data: $($Info.DataItemCount) items, Max depth: $($Info.MaxDepth)"
        }
        "MediaExtractedInfo" {
            $sizeKB = [math]::Round($Info.FileSize / 1024, 2)
            $summary += ", Media: $($Info.MediaType), Size: $sizeKB KB"
        }
    }

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

    # Increment counter
    $script:ModuleData.Counters.CollectionCreated++

    # Create collection object
    $collection = @{
        Name      = $Name
        CreatedAt = [datetime]::Now
        Items     = @()
        Metadata  = @{}
        _Type     = "ExtractedInfoCollection"
    }

    # Add system metadata
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
        # Verify that the collection is valid
        if ($null -eq $Collection -or $Collection._Type -ne "ExtractedInfoCollection") {
            throw "Invalid collection object"
        }
    }

    process {
        foreach ($item in $Info) {
            # Verify that the item is a valid extracted info object
            if ($null -eq $item -or -not $item.ContainsKey("_Type")) {
                Write-Warning "Invalid item skipped"
                continue
            }

            # Add the item to the collection
            $Collection.Items += $item

            # Update collection metadata
            $Collection.Metadata["_LastModified"] = [datetime]::Now.ToString("o")
            $Collection.Metadata["_ItemCount"] = $Collection.Items.Count
        }
    }

    end {
        return $Collection
    }
}

function Remove-ExtractedInfoFromCollection {
    [CmdletBinding(DefaultParameterSetName = "ById")]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Collection,

        [Parameter(Mandatory = $true, ParameterSetName = "ById", Position = 1)]
        [string]$Id,

        [Parameter(Mandatory = $true, ParameterSetName = "ByInfo", Position = 1)]
        [hashtable]$Info
    )

    # Verify that the collection is valid
    if ($null -eq $Collection -or $Collection._Type -ne "ExtractedInfoCollection") {
        throw "Invalid collection object"
    }

    # Determine the ID to remove
    $idToRemove = $Id
    if ($PSCmdlet.ParameterSetName -eq "ByInfo") {
        if ($null -eq $Info -or -not $Info.ContainsKey("Id")) {
            throw "Invalid info object"
        }
        $idToRemove = $Info.Id
    }

    # Find the item to remove
    $itemIndex = -1
    for ($i = 0; $i -lt $Collection.Items.Count; $i++) {
        if ($Collection.Items[$i].Id -eq $idToRemove) {
            $itemIndex = $i
            break
        }
    }

    # Remove the item if found
    if ($itemIndex -ge 0) {
        $Collection.Items = @($Collection.Items[0..($itemIndex - 1)] + $Collection.Items[($itemIndex + 1)..($Collection.Items.Count - 1)])

        # Update collection metadata
        $Collection.Metadata["_LastModified"] = [datetime]::Now.ToString("o")
        $Collection.Metadata["_ItemCount"] = $Collection.Items.Count

        return $true
    }

    return $false
}

function Get-ExtractedInfoFromCollection {
    [CmdletBinding(DefaultParameterSetName = "All")]
    [OutputType([hashtable[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Collection,

        [Parameter(ParameterSetName = "ById")]
        [string]$Id
    )

    # Verify that the collection is valid
    if ($null -eq $Collection -or $Collection._Type -ne "ExtractedInfoCollection") {
        throw "Invalid collection object"
    }

    # If collection is empty, return empty array
    if ($null -eq $Collection.Items -or $Collection.Items.Count -eq 0) {
        return @()
    }

    # If no ID specified, return all items
    if ($PSCmdlet.ParameterSetName -eq "All" -or [string]::IsNullOrEmpty($Id)) {
        return $Collection.Items
    }

    # Search for the item with the specified ID
    $foundItems = @()
    foreach ($item in $Collection.Items) {
        if ($item.Id -eq $Id) {
            $foundItems += $item
        }
    }

    return $foundItems
}

function Get-ExtractedInfoCollectionStatistics {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Collection
    )

    # Verify that the collection is valid
    if ($null -eq $Collection -or $Collection._Type -ne "ExtractedInfoCollection") {
        throw "Invalid collection object"
    }

    # Initialize statistics
    $stats = @{
        TotalCount         = $Collection.Items.Count
        ValidCount         = 0
        InvalidCount       = 0
        AverageConfidence  = 0
        SourceDistribution = @{}
        StateDistribution  = @{}
        TypeDistribution   = @{}
    }

    # If the collection is empty, return basic statistics
    if ($stats.TotalCount -eq 0) {
        return $stats
    }

    # Calculate detailed statistics
    $totalConfidence = 0

    foreach ($item in $Collection.Items) {
        # Count valid and invalid items
        if ($item.IsValid) {
            $stats.ValidCount++
        } else {
            $stats.InvalidCount++
        }

        # Sum confidence scores
        $totalConfidence += $item.ConfidenceScore

        # Count items by source
        $source = $item.Source
        if (-not [string]::IsNullOrEmpty($source)) {
            if (-not $stats.SourceDistribution.ContainsKey($source)) {
                $stats.SourceDistribution[$source] = 0
            }
            $stats.SourceDistribution[$source]++
        }

        # Count items by processing state
        $state = $item.ProcessingState
        if (-not [string]::IsNullOrEmpty($state)) {
            if (-not $stats.StateDistribution.ContainsKey($state)) {
                $stats.StateDistribution[$state] = 0
            }
            $stats.StateDistribution[$state]++
        }

        # Count items by type
        $type = $item._Type
        if (-not [string]::IsNullOrEmpty($type)) {
            if (-not $stats.TypeDistribution.ContainsKey($type)) {
                $stats.TypeDistribution[$type] = 0
            }
            $stats.TypeDistribution[$type]++
        }
    }

    # Calculate average confidence
    $stats.AverageConfidence = [math]::Round($totalConfidence / $stats.TotalCount, 2)

    # Add additional metadata
    $stats.CollectionName = $Collection.Name
    $stats.CollectionCreatedAt = $Collection.CreatedAt
    $stats.StatisticsGeneratedAt = [datetime]::Now

    return $stats
}

# Serialization functions
function ConvertTo-ExtractedInfoJson {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$InputObject,

        [Parameter(Position = 1)]
        [int]$Depth = 10,

        [Parameter(Position = 2)]
        [switch]$Compress
    )

    try {
        # Use built-in ConvertTo-Json cmdlet
        $json = Microsoft.PowerShell.Utility\ConvertTo-Json -InputObject $InputObject -Depth $Depth -Compress:$Compress
        return $json
    } catch {
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

        # If the result is a PSCustomObject representing an extracted info, convert it to a hashtable
        if ($obj.PSObject.Properties.Name -contains "_Type" -and
            $obj.PSObject.Properties.Name -contains "Id" -and
            $obj.PSObject.Properties.Name -contains "Metadata") {

            # Convert to hashtable
            $result = @{}

            # Copy all properties except Metadata
            foreach ($prop in $obj.PSObject.Properties) {
                if ($prop.Name -ne "Metadata") {
                    $result[$prop.Name] = $prop.Value
                }
            }

            # Convert Metadata to hashtable
            $result.Metadata = @{}
            if ($null -ne $obj.Metadata) {
                foreach ($metaProp in $obj.Metadata.PSObject.Properties) {
                    $result.Metadata[$metaProp.Name] = $metaProp.Value
                }
            }

            return $result
        }

        # Otherwise return the object as is
        return $obj
    } catch {
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

    # Verify that the input is a valid extracted info object
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "Invalid extracted info object"
    }

    try {
        # Create directory if it doesn't exist
        $directory = Split-Path -Parent $FilePath
        if (-not (Test-Path -Path $directory -PathType Container)) {
            New-Item -Path $directory -ItemType Directory -Force | Out-Null
        }

        # Save in the specified format
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
    } catch {
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

    # Verify that the file exists
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        throw "File not found: $FilePath"
    }

    try {
        # Load from the specified format
        switch ($Format.ToLower()) {
            "json" {
                $content = [System.IO.File]::ReadAllText($FilePath)
                $info = ConvertFrom-ExtractedInfoJson -Json $content
                return $info
            }
            default {
                throw "Unsupported format: $Format"
            }
        }
    } catch {
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
        [hashtable]$Info,

        [Parameter(Position = 1)]
        [switch]$UpdateObject
    )

    # Verify that the input is a valid extracted info object
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "Invalid extracted info object"
    }

    # Initialize validation result
    $isValid = $true
    $errors = @()

    # Basic validation for all types
    if ([string]::IsNullOrWhiteSpace($Info.Id)) {
        $isValid = $false
        $errors += "Missing or invalid Id"
    }

    if ([string]::IsNullOrWhiteSpace($Info.Source)) {
        $isValid = $false
        $errors += "Missing or invalid Source"
    }

    if ($Info.ConfidenceScore -lt 0 -or $Info.ConfidenceScore -gt 100) {
        $isValid = $false
        $errors += "ConfidenceScore must be between 0 and 100"
    }

    # Type-specific validation
    switch ($Info._Type) {
        "TextExtractedInfo" {
            if (-not $Info.ContainsKey("Text")) {
                $isValid = $false
                $errors += "TextExtractedInfo must have a Text property"
            }

            if (-not $Info.ContainsKey("Language")) {
                $isValid = $false
                $errors += "TextExtractedInfo must have a Language property"
            }
        }
        "StructuredDataExtractedInfo" {
            if (-not $Info.ContainsKey("Data")) {
                $isValid = $false
                $errors += "StructuredDataExtractedInfo must have a Data property"
            }

            if (-not $Info.ContainsKey("DataFormat")) {
                $isValid = $false
                $errors += "StructuredDataExtractedInfo must have a DataFormat property"
            }
        }
        "MediaExtractedInfo" {
            if (-not $Info.ContainsKey("MediaPath")) {
                $isValid = $false
                $errors += "MediaExtractedInfo must have a MediaPath property"
            }

            if (-not $Info.ContainsKey("MediaType")) {
                $isValid = $false
                $errors += "MediaExtractedInfo must have a MediaType property"
            }
        }
    }

    # Store validation errors in metadata if requested
    if ($UpdateObject) {
        $Info.IsValid = $isValid

        if ($errors.Count -gt 0) {
            $Info.Metadata["_ValidationErrors"] = $errors
            $Info.Metadata["_LastValidated"] = [datetime]::Now.ToString("o")
        } else {
            if ($Info.Metadata.ContainsKey("_ValidationErrors")) {
                $Info.Metadata.Remove("_ValidationErrors")
            }
            $Info.Metadata["_LastValidated"] = [datetime]::Now.ToString("o")
            $Info.Metadata["_IsValid"] = $true
        }
    }

    return $isValid
}

function Get-ValidationErrors {
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [hashtable]$Info
    )

    # Verify that the input is a valid extracted info object
    if ($null -eq $Info -or -not $Info.ContainsKey("_Type")) {
        throw "Invalid extracted info object"
    }

    # Check if validation has been performed
    if ($Info.Metadata.ContainsKey("_ValidationErrors")) {
        return $Info.Metadata["_ValidationErrors"]
    }

    # If not, perform validation now but don't update the object
    $isValid = Test-ExtractedInfo -Info $Info

    # If valid, return empty array
    if ($isValid) {
        return @()
    }

    # Otherwise, perform validation again to get errors
    $errors = @()

    # Basic validation for all types
    if ([string]::IsNullOrWhiteSpace($Info.Id)) {
        $errors += "Missing or invalid Id"
    }

    if ([string]::IsNullOrWhiteSpace($Info.Source)) {
        $errors += "Missing or invalid Source"
    }

    if ($Info.ConfidenceScore -lt 0 -or $Info.ConfidenceScore -gt 100) {
        $errors += "ConfidenceScore must be between 0 and 100"
    }

    # Type-specific validation
    switch ($Info._Type) {
        "TextExtractedInfo" {
            if (-not $Info.ContainsKey("Text")) {
                $errors += "TextExtractedInfo must have a Text property"
            }

            if (-not $Info.ContainsKey("Language")) {
                $errors += "TextExtractedInfo must have a Language property"
            }
        }
        "StructuredDataExtractedInfo" {
            if (-not $Info.ContainsKey("Data")) {
                $errors += "StructuredDataExtractedInfo must have a Data property"
            }

            if (-not $Info.ContainsKey("DataFormat")) {
                $errors += "StructuredDataExtractedInfo must have a DataFormat property"
            }
        }
        "MediaExtractedInfo" {
            if (-not $Info.ContainsKey("MediaPath")) {
                $errors += "MediaExtractedInfo must have a MediaPath property"
            }

            if (-not $Info.ContainsKey("MediaType")) {
                $errors += "MediaExtractedInfo must have a MediaType property"
            }
        }
    }

    return $errors
}

function Add-ValidationRule {
    [CmdletBinding()]
    [OutputType([scriptblock])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$InfoType,

        [Parameter(Mandatory = $true, Position = 2)]
        [scriptblock]$ValidationScript,

        [Parameter(Position = 3)]
        [string]$ErrorMessage = "Validation failed: $Name"
    )

    # Create a new validation rule
    $rule = @{
        Name             = $Name
        InfoType         = $InfoType
        ValidationScript = $ValidationScript
        ErrorMessage     = $ErrorMessage
    }

    # Initialize the validation rules collection if it doesn't exist
    if (-not $script:ModuleData.ContainsKey("ValidationRules")) {
        $script:ModuleData.ValidationRules = @{}
    }

    # Add the rule to the collection
    if (-not $script:ModuleData.ValidationRules.ContainsKey($InfoType)) {
        $script:ModuleData.ValidationRules[$InfoType] = @()
    }

    $script:ModuleData.ValidationRules[$InfoType] += $rule

    return $ValidationScript
}

# Import additional functions from Public\Types directory
$typesPath = Join-Path -Path $script:ModuleRoot -ChildPath "Public\Types"
if (Test-Path -Path $typesPath) {
    $typeFiles = Get-ChildItem -Path $typesPath -Filter "*.ps1" -File
    foreach ($file in $typeFiles) {
        Write-Verbose "Importing type file: $($file.FullName)"
        . $file.FullName
    }
}

# Import additional functions from Public\Merge directory
$mergePath = Join-Path -Path $script:ModuleRoot -ChildPath "Public\Merge"
if (Test-Path -Path $mergePath) {
    $mergeFiles = Get-ChildItem -Path $mergePath -Filter "*.ps1" -File
    foreach ($file in $mergeFiles) {
        Write-Verbose "Importing merge file: $($file.FullName)"
        . $file.FullName
    }
}

# Export public functions
Export-ModuleMember -Function @(
    # Creation functions
    'New-ExtractedInfo',
    'New-TextExtractedInfo',
    'New-StructuredDataExtractedInfo',
    'New-MediaExtractedInfo',
    'New-GeoLocationExtractedInfo',
    'Copy-ExtractedInfo',

    # Metadata functions
    'Add-ExtractedInfoMetadata',
    'Get-ExtractedInfoMetadata',
    'Remove-ExtractedInfoMetadata',
    'Get-ExtractedInfoSummary',

    # Collection functions
    'New-ExtractedInfoCollection',
    'Add-ExtractedInfoToCollection',
    'Remove-ExtractedInfoFromCollection',
    'Get-ExtractedInfoFromCollection',
    'Get-ExtractedInfoCollectionStatistics',

    # Serialization functions
    'ConvertTo-ExtractedInfoJson',
    'ConvertFrom-ExtractedInfoJson',
    'Save-ExtractedInfoToFile',
    'Import-ExtractedInfoFromFile',

    # Export functions
    'Export-GeoLocationExtractedInfo',
    'Export-GenericExtractedInfo',

    # Validation functions
    'Test-ExtractedInfo',
    'Get-ValidationErrors',
    'Add-ValidationRule',

    # Merge functions
    'Merge-ExtractedInfo',
    'Test-ExtractedInfoCompatibility',
    'Merge-ExtractedInfoMetadata',
    'Get-MergedConfidenceScore'
)
