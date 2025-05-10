# New-RestorePoint.ps1
# Script pour créer un nouveau point de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Name,
    
    [Parameter(Mandatory = $false)]
    [string]$Description,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("manual", "automatic", "scheduled", "pre-update", "pre-migration", "git-commit")]
    [string]$Type = "manual",
    
    [Parameter(Mandatory = $false)]
    [string[]]$Tags = @(),
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
    [string]$ConfigType,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigId,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory = $false)]
    [object]$Configuration,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$GitInfo,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$SystemState,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$Compress = $true,
    
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
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $rootPath)) -ChildPath "utils"
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

# Importer le script de sauvegarde de configuration
$saveConfigPath = Join-Path -Path $scriptPath -ChildPath "Save-ConfigurationState.ps1"

if (Test-Path -Path $saveConfigPath) {
    . $saveConfigPath
} else {
    Write-Log "Required script not found: $saveConfigPath" -Level "Error"
    exit 1
}

# Fonction pour générer un nom de point de restauration par défaut
function Get-DefaultRestorePointName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Type,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigType = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigId = ""
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    if ([string]::IsNullOrEmpty($ConfigType) -or [string]::IsNullOrEmpty($ConfigId)) {
        return "$Type-$timestamp"
    } else {
        return "$Type-$ConfigType-$ConfigId-$timestamp"
    }
}

# Fonction pour obtenir le chemin du répertoire des points de restauration
function Get-RestorePointsPath {
    [CmdletBinding()]
    param()
    
    $pointsPath = Join-Path -Path $scriptPath -ChildPath "points"
    
    if (-not (Test-Path -Path $pointsPath)) {
        New-Item -Path $pointsPath -ItemType Directory -Force | Out-Null
    }
    
    return $pointsPath
}

# Fonction pour obtenir le chemin du répertoire des états de configuration
function Get-ConfigurationStatesPath {
    [CmdletBinding()]
    param()
    
    $statesPath = Join-Path -Path $scriptPath -ChildPath "states"
    
    if (-not (Test-Path -Path $statesPath)) {
        New-Item -Path $statesPath -ItemType Directory -Force | Out-Null
    }
    
    return $statesPath
}

# Fonction pour créer un nouveau point de restauration
function New-RestorePoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("manual", "automatic", "scheduled", "pre-update", "pre-migration", "git-commit")]
        [string]$Type = "manual",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @(),
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigId,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $false)]
        [object]$Configuration,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$GitInfo,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$SystemState,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Compress = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Générer un nom par défaut si non fourni
    if ([string]::IsNullOrEmpty($Name)) {
        $Name = Get-DefaultRestorePointName -Type $Type -ConfigType $ConfigType -ConfigId $ConfigId
    }
    
    # Générer une description par défaut si non fournie
    if ([string]::IsNullOrEmpty($Description)) {
        $Description = "Restore point created on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        
        if (-not [string]::IsNullOrEmpty($ConfigType) -and -not [string]::IsNullOrEmpty($ConfigId)) {
            $Description += " for $ConfigType configuration '$ConfigId'"
        }
    }
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = Get-RestorePointsPath
    }
    
    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Générer un ID unique pour le point de restauration
    $restorePointId = [Guid]::NewGuid().ToString()
    
    # Créer les métadonnées du point de restauration
    $metadata = @{
        id = $restorePointId
        name = $Name
        description = $Description
        type = $Type
        created_at = (Get-Date).ToString("o")
        created_by = [Environment]::UserName
        tags = $Tags
        expiration = @{
            expires_at = (Get-Date).AddDays(30).ToString("o")
            retention_policy = "keep-for-duration"
            retention_days = 30
        }
        validation = @{
            status = "pending"
        }
    }
    
    # Ajouter les informations Git si fournies
    if ($null -ne $GitInfo -and $GitInfo.Count -gt 0) {
        $metadata.git_info = $GitInfo
    }
    
    # Initialiser le contenu du point de restauration
    $content = @{
        configurations = @()
        system_state = @{}
    }
    
    # Ajouter l'état du système si fourni
    if ($null -ne $SystemState -and $SystemState.Count -gt 0) {
        $content.system_state = $SystemState
    } else {
        # Ajouter des informations système de base
        $content.system_state = @{
            system_version = "1.0.0" # À remplacer par la version réelle du système
            environment = "development" # À remplacer par l'environnement réel
        }
    }
    
    # Sauvegarder la configuration si fournie
    if ((-not [string]::IsNullOrEmpty($ConfigPath) -or $null -ne $Configuration) -and -not [string]::IsNullOrEmpty($ConfigType)) {
        # Déterminer le chemin des états de configuration
        $statesPath = Get-ConfigurationStatesPath
        
        # Sauvegarder l'état de la configuration
        $saveResult = Save-ConfigurationState -ConfigType $ConfigType -ConfigId $ConfigId -ConfigPath $ConfigPath -Configuration $Configuration -OutputPath $statesPath -Compress:$Compress -Force:$Force
        
        if ($saveResult) {
            Write-Log "Configuration state saved successfully" -Level "Info"
            
            # Ajouter la configuration au contenu du point de restauration
            $configState = @{
                type = $ConfigType
                id = $ConfigId
                version = "1.0" # À remplacer par la version réelle de la configuration
                state_file = "states/$($ConfigType.ToLower())_$($ConfigId)_state.json"
            }
            
            $content.configurations += $configState
        } else {
            Write-Log "Failed to save configuration state" -Level "Error"
        }
    }
    
    # Initialiser les informations de restauration
    $restoreInfo = @{
        restore_history = @()
        restore_options = @{
            recommended_method = "full"
        }
    }
    
    # Créer le point de restauration complet
    $restorePoint = @{
        metadata = $metadata
        content = $content
        restore_info = $restoreInfo
    }
    
    # Déterminer le chemin du fichier de point de restauration
    $restorePointFileName = "$restorePointId.json"
    $restorePointFilePath = Join-Path -Path $OutputPath -ChildPath $restorePointFileName
    
    # Vérifier si le fichier existe déjà
    if (Test-Path -Path $restorePointFilePath) {
        if (-not $Force) {
            Write-Log "Restore point file already exists: $restorePointFilePath. Use -Force to overwrite." -Level "Warning"
            return $false
        }
        
        Write-Log "Overwriting existing restore point file: $restorePointFilePath" -Level "Warning"
    }
    
    # Sauvegarder le point de restauration
    try {
        $restorePoint | ConvertTo-Json -Depth 10 | Out-File -FilePath $restorePointFilePath -Encoding UTF8
        Write-Log "Restore point created successfully: $Name ($restorePointId)" -Level "Info"
        return $restorePoint
    } catch {
        Write-Log "Error creating restore point: $_" -Level "Error"
        return $false
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    New-RestorePoint -Name $Name -Description $Description -Type $Type -Tags $Tags -ConfigType $ConfigType -ConfigId $ConfigId -ConfigPath $ConfigPath -Configuration $Configuration -GitInfo $GitInfo -SystemState $SystemState -OutputPath $OutputPath -Compress:$Compress -Force:$Force
}
