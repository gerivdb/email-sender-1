# Sync-Configurations.ps1
# Script pour synchroniser les configurations entre Git et Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("GitToQdrant", "QdrantToGit", "TwoWay")]
    [string]$Direction = "TwoWay",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
    [string]$ConfigType = "All",

    [Parameter(Mandatory = $false)]
    [string]$RepositoryPath,

    [Parameter(Mandatory = $false)]
    [string]$ServerUrl = "http://localhost:6333",

    [Parameter(Mandatory = $false)]
    [string]$ApiKey = "",

    [Parameter(Mandatory = $false)]
    [ValidateSet("OpenAI", "DeepSeek", "Local", "Mock")]
    [string]$EmbeddingProvider = "OpenAI",

    [Parameter(Mandatory = $false)]
    [string]$ModelName = "text-embedding-3-large",

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
            "Error"   = 0
            "Warning" = 1
            "Info"    = 2
            "Debug"   = 3
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

# Importer les scripts nécessaires
$qdrantPath = Join-Path -Path $scriptPath -ChildPath "qdrant"
$gitPath = Join-Path -Path $scriptPath -ChildPath "git"

$qdrantSavePath = Join-Path -Path $qdrantPath -ChildPath "Save-ConfigurationToQdrant.ps1"
$qdrantConnectPath = Join-Path -Path $qdrantPath -ChildPath "Connect-QdrantServer.ps1"
$qdrantOperationPath = Join-Path -Path $qdrantPath -ChildPath "Invoke-QdrantOperation.ps1"

$gitSavePath = Join-Path -Path $gitPath -ChildPath "Save-ConfigurationToGit.ps1"
$gitOperationPath = Join-Path -Path $gitPath -ChildPath "Invoke-GitOperation.ps1"
$gitStructurePath = Join-Path -Path $gitPath -ChildPath "Get-GitRepositoryStructure.ps1"

# Vérifier que tous les scripts nécessaires existent
$requiredScripts = @($qdrantSavePath, $qdrantConnectPath, $qdrantOperationPath, $gitSavePath, $gitOperationPath, $gitStructurePath)
foreach ($script in $requiredScripts) {
    if (-not (Test-Path -Path $script)) {
        Write-Log "Required script not found: $script" -Level "Error"
        exit 1
    }
}

# Importer les scripts
. $qdrantSavePath
. $qdrantConnectPath
. $qdrantOperationPath
. $gitSavePath
. $gitOperationPath
. $gitStructurePath

# Fonction pour obtenir les types de configuration à synchroniser
function Get-ConfigurationTypes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
        [string]$ConfigType = "All"
    )

    if ($ConfigType -eq "All") {
        return @("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")
    } else {
        return @($ConfigType)
    }
}

# Fonction pour obtenir les configurations depuis Git
function Get-ConfigurationsFromGit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType
    )

    # Obtenir la structure du dépôt
    $structure = Get-GitRepositoryStructure

    # Déterminer le répertoire source
    $sourceDir = switch ($ConfigType) {
        "Template" { Join-Path -Path $RepositoryPath -ChildPath $structure.directories.templates.path }
        "Visualization" { Join-Path -Path $RepositoryPath -ChildPath $structure.directories.visualizations.path }
        "DataMapping" { Join-Path -Path $RepositoryPath -ChildPath $structure.directories.data_mappings.path }
        "Chart" { Join-Path -Path $RepositoryPath -ChildPath $structure.directories.charts.path }
        "Export" { Join-Path -Path $RepositoryPath -ChildPath $structure.directories.exports.path }
        "Search" { Join-Path -Path $RepositoryPath -ChildPath $structure.directories.searches.path }
        default { Join-Path -Path $RepositoryPath -ChildPath "configurations" }
    }

    # Vérifier si le répertoire existe
    if (-not (Test-Path -Path $sourceDir)) {
        Write-Log "Source directory does not exist: $sourceDir" -Level "Warning"
        return @()
    }

    # Obtenir tous les fichiers JSON dans le répertoire
    $files = Get-ChildItem -Path $sourceDir -Filter "*.json" -File

    if ($files.Count -eq 0) {
        Write-Log "No configuration files found in: $sourceDir" -Level "Warning"
        return @()
    }

    # Charger les configurations
    $configurations = @()

    foreach ($file in $files) {
        try {
            $config = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $config | Add-Member -NotePropertyName "_file_path" -NotePropertyValue $file.FullName -Force
            $config | Add-Member -NotePropertyName "_config_type" -NotePropertyValue $ConfigType -Force
            $configurations += $config
        } catch {
            Write-Log "Error loading configuration from file: $($file.FullName) - $_" -Level "Error"
        }
    }

    Write-Log "Loaded $($configurations.Count) configurations from Git" -Level "Info"
    return $configurations
}

