# Script pour corriger l'encodage des caractères accentués dans les fichiers JSON
# Ce script remplace les séquences d'échappement Unicode par les caractères accentués correspondants

# Fonction pour remplacer les séquences d'échappement Unicode par les caractères accentués
function Replace-UnicodeEscapes {
    param (
        [string]$jsonContent
    )
    
    # Dictionnaire de correspondance pour les caractères accentués les plus courants
    $replacements = @{
        '\u00e0' = 'à'
        '\u00e1' = 'á'
        '\u00e2' = 'â'
        '\u00e3' = 'ã'
        '\u00e4' = 'ä'
        '\u00e5' = 'å'
        '\u00e6' = 'æ'
        '\u00e7' = 'ç'
        '\u00e8' = 'è'
        '\u00e9' = 'é'
        '\u00ea' = 'ê'
        '\u00eb' = 'ë'
        '\u00ec' = 'ì'
        '\u00ed' = 'í'
        '\u00ee' = 'î'
        '\u00ef' = 'ï'
        '\u00f0' = 'ð'
        '\u00f1' = 'ñ'
        '\u00f2' = 'ò'
        '\u00f3' = 'ó'
        '\u00f4' = 'ô'
        '\u00f5' = 'õ'
        '\u00f6' = 'ö'
        '\u00f9' = 'ù'
        '\u00fa' = 'ú'
        '\u00fb' = 'û'
        '\u00fc' = 'ü'
        '\u00fd' = 'ý'
        '\u00ff' = 'ÿ'
        '\u00c0' = 'À'
        '\u00c1' = 'Á'
        '\u00c2' = 'Â'
        '\u00c3' = 'Ã'
        '\u00c4' = 'Ä'
        '\u00c5' = 'Å'
        '\u00c6' = 'Æ'
        '\u00c7' = 'Ç'
        '\u00c8' = 'È'
        '\u00c9' = 'É'
        '\u00ca' = 'Ê'
        '\u00cb' = 'Ë'
        '\u00cc' = 'Ì'
        '\u00cd' = 'Í'
        '\u00ce' = 'Î'
        '\u00cf' = 'Ï'
        '\u00d0' = 'Ð'
        '\u00d1' = 'Ñ'
        '\u00d2' = 'Ò'
        '\u00d3' = 'Ó'
        '\u00d4' = 'Ô'
        '\u00d5' = 'Õ'
        '\u00d6' = 'Ö'
        '\u00d9' = 'Ù'
        '\u00da' = 'Ú'
        '\u00db' = 'Û'
        '\u00dc' = 'Ü'
        '\u00dd' = 'Ý'
        '\u0153' = 'œ'
        '\u0152' = 'Œ'
    }
    
    # Remplacer toutes les séquences d'échappement par les caractères correspondants
    foreach ($key in $replacements.Keys) {
        $jsonContent = $jsonContent -replace $key, $replacements[$key]
    }
    
    # Fonction plus générique pour capturer et remplacer toutes les séquences d'échappement Unicode
    $jsonContent = [regex]::Replace($jsonContent, '\\u([0-9a-fA-F]{4})', {
        param($match)
        $unicodeValue = [int]::Parse($match.Groups[1].Value, [System.Globalization.NumberStyles]::HexNumber)
        [char]$unicodeValue
    })
    
    return $jsonContent
}

# Créer un répertoire pour les fichiers corrigés
$outputDir = "workflows-fixed"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
    Write-Host "Répertoire $outputDir créé."
}

# Traiter tous les fichiers JSON dans le répertoire workflows
$workflowFiles = Get-ChildItem -Path "workflows" -Filter "*.json"
$successCount = 0

foreach ($file in $workflowFiles) {
    Write-Host "Traitement du fichier: $($file.Name)" -NoNewline
    
    try {
        # Lire le contenu du fichier avec l'encodage UTF-8
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # Corriger l'encodage des caractères
        $fixedContent = Replace-UnicodeEscapes -jsonContent $content
        
        # Sauvegarder le fichier corrigé
        $outputPath = Join-Path -Path $outputDir -ChildPath $file.Name
        $fixedContent | Out-File -FilePath $outputPath -Encoding UTF8 -NoNewline
        
        Write-Host " - Succès!" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host " - Échec!" -ForegroundColor Red
        Write-Host "  Erreur: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nTraitement terminé: $successCount/$($workflowFiles.Count) fichiers corrigés."
Write-Host "Les fichiers corrigés se trouvent dans le répertoire: $outputDir"
Write-Host "`nVous pouvez maintenant importer ces fichiers corrigés dans n8n."
