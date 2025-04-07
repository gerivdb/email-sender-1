# Script pour corriger l'encodage des fichiers JSON en UTF-8 avec BOM

# CrÃ©er un rÃ©pertoire pour les fichiers corrigÃ©s
$outputDir = "workflows-utf8"
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
        
        # Sauvegarder le fichier avec l'encodage UTF-8 avec BOM
        $outputPath = Join-Path -Path $outputDir -ChildPath $file.Name
        $content | Out-File -FilePath $outputPath -Encoding UTF8
        
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
