<#
.SYNOPSIS
    Optimise la gestion des chemins de fichiers dans le cache disque du module PSCacheManager.
.DESCRIPTION
    Ce script améliore la gestion des chemins de fichiers dans le cache disque du module PSCacheManager
    en implémentant des techniques pour éviter les problèmes de longueur de chemin, normaliser les noms
    de fichiers et optimiser la structure des dossiers de cache.
.PARAMETER ModulePath
    Chemin du module PSCacheManager. Par défaut, utilise le dossier courant.
.PARAMETER ApplyChanges
    Si spécifié, applique les modifications au module. Sinon, affiche seulement les modifications proposées.
.EXAMPLE
    .\Optimize-PSCachePathHandling.ps1 -ApplyChanges
    Optimise la gestion des chemins de fichiers dans le module PSCacheManager et applique les modifications.
.NOTES
    Auteur: Système d'optimisation
    Date de création: 09/04/2025
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ModulePath = $PSScriptRoot,
    
    [Parameter(Mandatory = $false)]
    [switch]$ApplyChanges
)

# Vérifier si le module existe
$modulePsmPath = Join-Path -Path $ModulePath -ChildPath "PSCacheManager.psm1"
if (-not (Test-Path -Path $modulePsmPath)) {
    Write-Error "Module PSCacheManager introuvable à l'emplacement: $modulePsmPath"
    exit 1
}

# Fonction pour générer un hash court à partir d'une chaîne
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
    
    # Remplacer les caractères invalides dans les noms de fichiers
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
    
    # Créer une structure de dossiers à deux niveaux pour éviter d'avoir trop de fichiers dans un seul dossier
    $firstLevel = $safeKey.Substring(0, [Math]::Min(2, $safeKey.Length))
    $cachePath = Join-Path -Path $CacheBasePath -ChildPath $firstLevel
    
    # Créer le dossier s'il n'existe pas
    if (-not (Test-Path -Path $cachePath)) {
        New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
    }
    
    # Retourner le chemin complet du fichier cache
    return Join-Path -Path $cachePath -ChildPath "$safeKey.cache"
}

# Lire le contenu du module
$moduleContent = Get-Content -Path $modulePsmPath -Raw

# Modifications à apporter
$modifications = @(
    @{
        Description = "Amélioration de la méthode SaveToDisk pour gérer les chemins longs"
        Pattern = '(?s)\[void\] SaveToDisk\(\[string\]\$key, \[CacheItem\]\$item\) \{.*?if \(-not \$this\.EnableDiskCache\) \{.*?return.*?\}.*?\$persistPath = Join-Path -Path \$this\.CachePath -ChildPath "\$key\.cache"'
        Replacement = '[void] SaveToDisk([string]$key, [CacheItem]$item) {
        if (-not $this.EnableDiskCache) {
            return
        }
        
        # Normaliser le chemin du fichier cache
        $persistPath = $this.GetNormalizedCachePath($key)'
    },
    @{
        Description = "Amélioration de la méthode LoadFromDisk pour gérer les chemins longs"
        Pattern = '(?s)\[CacheItem\] LoadFromDisk\(\[string\]\$key\) \{.*?if \(-not \$this\.EnableDiskCache\) \{.*?return \$null.*?\}.*?\$persistPath = Join-Path -Path \$this\.CachePath -ChildPath "\$key\.cache"'
        Replacement = '[CacheItem] LoadFromDisk([string]$key) {
        if (-not $this.EnableDiskCache) {
            return $null
        }
        
        # Normaliser le chemin du fichier cache
        $persistPath = $this.GetNormalizedCachePath($key)'
    },
    @{
        Description = "Amélioration de la méthode RemoveFromDisk pour gérer les chemins longs"
        Pattern = '(?s)\[void\] RemoveFromDisk\(\[string\]\$key\) \{.*?if \(-not \$this\.EnableDiskCache\) \{.*?return.*?\}.*?\$persistPath = Join-Path -Path \$this\.CachePath -ChildPath "\$key\.cache"'
        Replacement = '[void] RemoveFromDisk([string]$key) {
        if (-not $this.EnableDiskCache) {
            return
        }
        
        # Normaliser le chemin du fichier cache
        $persistPath = $this.GetNormalizedCachePath($key)'
    },
    @{
        Description = "Ajout de la méthode GetNormalizedCachePath pour normaliser les chemins de fichiers"
        Pattern = '(?s)# Méthodes de statistiques.*?\[hashtable\] GetStatistics\(\) \{'
        Replacement = '# Méthode pour normaliser les chemins de fichiers cache
    [string] GetNormalizedCachePath([string]$key) {
        # Remplacer les caractères invalides dans les noms de fichiers
        $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
        $safeKey = $key
        foreach ($char in $invalidChars) {
            $safeKey = $safeKey.Replace($char, "_")
        }
        
        # Si le chemin est trop long, utiliser un hash
        if ($safeKey.Length -gt 100) {
            # Générer un hash MD5 court
            $stringAsStream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($key))
            $hash = Get-FileHash -InputStream $stringAsStream -Algorithm MD5
            $shortHash = $hash.Hash.Substring(0, 8).ToLower()
            
            # Tronquer la clé et ajouter le hash
            $shortKey = $safeKey.Substring(0, 90) + "_" + $shortHash
            $safeKey = $shortKey
        }
        
        # Créer une structure de dossiers à deux niveaux pour éviter d''avoir trop de fichiers dans un seul dossier
        $firstLevel = $safeKey.Substring(0, [Math]::Min(2, $safeKey.Length))
        $cachePath = Join-Path -Path $this.CachePath -ChildPath $firstLevel
        
        # Créer le dossier s''il n''existe pas
        if (-not (Test-Path -Path $cachePath)) {
            New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
        }
        
        # Retourner le chemin complet du fichier cache
        return Join-Path -Path $cachePath -ChildPath "$safeKey.cache"
    }
    
    # Méthodes de statistiques
    [hashtable] GetStatistics() {'
    },
    @{
        Description = "Modification de la méthode LoadPersistentCache pour utiliser la nouvelle structure de dossiers"
        Pattern = '(?s)\[void\] LoadPersistentCache\(\) \{.*?if \(-not \$this\.EnableDiskCache\) \{.*?return.*?\}.*?\$cacheFiles = Get-ChildItem -Path \$this\.CachePath -Filter "\*\.cache" -File'
        Replacement = '[void] LoadPersistentCache() {
        if (-not $this.EnableDiskCache) {
            return
        }
        
        # Rechercher récursivement tous les fichiers cache
        $cacheFiles = Get-ChildItem -Path $this.CachePath -Filter "*.cache" -File -Recurse'
    }
)

