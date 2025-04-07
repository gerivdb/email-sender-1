# Script pour corriger l'encodage des caractÃ¨res accentuÃ©s dans les fichiers JSON

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
        # Lire le contenu du fichier
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # Utiliser une approche plus simple pour remplacer les sÃ©quences d'Ã©chappement Unicode
        # Cette mÃ©thode utilise la classe .NET pour dÃ©coder les sÃ©quences d'Ã©chappement
        $fixedContent = [System.Text.RegularExpressions.Regex]::Replace(
            $content,
            '\\u([0-9a-fA-F]{4})',
            {
                param($match)
                $codePoint = [Convert]::ToInt32($match.Groups[1].Value, 16)
                [char]::ConvertFromUtf32($codePoint)
            }
        )
        
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