# Fonction pour obtenir les configurations depuis Qdrant
function Get-ConfigurationsFromQdrant {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,

        [Parameter(Mandatory = $false)]
        [string]$ServerUrl = "http://localhost:6333",

        [Parameter(Mandatory = $false)]
        [string]$ApiKey = ""
    )

    # Connecter au serveur Qdrant
    $connection = Connect-QdrantServer -ServerUrl $ServerUrl -ApiKey $ApiKey

    if ($null -eq $connection) {
        Write-Log "Failed to connect to Qdrant server" -Level "Error"
        return @()
    }

    # Obtenir le nom de la collection
    $collectionName = switch ($ConfigType) {
        "Template" { "roadmap_templates" }
        "Visualization" { "roadmap_visualizations" }
        "DataMapping" { "roadmap_data_mappings" }
        "Chart" { "roadmap_charts" }
        "Export" { "roadmap_exports" }
        "Search" { "roadmap_searches" }
        default { "roadmap_configurations" }
    }

    # Vérifier si la collection existe
    $collections = Invoke-QdrantOperation -Operation "ListCollections" -AsObject

    if ($null -eq $collections -or -not ($collections | Where-Object { $_ -eq $collectionName })) {
        Write-Log "Collection does not exist: $collectionName" -Level "Warning"
        return @()
    }

    # Préparer les paramètres de recherche
    $searchParams = @{
        limit        = 1000
        with_payload = $true
        with_vector  = $false
    }

    # Récupérer tous les points
    $points = @()
    $offset = 0
    $batchSize = 100

    do {
        $searchParams.limit = $batchSize
        $searchParams.offset = $offset

        $result = Invoke-QdrantOperation -Operation "ScrollPoints" -CollectionName $collectionName -SearchParams $searchParams -AsObject

        if ($null -eq $result -or $null -eq $result.points -or $result.points.Count -eq 0) {
            break
        }

        $points += $result.points
        $offset = $result.next_page_offset
    } while (-not [string]::IsNullOrEmpty($offset))

    # Extraire les configurations
    $configurations = @()

    foreach ($point in $points) {
        if ($null -ne $point.payload -and $null -ne $point.payload.configuration) {
            $config = $point.payload.configuration
            $config | Add-Member -NotePropertyName "_point_id" -NotePropertyValue $point.id -Force
            $config | Add-Member -NotePropertyName "_config_type" -NotePropertyValue $ConfigType -Force
            $configurations += $config
        }
    }

    Write-Log "Loaded $($configurations.Count) configurations from Qdrant" -Level "Info"
    return $configurations
}

# Fonction pour comparer les configurations
function Compare-Configurations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$GitConfigurations,

        [Parameter(Mandatory = $true)]
        [object[]]$QdrantConfigurations
    )

    $result = @{
        git_only    = @()
        qdrant_only = @()
        different   = @()
        identical   = @()
    }

    # Indexer les configurations Qdrant par nom et version
    $qdrantIndex = @{}

    foreach ($config in $QdrantConfigurations) {
        $key = "$($config.name)_v$($config.version)"
        $qdrantIndex[$key] = $config
    }

    # Comparer les configurations Git avec Qdrant
    foreach ($gitConfig in $GitConfigurations) {
        $key = "$($gitConfig.name)_v$($gitConfig.version)"

        if ($qdrantIndex.ContainsKey($key)) {
            $qdrantConfig = $qdrantIndex[$key]

            # Comparer les configurations (ignorer les propriétés spéciales)
            $gitJson = $gitConfig | Select-Object -Property * -ExcludeProperty _file_path, _config_type | ConvertTo-Json -Depth 10 -Compress
            $qdrantJson = $qdrantConfig | Select-Object -Property * -ExcludeProperty _point_id, _config_type | ConvertTo-Json -Depth 10 -Compress

            if ($gitJson -eq $qdrantJson) {
                $result.identical += @{
                    git    = $gitConfig
                    qdrant = $qdrantConfig
                }
            } else {
                $result.different += @{
                    git    = $gitConfig
                    qdrant = $qdrantConfig
                }
            }

            # Marquer comme traité
            $qdrantIndex.Remove($key)
        } else {
            $result.git_only += $gitConfig
        }
    }

    # Ajouter les configurations uniquement dans Qdrant
    foreach ($key in $qdrantIndex.Keys) {
        $result.qdrant_only += $qdrantIndex[$key]
    }

    return $result
}

