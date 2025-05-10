# Optimize-ConfigurationStorage.ps1
# Script pour optimiser le stockage des configurations
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$StatesPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$Compress,
    
    [Parameter(Mandatory = $false)]
    [switch]$Deduplicate,
    
    [Parameter(Mandatory = $false)]
    [switch]$CalculateDiff,
    
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

# Fonction pour compresser une configuration
function Compress-Configuration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Configuration
    )
    
    try {
        # Vérifier si la configuration est déjà compressée
        if ($Configuration.PSObject.Properties.Name.Contains("compressed") -and $Configuration.compressed -eq $true) {
            Write-Log "Configuration is already compressed" -Level "Debug"
            return $Configuration
        }
        
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
        
        # Créer la configuration compressée
        $compressedConfig = @{
            compressed = $true
            format = "gzip+base64"
            data = $compressedBase64
            original_size = $bytes.Length
            compressed_size = $compressedBytes.Length
            compression_ratio = [math]::Round(($bytes.Length - $compressedBytes.Length) / $bytes.Length * 100, 2)
        }
        
        return $compressedConfig
    } catch {
        Write-Log "Error compressing configuration: $_" -Level "Error"
        return $Configuration
    }
}

# Fonction pour décompresser une configuration
function Expand-Configuration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Configuration
    )
    
    try {
        # Vérifier si la configuration est compressée
        if (-not ($Configuration.PSObject.Properties.Name.Contains("compressed") -and $Configuration.compressed -eq $true)) {
            Write-Log "Configuration is not compressed" -Level "Debug"
            return $Configuration
        }
        
        # Vérifier le format de compression
        if ($Configuration.format -ne "gzip+base64") {
            Write-Log "Unsupported compression format: $($Configuration.format)" -Level "Error"
            return $Configuration
        }
        
        # Convertir de Base64 en bytes
        $compressedBytes = [Convert]::FromBase64String($Configuration.data)
        
        # Créer un stream pour la décompression
        $inputStream = New-Object System.IO.MemoryStream($compressedBytes)
        $gzipStream = New-Object System.IO.Compression.GZipStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
        $outputStream = New-Object System.IO.MemoryStream
        
        # Décompresser les données
        $buffer = New-Object byte[] 4096
        $count = 0
        
        do {
            $count = $gzipStream.Read($buffer, 0, $buffer.Length)
            if ($count -gt 0) {
                $outputStream.Write($buffer, 0, $count)
            }
        } while ($count -gt 0)
        
        # Obtenir les bytes décompressés
        $decompressedBytes = $outputStream.ToArray()
        
        # Fermer les streams
        $gzipStream.Close()
        $inputStream.Close()
        $outputStream.Close()
        
        # Convertir en JSON
        $jsonConfig = [System.Text.Encoding]::UTF8.GetString($decompressedBytes)
        
        # Convertir en objet
        $decompressedConfig = $jsonConfig | ConvertFrom-Json
        
        return $decompressedConfig
    } catch {
        Write-Log "Error decompressing configuration: $_" -Level "Error"
        return $Configuration
    }
}

# Fonction pour calculer le hash d'une configuration
function Get-ConfigurationHash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Configuration
    )
    
    try {
        # Décompresser la configuration si nécessaire
        $expandedConfig = $Configuration
        
        if ($Configuration.PSObject.Properties.Name.Contains("compressed") -and $Configuration.compressed -eq $true) {
            $expandedConfig = Expand-Configuration -Configuration $Configuration
        }
        
        # Convertir en JSON normalisé
        $jsonConfig = $expandedConfig | ConvertTo-Json -Depth 10 -Compress
        
        # Calculer le hash SHA-256
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($jsonConfig))
        $hash = [BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
        
        return $hash
    } catch {
        Write-Log "Error calculating configuration hash: $_" -Level "Error"
        return $null
    }
}

