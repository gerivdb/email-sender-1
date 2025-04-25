<#
.SYNOPSIS
    Version optimisée du détecteur de références brisées utilisant PSCacheManager.
.DESCRIPTION
    Ce script analyse tous les scripts du projet pour identifier les chemins de fichiers
    qui ne correspondent plus à la nouvelle structure de dossiers. Il génère un rapport
    des références à mettre à jour, avec mise en cache des résultats d'analyse pour
    améliorer les performances lors d'exécutions répétées.
.PARAMETER Path
    Chemin du dossier contenant les scripts à analyser. Par défaut: scripts
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport. Par défaut: broken_references_report.json
.PARAMETER ShowDetails
    Affiche des informations détaillées pendant l'exécution.
.PARAMETER DisableCache
    Si spécifié, désactive l'utilisation du cache pour cette analyse.
.EXAMPLE
    .\Detect-BrokenReferences-Cached.ps1
    Analyse tous les scripts dans le dossier scripts et génère un rapport.
.EXAMPLE
    .\Detect-BrokenReferences-Cached.ps1 -Path "D:\scripts" -OutputPath "D:\rapport.json" -DisableCache
    Analyse tous les scripts dans le dossier D:\scripts sans utiliser le cache et génère un rapport dans D:\rapport.json.
.NOTES
    Auteur: Système d'analyse d'erreurs
    Date de création: 09/04/2025
    Version: 2.0
#>

param (
    [string]$Path = "scripts",
    [string]$OutputPath = "broken_references_report.json",
    [switch]$ShowDetails,
    [switch]$DisableCache
)

# Importer le module PSCacheManager
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\utils\PSCacheManager\PSCacheManager.psm1"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module PSCacheManager introuvable à l'emplacement: $modulePath"
    exit 1
}

try {
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Verbose "Module PSCacheManager importé avec succès."
} catch {
    Write-Error "Erreur lors de l'importation du module PSCacheManager: $_"
    exit 1
}

# Initialiser les caches
$scriptContentCache = New-PSCache -Name "ScriptContent" -MaxMemoryItems 1000 -DefaultTTLSeconds 3600
$fileExistenceCache = New-PSCache -Name "FileExistence" -MaxMemoryItems 5000 -DefaultTTLSeconds 3600
$pathAnalysisCache = New-PSCache -Name "PathAnalysis" -MaxMemoryItems 500 -DefaultTTLSeconds 3600

# Fonction pour écrire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )

    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "TITLE" = "Cyan"
    }

    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"

    Write-Host $FormattedMessage -ForegroundColor $Color
}

# Fonction pour vérifier si un fichier existe (avec cache)
function Test-FileExistsWithCache {
    param (
        [string]$FilePath
    )
    
    if ($DisableCache) {
        return Test-Path -Path $FilePath -PathType Leaf
    }
    
    $cacheKey = "Exists_$FilePath"
    
    return Get-PSCacheItem -Cache $fileExistenceCache -Key $cacheKey -GenerateValue {
        Test-Path -Path $FilePath -PathType Leaf
    }
}

# Fonction pour extraire les chemins de fichiers d'un script
function Get-FilePathsFromScript {
    param (
        [string]$ScriptPath
    )
    
    $scriptInfo = Get-Item -Path $ScriptPath
    $cacheKey = "Paths_$($scriptInfo.FullName)_$($scriptInfo.LastWriteTime.Ticks)"
    
    if ($DisableCache) {
        return Extract-Paths -ScriptPath $ScriptPath
    }
    
    return Get-PSCacheItem -Cache $pathAnalysisCache -Key $cacheKey -GenerateValue {
        Extract-Paths -ScriptPath $ScriptPath
    }
}

