#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'analyse de la longueur des fichiers.

.DESCRIPTION
    Ce module contient des fonctions pour analyser la longueur des fichiers
    dans un projet et générer des rapports sur les fichiers qui dépassent
    les limites recommandées.

.NOTES
    Version: 1.0
    Auteur: Généré automatiquement
    Date de création: 2025-05-25
#>

# Fonction pour obtenir les limites de longueur depuis la configuration
function Get-FileLengthLimits {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    try {
        if (Test-Path $ConfigPath) {
            $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

            if ($config.agent_auto -and $config.agent_auto.code_quality -and $config.agent_auto.code_quality.file_length_limits) {
                return $config.agent_auto.code_quality.file_length_limits
            } else {
                Write-Warning "Configuration de longueur de fichiers non trouvée. Utilisation des valeurs par défaut."
            }
        } else {
            Write-Warning "Fichier de configuration non trouvé. Utilisation des valeurs par défaut."
        }
    } catch {
        Write-Error "Erreur lors de la lecture de la configuration: $_"
    }

    # Valeurs par défaut si la configuration n'est pas disponible
    return [PSCustomObject]@{
        enabled = $true
        ps1     = 300
        psm1    = 500
        psd1    = 200
        py      = 500
        js      = 300
        ts      = 300
        html    = 300
        css     = 300
        json    = 200
        yml     = 200
        md      = 600
    }
}

# Fonction pour analyser la longueur des fichiers
function Measure-FileLengths {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Limits,

        [Parameter(Mandatory = $false)]
        [string[]]$ExcludePaths = @("node_modules", "\.git", "dist", "build", "__pycache__", "\.vscode", "\.idea", "bin", "obj", "packages", "vendor", "reports", "logs")
    )

    $results = @()
    $extensions = @($Limits | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -ne "enabled" } | Select-Object -ExpandProperty Name)

    Write-Verbose "Extensions à analyser: $($extensions -join ', ')"
    Write-Verbose "Chemins exclus: $($ExcludePaths -join ', ')"

    # Créer le pattern d'exclusion
    $excludePattern = $ExcludePaths -join "|"

    # Limiter le nombre de fichiers analysés par extension pour éviter les problèmes de mémoire
    $maxFilesPerExtension = 1000

    foreach ($ext in $extensions) {
        $limit = $Limits.$ext
        $pattern = "*.$ext"

        Write-Verbose "Recherche des fichiers $pattern (limite: $limit lignes)"

        try {
            $files = Get-ChildItem -Path $Path -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch $excludePattern }

            # Limiter le nombre de fichiers si nécessaire
            if ($files.Count -gt $maxFilesPerExtension) {
                Write-Warning "Plus de $maxFilesPerExtension fichiers $pattern trouvés. Limitation à $maxFilesPerExtension fichiers."
                $files = $files | Select-Object -First $maxFilesPerExtension
            }

            $fileCount = $files.Count
            Write-Verbose "Nombre de fichiers $pattern trouvés: $fileCount"

            $processedCount = 0
            foreach ($file in $files) {
                try {
                    # Vérifier si le chemin est trop long
                    if ($file.FullName.Length -gt 260) {
                        Write-Warning "Chemin trop long, ignoré: $($file.FullName)"
                        continue
                    }

                    # Vérifier si le fichier est accessible
                    if (-not (Test-Path -Path $file.FullName -ErrorAction SilentlyContinue)) {
                        Write-Warning "Fichier inaccessible, ignoré: $($file.FullName)"
                        continue
                    }

                    # Afficher la progression pour les extensions avec beaucoup de fichiers
                    $processedCount++
                    if ($fileCount -gt 100 -and $processedCount % 100 -eq 0) {
                        Write-Verbose "Traitement des fichiers $pattern - $processedCount / $fileCount"
                    }

                    # Obtenir le nombre de lignes
                    $lineCount = (Get-Content -Path $file.FullName -ErrorAction SilentlyContinue).Count

                    $status = if ($lineCount -gt $limit) { "Dépasse" } else { "OK" }
                    $percentage = [math]::Round(($lineCount / $limit) * 100, 1)

                    $results += [PSCustomObject]@{
                        Path            = $file.FullName
                        Extension       = $ext
                        LineCount       = $lineCount
                        Limit           = $limit
                        Status          = $status
                        Percentage      = $percentage
                        SuggestedAction = if ($lineCount -gt $limit) {
                            Get-RefactoringStrategy -Extension $ext -LineCount $lineCount -Limit $limit
                        } else {
                            ""
                        }
                    }
                } catch {
                    Write-Warning "Erreur lors du traitement du fichier $($file.FullName) - $_"
                }
            }
        } catch {
            Write-Warning "Erreur lors de la recherche des fichiers $pattern - $_"
        }
    }

    return $results
}

# Fonction pour suggérer une stratégie de refactorisation
function Get-RefactoringStrategy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Extension,

        [Parameter(Mandatory = $true)]
        [int]$LineCount,

        [Parameter(Mandatory = $true)]
        [int]$Limit
    )

    $excess = $LineCount - $Limit
    $excessPercentage = [math]::Round(($excess / $Limit) * 100, 0)

    $strategy = switch ($Extension) {
        "ps1" {
            if ($excessPercentage -lt 20) {
                "Extraire les fonctions auxiliaires dans un module séparé"
            } elseif ($excessPercentage -lt 50) {
                "Diviser en scripts thématiques distincts"
            } else {
                "Refactoriser en module complet avec structure Public/Private"
            }
        }
        "psm1" {
            "Diviser en fichiers .ps1 individuels dans les dossiers Public/Private"
        }
        "py" {
            if ($excessPercentage -lt 20) {
                "Extraire les fonctions utilitaires dans un module séparé"
            } elseif ($excessPercentage -lt 50) {
                "Diviser en classes/modules thématiques"
            } else {
                "Refactoriser en package avec sous-modules"
            }
        }
        "js" {
            if ($excessPercentage -lt 20) {
                "Extraire les fonctions utilitaires"
            } elseif ($excessPercentage -lt 50) {
                "Diviser en modules thématiques"
            } else {
                "Refactoriser en architecture de composants"
            }
        }
        "ts" {
            if ($excessPercentage -lt 20) {
                "Extraire les interfaces et types dans des fichiers séparés"
            } elseif ($excessPercentage -lt 50) {
                "Diviser en modules thématiques"
            } else {
                "Refactoriser en architecture de composants"
            }
        }
        default {
            "Diviser en fichiers plus petits et plus spécifiques"
        }
    }

    return $strategy
}

