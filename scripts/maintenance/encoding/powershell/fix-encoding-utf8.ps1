# Script pour corriger l'encodage des fichiers JSON en UTF-8 avec BOM

# Créer un répertoire pour les fichiers corrigés
$outputDir = "workflows-utf8"
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
        # Lire le contenu du fichier
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # Sauvegarder le fichier avec l'encodage UTF-8 avec BOM
        $outputPath = Join-Path -Path $outputDir -ChildPath $file.Name
        $content | Out-File -FilePath $outputPath -Encoding UTF8
        
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
