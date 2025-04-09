<#
.SYNOPSIS
    Exemple d'utilisation du module PSCacheManager.
.DESCRIPTION
    Ce script montre comment utiliser le module PSCacheManager pour améliorer
    les performances des scripts PowerShell en mettant en cache les résultats
    d'opérations coûteuses.
.EXAMPLE
    .\Example-Usage.ps1
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Compatibilité: PowerShell 5.1 et supérieur
#>

# Importer le module
Import-Module "$PSScriptRoot\PSCacheManager.psd1" -Force

# Créer un gestionnaire de cache pour l'analyse de scripts
$scriptCache = New-PSCache -Name "ScriptAnalysis" -MaxItems 500 -DefaultTTLSeconds 1800

# Fonction pour analyser un script PowerShell avec mise en cache
function Test-ScriptWithCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script n'existe pas: $ScriptPath"
        return $null
    }

    # Générer une clé de cache basée sur le chemin et la date de modification
    $scriptInfo = Get-Item -Path $ScriptPath
    $cacheKey = "Analysis_$($scriptInfo.FullName)_$($scriptInfo.LastWriteTime.Ticks)"

    # Tenter de récupérer du cache, sinon générer
    $analysis = Get-PSCacheItem -Cache $scriptCache -Key $cacheKey -GenerateValue {
        Write-Verbose "Cache miss - Analyzing script $ScriptPath"

        # Simuler une opération coûteuse
        Start-Sleep -Milliseconds 500

        # Lire le contenu du script
        $content = Get-Content -Path $ScriptPath -Raw

        # Analyser le script avec l'AST (Abstract Syntax Tree)
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$parseErrors)

        # Compter les différents types d'éléments
        $commands = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true)
        $variables = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true)
        $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
        $parameters = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.ParameterAst] }, $true)

        # Créer l'objet d'analyse
        $result = [PSCustomObject]@{
            ScriptPath = $ScriptPath
            ScriptName = $scriptInfo.Name
            LastModified = $scriptInfo.LastWriteTime
            SizeBytes = $scriptInfo.Length
            LineCount = ($content -split "`n").Count
            CommandCount = $commands.Count
            VariableCount = $variables.Count
            FunctionCount = $functions.Count
            ParameterCount = $parameters.Count
            Functions = $functions | ForEach-Object { $_.Name }
            HasParseErrors = $parseErrors.Count -gt 0
            ParseErrors = $parseErrors
            AnalysisTimestamp = Get-Date
        }

        return $result
    } -TTLSeconds 3600 -Tags @("ScriptAnalysis", $scriptInfo.Extension)

    return $analysis
}

