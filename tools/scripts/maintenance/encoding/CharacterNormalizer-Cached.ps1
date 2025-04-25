<#
.SYNOPSIS
    Version optimisée du normalisateur de caractères utilisant PSCacheManager.
.DESCRIPTION
    Ce script normalise les caractères spéciaux (accents, caractères non-ASCII) dans un fichier texte
    avec mise en cache des résultats pour améliorer les performances lors de traitements répétitifs.
.PARAMETER FilePath
    Chemin du fichier à normaliser.
.PARAMETER OutputPath
    Chemin du fichier de sortie. Si non spécifié, le fichier original sera remplacé.
.PARAMETER NormalizationForm
    Forme de normalisation Unicode à utiliser. Les valeurs possibles sont:
    - FormD: Décomposition canonique
    - FormC: Décomposition suivie d'une recomposition canonique (par défaut)
    - FormKD: Décomposition de compatibilité
    - FormKC: Décomposition de compatibilité suivie d'une recomposition canonique
.PARAMETER RemoveAccents
    Si spécifié, les accents seront supprimés des caractères (ex: é -> e).
.PARAMETER ReplaceNonAscii
    Si spécifié, les caractères non-ASCII seront remplacés par leurs équivalents ASCII ou par des caractères de substitution.
.PARAMETER DisableCache
    Si spécifié, désactive l'utilisation du cache pour ce traitement.
.EXAMPLE
    .\CharacterNormalizer-Cached.ps1 -FilePath "C:\path\to\file.txt" -RemoveAccents
.NOTES
    Auteur: Système d'analyse d'erreurs
    Date de création: 09/04/2025
    Version: 2.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("FormD", "FormC", "FormKD", "FormKC")]
    [string]$NormalizationForm = "FormC",
    
    [Parameter(Mandatory = $false)]
    [switch]$RemoveAccents,
    
    [Parameter(Mandatory = $false)]
    [switch]$ReplaceNonAscii,
    
    [Parameter(Mandatory = $false)]
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

# Initialiser le cache pour la normalisation de caractères
$normalizationCache = New-PSCache -Name "CharacterNormalization" -MaxMemoryItems 500 -DefaultTTLSeconds 3600 -EvictionPolicy LRU

# Vérifier si le fichier existe
if (-not (Test-Path -Path $FilePath)) {
    Write-Error "Le fichier spécifié n'existe pas: $FilePath"
    exit 1
}

# Obtenir les informations du fichier pour la clé de cache
$fileInfo = Get-Item -Path $FilePath
$cacheKey = "Normalization_$($fileInfo.FullName)_$($fileInfo.LastWriteTime.Ticks)_$NormalizationForm_$RemoveAccents_$ReplaceNonAscii"

