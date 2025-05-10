# Manage-Configuration.ps1
# Script pour gérer les configurations du système de roadmap
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Get", "Save", "Update", "Delete", "List", "Validate", "Export", "Import")]
    [string]$Action = "Get",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
    [string]$ConfigType,
    
    [Parameter(Mandatory = $false)]
    [string]$Name,
    
    [Parameter(Mandatory = $false)]
    [string]$Version,
    
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeHistory,
    
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

# Importer les scripts de schéma et de versionnage
$schemaPath = Join-Path -Path $scriptPath -ChildPath "schema\Get-ConfigurationSchema.ps1"
$versioningPath = Join-Path -Path $scriptPath -ChildPath "schema\Get-VersioningRules.ps1"

if (Test-Path -Path $schemaPath) {
    . $schemaPath
} else {
    Write-Log "Schema script not found: $schemaPath" -Level "Error"
    exit 1
}

if (Test-Path -Path $versioningPath) {
    . $versioningPath
} else {
    Write-Log "Versioning script not found: $versioningPath" -Level "Error"
    exit 1
}

# Fonction pour obtenir le chemin de base des configurations
function Get-ConfigurationBasePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $false)]
        [switch]$History
    )
    
    $configRules = Get-VersioningRules -ConfigType "All" -AsObject
    $baseFolder = $configRules.global.storage.base_folder
    $historyFolder = $configRules.global.storage.history_folder
    
    $configTypeFolder = $ConfigType.ToLower()
    
    $basePath = Join-Path -Path $rootPath -ChildPath $baseFolder
    $typePath = Join-Path -Path $basePath -ChildPath $configTypeFolder
    
    if ($History) {
        $typePath = Join-Path -Path $typePath -ChildPath $historyFolder
    }
    
    # Créer les répertoires s'ils n'existent pas
    if (-not (Test-Path -Path $basePath)) {
        New-Item -Path $basePath -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-Path -Path $typePath)) {
        New-Item -Path $typePath -ItemType Directory -Force | Out-Null
    }
    
    return $typePath
}

# Fonction pour générer le nom de fichier d'une configuration
function Get-ConfigurationFileName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Version
    )
    
    $configRules = Get-VersioningRules -ConfigType $ConfigType -AsObject
    $namingConvention = $configRules.storage.naming_convention
    
    $fileName = $namingConvention -replace "{name}", $Name -replace "{version}", $Version
    
    return $fileName
}

# Fonction pour valider une configuration
function Test-Configuration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [object]$Configuration
    )
    
    # Obtenir le schéma pour ce type de configuration
    $schema = Get-ConfigurationSchema -SchemaType $ConfigType -AsObject
    
    # Vérifier les champs requis
    foreach ($requiredField in $schema.required) {
        if (-not $Configuration.PSObject.Properties.Name.Contains($requiredField)) {
            Write-Log "Missing required field: $requiredField" -Level "Error"
            return $false
        }
    }
    
    # Vérifier le format de version
    $versionRules = Get-VersioningRules -ConfigType $ConfigType -AsObject
    $versionPattern = $versionRules.version_pattern
    
    if ($Configuration.version -notmatch $versionPattern) {
        Write-Log "Invalid version format: $($Configuration.version). Expected pattern: $versionPattern" -Level "Error"
        return $false
    }
    
    # Vérification réussie
    return $true
}

