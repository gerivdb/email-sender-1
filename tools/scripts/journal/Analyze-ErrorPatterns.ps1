# Analyze-ErrorPatterns.ps1
# Script pour analyser les erreurs recurrentes et patterns problematiques

# Parametres

# Analyze-ErrorPatterns.ps1
# Script pour analyser les erreurs recurrentes et patterns problematiques

# Parametres
param (
    [Parameter(Mandatory = $false)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
]
    [string]$LogDirectory = "logs",

    [Parameter(Mandatory = $false)]
    [string]$OutputFile = "error_analysis.md",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeScripts
)

# Creer le repertoire de sortie si necessaire
$OutputDir = Split-Path -Parent $OutputFile
if (-not [string]::IsNullOrEmpty($OutputDir) -and -not (Test-Path -Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory | Out-Null
}

# Fonction pour analyser les fichiers de log
function Analyze-LogFiles {
    param (
        [string]$Directory
    )

    if (-not (Test-Path -Path $Directory)) {
        Write-Warning "Le repertoire $Directory n'existe pas."
        return @{}
    }

    $errorPatterns = @{}
    $logFiles = Get-ChildItem -Path $Directory -Filter "*.log" -Recurse

    foreach ($logFile in $logFiles) {
        $content = Get-Content -Path $logFile.FullName -Raw

        # Rechercher les patterns d'erreur courants
        $patterns = @(
            "Exception",
            "Error",
            "Failed",
            "Cannot find",
            "Access denied",
            "is not recognized",
            "Unexpected",
            "Invalid",
            "Timeout",
            "Not found",
            "Encoding",
            "Character",
            "Unicode",
            "UTF",
            "Process",
            "Dependency"
        )

        foreach ($pattern in $patterns) {
            $matches = [regex]::Matches($content, "(?i).*$pattern.*")

            foreach ($match in $matches) {
                $errorLine = $match.Value.Trim()

                # Extraire le type d'erreur
                $errorType = "Autre"

                if ($errorLine -match "Encoding|Character|Unicode|UTF") {
                    $errorType = "Encodage"
                }
                elseif ($errorLine -match "Exception|Error|Failed") {
                    $errorType = "Exception"
                }
                elseif ($errorLine -match "Cannot find|Not found") {
                    $errorType = "Fichier manquant"
                }
                elseif ($errorLine -match "Access denied") {
                    $errorType = "Permission"
                }
                elseif ($errorLine -match "Timeout") {
                    $errorType = "Timeout"
                }
                elseif ($errorLine -match "Process") {
                    $errorType = "Processus"
                }
                elseif ($errorLine -match "Dependency") {
                    $errorType = "Dependance"
                }

                # Ajouter au dictionnaire
                if (-not $errorPatterns.ContainsKey($errorType)) {
                    $errorPatterns[$errorType] = @()
                }

                if (-not $errorPatterns[$errorType].Contains($errorLine)) {
                    $errorPatterns[$errorType] += $errorLine
                }
            }
        }
    }

    return $errorPatterns
}

# Fonction pour analyser les scripts
function Analyze-Scripts {
    param (
        [string]$RootDirectory = "."
    )

    $scriptPatterns = @{
        "Encodage" = @()
        "Gestion d'erreurs" = @()
        "Compatibilite" = @()
        "Processus" = @()
        "Dependances" = @()
    }

    $scriptFiles = Get-ChildItem -Path $RootDirectory -Include "*.ps1", "*.py" -Recurse

    foreach ($scriptFile in $scriptFiles) {
        $content = Get-Content -Path $scriptFile.FullName -Raw

        # Verifier les problemes d'encodage
        if ($content -match "[Ã Ã¡Ã¢Ã£Ã¤Ã¥Ã¦Ã§Ã¨Ã©ÃªÃ«Ã¬Ã­Ã®Ã¯Ã°Ã±Ã²Ã³Ã´ÃµÃ¶Ã¸Ã¹ÃºÃ»Ã¼Ã½Ã¾Ã¿]") {
            $scriptPatterns["Encodage"] += "Caracteres accentues dans $($scriptFile.FullName)"
        }

        # Verifier la gestion d'erreurs
        if (-not ($content -match "try|catch|finally|trap")) {
            $scriptPatterns["Gestion d'erreurs"] += "Absence de gestion d'erreurs dans $($scriptFile.FullName)"
        }

        # Verifier la compatibilite
        if ($content -match "\\\\|C:\\|D:\\") {
            $scriptPatterns["Compatibilite"] += "Chemins absolus Windows dans $($scriptFile.FullName)"
        }

        # Verifier la gestion des processus
        if ($content -match "Start-Process|New-Object System.Diagnostics.Process|exec|subprocess") {
            if (-not ($content -match "WaitForExit|timeout|kill")) {
                $scriptPatterns["Processus"] += "Processus sans timeout/kill dans $($scriptFile.FullName)"
            }
        }

        # Verifier la gestion des dependances
        if ($content -match "Import-Module|require|import") {
            if (-not ($content -match "Test-Path|Get-Module|try|if")) {
                $scriptPatterns["Dependances"] += "Dependances sans verification dans $($scriptFile.FullName)"
            }
        }
    }

    return $scriptPatterns
}

# Analyser les logs
Write-Host "Analyse des fichiers de log..." -ForegroundColor Cyan
$errorPatterns = Analyze-LogFiles -Directory $LogDirectory

# Analyser les scripts si demande
$scriptPatterns = $null
if ($IncludeScripts) {
    Write-Host "Analyse des scripts..." -ForegroundColor Cyan
    $scriptPatterns = Analyze-Scripts
}

# Generer le rapport
Write-Host "Generation du rapport..." -ForegroundColor Cyan

$report = @"
# Analyse des erreurs recurrentes et patterns problematiques

*Genere le $(Get-Date -Format "dd/MM/yyyy HH:mm")*

## Erreurs identifiees dans les logs

"@

foreach ($errorType in $errorPatterns.Keys) {
    $report += "`n### $errorType`n`n"

    foreach ($errorItem in $errorPatterns[$errorType]) {
        $report += "- $errorItem`n"
    }
}

if ($IncludeScripts) {
    $report += @"

## Patterns problematiques dans les scripts

"@

    foreach ($patternType in $scriptPatterns.Keys) {
        $report += "`n### $patternType`n`n"

        foreach ($pattern in $scriptPatterns[$patternType]) {
            $report += "- $pattern`n"
        }
    }
}

$report += @"

## Recommandations

1. **Problemes d'encodage**
   - Standardiser l'encodage UTF-8 avec BOM pour tous les scripts PowerShell
   - Implementer une detection automatique d'encodage avant l'execution

2. **Gestion d'erreurs**
   - Ajouter des blocs try/catch dans tous les scripts
   - Implementer un systeme de journalisation centralise

3. **Compatibilite**
   - Utiliser des chemins relatifs ou des variables d'environnement
   - Implementer une bibliotheque de gestion de chemins cross-platform

4. **Gestion des processus**
   - Ajouter des timeouts systematiques pour tous les processus
   - Implementer un mecanisme de nettoyage des processus orphelins

5. **Gestion des dependances**
   - Verifier l'existence des dependances avant de les utiliser
   - Implementer un systeme de gestion des versions
"@

# Enregistrer le rapport
Set-Content -Path $OutputFile -Value $report

Write-Host "Rapport genere: $OutputFile" -ForegroundColor Green

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
