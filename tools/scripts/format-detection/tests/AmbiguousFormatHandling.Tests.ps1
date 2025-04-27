#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le systÃ¨me de gestion des cas ambigus de dÃ©tection de format.

.DESCRIPTION
    Ce script contient des tests unitaires pour vÃ©rifier le bon fonctionnement du systÃ¨me
    de gestion des cas ambigus de dÃ©tection de format. Il utilise le framework Pester
    pour exÃ©cuter les tests.

.EXAMPLE
    Invoke-Pester -Path .\AmbiguousFormatHandling.Tests.ps1
    ExÃ©cute les tests unitaires pour le systÃ¨me de gestion des cas ambigus.

.NOTES
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    catch {
        Write-Error "Impossible d'installer le module Pester : $_"
        exit 1
    }
}

# Chemins des scripts Ã  tester
$scriptRoot = Split-Path -Parent $PSScriptRoot
$handleAmbiguousScript = "$scriptRoot\analysis\Handle-AmbiguousFormats.ps1"
$showResultsScript = "$scriptRoot\analysis\Show-FormatDetectionResults.ps1"
$integrationScript = "$scriptRoot\Detect-FileFormatWithConfirmation.ps1"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "FormatDetectionTests_$(Get-Random)"
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# Fonction pour crÃ©er des fichiers de test
function New-FormatTestFile {
    param (
        [string]$FileName,
        [string]$Content,
        [string]$Directory = $testTempDir
    )

    $filePath = Join-Path -Path $Directory -ChildPath $FileName
    $Content | Set-Content -Path $filePath -Encoding UTF8
    return $filePath
}

# CrÃ©er des fichiers de test ambigus
$jsonJsContent = @"
{
    "name": "Test",
    "version": "1.0.0",
    "description": "This is a test file",
    "main": "index.js",
    "scripts": {
        "test": "echo \"Error: no test specified\" && exit 1"
    },
    "keywords": [
        "test",
        "example"
    ],
    "author": "Augment Agent",
    "license": "MIT"
}
"@

$xmlHtmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<html>
    <head>
        <title>Test Page</title>
    </head>
    <body>
        <h1>Hello World</h1>
        <p>This is a test file that could be XML or HTML.</p>
    </body>
</html>
"@

$csvTextContent = @"
Name,Age,Email
John Doe,30,john.doe@example.com
Jane Smith,25,jane.smith@example.com
Bob Johnson,40,bob.johnson@example.com
"@

# CrÃ©er les fichiers de test
$jsonJsPath = New-FormatTestFile -FileName "package.txt" -Content $jsonJsContent
# Ces fichiers sont crÃ©Ã©s pour des tests futurs mais ne sont pas utilisÃ©s dans les tests actuels
New-FormatTestFile -FileName "page.txt" -Content $xmlHtmlContent
New-FormatTestFile -FileName "data.txt" -Content $csvTextContent

# CrÃ©er un fichier de choix utilisateur pour les tests
$userChoicesContent = @"
{
    ".txt|JSON:80|JAVASCRIPT:70": "JSON",
    ".txt|XML:75|HTML:70": "XML",
    ".txt|CSV:80|TEXT:75": "CSV"
}
"@

$userChoicesPath = New-FormatTestFile -FileName "UserFormatChoices.json" -Content $userChoicesContent

