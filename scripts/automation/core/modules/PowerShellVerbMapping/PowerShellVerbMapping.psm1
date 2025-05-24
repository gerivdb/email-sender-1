#
# PowerShell Verb Mapping Module
# Provides standardized verb mappings for PowerShell function name validation and correction
#

#region Private Variables

# Cache for approved verbs to avoid repeated Get-Verb calls
$script:ApprovedVerbsCache = $null

#endregion

#region Public Functions

<#
.SYNOPSIS
    Gets the list of PowerShell approved verbs.

.DESCRIPTION
    Returns a cached list of approved PowerShell verbs using Get-Verb cmdlet.
    The list is cached for performance across multiple calls.

.EXAMPLE
    $approvedVerbs = Get-ApprovedVerbs
#>
function Get-ApprovedVerbs {
    [CmdletBinding()]
    [OutputType([string[]])]
    param()
    
    if ($null -eq $script:ApprovedVerbsCache) {
        Write-Verbose "Loading approved verbs from Get-Verb..."
        $script:ApprovedVerbsCache = Get-Verb | Select-Object -ExpandProperty Verb
        Write-Verbose "Loaded $($script:ApprovedVerbsCache.Count) approved verbs"
    }
    
    return $script:ApprovedVerbsCache
}

<#
.SYNOPSIS
    Gets the verb mapping table for common unapproved verbs.

.DESCRIPTION
    Returns a hashtable mapping common unapproved verbs to their approved equivalents.
    This mapping is used for automatic function name corrections.

.EXAMPLE
    $mappings = Get-VerbMappings
    $suggestedVerb = $mappings['Create']  # Returns 'New'
#>
function Get-VerbMappings {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    return @{
        'Analyze'     = 'Test'
        'Check'       = 'Test'
        'Create'      = 'New'
        'Extract'     = 'Export'
        'Fix'         = 'Repair'
        'Generate'    = 'New'
        'Manage'      = 'Set'
        'Process'     = 'Invoke'
        'Pull'        = 'Get'
        'Release'     = 'Publish'
        'Clone'       = 'Copy'
        'Detect'      = 'Find'
        'Handle'      = 'Invoke'
        'Run'         = 'Start'
        'Execute'     = 'Invoke'
        'Build'       = 'New'
        'Save'        = 'Export'
        'Load'        = 'Import'
        'Delete'      = 'Remove'
        'Destroy'     = 'Remove'
        'Kill'        = 'Stop'
        'Launch'      = 'Start'
        'Trigger'     = 'Invoke'
        'Validate'    = 'Test'
        'Verify'      = 'Confirm'
        'Navigate'    = 'Move'
        'Browse'      = 'Find'
        'Query'       = 'Get'
        'Fetch'       = 'Get'
        'Retrieve'    = 'Get'
        'Collect'     = 'Get'
        'Gather'      = 'Get'
        'Ensure'      = 'Confirm'
        'Apply'       = 'Set'
        'Configure'   = 'Set'
        'Setup'       = 'Initialize'
        'Install'     = 'Install'
        'Deploy'      = 'Deploy'
        'Propagate'   = 'Copy'
        'Plan'        = 'New'
    }
}

<#
.SYNOPSIS
    Tests if a verb is approved for PowerShell functions.

.DESCRIPTION
    Checks if the provided verb is in the list of PowerShell approved verbs.

.PARAMETER Verb
    The verb to test for approval.

.EXAMPLE
    Test-VerbApproved -Verb "Get"     # Returns $true
    Test-VerbApproved -Verb "Create"  # Returns $false
#>
function Test-VerbApproved {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Verb
    )
    
    $approvedVerbs = Get-ApprovedVerbs
    return $Verb -in $approvedVerbs
}

<#
.SYNOPSIS
    Gets a suggested approved verb for an unapproved verb.

.DESCRIPTION
    Returns the suggested approved verb mapping for a given unapproved verb.
    Returns $null if no mapping is available.

.PARAMETER Verb
    The unapproved verb to get a suggestion for.

.EXAMPLE
    Get-VerbSuggestion -Verb "Create"  # Returns "New"
    Get-VerbSuggestion -Verb "Unknown" # Returns $null
#>
function Get-VerbSuggestion {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Verb
    )
    
    $mappings = Get-VerbMappings
    return $mappings[$Verb]
}

<#
.SYNOPSIS
    Adds a custom verb mapping to the module's mapping table.

.DESCRIPTION
    Allows adding custom verb mappings for project-specific needs.
    These mappings are stored in memory and persist for the module session.

.PARAMETER UnapprovedVerb
    The unapproved verb to map.

.PARAMETER ApprovedVerb
    The approved verb to map to.

.EXAMPLE
    Add-VerbMapping -UnapprovedVerb "Customize" -ApprovedVerb "Set"
#>
function Add-VerbMapping {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UnapprovedVerb,
        
        [Parameter(Mandatory = $true)]
        [string]$ApprovedVerb
    )
    
    # Validate that the approved verb is actually approved
    if (-not (Test-VerbApproved -Verb $ApprovedVerb)) {
        throw "The suggested verb '$ApprovedVerb' is not an approved PowerShell verb."
    }
    
    # Get current mappings and add the new one
    $mappings = Get-VerbMappings
    $mappings[$UnapprovedVerb] = $ApprovedVerb
    
    Write-Verbose "Added verb mapping: $UnapprovedVerb -> $ApprovedVerb"
}

<#
.SYNOPSIS
    Gets statistics about verb usage in the mapping table.

.DESCRIPTION
    Returns statistical information about the verb mappings, including
    most common suggested verbs and total mappings available.

.EXAMPLE
    Get-VerbMappingStatistics
#>
function Get-VerbMappingStatistics {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
    $mappings = Get-VerbMappings
    $approvedVerbs = Get-ApprovedVerbs
    
    $stats = [PSCustomObject]@{
        TotalMappings = $mappings.Count
        TotalApprovedVerbs = $approvedVerbs.Count
        MostCommonSuggestions = $mappings.Values | Group-Object | Sort-Object Count -Descending | Select-Object -First 5
        UnmappedApprovedVerbs = $approvedVerbs | Where-Object { $_ -notin $mappings.Values }
    }
    
    return $stats
}

#endregion

#region Module Exports

# Export all public functions
Export-ModuleMember -Function @(
    'Get-ApprovedVerbs',
    'Get-VerbMappings',
    'Test-VerbApproved',
    'Get-VerbSuggestion',
    'Add-VerbMapping',
    'Get-VerbMappingStatistics'
)

#endregion