#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le système de gestion des cas ambigus de détection de format.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement du système
    de gestion des cas ambigus de détection de format. Il utilise le framework Pester
    pour exécuter les tests.

.EXAMPLE
    Invoke-Pester -Path .\AmbiguousFormatHandling.Tests.ps1
    Exécute les tests unitaires pour le système de gestion des cas ambigus.

.NOTES
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    catch {
        Write-Error "Impossible d'installer le module Pester : $_"
        exit 1
    }
}

# Chemins des scripts à tester
$scriptRoot = Split-Path -Parent $PSScriptRoot
$handleAmbiguousScript = "$scriptRoot\analysis\Handle-AmbiguousFormats.ps1"
$showResultsScript = "$scriptRoot\analysis\Show-FormatDetectionResults.ps1"
$integrationScript = "$scriptRoot\Detect-FileFormatWithConfirmation.ps1"

# Créer un répertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "FormatDetectionTests_$(Get-Random)"
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# Fonction pour créer des fichiers de test
function New-TestFile {
    param (
        [string]$FileName,
        [string]$Content,
        [string]$Directory = $testTempDir
    )
    
    $filePath = Join-Path -Path $Directory -ChildPath $FileName
    $Content | Set-Content -Path $filePath -Encoding UTF8
    return $filePath
}

# Créer des fichiers de test ambigus
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

# Créer les fichiers de test
$jsonJsPath = New-TestFile -FileName "package.txt" -Content $jsonJsContent
$xmlHtmlPath = New-TestFile -FileName "page.txt" -Content $xmlHtmlContent
$csvTextPath = New-TestFile -FileName "data.txt" -Content $csvTextContent

# Créer un fichier de choix utilisateur pour les tests
$userChoicesContent = @"
{
    ".txt|JSON:80|JAVASCRIPT:70": "JSON",
    ".txt|XML:75|HTML:70": "XML",
    ".txt|CSV:80|TEXT:75": "CSV"
}
"@

$userChoicesPath = New-TestFile -FileName "UserFormatChoices.json" -Content $userChoicesContent

# Tests Pester
Describe "Système de gestion des cas ambigus de détection de format" {
    Context "Script Handle-AmbiguousFormats.ps1" {
        It "Existe et est exécutable" {
            Test-Path -Path $handleAmbiguousScript -PathType Leaf | Should -Be $true
        }
        
        It "Détecte correctement un format non ambigu" {
            # Créer un fichier JSON clairement identifiable
            $clearJsonContent = @"
{
    "test": true,
    "value": 123
}
"@
            $clearJsonPath = New-TestFile -FileName "clear.json" -Content $clearJsonContent
            
            $result = & $handleAmbiguousScript -FilePath $clearJsonPath -AutoResolve
            
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"
            $result.ConfidenceScore | Should -BeGreaterThan 90
        }
        
        It "Identifie correctement un cas ambigu" {
            # Utiliser le fichier JSON/JS ambigu
            $result = & $handleAmbiguousScript -FilePath $jsonJsPath -AutoResolve
            
            $result | Should -Not -BeNullOrEmpty
            
            # Vérifier que les deux meilleurs scores sont proches
            $topFormats = $result.AllFormats | Sort-Object -Property Score, Priority -Descending | Select-Object -First 2
            $scoreDifference = $topFormats[0].Score - $topFormats[1].Score
            
            $scoreDifference | Should -BeLessThan 30
        }
        
        It "Résout automatiquement un cas ambigu" {
            $result = & $handleAmbiguousScript -FilePath $jsonJsPath -AutoResolve
            
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -BeIn @("JSON", "JAVASCRIPT")
        }
        
        It "Utilise les choix mémorisés" {
            # Copier le fichier de choix utilisateur dans le répertoire du script
            Copy-Item -Path $userChoicesPath -Destination "$scriptRoot\analysis\UserFormatChoices.json" -Force
            
            $result = & $handleAmbiguousScript -FilePath $jsonJsPath -RememberChoices
            
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"
        }
    }
    
    Context "Script Show-FormatDetectionResults.ps1" {
        It "Existe et est exécutable" {
            Test-Path -Path $showResultsScript -PathType Leaf | Should -Be $true
        }
        
        It "Affiche correctement les résultats" {
            # Créer un fichier JSON clairement identifiable
            $clearJsonContent = @"
{
    "test": true,
    "value": 123
}
"@
            $clearJsonPath = New-TestFile -FileName "clear.json" -Content $clearJsonContent
            
            $result = & $handleAmbiguousScript -FilePath $clearJsonPath -AutoResolve
            
            # Rediriger la sortie pour la vérifier
            $output = & $showResultsScript -FilePath $clearJsonPath -DetectionResult $result | Out-String
            
            $output | Should -Not -BeNullOrEmpty
            $output | Should -Match "Format détecté: JSON"
        }
        
        It "Exporte correctement les résultats au format JSON" {
            # Créer un fichier JSON clairement identifiable
            $clearJsonContent = @"
{
    "test": true,
    "value": 123
}
"@
            $clearJsonPath = New-TestFile -FileName "clear.json" -Content $clearJsonContent
            
            $result = & $handleAmbiguousScript -FilePath $clearJsonPath -AutoResolve
            
            $outputPath = Join-Path -Path $testTempDir -ChildPath "results.json"
            & $showResultsScript -FilePath $clearJsonPath -DetectionResult $result -ExportFormat "JSON" -OutputPath $outputPath
            
            Test-Path -Path $outputPath -PathType Leaf | Should -Be $true
            
            $exportedContent = Get-Content -Path $outputPath -Raw
            $exportedContent | Should -Not -BeNullOrEmpty
            $exportedContent | Should -Match "JSON"
        }
    }
    
    Context "Script d'intégration Detect-FileFormatWithConfirmation.ps1" {
        It "Existe et est exécutable" {
            Test-Path -Path $integrationScript -PathType Leaf | Should -Be $true
        }
        
        It "Détecte correctement un format non ambigu" {
            # Créer un fichier JSON clairement identifiable
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
        
        It "Résout automatiquement un cas ambigu" {
            $result = & $integrationScript -FilePath $jsonJsPath -AutoResolve
            
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -BeIn @("JSON", "JAVASCRIPT")
        }
    }
}

# Nettoyer après les tests
AfterAll {
    # Supprimer le répertoire temporaire
    if (Test-Path -Path $testTempDir) {
        Remove-Item -Path $testTempDir -Recurse -Force
    }
    
    # Supprimer le fichier de choix utilisateur
    if (Test-Path -Path "$scriptRoot\analysis\UserFormatChoices.json") {
        Remove-Item -Path "$scriptRoot\analysis\UserFormatChoices.json" -Force
    }
}
