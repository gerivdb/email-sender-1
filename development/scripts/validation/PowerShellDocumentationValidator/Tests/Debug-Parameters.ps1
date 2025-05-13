#Requires -Version 5.1
<#
.SYNOPSIS
    Débogage de la détection des paramètres.
.DESCRIPTION
    Ce script aide à déboguer la détection des paramètres dans le module PowerShellDocumentationValidator.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

[CmdletBinding()]
param()

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\PowerShellDocumentationValidator.psm1'
Import-Module -Name $modulePath -Force

# Créer un fichier de test avec des paramètres documentés
$tempFile = Join-Path -Path $PSScriptRoot -ChildPath 'ParametersTestFile.ps1'

$fileContent = @'
<#
.SYNOPSIS
    Fonction de test avec paramètres documentés.
.DESCRIPTION
    Cette fonction est utilisée pour tester la détection des paramètres documentés.
.PARAMETER Parameter1
    Premier paramètre de type string.
.PARAMETER Parameter2
    Deuxième paramètre de type int.
#>
function Test-Function {
    [CmdletBinding()]
    param (
        [string]$Parameter1,
        [int]$Parameter2 = 0
    )
    
    Write-Output "Test: $Parameter1, $Parameter2"
}
'@

$fileContent | Out-File -FilePath $tempFile -Encoding utf8

# Analyser le fichier pour déboguer la détection des paramètres
Write-Host "Débogage de la détection des paramètres..." -ForegroundColor Cyan

# Lire le contenu du fichier
$content = Get-Content -Path $tempFile -Raw

# Analyser le contenu du fichier
$ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)

# Récupérer toutes les définitions de fonction
$functionDefinitions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

foreach ($function in $functionDefinitions) {
    $functionName = $function.Name
    $helpContent = $function.GetHelpContent()
    
    Write-Host "Fonction : $functionName" -ForegroundColor Yellow
    
    if ($null -eq $helpContent) {
        Write-Host "  Pas de documentation" -ForegroundColor Red
        continue
    }
    
    Write-Host "  Synopsis : $($helpContent.Synopsis)" -ForegroundColor Green
    Write-Host "  Description : $($helpContent.Description)" -ForegroundColor Green
    
    Write-Host "  Paramètres :" -ForegroundColor Yellow
    foreach ($param in $helpContent.Parameters.Keys) {
        Write-Host "    $param : $($helpContent.Parameters[$param])" -ForegroundColor Green
    }
    
    # Récupérer les paramètres de la fonction
    $parameters = $function.Body.ParamBlock.Parameters
    if ($parameters) {
        Write-Host "  Paramètres de la fonction :" -ForegroundColor Yellow
        foreach ($parameter in $parameters) {
            $parameterName = $parameter.Name.VariablePath.UserPath
            Write-Host "    $parameterName" -ForegroundColor Cyan
            
            # Vérifier si le paramètre est documenté
            if ($helpContent.Parameters.ContainsKey($parameterName)) {
                Write-Host "      Documenté : Oui" -ForegroundColor Green
                Write-Host "      Description : $($helpContent.Parameters[$parameterName])" -ForegroundColor Green
            }
            else {
                Write-Host "      Documenté : Non" -ForegroundColor Red
            }
        }
    }
}

# Nettoyer les fichiers temporaires
if (Test-Path -Path $tempFile) {
    Remove-Item -Path $tempFile -Force
    Write-Verbose "Fichier temporaire supprimé : $tempFile"
}

Write-Host "Débogage terminé." -ForegroundColor Yellow