# Fonction pour synchroniser de Git vers Qdrant
function Sync-GitToQdrant {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,

        [Parameter(Mandatory = $false)]
        [string]$ServerUrl = "http://localhost:6333",

        [Parameter(Mandatory = $false)]
        [string]$ApiKey = "",

        [Parameter(Mandatory = $false)]
        [ValidateSet("OpenAI", "DeepSeek", "Local", "Mock")]
        [string]$EmbeddingProvider = "OpenAI",

        [Parameter(Mandatory = $false)]
        [string]$ModelName = "text-embedding-3-large",

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Obtenir les configurations depuis Git
    $gitConfigs = Get-ConfigurationsFromGit -RepositoryPath $RepositoryPath -ConfigType $ConfigType

    if ($gitConfigs.Count -eq 0) {
        Write-Log "No configurations found in Git for type: $ConfigType" -Level "Warning"
        return $false
    }

    # Obtenir les configurations depuis Qdrant
    $qdrantConfigs = Get-ConfigurationsFromQdrant -ConfigType $ConfigType -ServerUrl $ServerUrl -ApiKey $ApiKey

    # Comparer les configurations
    $comparison = Compare-Configurations -GitConfigurations $gitConfigs -QdrantConfigurations $qdrantConfigs

    Write-Log "Comparison results for ${ConfigType}:" -Level "Info"
    Write-Log "  Git only: $($comparison.git_only.Count)" -Level "Info"
    Write-Log "  Qdrant only: $($comparison.qdrant_only.Count)" -Level "Info"
    Write-Log "  Different: $($comparison.different.Count)" -Level "Info"
    Write-Log "  Identical: $($comparison.identical.Count)" -Level "Info"

    # Synchroniser les configurations uniquement dans Git
    foreach ($config in $comparison.git_only) {
        Write-Log "Saving configuration to Qdrant: $($config.name) v$($config.version)" -Level "Info"

        $result = Save-ConfigurationToQdrant -ConfigType $ConfigType -Configuration $config -ServerUrl $ServerUrl -ApiKey $ApiKey -EmbeddingProvider $EmbeddingProvider -ModelName $ModelName -Force:$Force

        if (-not $result) {
            Write-Log "Failed to save configuration to Qdrant: $($config.name) v$($config.version)" -Level "Error"
        }
    }

    # Synchroniser les configurations différentes
    if ($Force) {
        foreach ($diff in $comparison.different) {
            Write-Log "Updating configuration in Qdrant: $($diff.git.name) v$($diff.git.version)" -Level "Info"

            $result = Save-ConfigurationToQdrant -ConfigType $ConfigType -Configuration $diff.git -ServerUrl $ServerUrl -ApiKey $ApiKey -EmbeddingProvider $EmbeddingProvider -ModelName $ModelName -Force:$Force

            if (-not $result) {
                Write-Log "Failed to update configuration in Qdrant: $($diff.git.name) v$($diff.git.version)" -Level "Error"
            }
        }
    } else {
        Write-Log "$($comparison.different.Count) configurations are different. Use -Force to update them." -Level "Warning"
    }

    Write-Log "Git to Qdrant synchronization completed for type: $ConfigType" -Level "Info"
    return $true
}