# Fonction pour détecter l'encodage d'un fichier avec mise en cache
function Get-FileEncodingWithCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return $null
    }

    # Créer un gestionnaire de cache pour la détection d'encodage si nécessaire
    if (-not (Get-Variable -Name "encodingCache" -Scope Script -ErrorAction SilentlyContinue)) {
        $script:encodingCache = New-PSCache -Name "EncodingDetection" -MaxItems 1000 -DefaultTTLSeconds 86400
    }

    # Générer une clé de cache basée sur le chemin et la date de modification
    $fileInfo = Get-Item -Path $FilePath
    $cacheKey = "Encoding_$($fileInfo.FullName)_$($fileInfo.LastWriteTime.Ticks)"

    # Tenter de récupérer du cache, sinon générer
    $encodingInfo = Get-PSCacheItem -Cache $script:encodingCache -Key $cacheKey -GenerateValue {
        Write-Verbose "Cache miss - Detecting encoding for $FilePath"

        # Simuler une opération coûteuse
        Start-Sleep -Milliseconds 200

        # Lire les premiers octets du fichier pour détecter l'encodage
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)

        # Détecter l'encodage
        $encoding = "Unknown"
        $hasBOM = $false

        if ($bytes.Length -ge 2) {
            # Vérifier les BOM (Byte Order Mark)
            if ($bytes.Length -ge 4 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) {
                $encoding = "UTF-32 LE"
                $hasBOM = $true
            }
            elseif ($bytes.Length -ge 4 -and $bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
                $encoding = "UTF-32 BE"
                $hasBOM = $true
            }
            elseif ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
                $encoding = "UTF-8"
                $hasBOM = $true
            }
            elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
                $encoding = "UTF-16 BE"
                $hasBOM = $true
            }
            elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
                $encoding = "UTF-16 LE"
                $hasBOM = $true
            }
            else {
                # Analyse heuristique pour UTF-8 sans BOM
                $isUtf8 = $true
                $utf8Sequences = 0

                for ($i = 0; $i -lt [Math]::Min($bytes.Length, 1000); $i++) {
                    if ($bytes[$i] -ge 0x80) {
                        # Vérifier les séquences UTF-8 valides
                        if ($bytes[$i] -ge 0xC0 -and $bytes[$i] -le 0xDF -and $i + 1 -lt $bytes.Length -and $bytes[$i + 1] -ge 0x80 -and $bytes[$i + 1] -le 0xBF) {
                            $i++
                            $utf8Sequences++
                        }
                        elseif ($bytes[$i] -ge 0xE0 -and $bytes[$i] -le 0xEF -and $i + 2 -lt $bytes.Length -and $bytes[$i + 1] -ge 0x80 -and $bytes[$i + 1] -le 0xBF -and $bytes[$i + 2] -ge 0x80 -and $bytes[$i + 2] -le 0xBF) {
                            $i += 2
                            $utf8Sequences++
                        }
                        elseif ($bytes[$i] -ge 0xF0 -and $bytes[$i] -le 0xF7 -and $i + 3 -lt $bytes.Length -and $bytes[$i + 1] -ge 0x80 -and $bytes[$i + 1] -le 0xBF -and $bytes[$i + 2] -ge 0x80 -and $bytes[$i + 2] -le 0xBF -and $bytes[$i + 3] -ge 0x80 -and $bytes[$i + 3] -le 0xBF) {
                            $i += 3
                            $utf8Sequences++
                        }
                        else {
                            $isUtf8 = $false
                            break
                        }
                    }
                }

                if ($isUtf8 -and $utf8Sequences -gt 0) {
                    $encoding = "UTF-8"
                    $hasBOM = $false
                }
                else {
                    # Par défaut, supposer ASCII ou ANSI
                    $encoding = "ASCII/ANSI"
                    $hasBOM = $false
                }
            }
        }

        # Créer l'objet d'information d'encodage
        $result = [PSCustomObject]@{
            FilePath = $FilePath
            FileName = $fileInfo.Name
            Encoding = $encoding
            HasBOM = $hasBOM
            SizeBytes = $fileInfo.Length
            LastModified = $fileInfo.LastWriteTime
            DetectionTimestamp = Get-Date
        }

        return $result
    } -TTLSeconds 86400 -Tags @("EncodingDetection", $fileInfo.Extension)

    return $encodingInfo
}

# Démonstration d'utilisation
Write-Host "Démonstration du module PSCacheManager" -ForegroundColor Cyan
Write-Host "------------------------------------" -ForegroundColor Cyan

# Analyser le module lui-même
$modulePath = "$PSScriptRoot\PSCacheManager.psm1"
Write-Host "`nAnalyse du script: $modulePath" -ForegroundColor Yellow

# Premier appel (cache miss)
Write-Host "`nPremier appel (devrait être un cache miss):" -ForegroundColor Green
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$analysis1 = Test-ScriptWithCache -ScriptPath $modulePath -Verbose
$sw.Stop()
Write-Host "Temps d'exécution: $($sw.ElapsedMilliseconds) ms" -ForegroundColor Green

