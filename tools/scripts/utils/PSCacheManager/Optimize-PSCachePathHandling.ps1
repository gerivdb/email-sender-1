<#
.SYNOPSIS
    Optimise la gestion des chemins de fichiers dans le cache disque du module PSCacheManager.
.DESCRIPTION
    Ce script amÃ©liore la gestion des chemins de fichiers dans le cache disque du module PSCacheManager
    en implÃ©mentant des techniques pour Ã©viter les problÃ¨mes de longueur de chemin, normaliser les noms
    de fichiers et optimiser la structure des dossiers de cache.
.PARAMETER ModulePath
    Chemin du module PSCacheManager. Par dÃ©faut, utilise le dossier courant.
.PARAMETER ApplyChanges
    Si spÃ©cifiÃ©, applique les modifications au module. Sinon, affiche seulement les modifications proposÃ©es.
.EXAMPLE
    .\Optimize-PSCachePathHandling.ps1 -ApplyChanges
    Optimise la gestion des chemins de fichiers dans le module PSCacheManager et applique les modifications.
.NOTES
    Auteur: SystÃ¨me d'optimisation
    Date de crÃ©ation: 09/04/2025
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ModulePath = $PSScriptRoot,
    
    [Parameter(Mandatory = $false)]
    [switch]$ApplyChanges
)

# VÃ©rifier si le module existe
$modulePsmPath = Join-Path -Path $ModulePath -ChildPath "PSCacheManager.psm1"
if (-not (Test-Path -Path $modulePsmPath)) {
    Write-Error "Module PSCacheManager introuvable Ã  l'emplacement: $modulePsmPath"
    exit 1
}

# Fonction pour gÃ©nÃ©rer un hash court Ã  partir d'une chaÃ®ne
function Get-ShortHash {
    param (
        [string]$InputString
    )
    
    $stringAsStream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($InputString))
    $hash = Get-FileHash -InputStream $stringAsStream -Algorithm MD5
    return $hash.Hash.Substring(0, 8).ToLower()
}

# Fonction pour normaliser un chemin de fichier pour le cache
function Get-NormalizedCachePath {
    param (
        [string]$Key,
        [string]$CacheBasePath
    )
    
    # Remplacer les caractÃ¨res invalides dans les noms de fichiers
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    $safeKey = $Key
    foreach ($char in $invalidChars) {
        $safeKey = $safeKey.Replace($char, '_')
    }
    
    # Si le chemin est trop long, utiliser un hash
    if ($safeKey.Length -gt 100) {
        $hash = Get-ShortHash -InputString $Key
        $shortKey = $safeKey.Substring(0, 90) + "_" + $hash
        $safeKey = $shortKey
    }
    
    # CrÃ©er une structure de dossiers Ã  deux niveaux pour Ã©viter d'avoir trop de fichiers dans un seul dossier
    $firstLevel = $safeKey.Substring(0, [Math]::Min(2, $safeKey.Length))
    $cachePath = Join-Path -Path $CacheBasePath -ChildPath $firstLevel
    
    # CrÃ©er le dossier s'il n'existe pas
    if (-not (Test-Path -Path $cachePath)) {
        New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
    }
    
    # Retourner le chemin complet du fichier cache
    return Join-Path -Path $cachePath -ChildPath "$safeKey.cache"
}

# Lire le contenu du module
$moduleContent = Get-Content -Path $modulePsmPath -Raw

