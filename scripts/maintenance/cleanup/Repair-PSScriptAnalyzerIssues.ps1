#Requires -Version 5.1
<#
.SYNOPSIS
    Corrige automatiquement les problèmes courants détectés par PSScriptAnalyzer.
.DESCRIPTION
    Ce script analyse et corrige automatiquement plusieurs problèmes courants détectés par PSScriptAnalyzer,
    comme les comparaisons incorrectes avec $null, les verbes non approuvés, les variables non utilisées,
    et les valeurs par défaut des paramètres de type switch.
.PARAMETER ScriptPath
    Chemin du script à analyser et corriger. Accepte les wildcards.
.PARAMETER Fix
    Si spécifié, applique les corrections automatiquement. Sinon, affiche seulement les problèmes.
.PARAMETER CreateBackup
    Si spécifié, crée une sauvegarde des fichiers avant de les modifier.
.EXAMPLE
    .\Repair-PSScriptAnalyzerIssues.ps1 -ScriptPath .\MonScript.ps1
    Analyse le script spécifié et affiche les problèmes potentiels.
.EXAMPLE
    .\Repair-PSScriptAnalyzerIssues.ps1 -ScriptPath .\scripts\*.ps1 -Fix -CreateBackup
    Analyse tous les scripts dans le dossier, crée des sauvegardes et corrige les problèmes.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Date: 12/04/2025
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string[]]$ScriptPath,

    [Parameter(Mandatory = $false)]
    [switch]$Fix,

    [Parameter(Mandatory = $false)]
    [switch]$CreateBackup
)

# Vérifier si PSScriptAnalyzer est installé
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Warning "PSScriptAnalyzer n'est pas installé. Installation en cours..."
    Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
}

# Importer PSScriptAnalyzer
Import-Module PSScriptAnalyzer

# Fonction pour analyser un script
function Test-ScriptIssues {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le fichier n'existe pas: $Path"
        return $null
    }

    try {
        # Analyser le script avec PSScriptAnalyzer
        $results = Invoke-ScriptAnalyzer -Path $Path -Severity Warning, Error, Information

        # Analyser le script avec l'AST pour des vérifications supplémentaires
        $scriptContent = Get-Content -Path $Path -Raw
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$tokens, [ref]$errors)

        # Retourner les résultats
        return @{
            PSScriptAnalyzerResults = $results
            Ast                     = $ast
            Tokens                  = $tokens
            ParseErrors             = $errors
            Content                 = $scriptContent
        }
    } catch {
        Write-Error "Erreur lors de l'analyse du script $Path : $_"
        return $null
    }
}

# Fonction pour corriger les comparaisons avec $null
function Repair-NullComparison {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    # Rechercher les comparaisons incorrectes avec $null
    $pattern = '(\$\w+)\s+-(?:eq|ne)\s+\$null'
    $correctedContent = $Content -replace $pattern, '$null -$2 $1'

    return $correctedContent
}

# Fonction pour corriger les verbes non approuvés
function Repair-UnapprovedVerbs {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    # Dictionnaire des verbes non approuvés et leurs remplacements
    $verbMappings = @{
        'Analyze'  = 'Test'
        'Fix'      = 'Repair'
        'Create'   = 'New'
        'Delete'   = 'Remove'
        'Generate' = 'New'
        'Verify'   = 'Test'
        'Deny'     = 'Block'
        'Backup'   = 'Save'
        'Restore'  = 'Import'
        'Update'   = 'Set'
    }

    $correctedContent = $Content

    # Rechercher les définitions de fonctions avec des verbes non approuvés
    foreach ($verb in $verbMappings.Keys) {
        $pattern = "function\s+($verb)-(\w+)"
        $replacement = "function $($verbMappings[$verb])-`$2"
        $correctedContent = $correctedContent -replace $pattern, $replacement
    }

    return $correctedContent
}

# Fonction pour corriger les valeurs par défaut des paramètres de type switch
function Repair-SwitchDefaultValue {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    # Rechercher les paramètres switch avec une valeur par défaut
    $pattern = '\[switch\]\$(\w+)\s*=\s*\$true'
    $replacement = '[switch]$1'
    $correctedContent = $Content -replace $pattern, $replacement

    return $correctedContent
}