# Afficher les modifications proposées
Write-Host "Modifications proposées pour optimiser la gestion des chemins de fichiers:" -ForegroundColor Cyan
foreach ($mod in $modifications) {
    Write-Host "- $($mod.Description)" -ForegroundColor Yellow
}

# Appliquer les modifications si demandé
if ($ApplyChanges) {
    Write-Host "`nApplication des modifications..." -ForegroundColor Green
    
    # Créer une sauvegarde du fichier original
    $backupPath = "$modulePsmPath.bak"
    Copy-Item -Path $modulePsmPath -Destination $backupPath -Force
    Write-Host "Sauvegarde créée: $backupPath" -ForegroundColor Green
    
    # Appliquer les modifications
    $newContent = $moduleContent
    foreach ($mod in $modifications) {
        $newContent = $newContent -replace $mod.Pattern, $mod.Replacement
    }
    
    # Sauvegarder le fichier modifié
    $newContent | Out-File -FilePath $modulePsmPath -Encoding UTF8
    Write-Host "Modifications appliquées avec succès." -ForegroundColor Green
    
    # Vérifier si le module peut être importé
    try {
        Import-Module $modulePsmPath -Force -ErrorAction Stop
        Write-Host "Module importé avec succès après les modifications." -ForegroundColor Green
    } catch {
        Write-Error "Erreur lors de l'importation du module après les modifications: $_"
        Write-Host "Restauration de la sauvegarde..." -ForegroundColor Yellow
        Copy-Item -Path $backupPath -Destination $modulePsmPath -Force
        Write-Host "Sauvegarde restaurée." -ForegroundColor Green
    }
} else {
    Write-Host "`nLes modifications n'ont pas été appliquées. Utilisez le paramètre -ApplyChanges pour appliquer les modifications." -ForegroundColor Yellow
}

# Afficher des recommandations supplémentaires
Write-Host "`nRecommandations supplémentaires:" -ForegroundColor Cyan
Write-Host "1. Utilisez des clés de cache concises et significatives pour éviter les problèmes de longueur de chemin." -ForegroundColor White
Write-Host "2. Évitez d'utiliser des caractères spéciaux dans les clés de cache." -ForegroundColor White
Write-Host "3. Configurez le chemin de base du cache dans un emplacement avec un chemin court (ex: C:\Cache)." -ForegroundColor White
Write-Host "4. Utilisez la compression pour réduire la taille des fichiers de cache volumineux." -ForegroundColor White
Write-Host "5. Implémentez une stratégie de nettoyage périodique pour éviter l'accumulation de fichiers de cache obsolètes." -ForegroundColor White