# Modifications Ã  apporter
$modifications = @(
    @{
        Description = "AmÃ©lioration de la mÃ©thode SaveToDisk pour gÃ©rer les chemins longs"
        Pattern = '(?s)\[void\] SaveToDisk\(\[string\]\$key, \[CacheItem\]\$item\) \{.*?if \(-not \$this\.EnableDiskCache\) \{.*?return.*?\}.*?\$persistPath = Join-Path -Path \$this\.CachePath -ChildPath "\$key\.cache"'
        Replacement = '[void] SaveToDisk([string]$key, [CacheItem]$item) {
        if (-not $this.EnableDiskCache) {
            return
        }
        
        # Normaliser le chemin du fichier cache
        $persistPath = $this.GetNormalizedCachePath($key)'
    },
    @{
        Description = "AmÃ©lioration de la mÃ©thode LoadFromDisk pour gÃ©rer les chemins longs"
        Pattern = '(?s)\[CacheItem\] LoadFromDisk\(\[string\]\$key\) \{.*?if \(-not \$this\.EnableDiskCache\) \{.*?return \$null.*?\}.*?\$persistPath = Join-Path -Path \$this\.CachePath -ChildPath "\$key\.cache"'
        Replacement = '[CacheItem] LoadFromDisk([string]$key) {
        if (-not $this.EnableDiskCache) {
            return $null
        }
        
        # Normaliser le chemin du fichier cache
        $persistPath = $this.GetNormalizedCachePath($key)'
    },
    @{
        Description = "AmÃ©lioration de la mÃ©thode RemoveFromDisk pour gÃ©rer les chemins longs"
        Pattern = '(?s)\[void\] RemoveFromDisk\(\[string\]\$key\) \{.*?if \(-not \$this\.EnableDiskCache\) \{.*?return.*?\}.*?\$persistPath = Join-Path -Path \$this\.CachePath -ChildPath "\$key\.cache"'
        Replacement = '[void] RemoveFromDisk([string]$key) {
        if (-not $this.EnableDiskCache) {
            return
        }
        
        # Normaliser le chemin du fichier cache
        $persistPath = $this.GetNormalizedCachePath($key)'
    },
    @{
        Description = "Ajout de la mÃ©thode GetNormalizedCachePath pour normaliser les chemins de fichiers"
        Pattern = '(?s)# MÃ©thodes de statistiques.*?\[hashtable\] GetStatistics\(\) \{'
        Replacement = '# MÃ©thode pour normaliser les chemins de fichiers cache
    [string] GetNormalizedCachePath([string]$key) {
        # Remplacer les caractÃ¨res invalides dans les noms de fichiers
        $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
        $safeKey = $key
        foreach ($char in $invalidChars) {
            $safeKey = $safeKey.Replace($char, "_")
        }
        
        # Si le chemin est trop long, utiliser un hash
        if ($safeKey.Length -gt 100) {
            # GÃ©nÃ©rer un hash MD5 court
            $stringAsStream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($key))
            $hash = Get-FileHash -InputStream $stringAsStream -Algorithm MD5
            $shortHash = $hash.Hash.Substring(0, 8).ToLower()
            
            # Tronquer la clÃ© et ajouter le hash
            $shortKey = $safeKey.Substring(0, 90) + "_" + $shortHash
            $safeKey = $shortKey
        }
        
        # CrÃ©er une structure de dossiers Ã  deux niveaux pour Ã©viter d''avoir trop de fichiers dans un seul dossier
        $firstLevel = $safeKey.Substring(0, [Math]::Min(2, $safeKey.Length))
        $cachePath = Join-Path -Path $this.CachePath -ChildPath $firstLevel
        
        # CrÃ©er le dossier s''il n''existe pas
        if (-not (Test-Path -Path $cachePath)) {
            New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
        }
        
        # Retourner le chemin complet du fichier cache
        return Join-Path -Path $cachePath -ChildPath "$safeKey.cache"
    }
    
    # MÃ©thodes de statistiques
    [hashtable] GetStatistics() {'
    },
    @{
        Description = "Modification de la mÃ©thode LoadPersistentCache pour utiliser la nouvelle structure de dossiers"
        Pattern = '(?s)\[void\] LoadPersistentCache\(\) \{.*?if \(-not \$this\.EnableDiskCache\) \{.*?return.*?\}.*?\$cacheFiles = Get-ChildItem -Path \$this\.CachePath -Filter "\*\.cache" -File'
        Replacement = '[void] LoadPersistentCache() {
        if (-not $this.EnableDiskCache) {
            return
        }
        
        # Rechercher rÃ©cursivement tous les fichiers cache
        $cacheFiles = Get-ChildItem -Path $this.CachePath -Filter "*.cache" -File -Recurse'
    }
)

# Afficher les modifications proposÃ©es
Write-Host "Modifications proposÃ©es pour optimiser la gestion des chemins de fichiers:" -ForegroundColor Cyan
foreach ($mod in $modifications) {
    Write-Host "- $($mod.Description)" -ForegroundColor Yellow
}

# Appliquer les modifications si demandÃ©
if ($ApplyChanges) {
    Write-Host "`nApplication des modifications..." -ForegroundColor Green
    
    # CrÃ©er une sauvegarde du fichier original
    $backupPath = "$modulePsmPath.bak"
    Copy-Item -Path $modulePsmPath -Destination $backupPath -Force
    Write-Host "Sauvegarde crÃ©Ã©e: $backupPath" -ForegroundColor Green
    
    # Appliquer les modifications
    $newContent = $moduleContent
    foreach ($mod in $modifications) {
        $newContent = $newContent -replace $mod.Pattern, $mod.Replacement
    }
    
    # Sauvegarder le fichier modifiÃ©
    $newContent | Out-File -FilePath $modulePsmPath -Encoding UTF8
    Write-Host "Modifications appliquÃ©es avec succÃ¨s." -ForegroundColor Green
    
    # VÃ©rifier si le module peut Ãªtre importÃ©
    try {
        Import-Module $modulePsmPath -Force -ErrorAction Stop
        Write-Host "Module importÃ© avec succÃ¨s aprÃ¨s les modifications." -ForegroundColor Green
    } catch {
        Write-Error "Erreur lors de l'importation du module aprÃ¨s les modifications: $_"
        Write-Host "Restauration de la sauvegarde..." -ForegroundColor Yellow
        Copy-Item -Path $backupPath -Destination $modulePsmPath -Force
        Write-Host "Sauvegarde restaurÃ©e." -ForegroundColor Green
    }
} else {
    Write-Host "`nLes modifications n'ont pas Ã©tÃ© appliquÃ©es. Utilisez le paramÃ¨tre -ApplyChanges pour appliquer les modifications." -ForegroundColor Yellow
}

# Afficher des recommandations supplÃ©mentaires
Write-Host "`nRecommandations supplÃ©mentaires:" -ForegroundColor Cyan
Write-Host "1. Utilisez des clÃ©s de cache concises et significatives pour Ã©viter les problÃ¨mes de longueur de chemin." -ForegroundColor White
Write-Host "2. Ã‰vitez d'utiliser des caractÃ¨res spÃ©ciaux dans les clÃ©s de cache." -ForegroundColor White
Write-Host "3. Configurez le chemin de base du cache dans un emplacement avec un chemin court (ex: C:\Cache)." -ForegroundColor White
Write-Host "4. Utilisez la compression pour rÃ©duire la taille des fichiers de cache volumineux." -ForegroundColor White
Write-Host "5. ImplÃ©mentez une stratÃ©gie de nettoyage pÃ©riodique pour Ã©viter l'accumulation de fichiers de cache obsolÃ¨tes." -ForegroundColor White