# Fonction pour corriger les variables non utilisées
function Repair-UnusedVariables {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Token[]]$Tokens
    )

    # Collecter toutes les assignations de variables
    $assignments = @{}

    foreach ($token in $Tokens) {
        if ($token.Kind -eq 'Variable' -and $token.Next -and $token.Next.Kind -eq 'Operator' -and $token.Next.Text -eq '=') {
            $varName = $token.Text
            if (-not $assignments.ContainsKey($varName)) {
                $assignments[$varName] = @{
                    Name            = $varName
                    AssignmentCount = 0
                    UsageCount      = 0
                    Line            = $token.Extent.StartLineNumber
                    Column          = $token.Extent.StartColumnNumber
                    Extent          = $token.Extent
                }
            }
            $assignments[$varName].AssignmentCount++
        }
    }

    # Collecter toutes les utilisations de variables
    $Ast.FindAll({ $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true) | ForEach-Object {
        $varName = $_.VariablePath.UserPath
        if ($assignments.ContainsKey($varName)) {
            # Vérifier si c'est une utilisation et non une assignation
            $isAssignment = $false
            $parent = $_.Parent
            while ($null -ne $parent) {
                if ($parent -is [System.Management.Automation.Language.AssignmentStatementAst] -and
                    $parent.Left.Extent.Text -eq $_.Extent.Text) {
                    $isAssignment = $true
                    break
                }
                $parent = $parent.Parent
            }

            if (-not $isAssignment) {
                $assignments[$varName].UsageCount++
            }
        }
    }

    # Trouver les variables assignées mais non utilisées
    $unusedVars = @()
    foreach ($var in $assignments.Values) {
        if ($var.AssignmentCount -gt 0 -and $var.UsageCount -eq 0 -and
            $var.Name -ne '_' -and $var.Name -ne 'null' -and $var.Name -ne 'true' -and $var.Name -ne 'false' -and
            $var.Name -ne 'matches') {
            $unusedVars += $var
        }
    }

    # Corriger les variables non utilisées
    $lines = $Content -split "`r`n|\r|\n"
    $modified = $false

    foreach ($var in $unusedVars) {
        $lineIndex = $var.Line - 1
        $line = $lines[$lineIndex]

        # Trouver l'assignation de variable
        if ($line -match "(\s*)(\$[$var.Name])\s*=\s*(.+?)(\s*#.*)?\s*$") {
            $indent = $matches[1]
            $varName = $matches[2]
            $expression = $matches[3]
            $comment = $matches[4]

            # Remplacer par une expression qui utilise Out-Null
            if ($expression -match "\|\s*ForEach-Object") {
                $newLine = "$indent$expression | Out-Null$comment"
            } else {
                $newLine = "$indent$expression | Out-Null$comment"
            }

            $lines[$lineIndex] = $newLine
            $modified = $true
        }
    }

    if ($modified) {
        return $lines -join "`r`n"
    }

    return $Content
}

# Fonction pour corriger les assignations aux variables automatiques
function Repair-AutomaticVariableAssignment {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    # Liste des variables automatiques courantes
    $automaticVars = @('matches', 'PSItem', '_', 'args', 'input', 'PSBoundParameters', 'MyInvocation', 'PSScriptRoot', 'PSCommandPath')

    $correctedContent = $Content

    foreach ($var in $automaticVars) {
        # Remplacer les assignations directes
        $pattern = "(\s*)(\$\$var)\s*=\s*(.+?)(\s*#.*)?\s*$"
        $replacement = "`$1`$custom_$var = `$3`$4"
        $correctedContent = $correctedContent -replace $pattern, $replacement

        # Remplacer les utilisations
        $pattern = "(\s*)(\$\$var)(\W)"
        $replacement = "`$1`$custom_$var`$3"
        $correctedContent = $correctedContent -replace $pattern, $replacement
    }

    return $correctedContent
}