# Fonction pour trouver les configurations dupliquées
function Find-DuplicateConfigurations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$StatesPath
    )
    
    try {
        # Vérifier si le répertoire existe
        if (-not (Test-Path -Path $StatesPath)) {
            Write-Log "States directory not found: $StatesPath" -Level "Error"
            return $null
        }
        
        # Obtenir tous les fichiers d'état
        $stateFiles = Get-ChildItem -Path $StatesPath -Filter "*_state.json"
        
        if ($stateFiles.Count -eq 0) {
            Write-Log "No state files found in: $StatesPath" -Level "Info"
            return @()
        }
        
        # Initialiser les dictionnaires
        $hashToFiles = @{}
        $duplicates = @()
        
        # Traiter chaque fichier
        foreach ($stateFile in $stateFiles) {
            try {
                # Charger l'état
                $state = Get-Content -Path $stateFile.FullName -Raw | ConvertFrom-Json
                
                # Calculer le hash de la configuration
                $hash = Get-ConfigurationHash -Configuration $state.state
                
                if ($null -eq $hash) {
                    Write-Log "Failed to calculate hash for: $($stateFile.Name)" -Level "Warning"
                    continue
                }
                
                # Vérifier si le hash existe déjà
                if ($hashToFiles.ContainsKey($hash)) {
                    # Ajouter aux duplicats
                    $duplicates += @{
                        hash = $hash
                        original_file = $hashToFiles[$hash]
                        duplicate_file = $stateFile.FullName
                    }
                } else {
                    # Ajouter au dictionnaire
                    $hashToFiles[$hash] = $stateFile.FullName
                }
            } catch {
                Write-Log "Error processing state file $($stateFile.Name): $_" -Level "Warning"
            }
        }
        
        return $duplicates
    } catch {
        Write-Log "Error finding duplicate configurations: $_" -Level "Error"
        return $null
    }
}

# Fonction pour calculer les différences entre deux configurations
function Get-ConfigurationDiff {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$OldConfiguration,
        
        [Parameter(Mandatory = $true)]
        [object]$NewConfiguration
    )
    
    try {
        # Décompresser les configurations si nécessaire
        $oldExpanded = $OldConfiguration
        $newExpanded = $NewConfiguration
        
        if ($OldConfiguration.PSObject.Properties.Name.Contains("compressed") -and $OldConfiguration.compressed -eq $true) {
            $oldExpanded = Expand-Configuration -Configuration $OldConfiguration
        }
        
        if ($NewConfiguration.PSObject.Properties.Name.Contains("compressed") -and $NewConfiguration.compressed -eq $true) {
            $newExpanded = Expand-Configuration -Configuration $NewConfiguration
        }
        
        # Convertir en JSON
        $oldJson = $oldExpanded | ConvertTo-Json -Depth 10
        $newJson = $newExpanded | ConvertTo-Json -Depth 10
        
        # Calculer les différences
        $diff = @{
            added = @{}
            removed = @{}
            modified = @{}
        }
        
        # Parcourir les propriétés de la nouvelle configuration
        foreach ($prop in $newExpanded.PSObject.Properties) {
            if (-not $oldExpanded.PSObject.Properties.Name.Contains($prop.Name)) {
                # Propriété ajoutée
                $diff.added[$prop.Name] = $prop.Value
            } elseif ($oldExpanded.($prop.Name) -ne $newExpanded.($prop.Name)) {
                # Propriété modifiée
                $diff.modified[$prop.Name] = @{
                    old = $oldExpanded.($prop.Name)
                    new = $newExpanded.($prop.Name)
                }
            }
        }
        
        # Parcourir les propriétés de l'ancienne configuration
        foreach ($prop in $oldExpanded.PSObject.Properties) {
            if (-not $newExpanded.PSObject.Properties.Name.Contains($prop.Name)) {
                # Propriété supprimée
                $diff.removed[$prop.Name] = $prop.Value
            }
        }
        
        # Ajouter des métadonnées
        $diff.metadata = @{
            old_hash = Get-ConfigurationHash -Configuration $OldConfiguration
            new_hash = Get-ConfigurationHash -Configuration $NewConfiguration
            diff_created_at = (Get-Date).ToString("o")
        }
        
        return $diff
    } catch {
        Write-Log "Error calculating configuration diff: $_" -Level "Error"
        return $null
    }
}