# Fonction pour obtenir une configuration
function Get-Configuration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$Version,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeHistory
    )
    
    $configPath = Get-ConfigurationBasePath -ConfigType $ConfigType
    
    # Si une version spécifique est demandée
    if (-not [string]::IsNullOrEmpty($Version)) {
        $fileName = Get-ConfigurationFileName -ConfigType $ConfigType -Name $Name -Version $Version
        $filePath = Join-Path -Path $configPath -ChildPath $fileName
        
        if (Test-Path -Path $filePath) {
            try {
                $config = Get-Content -Path $filePath -Raw | ConvertFrom-Json
                Write-Log "Configuration loaded: $filePath" -Level "Info"
                return $config
            } catch {
                Write-Log "Error loading configuration: $_" -Level "Error"
                return $null
            }
        } else {
            # Vérifier dans l'historique si demandé
            if ($IncludeHistory) {
                $historyPath = Get-ConfigurationBasePath -ConfigType $ConfigType -History
                $historyFilePath = Join-Path -Path $historyPath -ChildPath $fileName
                
                if (Test-Path -Path $historyFilePath) {
                    try {
                        $config = Get-Content -Path $historyFilePath -Raw | ConvertFrom-Json
                        Write-Log "Configuration loaded from history: $historyFilePath" -Level "Info"
                        return $config
                    } catch {
                        Write-Log "Error loading configuration from history: $_" -Level "Error"
                        return $null
                    }
                }
            }
            
            Write-Log "Configuration not found: $Name v$Version" -Level "Warning"
            return $null
        }
    }
    
    # Si aucune version n'est spécifiée, obtenir la dernière version
    $pattern = "*$Name*"
    $files = Get-ChildItem -Path $configPath -Filter $pattern | Where-Object { $_.Name -match "_v\d+(\.\d+){1,2}\.json$" }
    
    if ($files.Count -eq 0) {
        Write-Log "No configurations found for: $Name" -Level "Warning"
        return $null
    }
    
    # Extraire les versions et trier
    $versions = @()
    foreach ($file in $files) {
        if ($file.Name -match "_v(\d+\.\d+(?:\.\d+)?)\.json$") {
            $version = $matches[1]
            $versions += @{
                Version = $version
                File = $file
            }
        }
    }
    
    # Trier les versions (en supposant un format SemVer)
    $sortedVersions = $versions | Sort-Object -Property { 
        $v = $_.Version -split "\."
        [int]$v[0] * 1000000 + [int]$v[1] * 1000 + $(if ($v.Length -gt 2) { [int]$v[2] } else { 0 })
    } -Descending
    
    if ($sortedVersions.Count -gt 0) {
        $latestFile = $sortedVersions[0].File
        
        try {
            $config = Get-Content -Path $latestFile.FullName -Raw | ConvertFrom-Json
            Write-Log "Latest configuration loaded: $($latestFile.Name)" -Level "Info"
            return $config
        } catch {
            Write-Log "Error loading latest configuration: $_" -Level "Error"
            return $null
        }
    }
    
    return $null
}

# Fonction pour sauvegarder une configuration
function Save-Configuration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $false)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [object]$Configuration,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si un fichier ou une configuration est fourni
    if ([string]::IsNullOrEmpty($FilePath) -and $null -eq $Configuration) {
        Write-Log "Either FilePath or Configuration must be provided" -Level "Error"
        return $false
    }
    
    # Charger la configuration à partir du fichier si nécessaire
    if (-not [string]::IsNullOrEmpty($FilePath)) {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Log "Configuration file not found: $FilePath" -Level "Error"
            return $false
        }
        
        try {
            $Configuration = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
        } catch {
            Write-Log "Error loading configuration from file: $_" -Level "Error"
            return $false
        }
    }
    
    # Valider la configuration
    if (-not (Test-Configuration -ConfigType $ConfigType -Configuration $Configuration)) {
        if (-not $Force) {
            Write-Log "Configuration validation failed. Use -Force to save anyway." -Level "Error"
            return $false
        } else {
            Write-Log "Configuration validation failed, but saving anyway due to -Force." -Level "Warning"
        }
    }
    
    # Obtenir le chemin de sauvegarde
    $configPath = Get-ConfigurationBasePath -ConfigType $ConfigType
    $fileName = Get-ConfigurationFileName -ConfigType $ConfigType -Name $Configuration.name -Version $Configuration.version
    $savePath = Join-Path -Path $configPath -ChildPath $fileName
    
    # Vérifier si la configuration existe déjà
    if (Test-Path -Path $savePath) {
        if (-not $Force) {
            Write-Log "Configuration already exists: $savePath. Use -Force to overwrite." -Level "Error"
            return $false
        } else {
            # Sauvegarder la version existante dans l'historique
            $historyPath = Get-ConfigurationBasePath -ConfigType $ConfigType -History
            $historyFilePath = Join-Path -Path $historyPath -ChildPath $fileName
            
            try {
                Copy-Item -Path $savePath -Destination $historyFilePath -Force
                Write-Log "Existing configuration backed up to history: $historyFilePath" -Level "Info"
            } catch {
                Write-Log "Error backing up existing configuration: $_" -Level "Warning"
            }
        }
    }
    
    # Sauvegarder la configuration
    try {
        $Configuration | ConvertTo-Json -Depth 10 | Out-File -FilePath $savePath -Encoding UTF8
        Write-Log "Configuration saved: $savePath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error saving configuration: $_" -Level "Error"
        return $false
    }
}

