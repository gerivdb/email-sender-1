# Script pour corriger les noms des workflows en remplaçant les caractères accentués

# Créer un répertoire pour les fichiers corrigés
$outputDir = "workflows-fixed-names"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
    Write-Host "Repertoire $outputDir cree."
}

# Traiter tous les fichiers JSON dans le répertoire de référence
$workflowsDir = "D:\DO\WEB\N8N_tests\scripts_ json_a_ tester\EMAIL_SENDER_1\workflows\re-import_pour_analyse"
if (-not (Test-Path $workflowsDir)) {
    Write-Host "Le repertoire de reference n'existe pas: $workflowsDir" -ForegroundColor Red
    exit
}

$workflowFiles = Get-ChildItem -Path $workflowsDir -Filter "*.json"
$successCount = 0

foreach ($file in $workflowFiles) {
    Write-Host "Traitement du fichier: $($file.Name)" -NoNewline
    
    try {
        # Lire le contenu du fichier
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # Convertir le contenu JSON en objet PowerShell
        $workflowJson = $content | ConvertFrom-Json
        
        # Remplacer les caractères accentués dans le nom du workflow
        $originalName = $workflowJson.name
        $newName = $originalName -replace "é", "e" -replace "è", "e" -replace "ê", "e" -replace "à", "a" -replace "ù", "u" -replace "ç", "c" -replace "î", "i" -replace "ï", "i" -replace "ô", "o" -replace "É", "E" -replace "È", "E" -replace "Ê", "E" -replace "À", "A" -replace "Ù", "U" -replace "Ç", "C" -replace "Î", "I" -replace "Ï", "I" -replace "Ô", "O"
        
        Write-Host " - Nom original: $originalName"
        Write-Host " - Nouveau nom: $newName"
        
        # Mettre à jour le nom du workflow
        $workflowJson.name = $newName
        
        # Convertir l'objet PowerShell en JSON
        $updatedContent = $workflowJson | ConvertTo-Json -Depth 100
        
        # Sauvegarder le fichier avec le nom corrigé
        $outputPath = Join-Path -Path $outputDir -ChildPath $file.Name
        $updatedContent | Out-File -FilePath $outputPath -Encoding UTF8
        
        Write-Host " - Succes!" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host " - Echec!" -ForegroundColor Red
        Write-Host "  Erreur: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nTraitement termine: $successCount/$($workflowFiles.Count) fichiers traites."
Write-Host "Les fichiers avec noms corriges se trouvent dans le repertoire: $outputDir"
Write-Host "`nVous pouvez maintenant importer ces fichiers dans n8n."
