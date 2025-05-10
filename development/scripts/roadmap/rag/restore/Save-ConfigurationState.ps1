# Save-ConfigurationState.ps1
# Script pour sauvegarder l'état d'une configuration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
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
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$Compress,
    
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

# Fonction pour obtenir les dépendances d'une configuration
function Get-ConfigurationDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [object]$Configuration
    )
    
    $dependencies = @()
    
    # Analyser les dépendances en fonction du type de configuration
    switch ($ConfigType) {
        "Template" {
            # Les templates n'ont généralement pas de dépendances
        }
        "Visualization" {
            # Les visualisations dépendent souvent des mappages de données et des charts
            if ($Configuration.PSObject.Properties.Name.Contains("data_mapping")) {
                $dependencies += @{
                    type = "DataMapping"
                    id = $Configuration.data_mapping.id
                    dependency_type = "required"
                }
            }
            
            if ($Configuration.PSObject.Properties.Name.Contains("chart_configuration")) {
                $dependencies += @{
                    type = "Chart"
                    id = $Configuration.chart_configuration.id
                    dependency_type = "required"
                }
            }
        }
        "DataMapping" {
            # Les mappages de données peuvent dépendre d'autres mappages
            if ($Configuration.PSObject.Properties.Name.Contains("dependencies")) {
                foreach ($dep in $Configuration.dependencies) {
                    $dependencies += @{
                        type = "DataMapping"
                        id = $dep.id
                        dependency_type = $dep.type
                    }
                }
            }
        }
        "Chart" {
            # Les charts peuvent dépendre des mappages de données
            if ($Configuration.PSObject.Properties.Name.Contains("data_field")) {
                $dependencies += @{
                    type = "DataMapping"
                    id = $Configuration.data_field
                    dependency_type = "recommended"
                }
            }
        }
        "Export" {
            # Les exports dépendent souvent des visualisations ou des charts
            if ($Configuration.PSObject.Properties.Name.Contains("source_id")) {
                $dependencies += @{
                    type = $Configuration.source_type
                    id = $Configuration.source_id
                    dependency_type = "required"
                }
            }
        }
        "Search" {
            # Les recherches peuvent dépendre de divers types de configurations
            if ($Configuration.PSObject.Properties.Name.Contains("search_targets")) {
                foreach ($target in $Configuration.search_targets) {
                    $dependencies += @{
                        type = $target.type
                        id = $target.id
                        dependency_type = "optional"
                    }
                }
            }
        }
    }
    
    return $dependencies
}

# Fonction pour compresser une configuration
function Compress-Configuration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Configuration
    )
    
    try {
        # Convertir la configuration en JSON
        $jsonConfig = $Configuration | ConvertTo-Json -Depth 10 -Compress
        
        # Convertir en bytes
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonConfig)
        
        # Créer un stream pour la compression
        $outputStream = New-Object System.IO.MemoryStream
        $gzipStream = New-Object System.IO.Compression.GZipStream($outputStream, [System.IO.Compression.CompressionMode]::Compress)
        
        # Compresser les données
        $gzipStream.Write($bytes, 0, $bytes.Length)
        $gzipStream.Close()
        
        # Obtenir les bytes compressés
        $compressedBytes = $outputStream.ToArray()
        $outputStream.Close()
        
        # Convertir en Base64 pour le stockage
        $compressedBase64 = [Convert]::ToBase64String($compressedBytes)
        
        return @{
            compressed = $true
            format = "gzip+base64"
            data = $compressedBase64
            original_size = $bytes.Length
            compressed_size = $compressedBytes.Length
            compression_ratio = [math]::Round(($bytes.Length - $compressedBytes.Length) / $bytes.Length * 100, 2)
        }
    } catch {
        Write-Log "Error compressing configuration: $_" -Level "Error"
        return $null
    }
}