# Fonction principale pour corriger les problèmes PSScriptAnalyzer
function Repair-PSScriptAnalyzerIssues {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [switch]$Fix,

        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup
    )

    # Résoudre les chemins avec wildcards
    $resolvedPaths = @()
    foreach ($path in $ScriptPath) {
        if ($path -match '\*') {
            $resolvedPaths += Get-ChildItem -Path $path -Filter "*.ps1" | Select-Object -ExpandProperty FullName
        } else {
            $resolvedPaths += $path
        }
    }

    $results = @()

    # Analyser et corriger chaque script
    foreach ($path in $resolvedPaths) {
        Write-Host "Analyse du script: $path" -ForegroundColor Cyan
        $analysisResults = Test-ScriptIssues -Path $path

        if ($null -eq $analysisResults) {
            Write-Warning "Impossible d'analyser le script: $path"
            continue
        }

        $scriptContent = $analysisResults.Content
        $modified = $false

        # Vérifier et corriger les problèmes
        $psaResults = $analysisResults.PSScriptAnalyzerResults

        # Afficher les problèmes détectés
        if ($psaResults.Count -gt 0) {
            Write-Host "Problèmes détectés dans $path :" -ForegroundColor Yellow
            $psaResults | ForEach-Object {
                $color = switch ($_.Severity) {
                    "Error" { "Red" }
                    "Warning" { "Yellow" }
                    "Information" { "White" }
                    default { "Gray" }
                }

                Write-Host "[$($_.Severity)] Ligne $($_.Line):$($_.Column) - $($_.Message)" -ForegroundColor $color
            }

            # Corriger les problèmes si demandé
            if ($Fix) {
                # Créer une sauvegarde si demandé
                if ($CreateBackup) {
                    $backupPath = "$path.bak"
                    Write-Host "Création d'une sauvegarde: $backupPath" -ForegroundColor Cyan
                    Copy-Item -Path $path -Destination $backupPath -Force
                }

                # Corriger les comparaisons avec $null
                $nullComparisonIssues = $psaResults | Where-Object { $_.RuleName -eq "PSPossibleIncorrectComparisonWithNull" }
                if ($nullComparisonIssues.Count -gt 0) {
                    Write-Host "Correction des comparaisons avec `$null..." -ForegroundColor Green
                    $scriptContent = Repair-NullComparison -Content $scriptContent
                    $modified = $true
                }

                # Corriger les verbes non approuvés
                $unapprovedVerbIssues = $psaResults | Where-Object { $_.RuleName -eq "PSUseApprovedVerbs" }
                if ($unapprovedVerbIssues.Count -gt 0) {
                    Write-Host "Correction des verbes non approuvés..." -ForegroundColor Green
                    $scriptContent = Repair-UnapprovedVerbs -Content $scriptContent
                    $modified = $true
                }

                # Corriger les valeurs par défaut des paramètres de type switch
                $switchDefaultIssues = $psaResults | Where-Object { $_.RuleName -eq "PSAvoidDefaultValueSwitchParameter" }
                if ($switchDefaultIssues.Count -gt 0) {
                    Write-Host "Correction des valeurs par défaut des paramètres de type switch..." -ForegroundColor Green
                    $scriptContent = Repair-SwitchDefaultValue -Content $scriptContent
                    $modified = $true
                }

                # Corriger les assignations aux variables automatiques
                $automaticVarIssues = $psaResults | Where-Object { $_.RuleName -eq "PSAvoidAssignmentToAutomaticVariable" }
                if ($automaticVarIssues.Count -gt 0) {
                    Write-Host "Correction des assignations aux variables automatiques..." -ForegroundColor Green
                    $scriptContent = Repair-AutomaticVariableAssignment -Content $scriptContent
                    $modified = $true
                }

                # Corriger les variables non utilisées
                $unusedVarIssues = $psaResults | Where-Object { $_.RuleName -eq "PSUseDeclaredVarsMoreThanAssignments" }
                if ($unusedVarIssues.Count -gt 0) {
                    Write-Host "Correction des variables non utilisées..." -ForegroundColor Green
                    $scriptContent = Repair-UnusedVariables -Content $scriptContent -Ast $analysisResults.Ast -Tokens $analysisResults.Tokens
                    $modified = $true
                }

                # Enregistrer les modifications
                if ($modified) {
                    Write-Host "Enregistrement des modifications dans $path" -ForegroundColor Green
                    Set-Content -Path $path -Value $scriptContent -Encoding UTF8

                    # Analyser à nouveau pour vérifier les corrections
                    $newAnalysisResults = Test-ScriptIssues -Path $path
                    $newPsaResults = $newAnalysisResults.PSScriptAnalyzerResults

                    $results += [PSCustomObject]@{
                        Path                = $path
                        OriginalIssueCount  = $psaResults.Count
                        RemainingIssueCount = $newPsaResults.Count
                        Fixed               = $modified
                    }
                } else {
                    Write-Host "Aucune modification nécessaire pour $path" -ForegroundColor Green

                    $results += [PSCustomObject]@{
                        Path                = $path
                        OriginalIssueCount  = $psaResults.Count
                        RemainingIssueCount = $psaResults.Count
                        Fixed               = $false
                    }
                }
            } else {
                $results += [PSCustomObject]@{
                    Path                = $path
                    OriginalIssueCount  = $psaResults.Count
                    RemainingIssueCount = $psaResults.Count
                    Fixed               = $false
                }
            }
        } else {
            Write-Host "Aucun problème détecté dans $path" -ForegroundColor Green

            $results += [PSCustomObject]@{
                Path                = $path
                OriginalIssueCount  = 0
                RemainingIssueCount = 0
                Fixed               = $false
            }
        }
    }

    # Afficher un résumé
    Write-Host "`nRésumé:" -ForegroundColor Cyan
    Write-Host "  Scripts analysés: $($resolvedPaths.Count)" -ForegroundColor White
    Write-Host "  Scripts avec problèmes: $($results | Where-Object { $_.OriginalIssueCount -gt 0 } | Measure-Object).Count" -ForegroundColor White
    Write-Host "  Problèmes détectés: $($results | Measure-Object -Property OriginalIssueCount -Sum).Sum" -ForegroundColor White

    if ($Fix) {
        Write-Host "  Scripts corrigés: $($results | Where-Object { $_.Fixed } | Measure-Object).Count" -ForegroundColor Green
        Write-Host "  Problèmes restants: $($results | Measure-Object -Property RemainingIssueCount -Sum).Sum" -ForegroundColor Yellow
    }

    return $results
}

# Exécuter le script
Repair-PSScriptAnalyzerIssues -ScriptPath $ScriptPath -Fix:$Fix -CreateBackup:$CreateBackup
