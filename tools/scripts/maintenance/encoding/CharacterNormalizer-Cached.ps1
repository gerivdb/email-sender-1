<#
.SYNOPSIS
    Version optimisÃ©e du normalisateur de caractÃ¨res utilisant PSCacheManager.
.DESCRIPTION
    Ce script normalise les caractÃ¨res spÃ©ciaux (accents, caractÃ¨res non-ASCII) dans un fichier texte
    avec mise en cache des rÃ©sultats pour amÃ©liorer les performances lors de traitements rÃ©pÃ©titifs.
.PARAMETER FilePath
    Chemin du fichier Ã  normaliser.
.PARAMETER OutputPath
    Chemin du fichier de sortie. Si non spÃ©cifiÃ©, le fichier original sera remplacÃ©.
.PARAMETER NormalizationForm
    Forme de normalisation Unicode Ã  utiliser. Les valeurs possibles sont:
    - FormD: DÃ©composition canonique
    - FormC: DÃ©composition suivie d'une recomposition canonique (par dÃ©faut)
    - FormKD: DÃ©composition de compatibilitÃ©
    - FormKC: DÃ©composition de compatibilitÃ© suivie d'une recomposition canonique
.PARAMETER RemoveAccents
    Si spÃ©cifiÃ©, les accents seront supprimÃ©s des caractÃ¨res (ex: Ã© -> e).
.PARAMETER ReplaceNonAscii
    Si spÃ©cifiÃ©, les caractÃ¨res non-ASCII seront remplacÃ©s par leurs Ã©quivalents ASCII ou par des caractÃ¨res de substitution.
.PARAMETER DisableCache
    Si spÃ©cifiÃ©, dÃ©sactive l'utilisation du cache pour ce traitement.
.EXAMPLE
    .\CharacterNormalizer-Cached.ps1 -FilePath "C:\path\to\file.txt" -RemoveAccents
.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 09/04/2025
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

# Initialiser le cache pour la normalisation de caractÃ¨res
$normalizationCache = New-PSCache -Name "CharacterNormalization" -MaxMemoryItems 500 -DefaultTTLSeconds 3600 -EvictionPolicy LRU

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $FilePath)) {
    Write-Error "Le fichier spÃ©cifiÃ© n'existe pas: $FilePath"
    exit 1
}

# Obtenir les informations du fichier pour la clÃ© de cache
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
    
    # Convertir la chaÃ®ne de normalisation en Ã©numÃ©ration
    $normalizationEnum = [System.Text.NormalizationForm]::FormC
    switch ($NormForm) {
        "FormD" { $normalizationEnum = [System.Text.NormalizationForm]::FormD }
        "FormC" { $normalizationEnum = [System.Text.NormalizationForm]::FormC }
        "FormKD" { $normalizationEnum = [System.Text.NormalizationForm]::FormKD }
        "FormKC" { $normalizationEnum = [System.Text.NormalizationForm]::FormKC }
    }
    
    # Normaliser le texte
    $normalizedContent = $Content.Normalize($normalizationEnum)
    
    # Supprimer les accents si demandÃ©
    if ($RemoveAccents) {
        Write-Verbose "Suppression des accents..."
        $normalizedContent = [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($normalizedContent))
    }
    
    # Remplacer les caractÃ¨res non-ASCII si demandÃ©
    if ($ReplaceNonAscii) {
        Write-Verbose "Remplacement des caractÃ¨res non-ASCII..."
        $sb = New-Object System.Text.StringBuilder
        
        foreach ($char in $normalizedContent.ToCharArray()) {
            if ([byte][char]$char -lt 128) {
                [void]$sb.Append($char)
            } else {
                # Table de correspondance pour certains caractÃ¨res spÃ©ciaux courants
                switch ([int][char]$char) {
                    # Lettres accentuÃ©es franÃ§aises
                    { $_ -in 224..227 } { [void]$sb.Append('a'); break } # Ã , Ã¡, Ã¢, Ã£
                    { $_ -in 232..235 } { [void]$sb.Append('e'); break } # Ã¨, Ã©, Ãª, Ã«
                    { $_ -in 236..239 } { [void]$sb.Append('i'); break } # Ã¬, Ã­, Ã®, Ã¯
                    { $_ -in 242..246 } { [void]$sb.Append('o'); break } # Ã², Ã³, Ã´, Ãµ, Ã¶
                    { $_ -in 249..252 } { [void]$sb.Append('u'); break } # Ã¹, Ãº, Ã», Ã¼
                    231 { [void]$sb.Append('c'); break } # Ã§
                    
                    # Autres caractÃ¨res spÃ©ciaux courants
                    171 { [void]$sb.Append('"'); break } # Â«
                    187 { [void]$sb.Append('"'); break } # Â»
                    8211 { [void]$sb.Append('-'); break } # â€“
                    8212 { [void]$sb.Append('-'); break } # â€”
                    8216 { [void]$sb.Append("'"); break } # '
                    8217 { [void]$sb.Append("'"); break } # '
                    8220 { [void]$sb.Append('"'); break } # "
                    8221 { [void]$sb.Append('"'); break } # "
                    8226 { [void]$sb.Append('*'); break } # â€¢
                    8230 { [void]$sb.Append('...'); break } # â€¦
                    
                    # Par dÃ©faut, remplacer par un point d'interrogation
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
        Write-Verbose "Cache dÃ©sactivÃ©, traitement direct du fichier..."
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        $normalizedContent = Normalize-Content -Content $content -NormForm $NormalizationForm -RemoveAccents $RemoveAccents -ReplaceNonAscii $ReplaceNonAscii
    } else {
        Write-Verbose "Utilisation du cache pour le traitement..."
        
        # Utiliser le cache pour obtenir le contenu normalisÃ©
        $normalizedContent = Get-PSCacheItem -Cache $normalizationCache -Key $cacheKey -GenerateValue {
            Write-Host "Cache miss - Normalisation du fichier $FilePath..." -ForegroundColor Yellow
            $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
            Normalize-Content -Content $content -NormForm $NormalizationForm -RemoveAccents $RemoveAccents -ReplaceNonAscii $ReplaceNonAscii
        }
    }
    
    # DÃ©terminer le chemin de sortie
    $outputFilePath = if ($OutputPath) { $OutputPath } else { $FilePath }
    
    # Ã‰crire le contenu normalisÃ© dans le fichier de sortie
    $normalizedContent | Out-File -FilePath $outputFilePath -Encoding UTF8 -NoNewline
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalMilliseconds
    
    Write-Host "Normalisation terminÃ©e en $duration ms. Fichier sauvegardÃ©: $outputFilePath" -ForegroundColor Green
    
    # Afficher les statistiques du cache
    if (-not $DisableCache) {
        $cacheStats = Get-PSCacheStatistics -Cache $normalizationCache
        Write-Verbose "Statistiques du cache:"
        Write-Verbose "  Ã‰lÃ©ments en cache: $($cacheStats.MemoryItemCount)"
        Write-Verbose "  Hits: $($cacheStats.Hits)"
        Write-Verbose "  Misses: $($cacheStats.Misses)"
        Write-Verbose "  Ratio de hits: $([Math]::Round($cacheStats.HitRatio * 100, 2))%"
    }
    
} catch {
    Write-Error "Erreur lors de la normalisation du fichier: $_"
    exit 1
}
