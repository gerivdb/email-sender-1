#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour la fonction de dÃ©tection d'encodage.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider le bon fonctionnement
    de la fonction de dÃ©tection d'encodage dÃ©veloppÃ©e dans le cadre de la
    section 2.1.2 de la roadmap.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas disponible. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
    }
    catch {
        Write-Error "Impossible d'installer le module Pester. Les tests ne peuvent pas Ãªtre exÃ©cutÃ©s."
        return
    }
}

# Chemin vers le script Ã  tester
$scriptPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\analysis\Detect-FileEncoding.ps1"

# CrÃ©er le rÃ©pertoire de test si nÃ©cessaire
$testSamplesPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\encoding_samples"
if (-not (Test-Path -Path $testSamplesPath -PathType Container)) {
    New-Item -Path $testSamplesPath -ItemType Directory -Force | Out-Null
}

# Fonction pour crÃ©er des fichiers d'Ã©chantillon pour les tests
function New-EncodingSampleFiles {
    param (
        [string]$TestDirectory
    )

    # Nettoyer le rÃ©pertoire de test
    Get-ChildItem -Path $TestDirectory -File | Remove-Item -Force

    # Contenu multilingue pour les tests
    $multilingualContent = @"
=== Test de dÃ©tection d'encodage ===

== Texte latin (ASCII) ==
The quick brown fox jumps over the lazy dog.
0123456789 !@#$%^&*()_+-=[]{}|;':",./<>?

== Texte franÃ§ais (Latin-1) ==
Voici un texte en franÃ§ais avec des accents : Ã©Ã¨ÃªÃ«Ã Ã¢Ã¤Ã´Ã¶Ã¹Ã»Ã¼Ã¿Ã§
Les Å“ufs et les bÅ“ufs sont dans le prÃ©.

== Texte grec (UTF-8) ==
ÎžÎµÏƒÎºÎµÏ€Î¬Î¶Ï‰ Ï„Î·Î½ ÏˆÏ…Ï‡Î¿Ï†Î¸ÏŒÏÎ± Î²Î´ÎµÎ»Ï…Î³Î¼Î¯Î±.
ÎšÎ±Î»Î·Î¼Î­ÏÎ±, Ï€ÏŽÏ‚ ÎµÎ¯ÏƒÏ„Îµ ÏƒÎ®Î¼ÎµÏÎ±;

== Texte russe (UTF-8) ==
Ð¡ÑŠÐµÑˆÑŒ Ð¶Ðµ ÐµÑ‰Ñ‘ ÑÑ‚Ð¸Ñ… Ð¼ÑÐ³ÐºÐ¸Ñ… Ñ„Ñ€Ð°Ð½Ñ†ÑƒÐ·ÑÐºÐ¸Ñ… Ð±ÑƒÐ»Ð¾Ðº, Ð´Ð° Ð²Ñ‹Ð¿ÐµÐ¹ Ñ‡Ð°ÑŽ.
Ð¨Ð¸Ñ€Ð¾ÐºÐ°Ñ ÑÐ»ÐµÐºÑ‚Ñ€Ð¸Ñ„Ð¸ÐºÐ°Ñ†Ð¸Ñ ÑŽÐ¶Ð½Ñ‹Ñ… Ð³ÑƒÐ±ÐµÑ€Ð½Ð¸Ð¹ Ð´Ð°ÑÑ‚ Ð¼Ð¾Ñ‰Ð½Ñ‹Ð¹ Ñ‚Ð¾Ð»Ñ‡Ð¾Ðº Ð¿Ð¾Ð´ÑŠÑ‘Ð¼Ñƒ ÑÐµÐ»ÑŒÑÐºÐ¾Ð³Ð¾ Ñ…Ð¾Ð·ÑÐ¹ÑÑ‚Ð²Ð°.

== Texte japonais (UTF-8) ==
ã„ã‚ã¯ã«ã»ã¸ã¨ ã¡ã‚Šã¬ã‚‹ã‚’ ã‚ã‹ã‚ˆãŸã‚Œã ã¤ã­ãªã‚‰ã‚€
ç§ã¯æ—¥æœ¬èªžã‚’å‹‰å¼·ã—ã¦ã„ã¾ã™ã€‚

== Texte emoji (UTF-8) ==
ðŸ˜€ ðŸ˜ƒ ðŸ˜„ ðŸ˜ ðŸ˜† ðŸ˜… ðŸ˜‚ ðŸ¤£ ðŸ¥² â˜ºï¸ ðŸ˜Š ðŸ˜‡ ðŸ™‚ ðŸ™ƒ ðŸ˜‰ ðŸ˜Œ ðŸ˜ ðŸ¥° ðŸ˜˜ ðŸ˜— ðŸ˜™ ðŸ˜š ðŸ˜‹ ðŸ˜› ðŸ˜ ðŸ˜œ
"@

    # CrÃ©er un fichier ASCII
    $asciiContent = "This is a simple ASCII text file."
    $asciiPath = Join-Path -Path $TestDirectory -ChildPath "ascii.txt"
    [System.IO.File]::WriteAllText($asciiPath, $asciiContent, [System.Text.ASCIIEncoding]::new())

    # CrÃ©er un fichier UTF-8 sans BOM
    $utf8Path = Join-Path -Path $TestDirectory -ChildPath "utf8.txt"
    [System.IO.File]::WriteAllText($utf8Path, $multilingualContent, [System.Text.UTF8Encoding]::new($false))

    # CrÃ©er un fichier UTF-8 avec BOM
    $utf8BomPath = Join-Path -Path $TestDirectory -ChildPath "utf8-bom.txt"
    [System.IO.File]::WriteAllText($utf8BomPath, $multilingualContent, [System.Text.UTF8Encoding]::new($true))

    # CrÃ©er un fichier UTF-16LE sans BOM
    $utf16LEPath = Join-Path -Path $TestDirectory -ChildPath "utf16le.txt"
    [System.IO.File]::WriteAllText($utf16LEPath, $multilingualContent, [System.Text.UnicodeEncoding]::new($false, $false))

    # CrÃ©er un fichier UTF-16LE avec BOM
    $utf16LEBomPath = Join-Path -Path $TestDirectory -ChildPath "utf16le-bom.txt"
    [System.IO.File]::WriteAllText($utf16LEBomPath, $multilingualContent, [System.Text.UnicodeEncoding]::new($false, $true))

    # CrÃ©er un fichier UTF-16BE sans BOM
    $utf16BEPath = Join-Path -Path $TestDirectory -ChildPath "utf16be.txt"
    [System.IO.File]::WriteAllText($utf16BEPath, $multilingualContent, [System.Text.UnicodeEncoding]::new($true, $false))

    # CrÃ©er un fichier UTF-16BE avec BOM
    $utf16BEBomPath = Join-Path -Path $TestDirectory -ChildPath "utf16be-bom.txt"
    [System.IO.File]::WriteAllText($utf16BEBomPath, $multilingualContent, [System.Text.UnicodeEncoding]::new($true, $true))

    # CrÃ©er un fichier Windows-1252
    $windows1252Path = Join-Path -Path $TestDirectory -ChildPath "windows1252.txt"
    [System.IO.File]::WriteAllText($windows1252Path, $multilingualContent, [System.Text.Encoding]::GetEncoding(1252))

    # CrÃ©er un fichier binaire
    $binaryPath = Join-Path -Path $TestDirectory -ChildPath "binary.bin"
    $binaryData = [byte[]]::new(256)
    for ($i = 0; $i -lt 256; $i++) {
        $binaryData[$i] = $i
    }
    [System.IO.File]::WriteAllBytes($binaryPath, $binaryData)

    # CrÃ©er un fichier avec des octets nuls (simulant UTF-16)
    $nullBytesPath = Join-Path -Path $TestDirectory -ChildPath "null_bytes.bin"
    $nullBytesData = [byte[]]::new(256)
    for ($i = 0; $i -lt 256; $i += 2) {
        $nullBytesData[$i] = 65 + ($i % 26)  # Lettres majuscules
        $nullBytesData[$i + 1] = 0  # Octets nuls
    }
    [System.IO.File]::WriteAllBytes($nullBytesPath, $nullBytesData)

    # Retourner un dictionnaire des fichiers crÃ©Ã©s avec leurs encodages attendus
    return @{
        $asciiPath = "ASCII"
        $utf8Path = "UTF-8"
        $utf8BomPath = "UTF-8-BOM"
        $utf16LEPath = "UTF-16LE"
        $utf16LEBomPath = "UTF-16LE"
        $utf16BEPath = "UTF-16BE"
        $utf16BEBomPath = "UTF-16BE"
        $windows1252Path = "Windows-1252"
        $binaryPath = "BINARY"
        $nullBytesPath = "UTF-16LE"
    }
}