# Fonction pour mettre à jour une configuration
function Update-Configuration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$Version,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Updates,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Obtenir la configuration existante
    $config = Get-Configuration -ConfigType $ConfigType -Name $Name -Version $Version
    
    if ($null -eq $config) {
        Write-Log "Configuration not found: $Name" -Level "Error"
        return $false
    }
    
    # Appliquer les mises à jour
    foreach ($key in $Updates.Keys) {
        # Vérifier si la propriété existe
        if ($config.PSObject.Properties.Name.Contains($key)) {
            $config.$key = $Updates[$key]
        } else {
            # Ajouter la propriété si elle n'existe pas
            $config | Add-Member -MemberType NoteProperty -Name $key -Value $Updates[$key]
        }
    }
    
    # Mettre à jour la date de modification
    $config.updated_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Sauvegarder la configuration mise à jour
    return Save-Configuration -ConfigType $ConfigType -Configuration $config -Force:$Force
}

# Fonction pour supprimer une configuration
function Remove-Configuration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$Version,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    $configPath = Get-ConfigurationBasePath -ConfigType $ConfigType
    
    # Si une version spécifique est demandée
    if (-not [string]::IsNullOrEmpty($Version)) {
        $fileName = Get-ConfigurationFileName -ConfigType $ConfigType -Name $Name -Version $Version
        $filePath = Join-Path -Path $configPath -ChildPath $fileName
        
        if (Test-Path -Path $filePath) {
            # Sauvegarder dans l'historique avant de supprimer
            $historyPath = Get-ConfigurationBasePath -ConfigType $ConfigType -History
            $historyFilePath = Join-Path -Path $historyPath -ChildPath $fileName
            
            try {
                Copy-Item -Path $filePath -Destination $historyFilePath -Force
                Write-Log "Configuration backed up to history: $historyFilePath" -Level "Info"
            } catch {
                if (-not $Force) {
                    Write-Log "Error backing up configuration: $_. Use -Force to delete anyway." -Level "Error"
                    return $false
                } else {
                    Write-Log "Error backing up configuration: $_. Deleting anyway due to -Force." -Level "Warning"
                }
            }
            
            # Supprimer la configuration
            try {
                Remove-Item -Path $filePath -Force
                Write-Log "Configuration deleted: $filePath" -Level "Info"
                return $true
            } catch {
                Write-Log "Error deleting configuration: $_" -Level "Error"
                return $false
            }
        } else {
            Write-Log "Configuration not found: $Name v$Version" -Level "Warning"
            return $false
        }
    }
    
    # Si aucune version n'est spécifiée, supprimer toutes les versions
    $pattern = "*$Name*"
    $files = Get-ChildItem -Path $configPath -Filter $pattern | Where-Object { $_.Name -match "_v\d+(\.\d+){1,2}\.json$" }
    
    if ($files.Count -eq 0) {
        Write-Log "No configurations found for: $Name" -Level "Warning"
        return $false
    }
    
    $success = $true
    
    foreach ($file in $files) {
        # Sauvegarder dans l'historique avant de supprimer
        $historyPath = Get-ConfigurationBasePath -ConfigType $ConfigType -History
        $historyFilePath = Join-Path -Path $historyPath -ChildPath $file.Name
        
        try {
            Copy-Item -Path $file.FullName -Destination $historyFilePath -Force
            Write-Log "Configuration backed up to history: $historyFilePath" -Level "Info"
        } catch {
            if (-not $Force) {
                Write-Log "Error backing up configuration: $_. Use -Force to delete anyway." -Level "Error"
                $success = $false
                continue
            } else {
                Write-Log "Error backing up configuration: $_. Deleting anyway due to -Force." -Level "Warning"
            }
        }
        
        # Supprimer la configuration
        try {
            Remove-Item -Path $file.FullName -Force
            Write-Log "Configuration deleted: $($file.FullName)" -Level "Info"
        } catch {
            Write-Log "Error deleting configuration: $_" -Level "Error"
            $success = $false
        }
    }
    
    return $success
}