# Afficher quelques informations
Write-Host "`nInformations sur le script:"
Write-Host "  Nom: $($analysis1.ScriptName)"
Write-Host "  Taille: $([Math]::Round($analysis1.SizeBytes / 1KB, 2)) KB"
Write-Host "  Lignes: $($analysis1.LineCount)"
Write-Host "  Fonctions: $($analysis1.FunctionCount)"
Write-Host "  Variables: $($analysis1.VariableCount)"
Write-Host "  Commandes: $($analysis1.CommandCount)"

# Deuxième appel (cache hit)
Write-Host "`nDeuxième appel (devrait être un cache hit):" -ForegroundColor Green
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$analysis2 = Test-ScriptWithCache -ScriptPath $modulePath -Verbose
$sw.Stop()
Write-Host "Temps d'exécution: $($sw.ElapsedMilliseconds) ms" -ForegroundColor Green

# Vérifier que les deux analyses sont identiques
Write-Host "`nVérification de la cohérence des résultats:"
Write-Host "  Analyses identiques: $(($analysis1.CommandCount -eq $analysis2.CommandCount) -and ($analysis1.VariableCount -eq $analysis2.VariableCount))"

# Détecter l'encodage
Write-Host "`nDétection de l'encodage du fichier: $modulePath" -ForegroundColor Yellow

# Premier appel (cache miss)
Write-Host "`nPremier appel (devrait être un cache miss):" -ForegroundColor Green
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$encoding1 = Get-FileEncodingWithCache -FilePath $modulePath -Verbose
$sw.Stop()
Write-Host "Temps d'exécution: $($sw.ElapsedMilliseconds) ms" -ForegroundColor Green

# Afficher les informations d'encodage
Write-Host "`nInformations d'encodage:"
Write-Host "  Encodage: $($encoding1.Encoding)"
Write-Host "  BOM: $($encoding1.HasBOM)"

# Deuxième appel (cache hit)
Write-Host "`nDeuxième appel (devrait être un cache hit):" -ForegroundColor Green
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$encoding2 = Get-FileEncodingWithCache -FilePath $modulePath -Verbose
$sw.Stop()
Write-Host "Temps d'exécution: $($sw.ElapsedMilliseconds) ms" -ForegroundColor Green

# Vérifier que les deux résultats d'encodage sont identiques
Write-Host "`nVérification de la cohérence des résultats d'encodage:"
Write-Host "  Encodages identiques: $($encoding1.Encoding -eq $encoding2.Encoding)"

# Afficher les statistiques du cache
Write-Host "`nStatistiques du cache d'analyse de scripts:" -ForegroundColor Yellow
$scriptCacheStats = Get-PSCacheStatistics -Cache $scriptCache
Write-Host "  Nom: $($scriptCacheStats.Name)"
Write-Host "  Éléments: $($scriptCacheStats.ItemCount)"
Write-Host "  Taille totale: $([Math]::Round($scriptCacheStats.TotalSize / 1KB, 2)) KB"
Write-Host "  Hits: $($scriptCacheStats.Hits)"
Write-Host "  Misses: $($scriptCacheStats.Misses)"
Write-Host "  Ratio de hits: $([Math]::Round($scriptCacheStats.HitRatio * 100, 2))%"

Write-Host "`nStatistiques du cache de détection d'encodage:" -ForegroundColor Yellow
$encodingCacheStats = Get-PSCacheStatistics -Cache $script:encodingCache
Write-Host "  Nom: $($encodingCacheStats.Name)"
Write-Host "  Éléments: $($encodingCacheStats.ItemCount)"
Write-Host "  Taille totale: $([Math]::Round($encodingCacheStats.TotalSize / 1KB, 2)) KB"
Write-Host "  Hits: $($encodingCacheStats.Hits)"
Write-Host "  Misses: $($encodingCacheStats.Misses)"
Write-Host "  Ratio de hits: $([Math]::Round($encodingCacheStats.HitRatio * 100, 2))%"

# Nettoyer les caches (optionnel)
# Clear-PSCache -Cache $scriptCache -ExpiredOnly
# Clear-PSCache -Cache $script:encodingCache -ExpiredOnly