# Fonction pour extraire les chemins de fichiers d'un script (implémentation)
function Extract-Paths {
    param (
        [string]$ScriptPath
    )
    
    Write-Log "Analyse du script: $ScriptPath" -Level "INFO"
    
    try {
        # Obtenir le contenu du script (avec cache)
        $scriptContent = if ($DisableCache) {
            Get-Content -Path $ScriptPath -Raw -ErrorAction Stop
        } else {
            $scriptInfo = Get-Item -Path $ScriptPath
            $contentCacheKey = "Content_$($scriptInfo.FullName)_$($scriptInfo.LastWriteTime.Ticks)"
            
            Get-PSCacheItem -Cache $scriptContentCache -Key $contentCacheKey -GenerateValue {
                Get-Content -Path $ScriptPath -Raw -ErrorAction Stop
            }
        }
        
        # Patterns pour détecter les chemins de fichiers
        $patterns = @(
            # Chemins entre guillemets
            '(?<=["''])([.\\\/\w-]+\.\w+)(?=["''])',
            # Chemins dans Join-Path
            '(?<=Join-Path\s+[-\w]+\s+["''])([.\\\/\w-]+)(?=["''])',
            # Chemins dans Import-Module
            '(?<=Import-Module\s+["''])([.\\\/\w-]+)(?=["''])',
            # Chemins dans Get-Content, Set-Content, etc.
            '(?<=(Get|Set|Test)-\w+\s+[-\w]+\s+["''])([.\\\/\w-]+)(?=["''])'
        )
        
        $detectedPaths = @()
        
        foreach ($pattern in $patterns) {
            $matches = [regex]::Matches($scriptContent, $pattern)
            foreach ($match in $matches) {
                $path = $match.Value
                
                # Ignorer les chemins qui ne semblent pas être des références à des fichiers
                if ($path -match '^\w+$' -or $path -match '^https?:' -or $path -match '^\$') {
                    continue
                }
                
                # Normaliser le chemin
                $normalizedPath = $path.Replace('/', '\')
                
                # Ajouter à la liste des chemins détectés
                if ($normalizedPath -notin $detectedPaths) {
                    $detectedPaths += $normalizedPath
                }
            }
        }
        
        return $detectedPaths
    }
    catch {
        Write-Log "Erreur lors de l'analyse du script $ScriptPath : $_" -Level "ERROR"
        return @()
    }
}

# Fonction principale pour détecter les références brisées
function Detect-BrokenReferences {
    param (
        [string]$RootPath,
        [string]$OutputFile
    )
    
    $startTime = Get-Date
    Write-Log "Début de la détection des références brisées..." -Level "TITLE"
    Write-Log "Dossier racine: $RootPath" -Level "INFO"
    
    # Récupérer tous les scripts PowerShell
    $scripts = Get-ChildItem -Path $RootPath -Recurse -Filter "*.ps1" -File
    Write-Log "Nombre de scripts trouvés: $($scripts.Count)" -Level "INFO"
    
    $brokenReferences = @()
    $processedScripts = 0
    $totalBrokenPaths = 0
    
    foreach ($script in $scripts) {
        $processedScripts++
        $scriptPaths = Get-FilePathsFromScript -ScriptPath $script.FullName
        
        $brokenPaths = @()
        foreach ($path in $scriptPaths) {
            # Vérifier si le chemin est relatif
            if ($path -match '^\.\.\\' -or $path -match '^\.\\'  -or $path -match '^[a-zA-Z]\\') {
                # Construire le chemin complet
                $basePath = Split-Path -Parent $script.FullName
                $fullPath = Join-Path -Path $basePath -ChildPath $path
                
                # Vérifier si le fichier existe
                $exists = Test-FileExistsWithCache -FilePath $fullPath
                
                if (-not $exists) {
                    $brokenPaths += @{
                        Path = $path
                        FullPath = $fullPath
                    }
                }
            }
        }
        
        if ($brokenPaths.Count -gt 0) {
            $brokenReferences += @{
                Script = $script.FullName
                BrokenPaths = $brokenPaths
            }
            
            $totalBrokenPaths += $brokenPaths.Count
            
            if ($ShowDetails) {
                Write-Log "Script: $($script.FullName)" -Level "WARNING"
                foreach ($brokenPath in $brokenPaths) {
                    Write-Log "  - Chemin brisé: $($brokenPath.Path)" -Level "WARNING"
                }
            }
        }
        
        # Afficher la progression
        if ($processedScripts % 10 -eq 0 -or $processedScripts -eq $scripts.Count) {
            Write-Progress -Activity "Détection des références brisées" -Status "Traitement des scripts" -PercentComplete (($processedScripts / $scripts.Count) * 100)
        }
    }
    
    Write-Progress -Activity "Détection des références brisées" -Completed
    
    # Générer le rapport
    $report = @{
        ScannedScripts = $scripts.Count
        BrokenReferences = $brokenReferences.Count
        TotalBrokenPaths = $totalBrokenPaths
        Details = $brokenReferences
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    # Sauvegarder le rapport
    $report | ConvertTo-Json -Depth 4 | Out-File -FilePath $OutputFile -Encoding UTF8
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    Write-Log "Détection terminée en $duration secondes." -Level "SUCCESS"
    Write-Log "Scripts analysés: $($scripts.Count)" -Level "INFO"
    Write-Log "Scripts avec références brisées: $($brokenReferences.Count)" -Level "INFO"
    Write-Log "Nombre total de chemins brisés: $totalBrokenPaths" -Level "INFO"
    Write-Log "Rapport sauvegardé: $OutputFile" -Level "SUCCESS"
    
    # Afficher les statistiques du cache si activé
    if (-not $DisableCache) {
        $contentStats = Get-PSCacheStatistics -Cache $scriptContentCache
        $existenceStats = Get-PSCacheStatistics -Cache $fileExistenceCache
        $pathStats = Get-PSCacheStatistics -Cache $pathAnalysisCache
        
        Write-Log "Statistiques du cache:" -Level "TITLE"
        Write-Log "Cache de contenu de scripts:" -Level "INFO"
        Write-Log "  - Éléments: $($contentStats.MemoryItemCount)" -Level "INFO"
        Write-Log "  - Hits: $($contentStats.Hits)" -Level "INFO"
        Write-Log "  - Misses: $($contentStats.Misses)" -Level "INFO"
        Write-Log "  - Ratio de hits: $([Math]::Round($contentStats.HitRatio * 100, 2))%" -Level "INFO"
        
        Write-Log "Cache d'existence de fichiers:" -Level "INFO"
        Write-Log "  - Éléments: $($existenceStats.MemoryItemCount)" -Level "INFO"
        Write-Log "  - Hits: $($existenceStats.Hits)" -Level "INFO"
        Write-Log "  - Misses: $($existenceStats.Misses)" -Level "INFO"
        Write-Log "  - Ratio de hits: $([Math]::Round($existenceStats.HitRatio * 100, 2))%" -Level "INFO"
        
        Write-Log "Cache d'analyse de chemins:" -Level "INFO"
        Write-Log "  - Éléments: $($pathStats.MemoryItemCount)" -Level "INFO"
        Write-Log "  - Hits: $($pathStats.Hits)" -Level "INFO"
        Write-Log "  - Misses: $($pathStats.Misses)" -Level "INFO"
        Write-Log "  - Ratio de hits: $([Math]::Round($pathStats.HitRatio * 100, 2))%" -Level "INFO"
    }
    
    return $report
}

# Exécuter la détection
Detect-BrokenReferences -RootPath $Path -OutputFile $OutputPath
