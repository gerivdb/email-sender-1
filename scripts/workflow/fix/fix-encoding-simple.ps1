# Script pour corriger l'encodage des caractères accentués dans les fichiers JSON

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
        # Lire le contenu du fichier
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # Utiliser une approche plus simple pour remplacer les séquences d'échappement Unicode
        # Cette méthode utilise la classe .NET pour décoder les séquences d'échappement
        $fixedContent = [System.Text.RegularExpressions.Regex]::Replace(
            $content,
            '\\u([0-9a-fA-F]{4})',
            {
                param($match)
                $codePoint = [Convert]::ToInt32($match.Groups[1].Value, 16)
                [char]::ConvertFromUtf32($codePoint)
            }
        )
        
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