# Fonction pour optimiser le stockage des configurations
function Optimize-ConfigurationStorage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$StatesPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Compress,
        
        [Parameter(Mandatory = $false)]
        [switch]$Deduplicate,
        
        [Parameter(Mandatory = $false)]
        [switch]$CalculateDiff,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Déterminer le chemin des états
    if ([string]::IsNullOrEmpty($StatesPath)) {
        $StatesPath = Join-Path -Path $scriptPath -ChildPath "states"
    }
    
    # Vérifier si le répertoire existe
    if (-not (Test-Path -Path $StatesPath)) {
        Write-Log "States directory not found: $StatesPath" -Level "Error"
        return $false
    }
    
    # Obtenir tous les fichiers d'état
    $stateFiles = Get-ChildItem -Path $StatesPath -Filter "*_state.json"
    
    if ($stateFiles.Count -eq 0) {
        Write-Log "No state files found in: $StatesPath" -Level "Info"
        return $true
    }
    
    Write-Log "Found $($stateFiles.Count) state files" -Level "Info"
    
    # Initialiser les compteurs
    $compressedCount = 0
    $deduplicatedCount = 0
    $diffCount = 0
    
    # Compresser les configurations si demandé
    if ($Compress) {
        Write-Log "Compressing configurations..." -Level "Info"
        
        foreach ($stateFile in $stateFiles) {
            try {
                # Charger l'état
                $state = Get-Content -Path $stateFile.FullName -Raw | ConvertFrom-Json
                
                # Vérifier si la configuration est déjà compressée
                if ($state.state.PSObject.Properties.Name.Contains("compressed") -and $state.state.compressed -eq $true) {
                    Write-Log "Configuration already compressed: $($stateFile.Name)" -Level "Debug"
                    continue
                }
                
                # Compresser la configuration
                $state.state = Compress-Configuration -Configuration $state.state
                
                # Sauvegarder l'état
                $state | ConvertTo-Json -Depth 10 | Out-File -FilePath $stateFile.FullName -Encoding UTF8
                
                $compressedCount++
            } catch {
                Write-Log "Error compressing configuration $($stateFile.Name): $_" -Level "Warning"
            }
        }
        
        Write-Log "Compressed $compressedCount configurations" -Level "Info"
    }
    
    # Dédupliquer les configurations si demandé
    if ($Deduplicate) {
        Write-Log "Finding duplicate configurations..." -Level "Info"
        
        $duplicates = Find-DuplicateConfigurations -StatesPath $StatesPath
        
        if ($null -eq $duplicates) {
            Write-Log "Failed to find duplicate configurations" -Level "Error"
        } elseif ($duplicates.Count -eq 0) {
            Write-Log "No duplicate configurations found" -Level "Info"
        } else {
            Write-Log "Found $($duplicates.Count) duplicate configurations" -Level "Info"
            
            # Créer le répertoire pour les duplicats
            $duplicatesPath = Join-Path -Path $StatesPath -ChildPath "duplicates"
            
            if (-not (Test-Path -Path $duplicatesPath)) {
                New-Item -Path $duplicatesPath -ItemType Directory -Force | Out-Null
            }
            
            # Traiter chaque duplicat
            foreach ($duplicate in $duplicates) {
                try {
                    $originalFile = $duplicate.original_file
                    $duplicateFile = $duplicate.duplicate_file
                    
                    # Charger les états
                    $originalState = Get-Content -Path $originalFile -Raw | ConvertFrom-Json
                    $duplicateState = Get-Content -Path $duplicateFile -Raw | ConvertFrom-Json
                    
                    # Créer un lien symbolique
                    $duplicateFileName = Split-Path -Leaf $duplicateFile
                    $linkPath = Join-Path -Path $duplicatesPath -ChildPath $duplicateFileName
                    
                    # Déplacer le fichier duplicat
                    Move-Item -Path $duplicateFile -Destination $linkPath -Force
                    
                    # Créer un fichier de référence
                    $referenceContent = @{
                        original_file = $originalFile
                        duplicate_file = $duplicateFile
                        hash = $duplicate.hash
                        moved_to = $linkPath
                        deduplication_date = (Get-Date).ToString("o")
                    } | ConvertTo-Json -Depth 10
                    
                    $referenceFile = [System.IO.Path]::ChangeExtension($linkPath, ".reference.json")
                    $referenceContent | Out-File -FilePath $referenceFile -Encoding UTF8
                    
                    $deduplicatedCount++
                } catch {
                    Write-Log "Error deduplicating configuration: $_" -Level "Warning"
                }
            }
            
            Write-Log "Deduplicated $deduplicatedCount configurations" -Level "Info"
        }
    }
    
    # Calculer les différences entre les versions si demandé
    if ($CalculateDiff) {
        Write-Log "Calculating configuration differences..." -Level "Info"
        
        # Créer le répertoire pour les diffs
        $diffsPath = Join-Path -Path $StatesPath -ChildPath "diffs"
        
        if (-not (Test-Path -Path $diffsPath)) {
            New-Item -Path $diffsPath -ItemType Directory -Force | Out-Null
        }
        
        # Regrouper les fichiers par type et ID
        $fileGroups = @{}
        
        foreach ($stateFile in $stateFiles) {
            try {
                # Extraire le type et l'ID de la configuration
                if ($stateFile.Name -match "^([^_]+)_([^_]+)_state\.json$") {
                    $type = $matches[1]
                    $id = $matches[2]
                    $key = "$type:$id"
                    
                    if (-not $fileGroups.ContainsKey($key)) {
                        $fileGroups[$key] = @()
                    }
                    
                    $fileGroups[$key] += $stateFile
                }
            } catch {
                Write-Log "Error processing state file $($stateFile.Name): $_" -Level "Warning"
            }
        }
        
        # Traiter chaque groupe
        foreach ($key in $fileGroups.Keys) {
            $files = $fileGroups[$key]
            
            # Trier les fichiers par date de modification
            $sortedFiles = $files | Sort-Object LastWriteTime
            
            # Calculer les différences entre les versions consécutives
            for ($i = 0; $i -lt $sortedFiles.Count - 1; $i++) {
                try {
                    $oldFile = $sortedFiles[$i]
                    $newFile = $sortedFiles[$i + 1]
                    
                    # Charger les états
                    $oldState = Get-Content -Path $oldFile.FullName -Raw | ConvertFrom-Json
                    $newState = Get-Content -Path $newFile.FullName -Raw | ConvertFrom-Json
                    
                    # Calculer les différences
                    $diff = Get-ConfigurationDiff -OldConfiguration $oldState.state -NewConfiguration $newState.state
                    
                    if ($null -eq $diff) {
                        Write-Log "Failed to calculate diff between $($oldFile.Name) and $($newFile.Name)" -Level "Warning"
                        continue
                    }
                    
                    # Sauvegarder le diff
                    $diffFileName = "$key-diff-$($i+1)-to-$($i+2).json"
                    $diffFilePath = Join-Path -Path $diffsPath -ChildPath $diffFileName
                    
                    $diff | ConvertTo-Json -Depth 10 | Out-File -FilePath $diffFilePath -Encoding UTF8
                    
                    $diffCount++
                } catch {
                    Write-Log "Error calculating diff: $_" -Level "Warning"
                }
            }
        }
        
        Write-Log "Calculated $diffCount configuration differences" -Level "Info"
    }
    
    # Afficher le résumé
    Write-Log "Optimization summary:" -Level "Info"
    Write-Log "- Compressed: $compressedCount configurations" -Level "Info"
    Write-Log "- Deduplicated: $deduplicatedCount configurations" -Level "Info"
    Write-Log "- Calculated diffs: $diffCount configuration differences" -Level "Info"
    
    return $true
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Optimize-ConfigurationStorage -StatesPath $StatesPath -Compress:$Compress -Deduplicate:$Deduplicate -CalculateDiff:$CalculateDiff -Force:$Force
}
