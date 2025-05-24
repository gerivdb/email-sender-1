<#
.SYNOPSIS
    Version optimisÃ©e du dÃ©tecteur de rÃ©fÃ©rences brisÃ©es utilisant PSCacheManager.
.DESCRIPTION
    Ce script analyse tous les scripts du projet pour identifier les chemins de fichiers
    qui ne correspondent plus Ã  la nouvelle structure de dossiers. Il gÃ©nÃ¨re un rapport
    des rÃ©fÃ©rences Ã  mettre Ã  jour, avec mise en cache des rÃ©sultats d'analyse pour
    amÃ©liorer les performances lors d'exÃ©cutions rÃ©pÃ©tÃ©es.
.PARAMETER Path
    Chemin du dossier contenant les scripts Ã  analyser. Par dÃ©faut: scripts
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport. Par dÃ©faut: broken_references_report.json
.PARAMETER ShowDetails
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.PARAMETER DisableCache
    Si spÃ©cifiÃ©, dÃ©sactive l'utilisation du cache pour cette analyse.
.EXAMPLE
    .\Find-BrokenReferences-Cached.ps1
    Analyse tous les scripts dans le dossier scripts et gÃ©nÃ¨re un rapport.
.EXAMPLE
    .\Find-BrokenReferences-Cached.ps1 -Path "D:\scripts" -OutputPath "D:\rapport.json" -DisableCache
    Analyse tous les scripts dans le dossier D:\scripts sans utiliser le cache et gÃ©nÃ¨re un rapport dans D:\rapport.json.
.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 09/04/2025
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
    Write-Error "Module PSCacheManager introuvable Ã  l'emplacement: $modulePath"
    exit 1
}

try {
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Verbose "Module PSCacheManager importÃ© avec succÃ¨s."
} catch {
    Write-Error "Erreur lors de l'importation du module PSCacheManager: $_"
    exit 1
}

# Initialiser les caches
$scriptContentCache = New-PSCache -Name "ScriptContent" -MaxMemoryItems 1000 -DefaultTTLSeconds 3600
$fileExistenceCache = New-PSCache -Name "FileExistence" -MaxMemoryItems 5000 -DefaultTTLSeconds 3600
$pathAnalysisCache = New-PSCache -Name "PathAnalysis" -MaxMemoryItems 500 -DefaultTTLSeconds 3600

# Fonction pour Ã©crire des messages de log
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

# Fonction pour vÃ©rifier si un fichier existe (avec cache)
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
        return Export-Paths -ScriptPath $ScriptPath
    }
    
    return Get-PSCacheItem -Cache $pathAnalysisCache -Key $cacheKey -GenerateValue {
        Export-Paths -ScriptPath $ScriptPath
    }
}

