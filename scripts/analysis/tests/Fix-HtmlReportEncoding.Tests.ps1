#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Fix-HtmlReportEncoding.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Fix-HtmlReportEncoding.ps1
    qui corrige les problèmes d'encodage dans les rapports HTML.
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas disponible. Installez-le avec 'Install-Module -Name Pester -Force'."
    return
}

# Importer le module d'aide pour les tests
$testHelpersPath = Join-Path -Path $PSScriptRoot -ChildPath "TestHelpers.psm1"
if (Test-Path -Path $testHelpersPath) {
    Import-Module -Name $testHelpersPath -Force
} else {
    throw "Le module TestHelpers.psm1 n'existe pas à l'emplacement: $testHelpersPath"
}

# Chemin du script à tester
$scriptPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "Fix-HtmlReportEncoding.ps1"
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script Fix-HtmlReportEncoding.ps1 n'existe pas à l'emplacement: $scriptPath"
}

Describe "Script Fix-HtmlReportEncoding" {
    BeforeAll {
        # Créer un environnement de test
        $testEnv = New-TestEnvironment -TestName "HtmlReportTests"
        $testDir = $testEnv.TestDirectory
        $testHtmlPath = $testEnv.TestHtmlFile
        $testHtml2Path = $testEnv.TestHtml2File
        $testHtml3Path = $testEnv.TestHtml3File
    }

    Context "Paramètres et validation" {
        It "Lève une exception si le chemin n'existe pas" {
            # Act & Assert
            { Invoke-ScriptWithParams -ScriptPath $scriptPath -Parameters @{ Path = "C:\chemin\inexistant" } } | Should -Throw
        }
    }

    Context "Correction d'encodage pour un fichier" {
        It "Corrige l'encodage d'un fichier HTML" {
            # Arrange
            # Créer un fichier HTML sans BOM UTF-8
            $testHtmlContent = "<!DOCTYPE html><html><head><title>Test</title></head><body><p>Test</p></body></html>"
            $testHtmlPath = Join-Path -Path $testEnv.TestDirectory -ChildPath "test-no-bom.html"
            Set-Content -Path $testHtmlPath -Value $testHtmlContent -Encoding ASCII

            # Vérifier que le fichier existe
            Test-Path -Path $testHtmlPath | Should -BeTrue

            # Act
            & $scriptPath -Path $testHtmlPath

            # Assert
            # Vérifier que le fichier a été corrigé avec UTF-8 avec BOM
            $content = Get-Content -Path $testHtmlPath -Raw -Encoding UTF8
            $content | Should -Not -BeNullOrEmpty

            # Vérifier que le contenu est toujours lisible
            $content | Should -Match "<!DOCTYPE html>"
            $content | Should -Match "<title>Test</title>"
        }
    }

    Context "Correction d'encodage pour un répertoire" {
        BeforeAll {
            # Créer un répertoire de test avec des fichiers HTML sans BOM
            $testHtmlDir = Join-Path -Path $testEnv.TestDirectory -ChildPath "html-dir"
            New-Item -Path $testHtmlDir -ItemType Directory -Force | Out-Null

            # Créer des fichiers HTML sans BOM UTF-8
            $testHtmlContent = "<!DOCTYPE html><html><head><title>Test</title></head><body><p>Test</p></body></html>"

            $testHtml1Path = Join-Path -Path $testHtmlDir -ChildPath "test1.html"
            Set-Content -Path $testHtml1Path -Value $testHtmlContent -Encoding ASCII

            $testHtml2Path = Join-Path -Path $testHtmlDir -ChildPath "test2.html"
            Set-Content -Path $testHtml2Path -Value $testHtmlContent -Encoding ASCII

            # Créer un sous-répertoire avec un fichier HTML sans BOM
            $testSubDir = Join-Path -Path $testHtmlDir -ChildPath "subdir"
            New-Item -Path $testSubDir -ItemType Directory -Force | Out-Null

            $testHtml3Path = Join-Path -Path $testSubDir -ChildPath "test3.html"
            Set-Content -Path $testHtml3Path -Value $testHtmlContent -Encoding ASCII
        }

        It "Corrige l'encodage de tous les fichiers HTML dans un répertoire" {
            # Arrange
            $testHtmlDir = Join-Path -Path $testEnv.TestDirectory -ChildPath "html-dir"
            $testHtml1Path = Join-Path -Path $testHtmlDir -ChildPath "test1.html"
            $testHtml2Path = Join-Path -Path $testHtmlDir -ChildPath "test2.html"

            # Vérifier que les fichiers existent
            Test-Path -Path $testHtml1Path | Should -BeTrue
            Test-Path -Path $testHtml2Path | Should -BeTrue

            # Act
            & $scriptPath -Path $testHtmlDir

            # Assert
            # Vérifier que les fichiers ont été corrigés avec UTF-8 avec BOM
            $content1 = Get-Content -Path $testHtml1Path -Raw -Encoding UTF8
            $content2 = Get-Content -Path $testHtml2Path -Raw -Encoding UTF8

            $content1 | Should -Not -BeNullOrEmpty
            $content2 | Should -Not -BeNullOrEmpty

            # Vérifier que le contenu est toujours lisible
            $content1 | Should -Match "<!DOCTYPE html>"
            $content2 | Should -Match "<!DOCTYPE html>"
        }

        It "Corrige l'encodage récursivement avec le paramètre -Recurse" {
            # Arrange
            $testHtmlDir = Join-Path -Path $testEnv.TestDirectory -ChildPath "html-dir"
            $testHtml3Path = Join-Path -Path $testHtmlDir -ChildPath "subdir\test3.html"

            # Réinitialiser le fichier dans le sous-répertoire sans BOM UTF-8
            $testHtmlContent = "<!DOCTYPE html><html><head><title>Test</title></head><body><p>Test</p></body></html>"
            Set-Content -Path $testHtml3Path -Value $testHtmlContent -Encoding ASCII

            # Vérifier que le fichier existe
            Test-Path -Path $testHtml3Path | Should -BeTrue

            # Act
            & $scriptPath -Path $testHtmlDir -Recurse

            # Assert
            # Vérifier que le fichier a été corrigé avec UTF-8 avec BOM
            $content = Get-Content -Path $testHtml3Path -Raw -Encoding UTF8
            $content | Should -Not -BeNullOrEmpty

            # Vérifier que le contenu est toujours lisible
            $content | Should -Match "<!DOCTYPE html>"
            $content | Should -Match "<title>Test</title>"
        }
    }
}