# Fonction pour sauvegarder l'état d'une configuration
function Save-ConfigurationState {
    [CmdletBinding()]
    param (
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
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Compress,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si un chemin de configuration ou une configuration est fourni
    if ([string]::IsNullOrEmpty($ConfigPath) -and $null -eq $Configuration) {
        Write-Log "Either ConfigPath or Configuration must be provided" -Level "Error"
        return $false
    }
    
    # Charger la configuration à partir du fichier si nécessaire
    if (-not [string]::IsNullOrEmpty($ConfigPath)) {
        if (-not (Test-Path -Path $ConfigPath)) {
            Write-Log "Configuration file not found: $ConfigPath" -Level "Error"
            return $false
        }
        
        try {
            $Configuration = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        } catch {
            Write-Log "Error loading configuration from file: $_" -Level "Error"
            return $false
        }
    }
    
    # Déterminer le type de configuration si non spécifié
    if ([string]::IsNullOrEmpty($ConfigType)) {
        if ($Configuration.PSObject.Properties.Name.Contains("content") -and $Configuration.PSObject.Properties.Name.Contains("type")) {
            $ConfigType = "Template"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("chart_configuration") -and $Configuration.PSObject.Properties.Name.Contains("data_mapping")) {
            $ConfigType = "Visualization"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("mappings") -and $Configuration.PSObject.Properties.Name.Contains("version")) {
            $ConfigType = "DataMapping"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("chart_type") -and $Configuration.PSObject.Properties.Name.Contains("data_field")) {
            $ConfigType = "Chart"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("export_type")) {
            $ConfigType = "Export"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("search_type") -and $Configuration.PSObject.Properties.Name.Contains("query")) {
            $ConfigType = "Search"
        } else {
            Write-Log "Could not determine configuration type" -Level "Error"
            return $false
        }
        
        Write-Log "Determined configuration type: $ConfigType" -Level "Info"
    }
    
    # Déterminer l'ID de la configuration si non spécifié
    if ([string]::IsNullOrEmpty($ConfigId)) {
        if ($Configuration.PSObject.Properties.Name.Contains("id")) {
            $ConfigId = $Configuration.id
        } elseif ($Configuration.PSObject.Properties.Name.Contains("name") -and $Configuration.PSObject.Properties.Name.Contains("version")) {
            $ConfigId = "$($Configuration.name)_v$($Configuration.version)"
        } else {
            $ConfigId = [Guid]::NewGuid().ToString()
        }
        
        Write-Log "Determined configuration ID: $ConfigId" -Level "Info"
    }
    
    # Obtenir les dépendances de la configuration
    $dependencies = Get-ConfigurationDependencies -ConfigType $ConfigType -Configuration $Configuration
    
    # Créer l'état de la configuration
    $state = @{
        type = $ConfigType
        id = $ConfigId
        version = if ($Configuration.PSObject.Properties.Name.Contains("version")) { $Configuration.version } else { "1.0" }
        state = if ($Compress) { Compress-Configuration -Configuration $Configuration } else { $Configuration }
        dependencies = $dependencies
        saved_at = (Get-Date).ToString("o")
    }
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = Join-Path -Path $scriptPath -ChildPath "states"
    }
    
    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Déterminer le chemin du fichier de sortie
    $stateFileName = "$($ConfigType.ToLower())_$($ConfigId)_state.json"
    $stateFilePath = Join-Path -Path $OutputPath -ChildPath $stateFileName
    
    # Vérifier si le fichier existe déjà
    if (Test-Path -Path $stateFilePath) {
        if (-not $Force) {
            Write-Log "State file already exists: $stateFilePath. Use -Force to overwrite." -Level "Warning"
            return $false
        }
        
        Write-Log "Overwriting existing state file: $stateFilePath" -Level "Warning"
    }
    
    # Sauvegarder l'état
    try {
        $state | ConvertTo-Json -Depth 10 | Out-File -FilePath $stateFilePath -Encoding UTF8
        Write-Log "Configuration state saved to: $stateFilePath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error saving configuration state: $_" -Level "Error"
        return $false
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Save-ConfigurationState -ConfigType $ConfigType -ConfigId $ConfigId -ConfigPath $ConfigPath -Configuration $Configuration -OutputPath $OutputPath -Compress:$Compress -Force:$Force
}
