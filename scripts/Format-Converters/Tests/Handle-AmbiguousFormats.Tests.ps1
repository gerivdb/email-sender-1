#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour la fonction Handle-AmbiguousFormats.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement de la fonction
    Handle-AmbiguousFormats du module Format-Converters. Il utilise le framework Pester pour exécuter les tests.

.EXAMPLE
    Invoke-Pester -Path .\Handle-AmbiguousFormats.Tests.ps1
    Exécute les tests unitaires pour la fonction Handle-AmbiguousFormats.

.NOTES
    Version: 1.0
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

# Chemin du module à tester
$moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulePath = Join-Path -Path $moduleRoot -ChildPath "Format-Converters.psm1"
$detectorsPath = Join-Path -Path $moduleRoot -ChildPath "Detectors"
$handleAmbiguousFormatsPath = Join-Path -Path $detectorsPath -ChildPath "Handle-AmbiguousFormats.ps1"

# Créer un répertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "AmbiguousFormatsTests_$(Get-Random)"
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

# Créer des fichiers ambigus pour les tests
$jsonJsAmbiguousContent = @"
{
    "function": "test",
    "code": "function test() { return 'Hello World'; }"
}
"@

$xmlHtmlAmbiguousContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<html>
    <head>
        <title>Test Page</title>
    </head>
    <body>
        <h1>Hello World</h1>
        <p>This is a test page.</p>
    </body>
</html>
"@

$csvTextAmbiguousContent = @"
This is a text file
That could be confused with a CSV
Because it has commas, like this, and this
"@

$jsonJsAmbiguousPath = New-TestFile -FileName "ambiguous_json_js.txt" -Content $jsonJsAmbiguousContent
$xmlHtmlAmbiguousPath = New-TestFile -FileName "ambiguous_xml_html.txt" -Content $xmlHtmlAmbiguousContent
$csvTextAmbiguousPath = New-TestFile -FileName "ambiguous_csv_text.txt" -Content $csvTextAmbiguousContent

# Créer un fichier de choix utilisateur pour les tests
$userChoicesContent = @"
{
    ".txt|JSON:75|JAVASCRIPT:65": "JSON",
    ".txt|XML:80|HTML:70": "XML",
    ".txt|CSV:60|TEXT:55": "CSV"
}
"@

$userChoicesPath = New-TestFile -FileName "UserFormatChoices.json" -Content $userChoicesContent

