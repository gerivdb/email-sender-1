#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le module PowerShellDocumentationValidator.
.DESCRIPTION
    Ce script teste les fonctionnalités du module PowerShellDocumentationValidator
    en validant différents scénarios de documentation PowerShell.
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

# Créer un dossier temporaire pour les tests
$tempDir = Join-Path -Path $PSScriptRoot -ChildPath 'temp'
if (-not (Test-Path -Path $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    Write-Verbose "Dossier temporaire créé : $tempDir"
}

# Fonction pour créer un fichier de test
function New-TestFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $filePath = Join-Path -Path $tempDir -ChildPath $Name
    $Content | Out-File -FilePath $filePath -Encoding utf8
    return $filePath
}

# Fonction pour exécuter un test
function Test-Scenario {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [string[]]$Rules = @("HeaderRules", "FunctionRules", "ParameterRules", "ExampleRules"),

        [Parameter(Mandatory = $false)]
        [int]$ExpectedIssueCount = 0,

        [Parameter(Mandatory = $false)]
        [string[]]$ExpectedRules = @()
    )

    Write-Host "Test du scénario : $Name" -ForegroundColor Cyan

    # Créer le fichier de test
    $filePath = New-TestFile -Name "$Name.ps1" -Content $Content

    # Exécuter le validateur
    $results = Test-PowerShellDocumentation -Path $filePath -Rules $Rules

    # Vérifier les résultats
    $issueCount = if ($null -eq $results) { 0 } else { $results.Count }

    if ($issueCount -eq $ExpectedIssueCount) {
        Write-Host "  Nombre d'erreurs correct : $issueCount" -ForegroundColor Green
    } else {
        Write-Host "  Nombre d'erreurs incorrect. Attendu : $ExpectedIssueCount, Obtenu : $issueCount" -ForegroundColor Red
    }

    # Vérifier les règles spécifiques
    foreach ($rule in $ExpectedRules) {
        $ruleFound = $results | Where-Object { $_.Rule -eq $rule }

        if ($ruleFound) {
            Write-Host "  Règle trouvée : $rule" -ForegroundColor Green
        } else {
            Write-Host "  Règle non trouvée : $rule" -ForegroundColor Red
        }
    }

    return $results
}

# Test 1: Fichier sans documentation
$test1Content = @'
function Test-Function {
    param (
        [string]$Parameter1,
        [int]$Parameter2
    )

    Write-Output "Test"
}
'@

$test1Results = Test-Scenario -Name "FichierSansDocumentation" -Content $test1Content -ExpectedIssueCount 2 -ExpectedRules @("RequireDocumentation")

# Test 2: Fichier avec documentation minimale
$test2Content = @'
<#
.SYNOPSIS
    Fonction de test.
.DESCRIPTION
    Cette fonction est utilisée pour tester le validateur de documentation.
#>
function Test-Function {
    param (
        [string]$Parameter1,
        [int]$Parameter2
    )

    Write-Output "Test"
}
'@

$test2Results = Test-Scenario -Name "FichierAvecDocumentationMinimale" -Content $test2Content -ExpectedIssueCount 6 -ExpectedRules @("RequireParameterDocumentation")

# Test 3: Fichier avec documentation complète
$test3Content = @'
<#
.SYNOPSIS
    Module de test pour le validateur de documentation.
.DESCRIPTION
    Ce module contient des fonctions de test pour valider le fonctionnement
    du validateur de documentation PowerShell.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-05-15
#>

<#
.SYNOPSIS
    Fonction de test avec documentation complète.
.DESCRIPTION
    Cette fonction est utilisée pour tester le validateur de documentation
    avec une documentation complète incluant tous les éléments requis.
.PARAMETER Parameter1
    Premier paramètre de type string. Ce paramètre est obligatoire.
.PARAMETER Parameter2
    Deuxième paramètre de type int. Ce paramètre est facultatif et a une valeur par défaut de 0.
.EXAMPLE
    Test-Function -Parameter1 "Test" -Parameter2 42
    Exécute la fonction avec les paramètres spécifiés.
.EXAMPLE
    Test-Function -Parameter1 "Test"
    Exécute la fonction avec seulement le premier paramètre.
.OUTPUTS
    System.String
.NOTES
    Cette fonction est un exemple de documentation complète.
#>
function Test-Function {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Parameter1,

        [Parameter(Mandatory = $false)]
        [int]$Parameter2 = 0
    )

    Write-Output "Test: $Parameter1, $Parameter2"
}
'@

$test3Results = Test-Scenario -Name "FichierAvecDocumentationComplete" -Content $test3Content -ExpectedIssueCount 7

# Test 4: Fonction avec exemples manquants
$test4Content = @'
<#
.SYNOPSIS
    Fonction de test sans exemples.
.DESCRIPTION
    Cette fonction est utilisée pour tester le validateur de documentation
    lorsque les exemples sont manquants.
.PARAMETER Parameter1
    Premier paramètre de type string.
.PARAMETER Parameter2
    Deuxième paramètre de type int.
#>
function Test-Function {
    param (
        [string]$Parameter1,
        [int]$Parameter2
    )

    Write-Output "Test"
}
'@

$test4Results = Test-Scenario -Name "FonctionSansExemples" -Content $test4Content -ExpectedIssueCount 6 -ExpectedRules @("RequireExample")

# Test 5: Fonction avec description trop courte
$test5Content = @'
<#
.SYNOPSIS
    Court.
.DESCRIPTION
    Trop court.
.PARAMETER Parameter1
    Premier paramètre.
.PARAMETER Parameter2
    Deuxième paramètre.
.EXAMPLE
    Test-Function -Parameter1 "Test" -Parameter2 42
#>
function Test-Function {
    param (
        [string]$Parameter1,
        [int]$Parameter2
    )

    Write-Output "Test"
}
'@

$test5Results = Test-Scenario -Name "FonctionAvecDescriptionCourte" -Content $test5Content -ExpectedIssueCount 8 -ExpectedRules @("MinSynopsisLength", "MinDescriptionLength")

# Test 6: Génération de rapport
$test6Results = $test1Results + $test2Results + $test4Results + $test5Results
$reportPath = Join-Path -Path $tempDir -ChildPath "DocumentationReport.html"
New-PowerShellDocumentationReport -Results $test6Results -Format HTML -OutputPath $reportPath

if (Test-Path -Path $reportPath) {
    Write-Host "Rapport HTML généré avec succès : $reportPath" -ForegroundColor Green
} else {
    Write-Host "Échec de la génération du rapport HTML" -ForegroundColor Red
}

# Nettoyer les fichiers temporaires
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
    Write-Verbose "Dossier temporaire supprimé : $tempDir"
}

Write-Host "`nTests terminés." -ForegroundColor Yellow
