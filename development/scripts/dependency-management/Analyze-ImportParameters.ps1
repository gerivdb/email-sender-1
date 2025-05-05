#Requires -Version 5.1
<#
.SYNOPSIS
    Analyse les paramÃ¨tres d'importation dans un script PowerShell.

.DESCRIPTION
    Ce script analyse un fichier PowerShell pour dÃ©tecter les instructions Import-Module
    et analyser en dÃ©tail les paramÃ¨tres utilisÃ©s dans ces instructions.

.PARAMETER FilePath
    Chemin du fichier PowerShell Ã  analyser.

.PARAMETER OutputFormat
    Format de sortie des rÃ©sultats (Text, JSON, CSV).

.EXAMPLE
    .\Analyze-ImportParameters.ps1 -FilePath "C:\Scripts\MyScript.ps1"

.EXAMPLE
    .\Analyze-ImportParameters.ps1 -FilePath "C:\Scripts\MyScript.ps1" -OutputFormat JSON

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-12-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Text", "JSON", "CSV")]
    [string]$OutputFormat = "Text"
)

# Importer les modules nÃ©cessaires
$moduleDependencyDetectorPath = Join-Path -Path $PSScriptRoot -ChildPath "ModuleDependencyDetector.psm1"
$importParameterAnalyzerPath = Join-Path -Path $PSScriptRoot -ChildPath "ImportParameterAnalyzer.psm1"

Import-Module $moduleDependencyDetectorPath -Force
Import-Module $importParameterAnalyzerPath -Force

# VÃ©rifier que le fichier existe
if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
    Write-Error "Le fichier spÃ©cifiÃ© n'existe pas : $FilePath"
    exit 1
}

# Analyser le fichier pour dÃ©tecter les instructions Import-Module
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

    # Analyser les paramÃ¨tres de chaque instruction Import-Module
    $results = @()
    foreach ($call in $importModuleCalls) {
        $parameterTypes = Get-ImportParameterTypes -CommandAst $call
        $namedParameters = Get-NamedParameters -CommandAst $call
        
        # Extraire les valeurs des paramÃ¨tres principaux
        $moduleName = Get-ParameterValue -CommandAst $call -ParameterName "Name"
        $modulePath = Get-ParameterValue -CommandAst $call -ParameterName "Path"
        
        # DÃ©terminer le nom du module (soit par le paramÃ¨tre Name, soit par le chemin)
        if (-not $moduleName -and $modulePath) {
            $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($modulePath)
        }
        
        # CrÃ©er l'objet rÃ©sultat
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

    # Afficher les rÃ©sultats selon le format demandÃ©
    switch ($OutputFormat) {
        "JSON" {
            $results | ConvertTo-Json -Depth 5
        }
        "CSV" {
            $results | ConvertTo-Csv -NoTypeInformation
        }
        default {
            # Format texte par dÃ©faut
            Write-Host "Analyse des paramÃ¨tres d'importation dans $FilePath :" -ForegroundColor Cyan

            if ($results.Count -eq 0) {
                Write-Host "  Aucune instruction d'importation de module dÃ©tectÃ©e." -ForegroundColor Yellow
            } else {
                Write-Host "  Nombre d'instructions Import-Module trouvÃ©es : $($results.Count)" -ForegroundColor Yellow

                foreach ($result in $results) {
                    Write-Host "`n  Module : $($result.ModuleName)" -ForegroundColor Green
                    Write-Host "    Ligne : $($result.LineNumber), Colonne : $($result.ColumnNumber)" -ForegroundColor Gray
                    Write-Host "    Commande : $($result.RawCommand)" -ForegroundColor Gray

                    if ($result.ModulePath) {
                        Write-Host "    Chemin : $($result.ModulePath)" -ForegroundColor Gray
                    }

                    Write-Host "    ParamÃ¨tres nommÃ©s : $($result.NamedParameters)" -ForegroundColor Gray
                    Write-Host "    ParamÃ¨tres positionnels : $($result.PositionalParameters)" -ForegroundColor Gray
                    Write-Host "    ParamÃ¨tres switch : $($result.SwitchParameters)" -ForegroundColor Gray
                    Write-Host "    A paramÃ¨tre Name : $($result.HasNameParameter)" -ForegroundColor Gray
                    Write-Host "    A paramÃ¨tre Path : $($result.HasPathParameter)" -ForegroundColor Gray
                    Write-Host "    A paramÃ¨tre Version : $($result.HasVersionParameter)" -ForegroundColor Gray
                    Write-Host "    A caractÃ¨res spÃ©ciaux : $($result.HasSpecialCharacters)" -ForegroundColor Gray
                    Write-Host "    ParamÃ¨tres requis : $($result.RequiredParameters)" -ForegroundColor Gray
                    Write-Host "    ParamÃ¨tres optionnels : $($result.OptionalParameters)" -ForegroundColor Gray
                }
            }
        }
    }
} catch {
    Write-Error "Erreur lors de l'analyse du fichier : $_"
    exit 1
}
