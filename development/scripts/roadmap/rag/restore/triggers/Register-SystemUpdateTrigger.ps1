# Register-SystemUpdateTrigger.ps1
# Script pour enregistrer des déclencheurs de mises à jour système
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Minor", "Major", "Patch", "All")]
    [string]$UpdateType = "All",
    
    [Parameter(Mandatory = $false)]
    [string]$ComponentName = "",
    
    [Parameter(Mandatory = $false)]
    [string]$TriggerName,
    
    [Parameter(Mandatory = $false)]
    [string]$Description,
    
    [Parameter(Mandatory = $false)]
    [scriptblock]$Condition,
    
    [Parameter(Mandatory = $false)]
    [scriptblock]$Action,
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateRestorePoint = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$Enabled = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $rootPath))) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Importer le script d'enregistrement de déclencheur
$registerTriggerPath = Join-Path -Path $scriptPath -ChildPath "Register-RestoreTrigger.ps1"

if (Test-Path -Path $registerTriggerPath) {
    . $registerTriggerPath
} else {
    Write-Log "Required script not found: $registerTriggerPath" -Level "Error"
    exit 1
}

# Fonction pour générer un nom de déclencheur par défaut
function Get-DefaultTriggerName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$UpdateType,
        
        [Parameter(Mandatory = $false)]
        [string]$ComponentName = ""
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    if ([string]::IsNullOrEmpty($ComponentName)) {
        return "SystemUpdate-$UpdateType-$timestamp"
    } else {
        $componentShort = $ComponentName -replace "[^a-zA-Z0-9]", ""
        
        if ($componentShort.Length -gt 10) {
            $componentShort = $componentShort.Substring(0, 10)
        }
        
        return "SystemUpdate-$UpdateType-$componentShort-$timestamp"
    }
}

# Fonction pour créer une action de création de point de restauration
function New-RestorePointAction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$UpdateType
    )
    
    $actionScript = @"
# Action de création de point de restauration
param(`$EventData)

# Importer le script de création de point de restauration
`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$createRestorePointPath = Join-Path -Path `$scriptPath -ChildPath "..\..\New-RestorePoint.ps1"

if (Test-Path -Path `$createRestorePointPath) {
    . `$createRestorePointPath
} else {
    Write-Host "Required script not found: `$createRestorePointPath" -ForegroundColor Red
    return `$false
}

# Extraire les données de l'événement
`$updateType = `$EventData.UpdateType
`$componentName = `$EventData.ComponentName
`$oldVersion = `$EventData.OldVersion
`$newVersion = `$EventData.NewVersion
`$updateDetails = `$EventData.UpdateDetails

# Générer un nom pour le point de restauration
`$restorePointName = "Pre-Update-`$componentName-`$oldVersion-to-`$newVersion-`$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Créer le point de restauration
`$result = New-RestorePoint -Name `$restorePointName -Type "pre-update" -Tags @("system-update", `$updateType.ToLower(), `$componentName) -Description "Pre-update restore point for `$componentName upgrade from `$oldVersion to `$newVersion" -SystemState @{
    update_type = `$updateType
    component_name = `$componentName
    old_version = `$oldVersion
    new_version = `$newVersion
    update_details = `$updateDetails
}

return `$result
"@
    
    return [scriptblock]::Create($actionScript)
}

# Fonction pour créer une condition de vérification
function New-VerificationCondition {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$UpdateType,
        
        [Parameter(Mandatory = $false)]
        [string]$ComponentName = ""
    )
    
    $conditionScript = @"
# Condition de vérification
param(`$EventData)

# Vérifier si les données de l'événement sont valides
if (`$null -eq `$EventData) {
    return `$false
}

# Vérifier le type de mise à jour
if ('$UpdateType' -ne 'All' -and `$EventData.UpdateType -ne '$UpdateType') {
    return `$false
}

# Vérifier le composant si spécifié
if ('$ComponentName' -ne '' -and `$EventData.ComponentName -ne '$ComponentName') {
    return `$false
}

# Vérifier si les versions sont valides
if ([string]::IsNullOrEmpty(`$EventData.OldVersion) -or [string]::IsNullOrEmpty(`$EventData.NewVersion)) {
    return `$false
}

# Vérifier si la mise à jour est significative
try {
    `$oldVersion = [Version]`$EventData.OldVersion
    `$newVersion = [Version]`$EventData.NewVersion
    
    # Vérifier si c'est une mise à jour (et non un downgrade)
    if (`$newVersion -le `$oldVersion) {
        return `$false
    }
    
    # Vérifier le type de mise à jour si spécifié
    if ('$UpdateType' -ne 'All') {
        switch ('$UpdateType') {
            'Major' {
                return `$newVersion.Major -gt `$oldVersion.Major
            }
            'Minor' {
                return `$newVersion.Major -eq `$oldVersion.Major -and `$newVersion.Minor -gt `$oldVersion.Minor
            }
            'Patch' {
                return `$newVersion.Major -eq `$oldVersion.Major -and `$newVersion.Minor -eq `$oldVersion.Minor -and `$newVersion.Build -gt `$oldVersion.Build
            }
        }
    }
} catch {
    # Si les versions ne sont pas au format standard, comparer les chaînes
    return `$EventData.NewVersion -ne `$EventData.OldVersion
}

