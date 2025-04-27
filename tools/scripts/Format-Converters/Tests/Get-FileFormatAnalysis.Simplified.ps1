#Requires -Version 5.1
<#
.SYNOPSIS
    Tests simplifiÃ©s pour la fonction Get-FileFormatAnalysis.

.DESCRIPTION
    Ce script contient des tests simplifiÃ©s pour la fonction Get-FileFormatAnalysis.
    Il utilise des fichiers de test crÃ©Ã©s localement pour tester les fonctionnalitÃ©s de base.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2023-04-11
#>

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"
Import-Module -Name $modulePath -Force

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$global:testTempDir = Join-Path -Path $env:TEMP -ChildPath "FormatConvertersTests_$(Get-Random)"
New-Item -Path $global:testTempDir -ItemType Directory -Force | Out-Null
Write-Host "RÃ©pertoire temporaire crÃ©Ã© : $global:testTempDir"

# CrÃ©er des fichiers de test
$global:jsonFilePath = Join-Path -Path $global:testTempDir -ChildPath "test.json"
$global:jsonContent = '{"name":"Test","version":"1.0.0"}'
$global:jsonContent | Set-Content -Path $global:jsonFilePath -Encoding UTF8
Write-Host "Fichier JSON crÃ©Ã© : $global:jsonFilePath"

$global:xmlFilePath = Join-Path -Path $global:testTempDir -ChildPath "test.xml"
$global:xmlContent = '<root><name>Test</name></root>'
$global:xmlContent | Set-Content -Path $global:xmlFilePath -Encoding UTF8
Write-Host "Fichier XML crÃ©Ã© : $global:xmlFilePath"

$global:htmlFilePath = Join-Path -Path $global:testTempDir -ChildPath "test.html"
$global:htmlContent = '<html><body>Test</body></html>'
$global:htmlContent | Set-Content -Path $global:htmlFilePath -Encoding UTF8
Write-Host "Fichier HTML crÃ©Ã© : $global:htmlFilePath"

$global:csvFilePath = Join-Path -Path $global:testTempDir -ChildPath "test.csv"
$global:csvContent = 'Name,Value
Test,1'
$global:csvContent | Set-Content -Path $global:csvFilePath -Encoding UTF8
Write-Host "Fichier CSV crÃ©Ã© : $global:csvFilePath"

$global:textFilePath = Join-Path -Path $global:testTempDir -ChildPath "test.txt"
$global:textContent = 'This is a test file.'
$global:textContent | Set-Content -Path $global:textFilePath -Encoding UTF8
Write-Host "Fichier texte crÃ©Ã© : $global:textFilePath"

# VÃ©rifier que les fichiers existent
Write-Host "VÃ©rification des fichiers crÃ©Ã©s :"
Write-Host "JSON : $global:jsonFilePath - $(Test-Path -Path $global:jsonFilePath)"
Write-Host "XML : $global:xmlFilePath - $(Test-Path -Path $global:xmlFilePath)"
Write-Host "HTML : $global:htmlFilePath - $(Test-Path -Path $global:htmlFilePath)"
Write-Host "CSV : $global:csvFilePath - $(Test-Path -Path $global:csvFilePath)"
Write-Host "Texte : $global:textFilePath - $(Test-Path -Path $global:textFilePath)"

# Tests pour Get-FileFormatAnalysis
Describe "Fonction Get-FileFormatAnalysis (SimplifiÃ©e)" {
    Context "Analyse de fichiers avec format dÃ©tectÃ©" {
        It "Analyse correctement un fichier JSON" {
            Write-Host "DÃ©but du test JSON"
            Write-Host "jsonFilePath = $jsonFilePath"
            Write-Host "Existe = $(Test-Path -Path $jsonFilePath)"

            try {
                $result = Get-FileFormatAnalysis -FilePath $jsonFilePath -Format "json"
                Write-Host "RÃ©sultat = $result"
                $result | Should -Not -BeNullOrEmpty
                $result.FilePath | Should -Be $jsonFilePath
                $result.Format | Should -Be "JSON"
            }
            catch {
                Write-Host "Erreur : $_"
                throw
            }
        }

        It "Analyse correctement un fichier XML" {
            $result = Get-FileFormatAnalysis -FilePath $xmlFilePath -Format "xml"
            $result | Should -Not -BeNullOrEmpty
            $result.FilePath | Should -Be $xmlFilePath
            $result.Format | Should -Be "XML"
        }

        It "Analyse correctement un fichier HTML" {
            $result = Get-FileFormatAnalysis -FilePath $htmlFilePath -Format "html"
            $result | Should -Not -BeNullOrEmpty
            $result.FilePath | Should -Be $htmlFilePath
            $result.Format | Should -Be "HTML"
        }

        It "Analyse correctement un fichier CSV" {
            $result = Get-FileFormatAnalysis -FilePath $csvFilePath -Format "csv"
            $result | Should -Not -BeNullOrEmpty
            $result.FilePath | Should -Be $csvFilePath
            $result.Format | Should -Be "CSV"
        }
    }

    Context "Analyse de fichiers avec dÃ©tection automatique" {
        It "DÃ©tecte et analyse correctement un fichier JSON" {
            $result = Get-FileFormatAnalysis -FilePath $jsonFilePath -AutoDetect
            $result | Should -Not -BeNullOrEmpty
            $result.FilePath | Should -Be $jsonFilePath
            $result.Format | Should -Be "JSON"
        }

        It "DÃ©tecte et analyse correctement un fichier XML" {
            $result = Get-FileFormatAnalysis -FilePath $xmlFilePath -AutoDetect
            $result | Should -Not -BeNullOrEmpty
            $result.FilePath | Should -Be $xmlFilePath
            $result.Format | Should -Be "XML"
        }
    }

    Context "Analyse avec inclusion du contenu" {
        It "Inclut le contenu du fichier lorsque demandÃ©" {
            $result = Get-FileFormatAnalysis -FilePath $global:jsonFilePath -Format "json" -IncludeContent
            $result | Should -Not -BeNullOrEmpty
            $result.Content | Should -Not -BeNullOrEmpty
            # VÃ©rifier simplement que le contenu n'est pas vide
            $result.Content.Length | Should -BeGreaterThan 0
        }
    }

    Context "Gestion des erreurs" {
        It "GÃ©nÃ¨re une erreur si le fichier n'existe pas" {
            $nonExistentFile = Join-Path -Path $testTempDir -ChildPath "non-existent.json"
            { Get-FileFormatAnalysis -FilePath $nonExistentFile -Format "json" } | Should -Throw
        }

        It "GÃ©nÃ¨re une erreur si le format n'est pas pris en charge" {
            { Get-FileFormatAnalysis -FilePath $jsonFilePath -Format "unsupported" } | Should -Throw
        }
    }
}

# Nettoyer les fichiers de test
AfterAll {
    if (Test-Path -Path $global:testTempDir) {
        Remove-Item -Path $global:testTempDir -Recurse -Force
        Write-Host "RÃ©pertoire temporaire supprimÃ© : $global:testTempDir"
    }
}
