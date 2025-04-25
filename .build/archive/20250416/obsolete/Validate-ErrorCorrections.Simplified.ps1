<#
.SYNOPSIS
    Version simplifiée du script pour valider les corrections d'erreurs PowerShell.
.DESCRIPTION
    Ce script valide les corrections appliquées aux scripts PowerShell
    en vérifiant la syntaxe et les bonnes pratiques.
.PARAMETER ScriptPath
    Chemin du script à valider.
.EXAMPLE
    .\Validate-ErrorCorrections.Simplified.ps1 -ScriptPath "C:\Scripts\MonScript.ps1"
    Valide les corrections appliquées au script spécifié.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath
)

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorLearningSystem.psm1"
Import-Module $modulePath -Force

# Initialiser le système
Initialize-ErrorLearningSystem

# Vérifier si le script existe
if (-not (Test-Path -Path $ScriptPath)) {
    Write-Error "Le script spécifié n'existe pas : $ScriptPath"
    exit 1
}

# Fonction pour valider la syntaxe d'un script
function Test-ScriptSyntax {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    Write-Host "Validation de la syntaxe du script : $ScriptPath"

    # Vérifier la syntaxe du script
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$errors)

    if ($errors -and $errors.Count -gt 0) {
        Write-Host "Erreurs de syntaxe détectées :" -ForegroundColor Red

        foreach ($error in $errors) {
            Write-Host "  Ligne $($error.Extent.StartLineNumber), colonne $($error.Extent.StartColumnNumber) : $($error.Message)" -ForegroundColor Red
        }

        return $false
    }
    else {
        Write-Host "La syntaxe du script est valide." -ForegroundColor Green
        return $true
    }
}

# Fonction pour valider les bonnes pratiques d'un script
function Test-ScriptBestPractices {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    Write-Host "Validation des bonnes pratiques du script : $ScriptPath"

    # Lire le contenu du script
    $scriptContent = Get-Content -Path $ScriptPath -Raw

    # Définir les patterns de bonnes pratiques
    $bestPracticesPatterns = @(
        @{
            Name = "HardcodedPath"
            Pattern = '(?<!\\)["''](?:[A-Z]:\\|\\\\)[^"'']*["'']'
            Description = "Chemin codé en dur détecté"
        },
        @{
            Name = "NoErrorHandling"
            Pattern = '(?<!try\s*\{\s*)(?:Get-Content|Set-Content)(?!\s*-ErrorAction\s+Stop)'
            Description = "Absence de gestion d'erreurs détecté"
        },
        @{
            Name = "WriteHostUsage"
            Pattern = 'Write-Host'
            Description = "Utilisation de Write-Host détecté"
        },
        @{
            Name = "ObsoleteCmdlet"
            Pattern = '(Get-WmiObject|Invoke-Expression)'
            Description = "Utilisation de cmdlets obsolètes détecté"
        }
    )

    # Vérifier les bonnes pratiques
    $issues = @()

    foreach ($pattern in $bestPracticesPatterns) {
        $matches = [regex]::Matches($scriptContent, $pattern.Pattern)

        foreach ($match in $matches) {
            # Trouver le numéro de ligne
            $lineNumber = ($scriptContent.Substring(0, $match.Index).Split("`n")).Length

            # Extraire la ligne complète
            $lines = $scriptContent.Split("`n")
            $line = $lines[$lineNumber - 1].Trim()

            # Créer un objet pour l'erreur détectée
            $issue = [PSCustomObject]@{
                Name = $pattern.Name
                Description = $pattern.Description
                LineNumber = $lineNumber
                Line = $line
                Match = $match.Value
            }

            $issues += $issue
        }
    }

    # Afficher les résultats
    if ($issues.Count -gt 0) {
        Write-Host "Problèmes de bonnes pratiques détectés :" -ForegroundColor Yellow

        foreach ($issue in $issues) {
            Write-Host "  [$($issue.Name)] Ligne $($issue.LineNumber) : $($issue.Description)" -ForegroundColor Yellow
            Write-Host "    $($issue.Line)" -ForegroundColor Yellow
        }

        return $false
    }
    else {
        Write-Host "Le script respecte les bonnes pratiques." -ForegroundColor Green
        return $true
    }
}

# Valider la syntaxe du script
$syntaxValid = Test-ScriptSyntax -ScriptPath $ScriptPath

# Valider les bonnes pratiques du script
$bestPracticesValid = Test-ScriptBestPractices -ScriptPath $ScriptPath

# Afficher le résultat global
if ($syntaxValid -and $bestPracticesValid) {
    Write-Host "`nLe script est valide et respecte les bonnes pratiques." -ForegroundColor Green
}
else {
    Write-Host "`nLe script présente des problèmes." -ForegroundColor Yellow

    if (-not $syntaxValid) {
        Write-Host "  - Erreurs de syntaxe détectées." -ForegroundColor Red
    }

    if (-not $bestPracticesValid) {
        Write-Host "  - Problèmes de bonnes pratiques détectés." -ForegroundColor Yellow
    }
}

Write-Host "`nValidation terminée."
