#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour la fonction D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\Format-Converters\Tests\Test-DetectedFileFormat.Tests.

.DESCRIPTION
    Ce fichier contient des tests pour la fonction D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\Format-Converters\Tests\Test-DetectedFileFormat.Tests.
    Il a Ã©tÃ© gÃ©nÃ©rÃ© automatiquement Ã  partir du fichier de test simplifiÃ© D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\Format-Converters\Tests\Test-DetectedFileFormat.Tests.Simplified.ps1.

.NOTES
    Date de gÃ©nÃ©ration : 2025-04-11 16:01:12
    Auteur : Augment Agent
#>

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module -Name $modulePath -Force
    Write-Host "Module Format-Converters importÃ© depuis : $modulePath"
}
else {
    Write-Error "Le module Format-Converters n'existe pas Ã  l'emplacement : $modulePath"
    exit 1
}

BeforeAll {
    # S'assurer que le module est importÃ©
    if (-not (Get-Module -Name Format-Converters)) {
        $modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"
        if (Test-Path -Path $modulePath) {
            Import-Module -Name $modulePath -Force
            Write-Host "Module Format-Converters importÃ© dans BeforeAll depuis : $modulePath"
        }
        else {
            Write-Error "Le module Format-Converters n'existe pas Ã  l'emplacement : $modulePath"
            exit 1
        }
    }

    # CrÃ©er un rÃ©pertoire temporaire pour les tests
    $testTempDir = Join-Path -Path $env:TEMP -ChildPath "FormatConvertersTests_$(Get-Random)"
    New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire temporaire crÃ©Ã© : $testTempDir"

    # CrÃ©er des fichiers de test
    $jsonFilePath = Join-Path -Path $testTempDir -ChildPath "test.json"
    $jsonContent = '{"name":"Test","version":"1.0.0"}'
    $jsonContent | Set-Content -Path $jsonFilePath -Encoding UTF8
    Write-Host "Fichier JSON crÃ©Ã© : $jsonFilePath"

    $xmlFilePath = Join-Path -Path $testTempDir -ChildPath "test.xml"
    $xmlContent = '<root><name>Test</name></root>'
    $xmlContent | Set-Content -Path $xmlFilePath -Encoding UTF8
    Write-Host "Fichier XML crÃ©Ã© : $xmlFilePath"

    $htmlFilePath = Join-Path -Path $testTempDir -ChildPath "test.html"
    $htmlContent = '<html><body>Test</body></html>'
    $htmlContent | Set-Content -Path $htmlFilePath -Encoding UTF8
    Write-Host "Fichier HTML crÃ©Ã© : $htmlFilePath"

    $csvFilePath = Join-Path -Path $testTempDir -ChildPath "test.csv"
    $csvContent = 'Name,Value
Test,1'
    $csvContent | Set-Content -Path $csvFilePath -Encoding UTF8
    Write-Host "Fichier CSV crÃ©Ã© : $csvFilePath"

    $textFilePath = Join-Path -Path $testTempDir -ChildPath "test.txt"
    $textContent = 'This is a test file.'
    $textContent | Set-Content -Path $textFilePath -Encoding UTF8
    Write-Host "Fichier texte crÃ©Ã© : $textFilePath"

    # VÃ©rifier que les fichiers existent
    Write-Host "VÃ©rification des fichiers crÃ©Ã©s :"
    Write-Host "JSON : $jsonFilePath - $(Test-Path -Path $jsonFilePath)"
    Write-Host "XML : $xmlFilePath - $(Test-Path -Path $xmlFilePath)"
    Write-Host "HTML : $htmlFilePath - $(Test-Path -Path $htmlFilePath)"
    Write-Host "CSV : $csvFilePath - $(Test-Path -Path $csvFilePath)"
    Write-Host "Texte : $textFilePath - $(Test-Path -Path $textFilePath)"
}

# Tests pour Get-FileFormatAnalysis
Describe "Fonction Get-FileFormatAnalysis" {
    Context "Analyse de fichiers avec format dÃ©tectÃ©" {
        It "Analyse correctement un fichier JSON" {
            Write-Host "DÃ©but du test JSON"
            Write-Host "jsonFilePath = $jsonFilePath"
            Write-Host "Existe = $(Test-Path -Path $jsonFilePath)"

            $result = Get-FileFormatAnalysis -FilePath $jsonFilePath -Format "json"
            Write-Host "RÃ©sultat = $result"

            $result | Should -Not -BeNullOrEmpty
            $result.FilePath | Should -Be $jsonFilePath
            $result.Format | Should -Be "JSON"
            $result.Size | Should -BeGreaterThan 0
            $result.Properties | Should -Not -BeNullOrEmpty
        }

        It "Analyse correctement un fichier XML" {
            $result = Get-FileFormatAnalysis -FilePath $xmlFilePath -Format "xml"
            $result | Should -Not -BeNullOrEmpty
            $result.FilePath | Should -Be $xmlFilePath
            $result.Format | Should -Be "XML"
            $result.Size | Should -BeGreaterThan 0
            $result.Properties | Should -Not -BeNullOrEmpty
        }

        It "Analyse correctement un fichier HTML" {
            $result = Get-FileFormatAnalysis -FilePath $htmlFilePath -Format "html"
            $result | Should -Not -BeNullOrEmpty
            $result.FilePath | Should -Be $htmlFilePath
            $result.Format | Should -Be "HTML"
            $result.Size | Should -BeGreaterThan 0
            $result.Properties | Should -Not -BeNullOrEmpty
        }

        It "Analyse correctement un fichier CSV" {
            $result = Get-FileFormatAnalysis -FilePath $csvFilePath -Format "csv"
            $result | Should -Not -BeNullOrEmpty
            $result.FilePath | Should -Be $csvFilePath
            $result.Format | Should -Be "CSV"
            $result.Size | Should -BeGreaterThan 0
            $result.Properties | Should -Not -BeNullOrEmpty
        }
    }

    Context "Analyse de fichiers avec dÃ©tection automatique" {
        It "DÃ©tecte et analyse correctement un fichier JSON" {
            $result = Get-FileFormatAnalysis -FilePath $jsonFilePath
            $result | Should -Not -BeNullOrEmpty
            $result.FilePath | Should -Be $jsonFilePath
            $result.Format | Should -Be "JSON"
            $result.Size | Should -BeGreaterThan 0
            $result.Properties | Should -Not -BeNullOrEmpty
        }

        It "DÃ©tecte et analyse correctement un fichier XML" {
            $result = Get-FileFormatAnalysis -FilePath $xmlFilePath
            $result | Should -Not -BeNullOrEmpty
            $result.FilePath | Should -Be $xmlFilePath
            $result.Format | Should -Be "XML"
            $result.Size | Should -BeGreaterThan 0
            $result.Properties | Should -Not -BeNullOrEmpty
        }
    }

    Context "Analyse avec inclusion du contenu" {
        It "Inclut le contenu du fichier lorsque demandÃ©" {
            $result = Get-FileFormatAnalysis -FilePath $jsonFilePath -Format "json" -IncludeContent
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
    if (Test-Path -Path $testTempDir) {
        Remove-Item -Path $testTempDir -Recurse -Force
        Write-Host "RÃ©pertoire temporaire supprimÃ© : $testTempDir"
    }
}