return `$true
"@
    
    return [scriptblock]::Create($conditionScript)
}

# Fonction pour enregistrer un déclencheur de mise à jour système
function Register-SystemUpdateTrigger {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Minor", "Major", "Patch", "All")]
        [string]$UpdateType = "All",
        
        [Parameter(Mandatory = $false)]
        [string]$ComponentName = "",
        
        [Parameter(Mandatory = $false)]
        [string]$TriggerName,
        
        [Parameter(Mandatory = $false)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$Condition,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$Action,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateRestorePoint = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$Enabled = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Générer un nom de déclencheur par défaut si non fourni
    if ([string]::IsNullOrEmpty($TriggerName)) {
        $TriggerName = Get-DefaultTriggerName -UpdateType $UpdateType -ComponentName $ComponentName
    }
    
    # Générer une description par défaut si non fournie
    if ([string]::IsNullOrEmpty($Description)) {
        if ([string]::IsNullOrEmpty($ComponentName)) {
            $Description = "System update trigger for $UpdateType updates"
        } else {
            $Description = "System update trigger for $UpdateType updates of component '$ComponentName'"
        }
    }
    
    # Créer une condition par défaut si non fournie
    if ($null -eq $Condition) {
        $Condition = New-VerificationCondition -UpdateType $UpdateType -ComponentName $ComponentName
    }
    
    # Créer une action par défaut si non fournie et si CreateRestorePoint est activé
    if ($null -eq $Action -and $CreateRestorePoint) {
        $Action = New-RestorePointAction -UpdateType $UpdateType
    }
    
    # Créer les paramètres du déclencheur
    $parameters = @{
        "UpdateType" = $UpdateType
    }
    
    if (-not [string]::IsNullOrEmpty($ComponentName)) {
        $parameters["ComponentName"] = $ComponentName
    }
    
    # Enregistrer le déclencheur
    $result = Register-RestoreTrigger -TriggerType "SystemUpdate" -TriggerName $TriggerName -Description $Description -Parameters $parameters -Condition $Condition -Action $Action -Enabled:$Enabled -Force:$Force
    
    if ($result) {
        Write-Log "System update trigger registered successfully: $TriggerName" -Level "Info"
        return $true
    } else {
        Write-Log "Failed to register system update trigger: $TriggerName" -Level "Error"
        return $false
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Register-SystemUpdateTrigger -UpdateType $UpdateType -ComponentName $ComponentName -TriggerName $TriggerName -Description $Description -Condition $Condition -Action $Action -CreateRestorePoint:$CreateRestorePoint -Enabled:$Enabled -Force:$Force
}