# Fonction pour extraire les chemins de fichiers d'un script (implÃ©mentation)
function Export-Paths {
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
        
        # Patterns pour dÃ©tecter les chemins de fichiers
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
                
                # Ignorer les chemins qui ne semblent pas Ãªtre des rÃ©fÃ©rences Ã  des fichiers
                if ($path -match '^\w+$' -or $path -match '^https?:' -or $path -match '^\$') {
                    continue
                }
                
                # Normaliser le chemin
                $normalizedPath = $path.Replace('/', '\')
                
                # Ajouter Ã  la liste des chemins dÃ©tectÃ©s
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

# Fonction principale pour dÃ©tecter les rÃ©fÃ©rences brisÃ©es
function Find-BrokenReferences {
    param (
        [string]$RootPath,
        [string]$OutputFile
    )
    
    $startTime = Get-Date
    Write-Log "DÃ©but de la dÃ©tection des rÃ©fÃ©rences brisÃ©es..." -Level "TITLE"
    Write-Log "Dossier racine: $RootPath" -Level "INFO"
    
    # RÃ©cupÃ©rer tous les scripts PowerShell
    $scripts = Get-ChildItem -Path $RootPath -Recurse -Filter "*.ps1" -File
    Write-Log "Nombre de scripts trouvÃ©s: $($scripts.Count)" -Level "INFO"
    
    $brokenReferences = @()
    $processedScripts = 0
    $totalBrokenPaths = 0
    
    foreach ($script in $scripts) {
        $processedScripts++
        $scriptPaths = Get-FilePathsFromScript -ScriptPath $script.FullName
        
        $brokenPaths = @()
        foreach ($path in $scriptPaths) {
            # VÃ©rifier si le chemin est relatif
            if ($path -match '^\.\.\\' -or $path -match '^\.\\'  -or $path -match '^[a-zA-Z]\\') {
                # Construire le chemin complet
                $basePath = Split-Path -Parent $script.FullName
                $fullPath = Join-Path -Path $basePath -ChildPath $path
                
                # VÃ©rifier si le fichier existe
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
                    Write-Log "  - Chemin brisÃ©: $($brokenPath.Path)" -Level "WARNING"
                }
            }
        }
        
        # Afficher la progression
        if ($processedScripts % 10 -eq 0 -or $processedScripts -eq $scripts.Count) {
            Write-Progress -Activity "DÃ©tection des rÃ©fÃ©rences brisÃ©es" -Status "Traitement des scripts" -PercentComplete (($processedScripts / $scripts.Count) * 100)
        }
    }
    
    Write-Progress -Activity "DÃ©tection des rÃ©fÃ©rences brisÃ©es" -Completed
    
    # GÃ©nÃ©rer le rapport
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
    
    Write-Log "DÃ©tection terminÃ©e en $duration secondes." -Level "SUCCESS"
    Write-Log "Scripts analysÃ©s: $($scripts.Count)" -Level "INFO"
    Write-Log "Scripts avec rÃ©fÃ©rences brisÃ©es: $($brokenReferences.Count)" -Level "INFO"
    Write-Log "Nombre total de chemins brisÃ©s: $totalBrokenPaths" -Level "INFO"
    Write-Log "Rapport sauvegardÃ©: $OutputFile" -Level "SUCCESS"
    
    # Afficher les statistiques du cache si activÃ©
    if (-not $DisableCache) {
        $contentStats = Get-PSCacheStatistics -Cache $scriptContentCache
        $existenceStats = Get-PSCacheStatistics -Cache $fileExistenceCache
        $pathStats = Get-PSCacheStatistics -Cache $pathAnalysisCache
        
        Write-Log "Statistiques du cache:" -Level "TITLE"
        Write-Log "Cache de contenu de scripts:" -Level "INFO"
        Write-Log "  - Ã‰lÃ©ments: $($contentStats.MemoryItemCount)" -Level "INFO"
        Write-Log "  - Hits: $($contentStats.Hits)" -Level "INFO"
        Write-Log "  - Misses: $($contentStats.Misses)" -Level "INFO"
        Write-Log "  - Ratio de hits: $([Math]::Round($contentStats.HitRatio * 100, 2))%" -Level "INFO"
        
        Write-Log "Cache d'existence de fichiers:" -Level "INFO"
        Write-Log "  - Ã‰lÃ©ments: $($existenceStats.MemoryItemCount)" -Level "INFO"
        Write-Log "  - Hits: $($existenceStats.Hits)" -Level "INFO"
        Write-Log "  - Misses: $($existenceStats.Misses)" -Level "INFO"
        Write-Log "  - Ratio de hits: $([Math]::Round($existenceStats.HitRatio * 100, 2))%" -Level "INFO"
        
        Write-Log "Cache d'analyse de chemins:" -Level "INFO"
        Write-Log "  - Ã‰lÃ©ments: $($pathStats.MemoryItemCount)" -Level "INFO"
        Write-Log "  - Hits: $($pathStats.Hits)" -Level "INFO"
        Write-Log "  - Misses: $($pathStats.Misses)" -Level "INFO"
        Write-Log "  - Ratio de hits: $([Math]::Round($pathStats.HitRatio * 100, 2))%" -Level "INFO"
    }
    
    return $report
}

# ExÃ©cuter la dÃ©tection
Find-BrokenReferences -RootPath $Path -OutputFile $OutputPath

