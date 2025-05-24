# Script pour corriger l'encodage des caractÃ¨res accentuÃ©s dans les fichiers JSON
# Ce script remplace les sÃ©quences d'Ã©chappement Unicode par les caractÃ¨res accentuÃ©s correspondants

# Fonction pour remplacer les sÃ©quences d'Ã©chappement Unicode par les caractÃ¨res accentuÃ©s
function Set-UnicodeEscapes {
    param (
        [string]$jsonContent
    )
    
    # Dictionnaire de correspondance pour les caractÃ¨res accentuÃ©s les plus courants
    $replacements = @{
        '\u00e0' = 'Ã '
        '\u00e1' = 'Ã¡'
        '\u00e2' = 'Ã¢'
        '\u00e3' = 'Ã£'
        '\u00e4' = 'Ã¤'
        '\u00e5' = 'Ã¥'
        '\u00e6' = 'Ã¦'
        '\u00e7' = 'Ã§'
        '\u00e8' = 'Ã¨'
        '\u00e9' = 'Ã©'
        '\u00ea' = 'Ãª'
        '\u00eb' = 'Ã«'
        '\u00ec' = 'Ã¬'
        '\u00ed' = 'Ã­'
        '\u00ee' = 'Ã®'
        '\u00ef' = 'Ã¯'
        '\u00f0' = 'Ã°'
        '\u00f1' = 'Ã±'
        '\u00f2' = 'Ã²'
        '\u00f3' = 'Ã³'
        '\u00f4' = 'Ã´'
        '\u00f5' = 'Ãµ'
        '\u00f6' = 'Ã¶'
        '\u00f9' = 'Ã¹'
        '\u00fa' = 'Ãº'
        '\u00fb' = 'Ã»'
        '\u00fc' = 'Ã¼'
        '\u00fd' = 'Ã½'
        '\u00ff' = 'Ã¿'
        '\u00c0' = 'Ã€'
        '\u00c1' = 'Ã'
        '\u00c2' = 'Ã‚'
        '\u00c3' = 'Ãƒ'
        '\u00c4' = 'Ã„'
        '\u00c5' = 'Ã…'
        '\u00c6' = 'Ã†'
        '\u00c7' = 'Ã‡'
        '\u00c8' = 'Ãˆ'
        '\u00c9' = 'Ã‰'
        '\u00ca' = 'ÃŠ'
        '\u00cb' = 'Ã‹'
        '\u00cc' = 'ÃŒ'
        '\u00cd' = 'Ã'
        '\u00ce' = 'ÃŽ'
        '\u00cf' = 'Ã'
        '\u00d0' = 'Ã'
        '\u00d1' = 'Ã‘'
        '\u00d2' = 'Ã’'
        '\u00d3' = 'Ã“'
        '\u00d4' = 'Ã”'
        '\u00d5' = 'Ã•'
        '\u00d6' = 'Ã–'
        '\u00d9' = 'Ã™'
        '\u00da' = 'Ãš'
        '\u00db' = 'Ã›'
        '\u00dc' = 'Ãœ'
        '\u00dd' = 'Ã'
        '\u0153' = 'Å“'
        '\u0152' = 'Å’'
    }
    
    # Remplacer toutes les sÃ©quences d'Ã©chappement par les caractÃ¨res correspondants
    foreach ($key in $replacements.Keys) {
        $jsonContent = $jsonContent -replace $key, $replacements[$key]
    }
    
    # Fonction plus gÃ©nÃ©rique pour capturer et remplacer toutes les sÃ©quences d'Ã©chappement Unicode
    $jsonContent = [regex]::Replace($jsonContent, '\\u([0-9a-fA-F]{4})', {
        param($match)
        $unicodeValue = [int]::Parse($match.Groups[1].Value, [System.Globalization.NumberStyles]::HexNumber)
        [char]$unicodeValue
    })
    
    return $jsonContent
}

# CrÃ©er un rÃ©pertoire pour les fichiers corrigÃ©s
$outputDir = "workflows-fixed"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
    Write-Host "RÃ©pertoire $outputDir crÃ©Ã©."
}

# Traiter tous les fichiers JSON dans le rÃ©pertoire workflows
$workflowFiles = Get-ChildItem -Path "workflows" -Filter "*.json"
$successCount = 0

foreach ($file in $workflowFiles) {
    Write-Host "Traitement du fichier: $($file.Name)" -NoNewline
    
    try {
        # Lire le contenu du fichier avec l'encodage UTF-8
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # Corriger l'encodage des caractÃ¨res
        $fixedContent = Set-UnicodeEscapes -jsonContent $content
        
        # Sauvegarder le fichier corrigÃ©
        $outputPath = Join-Path -Path $outputDir -ChildPath $file.Name
        $fixedContent | Out-File -FilePath $outputPath -Encoding UTF8 -NoNewline
        
        Write-Host " - SuccÃ¨s!" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host " - Ã‰chec!" -ForegroundColor Red
        Write-Host "  Erreur: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nTraitement terminÃ©: $successCount/$($workflowFiles.Count) fichiers corrigÃ©s."
Write-Host "Les fichiers corrigÃ©s se trouvent dans le rÃ©pertoire: $outputDir"
Write-Host "`nVous pouvez maintenant importer ces fichiers corrigÃ©s dans n8n."