# Tests Pester
Describe "SystÃ¨me de gestion des cas ambigus de dÃ©tection de format" {
    Context "Script Handle-AmbiguousFormats.ps1" {
        It "Existe et est exÃ©cutable" {
            Test-Path -Path $handleAmbiguousScript -PathType Leaf | Should -Be $true
        }

        It "DÃ©tecte correctement un format non ambigu" {
            # CrÃ©er un fichier JSON clairement identifiable
            $clearJsonContent = @"
{
    "test": true,
    "value": 123
}
"@
            $clearJsonPath = New-FormatTestFile -FileName "clear.json" -Content $clearJsonContent

            $result = & $handleAmbiguousScript -FilePath $clearJsonPath -AutoResolve

            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"
            $result.ConfidenceScore | Should -BeGreaterThan 90
        }

        It "Identifie correctement un cas ambigu" {
            # Utiliser le fichier JSON/JS ambigu
            $result = & $handleAmbiguousScript -FilePath $jsonJsPath -AutoResolve

            $result | Should -Not -BeNullOrEmpty

            # VÃ©rifier que les deux meilleurs scores sont proches
            $topFormats = $result.AllFormats | Sort-Object -Property Score, Priority -Descending | Select-Object -First 2
            $scoreDifference = $topFormats[0].Score - $topFormats[1].Score

            $scoreDifference | Should -BeLessThan 30
        }

        It "RÃ©sout automatiquement un cas ambigu" {
            $result = & $handleAmbiguousScript -FilePath $jsonJsPath -AutoResolve

            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -BeIn @("JSON", "JAVASCRIPT")
        }

        It "Utilise les choix mÃ©morisÃ©s" {
            # Copier le fichier de choix utilisateur dans le rÃ©pertoire du script
            Copy-Item -Path $userChoicesPath -Destination "$scriptRoot\analysis\UserFormatChoices.json" -Force

            $result = & $handleAmbiguousScript -FilePath $jsonJsPath -RememberChoices

            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"
        }
    }

    Context "Script Show-FormatDetectionResults.ps1" {
        It "Existe et est exÃ©cutable" {
            Test-Path -Path $showResultsScript -PathType Leaf | Should -Be $true
        }

        It "Affiche correctement les rÃ©sultats" {
            # CrÃ©er un fichier JSON clairement identifiable
            $clearJsonContent = @"
{
    "test": true,
    "value": 123
}
"@
            $clearJsonPath = New-FormatTestFile -FileName "clear.json" -Content $clearJsonContent

            $result = & $handleAmbiguousScript -FilePath $clearJsonPath -AutoResolve

            # Rediriger la sortie pour la vÃ©rifier
            $output = & $showResultsScript -FilePath $clearJsonPath -DetectionResult $result | Out-String

            $output | Should -Not -BeNullOrEmpty
            $output | Should -Match "Format dÃ©tectÃ©: JSON"
        }

        It "Exporte correctement les rÃ©sultats au format JSON" {
            # CrÃ©er un fichier JSON clairement identifiable
            $clearJsonContent = @"
{
    "test": true,
    "value": 123
}
"@
            $clearJsonPath = New-FormatTestFile -FileName "clear.json" -Content $clearJsonContent

            $result = & $handleAmbiguousScript -FilePath $clearJsonPath -AutoResolve

            $outputPath = Join-Path -Path $testTempDir -ChildPath "results.json"
            & $showResultsScript -FilePath $clearJsonPath -DetectionResult $result -ExportFormat "JSON" -OutputPath $outputPath

            Test-Path -Path $outputPath -PathType Leaf | Should -Be $true

            $exportedContent = Get-Content -Path $outputPath -Raw
            $exportedContent | Should -Not -BeNullOrEmpty
            $exportedContent | Should -Match "JSON"
        }
    }

    Context "Script d'intÃ©gration Detect-FileFormatWithConfirmation.ps1" {
        It "Existe et est exÃ©cutable" {
            Test-Path -Path $integrationScript -PathType Leaf | Should -Be $true
        }

        It "DÃ©tecte correctement un format non ambigu" {
            # CrÃ©er un fichier JSON clairement identifiable
            $clearJsonContent = @"
{
    "test": true,
    "value": 123
}
"@
            $clearJsonPath = New-TestFile -FileName "clear.json" -Content $clearJsonContent

            $result = & $integrationScript -FilePath $clearJsonPath -AutoResolve

            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"
            $result.ConfidenceScore | Should -BeGreaterThan 90
        }

        It "RÃ©sout automatiquement un cas ambigu" {
            $result = & $integrationScript -FilePath $jsonJsPath -AutoResolve

            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -BeIn @("JSON", "JAVASCRIPT")
        }
    }
}

# Nettoyer aprÃ¨s les tests
AfterAll {
    # Supprimer le rÃ©pertoire temporaire
    if (Test-Path -Path $testTempDir) {
        Remove-Item -Path $testTempDir -Recurse -Force
    }

    # Supprimer le fichier de choix utilisateur
    if (Test-Path -Path "$scriptRoot\analysis\UserFormatChoices.json") {
        Remove-Item -Path "$scriptRoot\analysis\UserFormatChoices.json" -Force
    }
}
