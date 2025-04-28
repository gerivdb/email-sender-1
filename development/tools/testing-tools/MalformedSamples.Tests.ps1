#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script de gÃ©nÃ©ration d'Ã©chantillons malformÃ©s.

.DESCRIPTION
    Ce script contient des tests unitaires pour vÃ©rifier le bon fonctionnement du script
    de gÃ©nÃ©ration d'Ã©chantillons malformÃ©s. Il utilise le framework Pester pour exÃ©cuter les tests.

.EXAMPLE
    Invoke-Pester -Path .\MalformedSamples.Tests.ps1
    ExÃ©cute les tests unitaires pour le script de gÃ©nÃ©ration d'Ã©chantillons malformÃ©s.

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
$generateMalformedScript = "$PSScriptRoot\Generate-MalformedSamples.ps1"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "MalformedSamplesTests_$(Get-Random)"
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# CrÃ©er un rÃ©pertoire source temporaire pour les tests
$testSourceDir = Join-Path -Path $testTempDir -ChildPath "source"
New-Item -Path $testSourceDir -ChildPath "formats" -ItemType Directory -Force | Out-Null

# Fonction pour crÃ©er des fichiers de test
function New-TestFile {
    param (
        [string]$FileName,
        [string]$Content,
        [string]$Directory
    )
    
    $filePath = Join-Path -Path $Directory -ChildPath $FileName
    $Content | Set-Content -Path $filePath -Encoding UTF8
    return $filePath
}

# CrÃ©er des fichiers d'exemple pour les tests
$jsonContent = @"
{
    "name": "Test",
    "version": "1.0.0",
    "description": "This is a test file"
}
"@

$xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<root>
    <element>Test</element>
    <element>Example</element>
</root>
"@

$textContent = @"
This is a test file.
It contains plain text.
"@

$jsonPath = New-TestFile -FileName "sample.json" -Content $jsonContent -Directory (Join-Path -Path $testSourceDir -ChildPath "formats")
$xmlPath = New-TestFile -FileName "sample.xml" -Content $xmlContent -Directory (Join-Path -Path $testSourceDir -ChildPath "formats")
$textPath = New-TestFile -FileName "sample.txt" -Content $textContent -Directory (Join-Path -Path $testSourceDir -ChildPath "formats")

