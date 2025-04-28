#Requires -Version 5.1
<#
.SYNOPSIS
    GÃ©nÃ¨re des fichiers d'Ã©chantillon avec diffÃ©rents encodages.

.DESCRIPTION
    Ce script gÃ©nÃ¨re des fichiers d'Ã©chantillon avec diffÃ©rents encodages
    pour tester la dÃ©tection d'encodage. Il crÃ©e des fichiers texte avec
    du contenu multilingue dans diffÃ©rents encodages.

.PARAMETER OutputDirectory
    Le rÃ©pertoire oÃ¹ les fichiers d'Ã©chantillon seront enregistrÃ©s.
    Par dÃ©faut, utilise le rÃ©pertoire 'samples/encoding'.

.PARAMETER GenerateExpectedEncodings
    Indique si un fichier JSON contenant les encodages attendus doit Ãªtre gÃ©nÃ©rÃ©.

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

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputDirectory -PathType Container)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $OutputDirectory" -ForegroundColor Green
}

# Contenu multilingue pour les tests
$multilingualContent = @"
=== Test de dÃ©tection d'encodage ===

== Texte latin (ASCII) ==
The quick brown fox jumps over the lazy dog.
0123456789 !@#$%^&*()_+-=[]{}|;':",./<>?

== Texte franÃ§ais (Latin-1) ==
Voici un texte en franÃ§ais avec des accents : Ã©Ã¨ÃªÃ«Ã Ã¢Ã¤Ã´Ã¶Ã¹Ã»Ã¼Ã¿Ã§
Les Å“ufs et les bÅ“ufs sont dans le prÃ©.

== Texte allemand (Latin-1) ==
Falsches Ãœben von Xylophonmusik quÃ¤lt jeden grÃ¶ÃŸeren Zwerg.
Die KÃ¶nigin und der KÃ¶nig leben in einem SchloÃŸ.

== Texte grec (UTF-8) ==
ÎžÎµÏƒÎºÎµÏ€Î¬Î¶Ï‰ Ï„Î·Î½ ÏˆÏ…Ï‡Î¿Ï†Î¸ÏŒÏÎ± Î²Î´ÎµÎ»Ï…Î³Î¼Î¯Î±.
ÎšÎ±Î»Î·Î¼Î­ÏÎ±, Ï€ÏŽÏ‚ ÎµÎ¯ÏƒÏ„Îµ ÏƒÎ®Î¼ÎµÏÎ±;

== Texte russe (UTF-8) ==
Ð¡ÑŠÐµÑˆÑŒ Ð¶Ðµ ÐµÑ‰Ñ‘ ÑÑ‚Ð¸Ñ… Ð¼ÑÐ³ÐºÐ¸Ñ… Ñ„Ñ€Ð°Ð½Ñ†ÑƒÐ·ÑÐºÐ¸Ñ… Ð±ÑƒÐ»Ð¾Ðº, Ð´Ð° Ð²Ñ‹Ð¿ÐµÐ¹ Ñ‡Ð°ÑŽ.
Ð¨Ð¸Ñ€Ð¾ÐºÐ°Ñ ÑÐ»ÐµÐºÑ‚Ñ€Ð¸Ñ„Ð¸ÐºÐ°Ñ†Ð¸Ñ ÑŽÐ¶Ð½Ñ‹Ñ… Ð³ÑƒÐ±ÐµÑ€Ð½Ð¸Ð¹ Ð´Ð°ÑÑ‚ Ð¼Ð¾Ñ‰Ð½Ñ‹Ð¹ Ñ‚Ð¾Ð»Ñ‡Ð¾Ðº Ð¿Ð¾Ð´ÑŠÑ‘Ð¼Ñƒ ÑÐµÐ»ÑŒÑÐºÐ¾Ð³Ð¾ Ñ…Ð¾Ð·ÑÐ¹ÑÑ‚Ð²Ð°.

== Texte japonais (UTF-8) ==
ã„ã‚ã¯ã«ã»ã¸ã¨ ã¡ã‚Šã¬ã‚‹ã‚’ ã‚ã‹ã‚ˆãŸã‚Œã ã¤ã­ãªã‚‰ã‚€
ç§ã¯æ—¥æœ¬èªžã‚’å‹‰å¼·ã—ã¦ã„ã¾ã™ã€‚

== Texte chinois (UTF-8) ==
æˆ‘èƒ½åžä¸‹çŽ»ç’ƒè€Œä¸ä¼¤èº«ä½“ã€‚
ä½ å¥½ï¼Œä¸–ç•Œï¼

== Texte arabe (UTF-8) ==
Ø£Ù†Ø§ Ù‚Ø§Ø¯Ø± Ø¹Ù„Ù‰ Ø£ÙƒÙ„ Ø§Ù„Ø²Ø¬Ø§Ø¬ Ùˆ Ù‡Ø°Ø§ Ù„Ø§ ÙŠØ¤Ù„Ù…Ù†ÙŠ.
Ù…Ø±Ø­Ø¨Ø§ Ø¨Ø§Ù„Ø¹Ø§Ù„Ù…!

