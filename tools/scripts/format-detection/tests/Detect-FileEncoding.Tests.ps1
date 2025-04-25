#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour la fonction de détection d'encodage.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider le bon fonctionnement
    de la fonction de détection d'encodage développée dans le cadre de la
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
        Write-Error "Impossible d'installer le module Pester. Les tests ne peuvent pas être exécutés."
        return
    }
}

# Chemin vers le script à tester
$scriptPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\analysis\Detect-FileEncoding.ps1"

# Créer le répertoire de test si nécessaire
$testSamplesPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\encoding_samples"
if (-not (Test-Path -Path $testSamplesPath -PathType Container)) {
    New-Item -Path $testSamplesPath -ItemType Directory -Force | Out-Null
}

# Fonction pour créer des fichiers d'échantillon pour les tests
function New-EncodingSampleFiles {
    param (
        [string]$TestDirectory
    )

    # Nettoyer le répertoire de test
    Get-ChildItem -Path $TestDirectory -File | Remove-Item -Force

    # Contenu multilingue pour les tests
    $multilingualContent = @"
=== Test de détection d'encodage ===

== Texte latin (ASCII) ==
The quick brown fox jumps over the lazy dog.
0123456789 !@#$%^&*()_+-=[]{}|;':",./<>?

== Texte français (Latin-1) ==
Voici un texte en français avec des accents : éèêëàâäôöùûüÿç
Les œufs et les bœufs sont dans le pré.

== Texte grec (UTF-8) ==
Ξεσκεπάζω την ψυχοφθόρα βδελυγμία.
Καλημέρα, πώς είστε σήμερα;

== Texte russe (UTF-8) ==
Съешь же ещё этих мягких французских булок, да выпей чаю.
Широкая электрификация южных губерний даст мощный толчок подъёму сельского хозяйства.

== Texte japonais (UTF-8) ==
いろはにほへと ちりぬるを わかよたれそ つねならむ
私は日本語を勉強しています。

== Texte emoji (UTF-8) ==
😀 😃 😄 😁 😆 😅 😂 🤣 🥲 ☺️ 😊 😇 🙂 🙃 😉 😌 😍 🥰 😘 😗 😙 😚 😋 😛 😝 😜
"@

    # Créer un fichier ASCII
    $asciiContent = "This is a simple ASCII text file."
    $asciiPath = Join-Path -Path $TestDirectory -ChildPath "ascii.txt"
    [System.IO.File]::WriteAllText($asciiPath, $asciiContent, [System.Text.ASCIIEncoding]::new())

    # Créer un fichier UTF-8 sans BOM
    $utf8Path = Join-Path -Path $TestDirectory -ChildPath "utf8.txt"
    [System.IO.File]::WriteAllText($utf8Path, $multilingualContent, [System.Text.UTF8Encoding]::new($false))

    # Créer un fichier UTF-8 avec BOM
    $utf8BomPath = Join-Path -Path $TestDirectory -ChildPath "utf8-bom.txt"
    [System.IO.File]::WriteAllText($utf8BomPath, $multilingualContent, [System.Text.UTF8Encoding]::new($true))

    # Créer un fichier UTF-16LE sans BOM
    $utf16LEPath = Join-Path -Path $TestDirectory -ChildPath "utf16le.txt"
    [System.IO.File]::WriteAllText($utf16LEPath, $multilingualContent, [System.Text.UnicodeEncoding]::new($false, $false))

    # Créer un fichier UTF-16LE avec BOM
    $utf16LEBomPath = Join-Path -Path $TestDirectory -ChildPath "utf16le-bom.txt"
    [System.IO.File]::WriteAllText($utf16LEBomPath, $multilingualContent, [System.Text.UnicodeEncoding]::new($false, $true))

    # Créer un fichier UTF-16BE sans BOM
    $utf16BEPath = Join-Path -Path $TestDirectory -ChildPath "utf16be.txt"
    [System.IO.File]::WriteAllText($utf16BEPath, $multilingualContent, [System.Text.UnicodeEncoding]::new($true, $false))

    # Créer un fichier UTF-16BE avec BOM
    $utf16BEBomPath = Join-Path -Path $TestDirectory -ChildPath "utf16be-bom.txt"
    [System.IO.File]::WriteAllText($utf16BEBomPath, $multilingualContent, [System.Text.UnicodeEncoding]::new($true, $true))

    # Créer un fichier Windows-1252
    $windows1252Path = Join-Path -Path $TestDirectory -ChildPath "windows1252.txt"
    [System.IO.File]::WriteAllText($windows1252Path, $multilingualContent, [System.Text.Encoding]::GetEncoding(1252))

    # Créer un fichier binaire
    $binaryPath = Join-Path -Path $TestDirectory -ChildPath "binary.bin"
    $binaryData = [byte[]]::new(256)
    for ($i = 0; $i -lt 256; $i++) {
        $binaryData[$i] = $i
    }
    [System.IO.File]::WriteAllBytes($binaryPath, $binaryData)

    # Créer un fichier avec des octets nuls (simulant UTF-16)
    $nullBytesPath = Join-Path -Path $TestDirectory -ChildPath "null_bytes.bin"
    $nullBytesData = [byte[]]::new(256)
    for ($i = 0; $i -lt 256; $i += 2) {
        $nullBytesData[$i] = 65 + ($i % 26)  # Lettres majuscules
        $nullBytesData[$i + 1] = 0  # Octets nuls
    }
    [System.IO.File]::WriteAllBytes($nullBytesPath, $nullBytesData)

    # Retourner un dictionnaire des fichiers créés avec leurs encodages attendus
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

# Créer les fichiers d'échantillon
$expectedEncodings = New-EncodingSampleFiles -TestDirectory $testSamplesPath

# Démarrer les tests Pester
Describe "Tests de détection d'encodage" {
    BeforeAll {
        # Charger le script à tester
        . $scriptPath
    }

    Context "Détection des BOM" {
        It "Détecte correctement l'encodage UTF-8 avec BOM" {
            $utf8BomPath = Join-Path -Path $testSamplesPath -ChildPath "utf8-bom.txt"
            $result = Get-FileEncoding -FilePath $utf8BomPath
            $result.Encoding | Should -Be "UTF-8-BOM"
            $result.BOM | Should -Be $true
        }

        It "Détecte correctement l'encodage UTF-16LE avec BOM" {
            $utf16LEBomPath = Join-Path -Path $testSamplesPath -ChildPath "utf16le-bom.txt"
            $result = Get-FileEncoding -FilePath $utf16LEBomPath
            $result.Encoding | Should -Be "UTF-16LE"
            $result.BOM | Should -Be $true
        }

        It "Détecte correctement l'encodage UTF-16BE avec BOM" {
            $utf16BEBomPath = Join-Path -Path $testSamplesPath -ChildPath "utf16be-bom.txt"
            $result = Get-FileEncoding -FilePath $utf16BEBomPath
            $result.Encoding | Should -Be "UTF-16BE"
            $result.BOM | Should -Be $true
        }
    }

    Context "Détection sans BOM" {
        It "Détecte correctement l'encodage ASCII" {
            $asciiPath = Join-Path -Path $testSamplesPath -ChildPath "ascii.txt"
            $result = Get-FileEncoding -FilePath $asciiPath
            $result.Encoding | Should -Be "ASCII"
            $result.BOM | Should -Be $false
        }

        It "Détecte correctement l'encodage UTF-8 sans BOM" {
            $utf8Path = Join-Path -Path $testSamplesPath -ChildPath "utf8.txt"
            $result = Get-FileEncoding -FilePath $utf8Path
            $result.Encoding | Should -Be "UTF-8"
            $result.BOM | Should -Be $false
        }

        It "Détecte correctement l'encodage UTF-16LE sans BOM" {
            $utf16LEPath = Join-Path -Path $testSamplesPath -ChildPath "utf16le.txt"
            $result = Get-FileEncoding -FilePath $utf16LEPath
            $result.Encoding | Should -Be "UTF-16LE"
            $result.BOM | Should -Be $false
        }

        It "Détecte correctement l'encodage UTF-16BE sans BOM" {
            $utf16BEPath = Join-Path -Path $testSamplesPath -ChildPath "utf16be.txt"
            $result = Get-FileEncoding -FilePath $utf16BEPath
            $result.Encoding | Should -Be "UTF-16BE"
            $result.BOM | Should -Be $false
        }

        It "Détecte correctement l'encodage Windows-1252" {
            $windows1252Path = Join-Path -Path $testSamplesPath -ChildPath "windows1252.txt"
            $result = Get-FileEncoding -FilePath $windows1252Path
            $result.Encoding | Should -Be "Windows-1252"
            $result.BOM | Should -Be $false
        }
    }

    Context "Détection de fichiers binaires" {
        It "Détecte correctement un fichier binaire" {
            $binaryPath = Join-Path -Path $testSamplesPath -ChildPath "binary.bin"
            $result = Get-FileEncoding -FilePath $binaryPath
            $result.Encoding | Should -Be "BINARY"
            $result.BOM | Should -Be $false
        }

        It "Détecte correctement un fichier avec des octets nuls" {
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
        # Nettoyer les fichiers d'échantillon
        Get-ChildItem -Path $testSamplesPath -File | Remove-Item -Force
    }
}