# Tests Pester
Describe "Script de gÃ©nÃ©ration d'Ã©chantillons malformÃ©s" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire de sortie pour les tests
        $testOutputDir = Join-Path -Path $testTempDir -ChildPath "output"
        New-Item -Path $testOutputDir -ItemType Directory -Force | Out-Null
    }
    
    Context "Fonctions internes" {
        It "La fonction New-DirectoryIfNotExists crÃ©e un rÃ©pertoire s'il n'existe pas" {
            # CrÃ©er un chemin de test
            $testPath = Join-Path -Path $testTempDir -ChildPath "test_directory"
            
            # ExÃ©cuter la fonction via le script
            $scriptBlock = {
                . $generateMalformedScript
                New-DirectoryIfNotExists -Path $testPath
            }
            
            # VÃ©rifier que le rÃ©pertoire a Ã©tÃ© crÃ©Ã©
            $scriptBlock | Should -Not -Throw
            Test-Path -Path $testPath -PathType Container | Should -Be $true
        }
        
        It "La fonction New-TruncatedFile crÃ©e un fichier tronquÃ©" {
            # CrÃ©er un fichier source
            $sourceContent = "This is a test file with some content that will be truncated."
            $sourcePath = Join-Path -Path $testTempDir -ChildPath "source.txt"
            $sourceContent | Set-Content -Path $sourcePath -Encoding UTF8
            
            # CrÃ©er un fichier de destination
            $destPath = Join-Path -Path $testTempDir -ChildPath "truncated.txt"
            
            # ExÃ©cuter la fonction via le script
            $scriptBlock = {
                . $generateMalformedScript
                New-TruncatedFile -SourcePath $sourcePath -DestinationPath $destPath -PercentageToKeep 50
            }
            
            # VÃ©rifier que le fichier a Ã©tÃ© tronquÃ©
            $scriptBlock | Should -Not -Throw
            Test-Path -Path $destPath -PathType Leaf | Should -Be $true
            
            $originalLength = $sourceContent.Length
            $truncatedContent = Get-Content -Path $destPath -Raw
            $truncatedLength = $truncatedContent.Length
            
            $truncatedLength | Should -BeLessThan $originalLength
            $truncatedLength | Should -BeGreaterOrEqual ($originalLength * 0.4) # Tenir compte des arrondis
            $truncatedLength | Should -BeLessOrEqual ($originalLength * 0.6) # Tenir compte des arrondis
        }
        
        It "La fonction New-CorruptedTextFile crÃ©e un fichier texte corrompu" {
            # CrÃ©er un fichier source
            $sourceContent = "This is a test file with some content that will be corrupted."
            $sourcePath = Join-Path -Path $testTempDir -ChildPath "source_corrupt.txt"
            $sourceContent | Set-Content -Path $sourcePath -Encoding UTF8
            
            # CrÃ©er un fichier de destination
            $destPath = Join-Path -Path $testTempDir -ChildPath "corrupted.txt"
            
            # ExÃ©cuter la fonction via le script
            $scriptBlock = {
                . $generateMalformedScript
                New-CorruptedTextFile -SourcePath $sourcePath -DestinationPath $destPath -CorruptionPercentage 20
            }
            
            # VÃ©rifier que le fichier a Ã©tÃ© corrompu
            $scriptBlock | Should -Not -Throw
            Test-Path -Path $destPath -PathType Leaf | Should -Be $true
            
            $corruptedContent = Get-Content -Path $destPath -Raw
            $corruptedContent | Should -Not -BeExactly $sourceContent
        }
        
        It "La fonction New-IncorrectHeaderFile crÃ©e un fichier avec un en-tÃªte incorrect" {
            # CrÃ©er un fichier source
            $sourceContent = "Original header line\nThis is the content of the file."
            $sourcePath = Join-Path -Path $testTempDir -ChildPath "source_header.txt"
            $sourceContent | Set-Content -Path $sourcePath -Encoding UTF8
            
            # CrÃ©er un fichier de destination
            $destPath = Join-Path -Path $testTempDir -ChildPath "incorrect_header.txt"
            
            # ExÃ©cuter la fonction via le script
            $scriptBlock = {
                . $generateMalformedScript
                New-IncorrectHeaderFile -SourcePath $sourcePath -DestinationPath $destPath -IncorrectHeader "Modified header\n"
            }
            
            # VÃ©rifier que le fichier a un en-tÃªte incorrect
            $scriptBlock | Should -Not -Throw
            Test-Path -Path $destPath -PathType Leaf | Should -Be $true
            
            $incorrectContent = Get-Content -Path $destPath -Raw
            $incorrectContent | Should -Not -BeExactly $sourceContent
            $incorrectContent | Should -Match "Modified header"
        }
        
        It "La fonction New-HybridFile crÃ©e un fichier hybride" {
            # CrÃ©er deux fichiers sources
            $sourceContent1 = "This is the first source file."
            $sourceContent2 = "This is the second source file."
            $sourcePath1 = Join-Path -Path $testTempDir -ChildPath "source1.txt"
            $sourcePath2 = Join-Path -Path $testTempDir -ChildPath "source2.txt"
            $sourceContent1 | Set-Content -Path $sourcePath1 -Encoding UTF8
            $sourceContent2 | Set-Content -Path $sourcePath2 -Encoding UTF8
            
            # CrÃ©er un fichier de destination
            $destPath = Join-Path -Path $testTempDir -ChildPath "hybrid.txt"
            
            # ExÃ©cuter la fonction via le script
            $scriptBlock = {
                . $generateMalformedScript
                New-HybridFile -SourcePath1 $sourcePath1 -SourcePath2 $sourcePath2 -DestinationPath $destPath -MixPercentage 50
            }
            
            # VÃ©rifier que le fichier hybride a Ã©tÃ© crÃ©Ã©
            $scriptBlock | Should -Not -Throw
            Test-Path -Path $destPath -PathType Leaf | Should -Be $true
            
            $hybridContent = Get-Content -Path $destPath -Raw
            $hybridContent | Should -Not -BeExactly $sourceContent1
            $hybridContent | Should -Not -BeExactly $sourceContent2
        }
    }
    
    Context "ExÃ©cution du script complet" {
        It "Le script s'exÃ©cute sans erreur avec les paramÃ¨tres par dÃ©faut" {
            # ExÃ©cuter le script avec des paramÃ¨tres minimaux
            $scriptBlock = {
                & $generateMalformedScript -SourceDirectory $testSourceDir -OutputDirectory (Join-Path -Path $testTempDir -ChildPath "output_default") -Force
            }
            
            # VÃ©rifier que le script s'exÃ©cute sans erreur
            $scriptBlock | Should -Not -Throw
        }
        
        It "Le script crÃ©e les sous-rÃ©pertoires attendus" {
            # ExÃ©cuter le script
            $outputDir = Join-Path -Path $testTempDir -ChildPath "output_subdirs"
            & $generateMalformedScript -SourceDirectory $testSourceDir -OutputDirectory $outputDir -Force
            
            # VÃ©rifier que les sous-rÃ©pertoires ont Ã©tÃ© crÃ©Ã©s
            Test-Path -Path (Join-Path -Path $outputDir -ChildPath "truncated") -PathType Container | Should -Be $true
            Test-Path -Path (Join-Path -Path $outputDir -ChildPath "corrupted") -PathType Container | Should -Be $true
            Test-Path -Path (Join-Path -Path $outputDir -ChildPath "incorrect_header") -PathType Container | Should -Be $true
            Test-Path -Path (Join-Path -Path $outputDir -ChildPath "incorrect_extension") -PathType Container | Should -Be $true
            Test-Path -Path (Join-Path -Path $outputDir -ChildPath "hybrid") -PathType Container | Should -Be $true
        }
        
        It "Le script gÃ©nÃ¨re des fichiers tronquÃ©s" {
            # ExÃ©cuter le script
            $outputDir = Join-Path -Path $testTempDir -ChildPath "output_truncated"
            & $generateMalformedScript -SourceDirectory $testSourceDir -OutputDirectory $outputDir -Force
            
            # VÃ©rifier que des fichiers tronquÃ©s ont Ã©tÃ© crÃ©Ã©s
            $truncatedFiles = Get-ChildItem -Path (Join-Path -Path $outputDir -ChildPath "truncated") -File
            $truncatedFiles.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier que les fichiers tronquÃ©s sont plus petits que les originaux
            $jsonTruncated = $truncatedFiles | Where-Object { $_.Name -like "*sample.json*" } | Select-Object -First 1
            if ($jsonTruncated) {
                $jsonTruncated.Length | Should -BeLessThan (Get-Item -Path $jsonPath).Length
            }
        }
        
        It "Le script gÃ©nÃ¨re des fichiers corrompus" {
            # ExÃ©cuter le script
            $outputDir = Join-Path -Path $testTempDir -ChildPath "output_corrupted"
            & $generateMalformedScript -SourceDirectory $testSourceDir -OutputDirectory $outputDir -Force
            
            # VÃ©rifier que des fichiers corrompus ont Ã©tÃ© crÃ©Ã©s
            $corruptedFiles = Get-ChildItem -Path (Join-Path -Path $outputDir -ChildPath "corrupted") -File
            $corruptedFiles.Count | Should -BeGreaterThan 0
        }
        
        It "Le script gÃ©nÃ¨re des fichiers avec extension incorrecte" {
            # ExÃ©cuter le script
            $outputDir = Join-Path -Path $testTempDir -ChildPath "output_extension"
            & $generateMalformedScript -SourceDirectory $testSourceDir -OutputDirectory $outputDir -Force
            
            # VÃ©rifier que des fichiers avec extension incorrecte ont Ã©tÃ© crÃ©Ã©s
            $incorrectExtFiles = Get-ChildItem -Path (Join-Path -Path $outputDir -ChildPath "incorrect_extension") -File
            $incorrectExtFiles.Count | Should -BeGreaterThan 0
        }
        
        It "Le script gÃ©nÃ¨re des fichiers hybrides" {
            # ExÃ©cuter le script
            $outputDir = Join-Path -Path $testTempDir -ChildPath "output_hybrid"
            & $generateMalformedScript -SourceDirectory $testSourceDir -OutputDirectory $outputDir -Force
            
            # VÃ©rifier que des fichiers hybrides ont Ã©tÃ© crÃ©Ã©s
            $hybridFiles = Get-ChildItem -Path (Join-Path -Path $outputDir -ChildPath "hybrid") -File
            $hybridFiles.Count | Should -BeGreaterThan 0
        }
    }
}

# Nettoyer aprÃ¨s les tests
AfterAll {
    # Supprimer le rÃ©pertoire temporaire
    if (Test-Path -Path $testTempDir) {
        Remove-Item -Path $testTempDir -Recurse -Force
    }
}
