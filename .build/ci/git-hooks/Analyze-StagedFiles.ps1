<#
.SYNOPSIS
    Analyse les fichiers PowerShell modifiés pour détecter les erreurs potentielles.
.DESCRIPTION
    Ce script analyse les fichiers PowerShell modifiés (staged) pour détecter les erreurs potentielles
    avant de les committer. Il utilise le module ErrorPatternAnalyzer pour l'analyse.
.NOTES
    Auteur: Augment Code
    Date: 14/04/2025
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter()]
    [switch]$IgnoreWarnings,

    [Parameter()]
    [switch]$IgnoreErrors,

    [Parameter()]
    [string]$ConfigPath = (Join-Path -Path (git rev-parse --show-toplevel) -ChildPath "git-hooks\config\pre-commit-config.json"),

    [Parameter()]
    [switch]$Verbose
)

# Importer le module d'analyse des patterns d'erreurs
$modulePath = Join-Path -Path (git rev-parse --show-toplevel) -ChildPath "scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module ErrorPatternAnalyzer non trouvé: $modulePath"
    exit 1
}

# Charger la configuration
$config = @{
    IgnorePatterns = @()
    SeverityLevel  = "Warning"
    MaxErrors      = 10
    ExcludePaths   = @(
        "node_modules",
        "vendor",
        "dist",
        "out"
    )
}

if (Test-Path -Path $ConfigPath) {
    try {
        $configJson = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

        if ($configJson.IgnorePatterns) {
            $config.IgnorePatterns = $configJson.IgnorePatterns
        }

        if ($configJson.SeverityLevel) {
            $config.SeverityLevel = $configJson.SeverityLevel
        }

        if ($configJson.MaxErrors) {
            $config.MaxErrors = $configJson.MaxErrors
        }

        if ($configJson.ExcludePaths) {
            $config.ExcludePaths = $configJson.ExcludePaths
        }
    } catch {
        Write-Warning "Erreur lors du chargement de la configuration: $_"
        Write-Warning "Utilisation de la configuration par défaut."
    }
}

# Fonction pour vérifier si un chemin doit être exclu
function Test-ExcludePath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    foreach ($excludePath in $config.ExcludePaths) {
        if ($Path -like "*$excludePath*") {
            return $true
        }
    }

    return $false
}

# Obtenir la liste des fichiers PowerShell modifiés (staged)
$stagedFiles = git diff --cached --name-only --diff-filter=ACM | Where-Object { $_ -like "*.ps1" -or $_ -like "*.psm1" }

if (-not $stagedFiles) {
    Write-Host "Aucun fichier PowerShell modifié à analyser."
    exit 0
}

# Filtrer les fichiers exclus
$filesToAnalyze = $stagedFiles | Where-Object { -not (Test-ExcludePath -Path $_) }

if (-not $filesToAnalyze) {
    Write-Host "Aucun fichier PowerShell à analyser après filtrage."
    exit 0
}

Write-Host "Analyse des fichiers PowerShell modifiés..." -ForegroundColor Cyan

$errorCount = 0
$warningCount = 0
$errorList = @()

# Analyser chaque fichier
foreach ($file in $filesToAnalyze) {
    $filePath = Join-Path -Path (git rev-parse --show-toplevel) -ChildPath $file

    if (-not (Test-Path -Path $filePath)) {
        Write-Warning "Fichier non trouvé: $filePath"
        continue
    }

    Write-Host "Analyse de $file..." -ForegroundColor Yellow

    # Obtenir le contenu du fichier
    $content = Get-Content -Path $filePath -Raw

    # Analyser le fichier pour détecter les erreurs potentielles
    $patterns = Get-ErrorPatterns -ScriptContent $content

    if (-not $patterns) {
        Write-Host "  Aucun pattern d'erreur détecté." -ForegroundColor Green
        continue
    }

    # Filtrer les patterns ignorés
    $filteredPatterns = $patterns | Where-Object {
        $pattern = $_
        -not ($config.IgnorePatterns | Where-Object { $pattern.Id -like $_ })
    }

    if (-not $filteredPatterns) {
        Write-Host "  Aucun pattern d'erreur après filtrage." -ForegroundColor Green
        continue
    }

    # Afficher les erreurs et avertissements
    foreach ($pattern in $filteredPatterns) {
        $severity = $pattern.Severity
        $message = $pattern.Message
        $lineNumber = $pattern.LineNumber
        $id = $pattern.Id

        $errorInfo = [PSCustomObject]@{
            File       = $file
            LineNumber = $lineNumber
            Severity   = $severity
            Message    = $message
            Id         = $id
        }

        $errorList += $errorInfo

        if ($severity -eq "Error") {
            if (-not $IgnoreErrors) {
                Write-Host "  [ERROR] Ligne $lineNumber : $message [$id]" -ForegroundColor Red
                $errorCount++
            }
        } elseif ($severity -eq "Warning") {
            if (-not $IgnoreWarnings) {
                Write-Host "  [WARNING] Ligne $lineNumber : $message [$id]" -ForegroundColor Yellow
                $warningCount++
            }
        }
    }
}

# Générer un rapport
$reportPath = Join-Path -Path (git rev-parse --show-toplevel) -ChildPath "git-hooks\reports\pre-commit-report.md"
$reportDir = Split-Path -Path $reportPath -Parent

if (-not (Test-Path -Path $reportDir)) {
    New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
}

$report = @"
# Rapport d'analyse pre-commit

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Résumé

- Fichiers analysés: $($filesToAnalyze.Count)
- Erreurs détectées: $errorCount
- Avertissements détectés: $warningCount

## Détails

| Fichier | Ligne | Sévérité | Message | ID |
|---------|-------|----------|---------|-----|
"@

foreach ($errorItem in $errorList) {
    $report += "`n| $($errorItem.File) | $($errorItem.LineNumber) | $($errorItem.Severity) | $($errorItem.Message) | $($errorItem.Id) |"
}

$report | Out-File -FilePath $reportPath -Encoding utf8

Write-Host "`nRapport généré: $reportPath" -ForegroundColor Cyan

# Déterminer si le commit doit être bloqué
$blockCommit = $false

if ($errorCount -gt 0 -and -not $IgnoreErrors) {
    if ($errorCount -ge $config.MaxErrors) {
        Write-Host "`nTrop d'erreurs détectées ($errorCount). Commit bloqué." -ForegroundColor Red
        $blockCommit = $true
    } else {
        Write-Host "`nErreurs détectées ($errorCount). Veuillez les corriger avant de committer." -ForegroundColor Red
        $blockCommit = $true
    }
}

if ($blockCommit) {
    exit 1
} else {
    Write-Host "`nAnalyse terminée. Commit autorisé." -ForegroundColor Green
    exit 0
}