# Fonction pour synchroniser de Qdrant vers Git
function Sync-QdrantToGit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,

        [Parameter(Mandatory = $false)]
        [string]$ServerUrl = "http://localhost:6333",

        [Parameter(Mandatory = $false)]
        [string]$ApiKey = "",

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Obtenir les configurations depuis Qdrant
    $qdrantConfigs = Get-ConfigurationsFromQdrant -ConfigType $ConfigType -ServerUrl $ServerUrl -ApiKey $ApiKey

    if ($qdrantConfigs.Count -eq 0) {
        Write-Log "No configurations found in Qdrant for type: $ConfigType" -Level "Warning"
        return $false
    }

    # Obtenir les configurations depuis Git
    $gitConfigs = Get-ConfigurationsFromGit -RepositoryPath $RepositoryPath -ConfigType $ConfigType

    # Comparer les configurations
    $comparison = Compare-Configurations -GitConfigurations $gitConfigs -QdrantConfigurations $qdrantConfigs

    Write-Log "Comparison results for ${ConfigType}:" -Level "Info"
    Write-Log "  Git only: $($comparison.git_only.Count)" -Level "Info"
    Write-Log "  Qdrant only: $($comparison.qdrant_only.Count)" -Level "Info"
    Write-Log "  Different: $($comparison.different.Count)" -Level "Info"
    Write-Log "  Identical: $($comparison.identical.Count)" -Level "Info"

    # Synchroniser les configurations uniquement dans Qdrant
    foreach ($config in $comparison.qdrant_only) {
        Write-Log "Saving configuration to Git: $($config.name) v$($config.version)" -Level "Info"

        $result = Save-ConfigurationToGit -ConfigType $ConfigType -Configuration $config -RepositoryPath $RepositoryPath -Force:$Force

        if (-not $result) {
            Write-Log "Failed to save configuration to Git: $($config.name) v$($config.version)" -Level "Error"
        }
    }

    # Synchroniser les configurations différentes
    if ($Force) {
        foreach ($diff in $comparison.different) {
            Write-Log "Updating configuration in Git: $($diff.qdrant.name) v$($diff.qdrant.version)" -Level "Info"

            $result = Save-ConfigurationToGit -ConfigType $ConfigType -Configuration $diff.qdrant -RepositoryPath $RepositoryPath -Force:$Force

            if (-not $result) {
                Write-Log "Failed to update configuration in Git: $($diff.qdrant.name) v$($diff.qdrant.version)" -Level "Error"
            }
        }
    } else {
        Write-Log "$($comparison.different.Count) configurations are different. Use -Force to update them." -Level "Warning"
    }

    Write-Log "Qdrant to Git synchronization completed for type: $ConfigType" -Level "Info"
    return $true
}

# Fonction principale
function Sync-Configurations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("GitToQdrant", "QdrantToGit", "TwoWay")]
        [string]$Direction = "TwoWay",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
        [string]$ConfigType = "All",

        [Parameter(Mandatory = $false)]
        [string]$RepositoryPath,

        [Parameter(Mandatory = $false)]
        [string]$ServerUrl = "http://localhost:6333",

        [Parameter(Mandatory = $false)]
        [string]$ApiKey = "",

        [Parameter(Mandatory = $false)]
        [ValidateSet("OpenAI", "DeepSeek", "Local", "Mock")]
        [string]$EmbeddingProvider = "OpenAI",

        [Parameter(Mandatory = $false)]
        [string]$ModelName = "text-embedding-3-large",

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier si un chemin de dépôt est fourni
    if ([string]::IsNullOrEmpty($RepositoryPath)) {
        $RepositoryPath = Join-Path -Path $rootPath -ChildPath "git_repository"
    }

    # Obtenir les types de configuration à synchroniser
    $configTypes = Get-ConfigurationTypes -ConfigType $ConfigType

    # Synchroniser chaque type de configuration
    foreach ($type in $configTypes) {
        Write-Log "Synchronizing configurations of type: $type" -Level "Info"

        if ($Direction -eq "GitToQdrant" -or $Direction -eq "TwoWay") {
            Write-Log "Synchronizing from Git to Qdrant" -Level "Info"
            Sync-GitToQdrant -RepositoryPath $RepositoryPath -ConfigType $type -ServerUrl $ServerUrl -ApiKey $ApiKey -EmbeddingProvider $EmbeddingProvider -ModelName $ModelName -Force:$Force
        }

        if ($Direction -eq "QdrantToGit" -or $Direction -eq "TwoWay") {
            Write-Log "Synchronizing from Qdrant to Git" -Level "Info"
            Sync-QdrantToGit -RepositoryPath $RepositoryPath -ConfigType $type -ServerUrl $ServerUrl -ApiKey $ApiKey -Force:$Force
        }
    }

    Write-Log "Configuration synchronization completed" -Level "Info"
    return $true
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Sync-Configurations -Direction $Direction -ConfigType $ConfigType -RepositoryPath $RepositoryPath -ServerUrl $ServerUrl -ApiKey $ApiKey -EmbeddingProvider $EmbeddingProvider -ModelName $ModelName -Force:$Force
}