# Fonction pour générer le rapport
function New-FileLengthReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Results,

        [Parameter(Mandatory = $true)]
        [string]$ReportPath,

        [Parameter(Mandatory = $false)]
        [string]$BasePath = ""
    )

    $reportDir = Split-Path -Path $ReportPath -Parent
    if (-not (Test-Path $reportDir)) {
        New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
    }

    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $totalFiles = $Results.Count
    $exceedingFiles = ($Results | Where-Object { $_.Status -eq "Dépasse" }).Count
    $exceedingPercentage = if ($totalFiles -gt 0) { [math]::Round(($exceedingFiles / $totalFiles) * 100, 1) } else { 0 }

    # Normaliser les chemins si un chemin de base est fourni
    if ($BasePath -ne "") {
        $Results = $Results | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "RelativePath" -Value ($_.Path.Replace($BasePath, '').TrimStart('\/')) -Force
            $_
        }
    } else {
        $Results = $Results | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "RelativePath" -Value $_.Path -Force
            $_
        }
    }

    $report = @"
# Rapport d'analyse de longueur des fichiers
*Généré le $date*

## Résumé

- **Fichiers analysés**: $totalFiles
- **Fichiers dépassant les limites**: $exceedingFiles ($exceedingPercentage%)

## Fichiers dépassant les limites

| Fichier | Extension | Lignes | Limite | % | Action suggérée |
|---------|-----------|--------|--------|---|----------------|
"@

    $exceeding = $Results | Where-Object { $_.Status -eq "Dépasse" } | Sort-Object -Property Percentage -Descending

    foreach ($file in $exceeding) {
        $report += "`n| $($file.RelativePath) | $($file.Extension) | $($file.LineCount) | $($file.Limit) | $($file.Percentage)% | $($file.SuggestedAction) |"
    }

    $report += @"

## Statistiques par type de fichier

| Extension | Fichiers analysés | Fichiers dépassant | % dépassant | Moyenne de lignes |
|-----------|-------------------|-------------------|------------|------------------|
"@

    $extensions = $Results | Select-Object -ExpandProperty Extension -Unique

    foreach ($ext in $extensions) {
        $extFiles = $Results | Where-Object { $_.Extension -eq $ext }
        $extTotal = $extFiles.Count
        $extExceeding = ($extFiles | Where-Object { $_.Status -eq "Dépasse" }).Count
        $extExceedingPercentage = if ($extTotal -gt 0) { [math]::Round(($extExceeding / $extTotal) * 100, 1) } else { 0 }
        $extAverage = if ($extTotal -gt 0) { [math]::Round(($extFiles | Measure-Object -Property LineCount -Average).Average, 1) } else { 0 }

        $report += "`n| $ext | $extTotal | $extExceeding | $extExceedingPercentage% | $extAverage |"
    }

    $report += @"

## Recommandations

1. **Fichiers prioritaires à refactoriser**:
"@

    $priority = $exceeding | Sort-Object -Property Percentage -Descending | Select-Object -First 5

    foreach ($file in $priority) {
        $report += "`n   - $($file.RelativePath) ($($file.LineCount) lignes, $($file.Percentage)% de la limite)"
    }

    $report += @"

2. **Stratégies générales**:
   - Appliquer le principe de responsabilité unique (SRP)
   - Extraire les fonctionnalités communes dans des modules utilitaires
   - Utiliser des patterns de conception pour réduire la duplication
   - Suivre les recommandations du guide [Gestion-Longueur-Fichiers.md](../../docs/guides/standards/Gestion-Longueur-Fichiers.md)

## Conclusion

Ce rapport identifie les fichiers qui dépassent les limites de longueur recommandées. La refactorisation de ces fichiers améliorera la maintenabilité, la lisibilité et les performances du code.
"@

    Set-Content -Path $ReportPath -Value $report

    Write-Host "Rapport généré: $ReportPath" -ForegroundColor Green
}

# Fonction principale
function Start-FileLengthAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$ReportPath,

        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    Write-Host "Analyse de la longueur des fichiers dans $Path..." -ForegroundColor Cyan

    $limits = Get-FileLengthLimits -ConfigPath $ConfigPath
    $results = Measure-FileLengths -Path $Path -Limits $limits

    Write-Host "Génération du rapport..." -ForegroundColor Cyan
    New-FileLengthReport -Results $results -ReportPath $ReportPath -BasePath $Path

    $exceedingFiles = ($results | Where-Object { $_.Status -eq "Dépasse" }).Count
    $totalFiles = $results.Count

    Write-Host "Analyse terminée: $exceedingFiles fichiers sur $totalFiles dépassent les limites recommandées." -ForegroundColor Yellow

    return $results
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-FileLengthLimits, Measure-FileLengths, Get-RefactoringStrategy, New-FileLengthReport, Start-FileLengthAnalysis