# Fonction pour lister les configurations
function Get-ConfigurationList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $false)]
        [string]$NameFilter,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeHistory
    )
    
    $configPath = Get-ConfigurationBasePath -ConfigType $ConfigType
    
    # Obtenir les fichiers de configuration
    $pattern = if ([string]::IsNullOrEmpty($NameFilter)) { "*.json" } else { "*$NameFilter*.json" }
    $files = Get-ChildItem -Path $configPath -Filter $pattern | Where-Object { $_.Name -match "_v\d+(\.\d+){1,2}\.json$" }
    
    $configurations = @()
    
    foreach ($file in $files) {
        try {
            $config = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            
            $configurations += @{
                Name = $config.name
                Version = $config.version
                Description = $config.description
                UpdatedAt = $config.updated_at
                FilePath = $file.FullName
                FileName = $file.Name
            }
        } catch {
            Write-Log "Error loading configuration: $($file.FullName): $_" -Level "Warning"
        }
    }
    
    # Inclure l'historique si demandé
    if ($IncludeHistory) {
        $historyPath = Get-ConfigurationBasePath -ConfigType $ConfigType -History
        
        if (Test-Path -Path $historyPath) {
            $historyFiles = Get-ChildItem -Path $historyPath -Filter $pattern | Where-Object { $_.Name -match "_v\d+(\.\d+){1,2}\.json$" }
            
            foreach ($file in $historyFiles) {
                try {
                    $config = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                    
                    $configurations += @{
                        Name = $config.name
                        Version = $config.version
                        Description = $config.description
                        UpdatedAt = $config.updated_at
                        FilePath = $file.FullName
                        FileName = $file.Name
                        IsHistory = $true
                    }
                } catch {
                    Write-Log "Error loading history configuration: $($file.FullName): $_" -Level "Warning"
                }
            }
        }
    }
    
    # Trier par nom et version
    $sortedConfigurations = $configurations | Sort-Object -Property Name, @{
        Expression = {
            $v = $_.Version -split "\."
            [int]$v[0] * 1000000 + [int]$v[1] * 1000 + $(if ($v.Length -gt 2) { [int]$v[2] } else { 0 })
        }
        Descending = $true
    }
    
    return $sortedConfigurations
}

# Fonction pour exporter une configuration
function Export-Configuration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$Version,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    # Obtenir la configuration
    $config = Get-Configuration -ConfigType $ConfigType -Name $Name -Version $Version
    
    if ($null -eq $config) {
        Write-Log "Configuration not found: $Name" -Level "Error"
        return $false
    }
    
    # Exporter la configuration
    try {
        $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Log "Configuration exported to: $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error exporting configuration: $_" -Level "Error"
        return $false
    }
}

# Fonction pour importer une configuration
function Import-Configuration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Log "Import file not found: $FilePath" -Level "Error"
        return $false
    }
    
    # Charger la configuration
    try {
        $config = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
    } catch {
        Write-Log "Error loading import file: $_" -Level "Error"
        return $false
    }
    
    # Sauvegarder la configuration
    return Save-Configuration -ConfigType $ConfigType -Configuration $config -Force:$Force
}

