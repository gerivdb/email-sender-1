#Requires -Version 5.1
<#
.SYNOPSIS
    Génère des fichiers d'échantillon avec différents encodages.

.DESCRIPTION
    Ce script génère des fichiers d'échantillon avec différents encodages
    pour tester la détection d'encodage. Il crée des fichiers texte avec
    du contenu multilingue dans différents encodages.

.PARAMETER OutputDirectory
    Le répertoire où les fichiers d'échantillon seront enregistrés.
    Par défaut, utilise le répertoire 'samples/encoding'.

.PARAMETER GenerateExpectedEncodings
    Indique si un fichier JSON contenant les encodages attendus doit être généré.

.EXAMPLE
    .\Generate-EncodingSamples.ps1 -OutputDirectory "C:\Samples\Encoding" -GenerateExpectedEncodings

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputDirectory = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "samples") -ChildPath "encoding"),
    
    [Parameter()]
    [switch]$GenerateExpectedEncodings
)

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputDirectory -PathType Container)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire de sortie créé : $OutputDirectory" -ForegroundColor Green
}

# Contenu multilingue pour les tests
$multilingualContent = @"
=== Test de détection d'encodage ===

== Texte latin (ASCII) ==
The quick brown fox jumps over the lazy dog.
0123456789 !@#$%^&*()_+-=[]{}|;':",./<>?

== Texte français (Latin-1) ==
Voici un texte en français avec des accents : éèêëàâäôöùûüÿç
Les œufs et les bœufs sont dans le pré.

== Texte allemand (Latin-1) ==
Falsches Üben von Xylophonmusik quält jeden größeren Zwerg.
Die Königin und der König leben in einem Schloß.

== Texte grec (UTF-8) ==
Ξεσκεπάζω την ψυχοφθόρα βδελυγμία.
Καλημέρα, πώς είστε σήμερα;

== Texte russe (UTF-8) ==
Съешь же ещё этих мягких французских булок, да выпей чаю.
Широкая электрификация южных губерний даст мощный толчок подъёму сельского хозяйства.

== Texte japonais (UTF-8) ==
いろはにほへと ちりぬるを わかよたれそ つねならむ
私は日本語を勉強しています。

== Texte chinois (UTF-8) ==
我能吞下玻璃而不伤身体。
你好，世界！

== Texte arabe (UTF-8) ==
أنا قادر على أكل الزجاج و هذا لا يؤلمني.
مرحبا بالعالم!

== Texte hébreu (UTF-8) ==
אני יכול לאכול זכוכית וזה לא מזיק לי.
שלום עולם!

== Texte emoji (UTF-8) ==
😀 😃 😄 😁 😆 😅 😂 🤣 🥲 ☺️ 😊 😇 🙂 🙃 😉 😌 😍 🥰 😘 😗 😙 😚 😋 😛 😝 😜
🐶 🐱 🐭 🐹 🐰 🦊 🐻 🐼 🐻‍❄️ 🐨 🐯 🦁 🐮 🐷 🐽 🐸 🐵 🙈 🙉 🙊 🐒 🐔 🐧 🐦 🐤 🐣
"@

# Définir les encodages à tester
$encodings = @(
    @{ Name = "ASCII"; Encoding = [System.Text.ASCIIEncoding]::new(); HasBOM = $false },
    @{ Name = "UTF-8"; Encoding = [System.Text.UTF8Encoding]::new($false); HasBOM = $false },
    @{ Name = "UTF-8-BOM"; Encoding = [System.Text.UTF8Encoding]::new($true); HasBOM = $true },
    @{ Name = "UTF-16LE"; Encoding = [System.Text.UnicodeEncoding]::new($false, $false); HasBOM = $false },
    @{ Name = "UTF-16LE-BOM"; Encoding = [System.Text.UnicodeEncoding]::new($false, $true); HasBOM = $true },
    @{ Name = "UTF-16BE"; Encoding = [System.Text.UnicodeEncoding]::new($true, $false); HasBOM = $false },
    @{ Name = "UTF-16BE-BOM"; Encoding = [System.Text.UnicodeEncoding]::new($true, $true); HasBOM = $true },
    @{ Name = "Windows-1252"; Encoding = [System.Text.Encoding]::GetEncoding(1252); HasBOM = $false },
    @{ Name = "ISO-8859-1"; Encoding = [System.Text.Encoding]::GetEncoding(28591); HasBOM = $false }
)

# Dictionnaire pour stocker les encodages attendus
$expectedEncodings = @{}

# Générer les fichiers d'échantillon
foreach ($encoding in $encodings) {
    $fileName = "sample_$($encoding.Name).txt"
    $filePath = Join-Path -Path $OutputDirectory -ChildPath $fileName
    
    try {
        # Écrire le contenu dans le fichier avec l'encodage spécifié
        [System.IO.File]::WriteAllText($filePath, $multilingualContent, $encoding.Encoding)
        
        Write-Host "Fichier créé : $fileName (Encodage: $($encoding.Name), BOM: $($encoding.HasBOM))" -ForegroundColor Green
        
        # Ajouter l'encodage attendu au dictionnaire
        $expectedEncodings[$filePath] = $encoding.Name
    } catch {
        Write-Warning "Erreur lors de la création du fichier $fileName : $_"
    }
}

# Créer des fichiers binaires pour tester la détection
$binaryFiles = @(
    @{ Name = "sample_binary.bin"; Size = 1024 },
    @{ Name = "sample_binary_with_text.bin"; Size = 1024; HasText = $true },
    @{ Name = "sample_binary_with_nulls.bin"; Size = 1024; HasNulls = $true }
)

foreach ($binaryFile in $binaryFiles) {
    $filePath = Join-Path -Path $OutputDirectory -ChildPath $binaryFile.Name
    
    try {
        # Créer un tableau d'octets aléatoires
        $bytes = [byte[]]::new($binaryFile.Size)
        $random = [System.Random]::new()
        $random.NextBytes($bytes)
        
        # Ajouter du texte si demandé
        if ($binaryFile.HasText) {
            $text = "This is some text embedded in a binary file."
            $textBytes = [System.Text.Encoding]::ASCII.GetBytes($text)
            [Array]::Copy($textBytes, 0, $bytes, 100, $textBytes.Length)
        }
        
        # Ajouter des octets nuls si demandé
        if ($binaryFile.HasNulls) {
            for ($i = 0; $i -lt 100; $i++) {
                $bytes[$i * 2] = 0
            }
        }
        
        # Écrire les octets dans le fichier
        [System.IO.File]::WriteAllBytes($filePath, $bytes)
        
        Write-Host "Fichier créé : $($binaryFile.Name) (Binaire)" -ForegroundColor Green
        
        # Ajouter l'encodage attendu au dictionnaire
        $expectedEncodings[$filePath] = "BINARY"
    } catch {
        Write-Warning "Erreur lors de la création du fichier $($binaryFile.Name) : $_"
    }
}

# Générer le fichier d'encodages attendus si demandé
if ($GenerateExpectedEncodings) {
    $expectedEncodingsPath = Join-Path -Path $OutputDirectory -ChildPath "ExpectedEncodings.json"
    $expectedEncodings | ConvertTo-Json | Out-File -FilePath $expectedEncodingsPath -Encoding utf8
    
    Write-Host "Fichier d'encodages attendus créé : $expectedEncodingsPath" -ForegroundColor Green
}

Write-Host "`nGénération des fichiers d'échantillon terminée." -ForegroundColor Cyan
Write-Host "Nombre total de fichiers créés : $($encodings.Count + $binaryFiles.Count)" -ForegroundColor Cyan