# CrÃ©er les fichiers d'Ã©chantillon
$expectedEncodings = New-EncodingSampleFiles -TestDirectory $testSamplesPath

# DÃ©marrer les tests Pester
Describe "Tests de dÃ©tection d'encodage" {
    BeforeAll {
        # Charger le script Ã  tester
        . $scriptPath
    }

    Context "DÃ©tection des BOM" {
        It "DÃ©tecte correctement l'encodage UTF-8 avec BOM" {
            $utf8BomPath = Join-Path -Path $testSamplesPath -ChildPath "utf8-bom.txt"
            $result = Get-FileEncoding -FilePath $utf8BomPath
            $result.Encoding | Should -Be "UTF-8-BOM"
            $result.BOM | Should -Be $true
        }

        It "DÃ©tecte correctement l'encodage UTF-16LE avec BOM" {
            $utf16LEBomPath = Join-Path -Path $testSamplesPath -ChildPath "utf16le-bom.txt"
            $result = Get-FileEncoding -FilePath $utf16LEBomPath
            $result.Encoding | Should -Be "UTF-16LE"
            $result.BOM | Should -Be $true
        }

        It "DÃ©tecte correctement l'encodage UTF-16BE avec BOM" {
            $utf16BEBomPath = Join-Path -Path $testSamplesPath -ChildPath "utf16be-bom.txt"
            $result = Get-FileEncoding -FilePath $utf16BEBomPath
            $result.Encoding | Should -Be "UTF-16BE"
            $result.BOM | Should -Be $true
        }
    }

    Context "DÃ©tection sans BOM" {
        It "DÃ©tecte correctement l'encodage ASCII" {
            $asciiPath = Join-Path -Path $testSamplesPath -ChildPath "ascii.txt"
            $result = Get-FileEncoding -FilePath $asciiPath
            $result.Encoding | Should -Be "ASCII"
            $result.BOM | Should -Be $false
        }

        It "DÃ©tecte correctement l'encodage UTF-8 sans BOM" {
            $utf8Path = Join-Path -Path $testSamplesPath -ChildPath "utf8.txt"
            $result = Get-FileEncoding -FilePath $utf8Path
            $result.Encoding | Should -Be "UTF-8"
            $result.BOM | Should -Be $false
        }

        It "DÃ©tecte correctement l'encodage UTF-16LE sans BOM" {
            $utf16LEPath = Join-Path -Path $testSamplesPath -ChildPath "utf16le.txt"
            $result = Get-FileEncoding -FilePath $utf16LEPath
            $result.Encoding | Should -Be "UTF-16LE"
            $result.BOM | Should -Be $false
        }

        It "DÃ©tecte correctement l'encodage UTF-16BE sans BOM" {
            $utf16BEPath = Join-Path -Path $testSamplesPath -ChildPath "utf16be.txt"
            $result = Get-FileEncoding -FilePath $utf16BEPath
            $result.Encoding | Should -Be "UTF-16BE"
            $result.BOM | Should -Be $false
        }

        It "DÃ©tecte correctement l'encodage Windows-1252" {
            $windows1252Path = Join-Path -Path $testSamplesPath -ChildPath "windows1252.txt"
            $result = Get-FileEncoding -FilePath $windows1252Path
            $result.Encoding | Should -Be "Windows-1252"
            $result.BOM | Should -Be $false
        }
    }

    Context "DÃ©tection de fichiers binaires" {
        It "DÃ©tecte correctement un fichier binaire" {
            $binaryPath = Join-Path -Path $testSamplesPath -ChildPath "binary.bin"
            $result = Get-FileEncoding -FilePath $binaryPath
            $result.Encoding | Should -Be "BINARY"
            $result.BOM | Should -Be $false
        }

        It "DÃ©tecte correctement un fichier avec des octets nuls" {
            $nullBytesPath = Join-Path -Path $testSamplesPath -ChildPath "null_bytes.bin"
            $result = Get-FileEncoding -FilePath $nullBytesPath
            $result.Encoding | Should -Be "UTF-16LE"
            $result.BOM | Should -Be $false
        }
    }

    Context "Gestion des erreurs" {
        It "Retourne FILE_NOT_FOUND pour un fichier inexistant" {
            $nonExistentPath = Join-Path -Path $testSamplesPath -ChildPath "non_existent.txt"
            $result = Get-FileEncoding -FilePath $nonExistentPath
            $result.Encoding | Should -Be "FILE_NOT_FOUND"
        }
    }

    AfterAll {
        # Nettoyer les fichiers d'Ã©chantillon
        Get-ChildItem -Path $testSamplesPath -File | Remove-Item -Force
    }
}