# Fonction principale
function Manage-Configuration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Get", "Save", "Update", "Delete", "List", "Validate", "Export", "Import")]
        [string]$Action = "Get",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $false)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$Version,
        
        [Parameter(Mandatory = $false)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeHistory
    )
    
    switch ($Action) {
        "Get" {
            if ([string]::IsNullOrEmpty($ConfigType) -or [string]::IsNullOrEmpty($Name)) {
                Write-Log "ConfigType and Name are required for Get action" -Level "Error"
                return $null
            }
            
            return Get-Configuration -ConfigType $ConfigType -Name $Name -Version $Version -IncludeHistory:$IncludeHistory
        }
        "Save" {
            if ([string]::IsNullOrEmpty($ConfigType)) {
                Write-Log "ConfigType is required for Save action" -Level "Error"
                return $false
            }
            
            return Save-Configuration -ConfigType $ConfigType -FilePath $FilePath -Force:$Force
        }
        "Update" {
            if ([string]::IsNullOrEmpty($ConfigType) -or [string]::IsNullOrEmpty($Name) -or [string]::IsNullOrEmpty($FilePath)) {
                Write-Log "ConfigType, Name, and FilePath are required for Update action" -Level "Error"
                return $false
            }
            
            # Charger les mises à jour à partir du fichier
            try {
                $updates = Get-Content -Path $FilePath -Raw | ConvertFrom-Json -AsHashtable
            } catch {
                Write-Log "Error loading updates from file: $_" -Level "Error"
                return $false
            }
            
            return Update-Configuration -ConfigType $ConfigType -Name $Name -Version $Version -Updates $updates -Force:$Force
        }
        "Delete" {
            if ([string]::IsNullOrEmpty($ConfigType) -or [string]::IsNullOrEmpty($Name)) {
                Write-Log "ConfigType and Name are required for Delete action" -Level "Error"
                return $false
            }
            
            return Remove-Configuration -ConfigType $ConfigType -Name $Name -Version $Version -Force:$Force
        }
        "List" {
            if ([string]::IsNullOrEmpty($ConfigType)) {
                Write-Log "ConfigType is required for List action" -Level "Error"
                return $null
            }
            
            return Get-ConfigurationList -ConfigType $ConfigType -NameFilter $Name -IncludeHistory:$IncludeHistory
        }
        "Validate" {
            if ([string]::IsNullOrEmpty($ConfigType) -or [string]::IsNullOrEmpty($FilePath)) {
                Write-Log "ConfigType and FilePath are required for Validate action" -Level "Error"
                return $false
            }
            
            # Charger la configuration à partir du fichier
            try {
                $config = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
            } catch {
                Write-Log "Error loading configuration from file: $_" -Level "Error"
                return $false
            }
            
            return Test-Configuration -ConfigType $ConfigType -Configuration $config
        }
        "Export" {
            if ([string]::IsNullOrEmpty($ConfigType) -or [string]::IsNullOrEmpty($Name) -or [string]::IsNullOrEmpty($OutputPath)) {
                Write-Log "ConfigType, Name, and OutputPath are required for Export action" -Level "Error"
                return $false
            }
            
            return Export-Configuration -ConfigType $ConfigType -Name $Name -Version $Version -OutputPath $OutputPath
        }
        "Import" {
            if ([string]::IsNullOrEmpty($ConfigType) -or [string]::IsNullOrEmpty($FilePath)) {
                Write-Log "ConfigType and FilePath are required for Import action" -Level "Error"
                return $false
            }
            
            return Import-Configuration -ConfigType $ConfigType -FilePath $FilePath -Force:$Force
        }
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Manage-Configuration -Action $Action -ConfigType $ConfigType -Name $Name -Version $Version -FilePath $FilePath -OutputPath $OutputPath -Force:$Force -IncludeHistory:$IncludeHistory
}