# Tests Pester
Describe "Fonction Handle-AmbiguousFormats" {
    BeforeAll {
        # Importer le module Format-Converters
        Import-Module $modulePath -Force
        
        # Créer un mock pour la fonction Confirm-FormatDetection
        function global:Confirm-FormatDetection {
            param (
                [array]$Formats
            )
            
            # Retourner le premier format par défaut
            return $Formats[0].Format
        }
    }
    
    Context "Détection de cas ambigus" {
        It "Détecte correctement un cas ambigu entre JSON et JavaScript" {
            $result = Handle-AmbiguousFormats -FilePath $jsonJsAmbiguousPath -ShowDetails
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -BeIn @("JSON", "JAVASCRIPT")
        }
        
        It "Détecte correctement un cas ambigu entre XML et HTML" {
            $result = Handle-AmbiguousFormats -FilePath $xmlHtmlAmbiguousPath -ShowDetails
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -BeIn @("XML", "HTML")
        }
        
        It "Détecte correctement un cas ambigu entre CSV et TEXT" {
            $result = Handle-AmbiguousFormats -FilePath $csvTextAmbiguousPath -ShowDetails
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -BeIn @("CSV", "TEXT")
        }
    }
    
    Context "Résolution automatique des cas ambigus" {
        It "Résout automatiquement un cas ambigu avec l'option -AutoResolve" {
            $result = Handle-AmbiguousFormats -FilePath $jsonJsAmbiguousPath -AutoResolve -ShowDetails
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -BeIn @("JSON", "JAVASCRIPT")
        }
        
        It "Résout automatiquement un cas ambigu en fonction de la priorité" {
            # Créer un mock pour Detect-FileFormat qui retourne un résultat ambigu avec des priorités différentes
            Mock Detect-FileFormat {
                return [PSCustomObject]@{
                    FilePath = $FilePath
                    DetectedFormat = "FORMAT1"
                    ConfidenceScore = 75
                    AllFormats = @(
                        [PSCustomObject]@{
                            Format = "FORMAT1"
                            Score = 75
                            Priority = 5
                            MatchedCriteria = @("Critère 1")
                        },
                        [PSCustomObject]@{
                            Format = "FORMAT2"
                            Score = 70
                            Priority = 10
                            MatchedCriteria = @("Critère 2")
                        }
                    )
                }
            } -ParameterFilter { $IncludeAllFormats }
            
            $result = Handle-AmbiguousFormats -FilePath "test.txt" -AutoResolve
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "FORMAT2"
        }
    }
    
    Context "Mémorisation des choix utilisateur" {
        It "Utilise un choix mémorisé pour un cas similaire" {
            # Créer un mock pour Detect-FileFormat qui retourne un résultat ambigu
            Mock Detect-FileFormat {
                return [PSCustomObject]@{
                    FilePath = $FilePath
                    DetectedFormat = "JSON"
                    ConfidenceScore = 75
                    AllFormats = @(
                        [PSCustomObject]@{
                            Format = "JSON"
                            Score = 75
                            Priority = 10
                            MatchedCriteria = @("Critère 1")
                        },
                        [PSCustomObject]@{
                            Format = "JAVASCRIPT"
                            Score = 65
                            Priority = 9
                            MatchedCriteria = @("Critère 2")
                        }
                    )
                }
            } -ParameterFilter { $IncludeAllFormats }
            
            $result = Handle-AmbiguousFormats -FilePath "test.txt" -RememberChoices -UserChoicesPath $userChoicesPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "JSON"
        }
        
        It "Mémorise un nouveau choix utilisateur" {
            # Créer un mock pour Detect-FileFormat qui retourne un résultat ambigu
            Mock Detect-FileFormat {
                return [PSCustomObject]@{
                    FilePath = $FilePath
                    DetectedFormat = "FORMAT1"
                    ConfidenceScore = 75
                    AllFormats = @(
                        [PSCustomObject]@{
                            Format = "FORMAT1"
                            Score = 75
                            Priority = 10
                            MatchedCriteria = @("Critère 1")
                        },
                        [PSCustomObject]@{
                            Format = "FORMAT2"
                            Score = 65
                            Priority = 9
                            MatchedCriteria = @("Critère 2")
                        }
                    )
                }
            } -ParameterFilter { $IncludeAllFormats }
            
            # Créer un nouveau fichier de choix utilisateur temporaire
            $tempUserChoicesPath = New-TestFile -FileName "TempUserFormatChoices.json" -Content "{}"
            
            # Créer un mock pour Confirm-FormatDetection qui retourne un format spécifique
            Mock Confirm-FormatDetection {
                return "FORMAT1"
            }
            
            $result = Handle-AmbiguousFormats -FilePath "new_test.txt" -RememberChoices -UserChoicesPath $tempUserChoicesPath
            $result | Should -Not -BeNullOrEmpty
            $result.DetectedFormat | Should -Be "FORMAT1"
            
            # Vérifier que le choix a été mémorisé
            $userChoices = Get-Content -Path $tempUserChoicesPath -Raw | ConvertFrom-Json
            $userChoices.PSObject.Properties.Count | Should -BeGreaterThan 0
        }
    }
    
    Context "Personnalisation du seuil d'ambiguïté" {
        It "Utilise le seuil d'ambiguïté personnalisé" {
            # Créer un mock pour Detect-FileFormat qui retourne un résultat avec une différence de score de 25
            Mock Detect-FileFormat {
                return [PSCustomObject]@{
                    FilePath = $FilePath
                    DetectedFormat = "FORMAT1"
                    ConfidenceScore = 75
                    AllFormats = @(
                        [PSCustomObject]@{
                            Format = "FORMAT1"
                            Score = 75
                            Priority = 10
                            MatchedCriteria = @("Critère 1")
                        },
                        [PSCustomObject]@{
                            Format = "FORMAT2"
                            Score = 50
                            Priority = 9
                            MatchedCriteria = @("Critère 2")
                        }
                    )
                }
            } -ParameterFilter { $IncludeAllFormats }
            
            # Avec un seuil de 20, ce n'est pas ambigu
            $result1 = Handle-AmbiguousFormats -FilePath "test.txt" -AmbiguityThreshold 20
            $result1.DetectedFormat | Should -Be "FORMAT1"
            
            # Avec un seuil de 30, c'est ambigu
            Mock Confirm-FormatDetection {
                return "FORMAT2"
            }
            
            $result2 = Handle-AmbiguousFormats -FilePath "test.txt" -AmbiguityThreshold 30
            $result2.DetectedFormat | Should -Be "FORMAT2"
        }
    }
    
    Context "Gestion des erreurs" {
        It "Lève une erreur si le fichier n'existe pas" {
            { Handle-AmbiguousFormats -FilePath "fichier_inexistant.txt" } | Should -Throw
        }
    }
}

# Nettoyer après les tests
AfterAll {
    # Supprimer le répertoire temporaire
    if (Test-Path -Path $testTempDir) {
        Remove-Item -Path $testTempDir -Recurse -Force
    }
    
    # Supprimer la fonction globale mock
    Remove-Item -Path function:global:Confirm-FormatDetection -ErrorAction SilentlyContinue
    
    # Décharger le module
    Remove-Module -Name Format-Converters -ErrorAction SilentlyContinue
}
