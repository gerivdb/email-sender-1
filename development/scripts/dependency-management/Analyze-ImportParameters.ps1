#Requires -Version 5.1
<#
.SYNOPSIS
    Analyse les paramètres d'importation dans un script PowerShell.

.DESCRIPTION
    Ce script analyse un fichier PowerShell pour détecter les instructions Import-Module
    et analyser en détail les paramètres utilisés dans ces instructions.

.PARAMETER FilePath
    Chemin du fichier PowerShell à analyser.

.PARAMETER OutputFormat
    Format de sortie des résultats (Text, JSON, CSV).

.EXAMPLE
    .\Analyze-ImportParameters.ps1 -FilePath "C:\Scripts\MyScript.ps1"

.EXAMPLE
    .\Analyze-ImportParameters.ps1 -FilePath "C:\Scripts\MyScript.ps1" -OutputFormat JSON

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-12-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Text", "JSON", "CSV")]
    [string]$OutputFormat = "Text"
)

# Importer les modules nécessaires
$moduleDependencyDetectorPath = Join-Path -Path $PSScriptRoot -ChildPath "ModuleDependencyDetector.psm1"
$importParameterAnalyzerPath = Join-Path -Path $PSScriptRoot -ChildPath "ImportParameterAnalyzer.psm1"

Import-Module $moduleDependencyDetectorPath -Force
Import-Module $importParameterAnalyzerPath -Force

# Vérifier que le fichier existe
if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
    Write-Error "Le fichier spécifié n'existe pas : $FilePath"
    exit 1
}

# Analyser le fichier pour détecter les instructions Import-Module
try {
    # Obtenir le contenu du fichier
    $scriptContent = Get-Content -Path $FilePath -Raw

    # Analyser le script avec l'AST
    $tokens = $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)

    # Trouver toutes les instructions Import-Module
    $importModuleCalls = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.CommandAst] -and
        $node.CommandElements.Count -gt 0 -and
        $node.CommandElements[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
        $node.CommandElements[0].Value -eq 'Import-Module'
    }, $true)

    # Analyser les paramètres de chaque instruction Import-Module
    $results = @()
    foreach ($call in $importModuleCalls) {
        $parameterTypes = Get-ImportParameterTypes -CommandAst $call
        $namedParameters = Get-NamedParameters -CommandAst $call
        
        # Extraire les valeurs des paramètres principaux
        $moduleName = Get-ParameterValue -CommandAst $call -ParameterName "Name"
        $modulePath = Get-ParameterValue -CommandAst $call -ParameterName "Path"
        
        # Déterminer le nom du module (soit par le paramètre Name, soit par le chemin)
        if (-not $moduleName -and $modulePath) {
            $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($modulePath)
        }
        
        # Créer l'objet résultat
        $result = [PSCustomObject]@{
            ModuleName = $moduleName
            ModulePath = $modulePath
            LineNumber = $call.Extent.StartLineNumber
            ColumnNumber = $call.Extent.StartColumnNumber
            RawCommand = $call.Extent.Text
            NamedParameters = $namedParameters.Keys -join ', '
            PositionalParameters = $parameterTypes.PositionalParameters.Count
            SwitchParameters = $parameterTypes.SwitchParameters -join ', '
            HasNameParameter = $parameterTypes.HasNameParameter
            HasPathParameter = $parameterTypes.HasPathParameter
            HasVersionParameter = $parameterTypes.HasVersionParameter
            HasSpecialCharacters = $parameterTypes.HasSpecialCharacters
            RequiredParameters = $parameterTypes.RequiredParameters -join ', '
            OptionalParameters = $parameterTypes.OptionalParameters -join ', '
        }
        
        $results += $result
    }

    # Afficher les résultats selon le format demandé
    switch ($OutputFormat) {
        "JSON" {
            $results | ConvertTo-Json -Depth 5
        }
        "CSV" {
            $results | ConvertTo-Csv -NoTypeInformation
        }
        default {
            # Format texte par défaut
            Write-Host "Analyse des paramètres d'importation dans $FilePath :" -ForegroundColor Cyan

            if ($results.Count -eq 0) {
                Write-Host "  Aucune instruction d'importation de module détectée." -ForegroundColor Yellow
            } else {
                Write-Host "  Nombre d'instructions Import-Module trouvées : $($results.Count)" -ForegroundColor Yellow

                foreach ($result in $results) {
                    Write-Host "`n  Module : $($result.ModuleName)" -ForegroundColor Green
                    Write-Host "    Ligne : $($result.LineNumber), Colonne : $($result.ColumnNumber)" -ForegroundColor Gray
                    Write-Host "    Commande : $($result.RawCommand)" -ForegroundColor Gray

                    if ($result.ModulePath) {
                        Write-Host "    Chemin : $($result.ModulePath)" -ForegroundColor Gray
                    }

                    Write-Host "    Paramètres nommés : $($result.NamedParameters)" -ForegroundColor Gray
                    Write-Host "    Paramètres positionnels : $($result.PositionalParameters)" -ForegroundColor Gray
                    Write-Host "    Paramètres switch : $($result.SwitchParameters)" -ForegroundColor Gray
                    Write-Host "    A paramètre Name : $($result.HasNameParameter)" -ForegroundColor Gray
                    Write-Host "    A paramètre Path : $($result.HasPathParameter)" -ForegroundColor Gray
                    Write-Host "    A paramètre Version : $($result.HasVersionParameter)" -ForegroundColor Gray
                    Write-Host "    A caractères spéciaux : $($result.HasSpecialCharacters)" -ForegroundColor Gray
                    Write-Host "    Paramètres requis : $($result.RequiredParameters)" -ForegroundColor Gray
                    Write-Host "    Paramètres optionnels : $($result.OptionalParameters)" -ForegroundColor Gray
                }
            }
        }
    }
} catch {
    Write-Error "Erreur lors de l'analyse du fichier : $_"
    exit 1
}