== Texte hÃ©breu (UTF-8) ==
×× ×™ ×™×›×•×œ ×œ××›×•×œ ×–×›×•×›×™×ª ×•×–×” ×œ× ×ž×–×™×§ ×œ×™.
×©×œ×•× ×¢×•×œ×!

== Texte emoji (UTF-8) ==
ðŸ˜€ ðŸ˜ƒ ðŸ˜„ ðŸ˜ ðŸ˜† ðŸ˜… ðŸ˜‚ ðŸ¤£ ðŸ¥² â˜ºï¸ ðŸ˜Š ðŸ˜‡ ðŸ™‚ ðŸ™ƒ ðŸ˜‰ ðŸ˜Œ ðŸ˜ ðŸ¥° ðŸ˜˜ ðŸ˜— ðŸ˜™ ðŸ˜š ðŸ˜‹ ðŸ˜› ðŸ˜ ðŸ˜œ
ðŸ¶ ðŸ± ðŸ­ ðŸ¹ ðŸ° ðŸ¦Š ðŸ» ðŸ¼ ðŸ»â€â„ï¸ ðŸ¨ ðŸ¯ ðŸ¦ ðŸ® ðŸ· ðŸ½ ðŸ¸ ðŸµ ðŸ™ˆ ðŸ™‰ ðŸ™Š ðŸ’ ðŸ” ðŸ§ ðŸ¦ ðŸ¤ ðŸ£
"@

# DÃ©finir les encodages Ã  tester
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

# GÃ©nÃ©rer les fichiers d'Ã©chantillon
foreach ($encoding in $encodings) {
    $fileName = "sample_$($encoding.Name).txt"
    $filePath = Join-Path -Path $OutputDirectory -ChildPath $fileName
    
    try {
        # Ã‰crire le contenu dans le fichier avec l'encodage spÃ©cifiÃ©
        [System.IO.File]::WriteAllText($filePath, $multilingualContent, $encoding.Encoding)
        
        Write-Host "Fichier crÃ©Ã© : $fileName (Encodage: $($encoding.Name), BOM: $($encoding.HasBOM))" -ForegroundColor Green
        
        # Ajouter l'encodage attendu au dictionnaire
        $expectedEncodings[$filePath] = $encoding.Name
    } catch {
        Write-Warning "Erreur lors de la crÃ©ation du fichier $fileName : $_"
    }
}

# CrÃ©er des fichiers binaires pour tester la dÃ©tection
$binaryFiles = @(
    @{ Name = "sample_binary.bin"; Size = 1024 },
    @{ Name = "sample_binary_with_text.bin"; Size = 1024; HasText = $true },
    @{ Name = "sample_binary_with_nulls.bin"; Size = 1024; HasNulls = $true }
)

foreach ($binaryFile in $binaryFiles) {
    $filePath = Join-Path -Path $OutputDirectory -ChildPath $binaryFile.Name
    
    try {
        # CrÃ©er un tableau d'octets alÃ©atoires
        $bytes = [byte[]]::new($binaryFile.Size)
        $random = [System.Random]::new()
        $random.NextBytes($bytes)
        
        # Ajouter du texte si demandÃ©
        if ($binaryFile.HasText) {
            $text = "This is some text embedded in a binary file."
            $textBytes = [System.Text.Encoding]::ASCII.GetBytes($text)
            [Array]::Copy($textBytes, 0, $bytes, 100, $textBytes.Length)
        }
        
        # Ajouter des octets nuls si demandÃ©
        if ($binaryFile.HasNulls) {
            for ($i = 0; $i -lt 100; $i++) {
                $bytes[$i * 2] = 0
            }
        }
        
        # Ã‰crire les octets dans le fichier
        [System.IO.File]::WriteAllBytes($filePath, $bytes)
        
        Write-Host "Fichier crÃ©Ã© : $($binaryFile.Name) (Binaire)" -ForegroundColor Green
        
        # Ajouter l'encodage attendu au dictionnaire
        $expectedEncodings[$filePath] = "BINARY"
    } catch {
        Write-Warning "Erreur lors de la crÃ©ation du fichier $($binaryFile.Name) : $_"
    }
}

# GÃ©nÃ©rer le fichier d'encodages attendus si demandÃ©
if ($GenerateExpectedEncodings) {
    $expectedEncodingsPath = Join-Path -Path $OutputDirectory -ChildPath "ExpectedEncodings.json"
    $expectedEncodings | ConvertTo-Json | Out-File -FilePath $expectedEncodingsPath -Encoding utf8
    
    Write-Host "Fichier d'encodages attendus crÃ©Ã© : $expectedEncodingsPath" -ForegroundColor Green
}

Write-Host "`nGÃ©nÃ©ration des fichiers d'Ã©chantillon terminÃ©e." -ForegroundColor Cyan
Write-Host "Nombre total de fichiers crÃ©Ã©s : $($encodings.Count + $binaryFiles.Count)" -ForegroundColor Cyan