# Fonction pour normaliser le contenu
function Normalize-Content {
    param (
        [string]$Content,
        [string]$NormForm,
        [bool]$RemoveAccents,
        [bool]$ReplaceNonAscii
    )
    
    Write-Verbose "Normalisation du contenu avec la forme $NormForm..."
    
    # Convertir la chaîne de normalisation en énumération
    $normalizationEnum = [System.Text.NormalizationForm]::FormC
    switch ($NormForm) {
        "FormD" { $normalizationEnum = [System.Text.NormalizationForm]::FormD }
        "FormC" { $normalizationEnum = [System.Text.NormalizationForm]::FormC }
        "FormKD" { $normalizationEnum = [System.Text.NormalizationForm]::FormKD }
        "FormKC" { $normalizationEnum = [System.Text.NormalizationForm]::FormKC }
    }
    
    # Normaliser le texte
    $normalizedContent = $Content.Normalize($normalizationEnum)
    
    # Supprimer les accents si demandé
    if ($RemoveAccents) {
        Write-Verbose "Suppression des accents..."
        $normalizedContent = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($normalizedContent))
    }
    
    # Remplacer les caractères non-ASCII si demandé
    if ($ReplaceNonAscii) {
        Write-Verbose "Remplacement des caractères non-ASCII..."
        $sb = New-Object System.Text.StringBuilder
        
        foreach ($char in $normalizedContent.ToCharArray()) {
            if ([byte][char]$char -lt 128) {
                [void]$sb.Append($char)
            } else {
                # Table de correspondance pour certains caractères spéciaux courants
                switch ([int][char]$char) {
                    # Lettres accentuées françaises
                    { $_ -in 224..227 } { [void]$sb.Append('a'); break } # à, á, â, ã
                    { $_ -in 232..235 } { [void]$sb.Append('e'); break } # è, é, ê, ë
                    { $_ -in 236..239 } { [void]$sb.Append('i'); break } # ì, í, î, ï
                    { $_ -in 242..246 } { [void]$sb.Append('o'); break } # ò, ó, ô, õ, ö
                    { $_ -in 249..252 } { [void]$sb.Append('u'); break } # ù, ú, û, ü
                    231 { [void]$sb.Append('c'); break } # ç
                    
                    # Autres caractères spéciaux courants
                    171 { [void]$sb.Append('"'); break } # «
                    187 { [void]$sb.Append('"'); break } # »
                    8211 { [void]$sb.Append('-'); break } # –
                    8212 { [void]$sb.Append('-'); break } # —
                    8216 { [void]$sb.Append("'"); break } # '
                    8217 { [void]$sb.Append("'"); break } # '
                    8220 { [void]$sb.Append('"'); break } # "
                    8221 { [void]$sb.Append('"'); break } # "
                    8226 { [void]$sb.Append('*'); break } # •
                    8230 { [void]$sb.Append('...'); break } # …
                    
                    # Par défaut, remplacer par un point d'interrogation
                    default { [void]$sb.Append('?') }
                }
            }
        }
        
        $normalizedContent = $sb.ToString()
    }
    
    return $normalizedContent
}

# Traitement principal avec mise en cache
try {
    $startTime = Get-Date
    
    if ($DisableCache) {
        Write-Verbose "Cache désactivé, traitement direct du fichier..."
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        $normalizedContent = Normalize-Content -Content $content -NormForm $NormalizationForm -RemoveAccents $RemoveAccents -ReplaceNonAscii $ReplaceNonAscii
    } else {
        Write-Verbose "Utilisation du cache pour le traitement..."
        
        # Utiliser le cache pour obtenir le contenu normalisé
        $normalizedContent = Get-PSCacheItem -Cache $normalizationCache -Key $cacheKey -GenerateValue {
            Write-Host "Cache miss - Normalisation du fichier $FilePath..." -ForegroundColor Yellow
            $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
            Normalize-Content -Content $content -NormForm $NormalizationForm -RemoveAccents $RemoveAccents -ReplaceNonAscii $ReplaceNonAscii
        }
    }
    
    # Déterminer le chemin de sortie
    $outputFilePath = if ($OutputPath) { $OutputPath } else { $FilePath }
    
    # Écrire le contenu normalisé dans le fichier de sortie
    $normalizedContent | Out-File -FilePath $outputFilePath -Encoding UTF8 -NoNewline
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    
    Write-Host "Normalisation terminée en $duration ms. Fichier sauvegardé: $outputFilePath" -ForegroundColor Green
    
    # Afficher les statistiques du cache
    if (-not $DisableCache) {
        $cacheStats = Get-PSCacheStatistics -Cache $normalizationCache
        Write-Verbose "Statistiques du cache:"
        Write-Verbose "  Éléments en cache: $($cacheStats.MemoryItemCount)"
        Write-Verbose "  Hits: $($cacheStats.Hits)"
        Write-Verbose "  Misses: $($cacheStats.Misses)"
        Write-Verbose "  Ratio de hits: $([Math]::Round($cacheStats.HitRatio * 100, 2))%"
    }
    
} catch {
    Write-Error "Erreur lors de la normalisation du fichier: $_"
    exit 1
}
