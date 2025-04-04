# Script pour remplacer les caractères accentués par des caractères non accentués dans les fichiers JSON

# Créer un répertoire pour les fichiers sans accents
$outputDir = "workflows-no-accents-reference"
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
        
        # Remplacer les caractères accentués par des caractères non accentués
        $fixedContent = $content -replace 'à', 'a' -replace 'á', 'a' -replace 'â', 'a' -replace 'ä', 'a' -replace 'ã', 'a' -replace 'å', 'a'
        $fixedContent = $fixedContent -replace 'ç', 'c'
        $fixedContent = $fixedContent -replace 'è', 'e' -replace 'é', 'e' -replace 'ê', 'e' -replace 'ë', 'e'
        $fixedContent = $fixedContent -replace 'ì', 'i' -replace 'í', 'i' -replace 'î', 'i' -replace 'ï', 'i'
        $fixedContent = $fixedContent -replace 'ñ', 'n'
        $fixedContent = $fixedContent -replace 'ò', 'o' -replace 'ó', 'o' -replace 'ô', 'o' -replace 'õ', 'o' -replace 'ö', 'o'
        $fixedContent = $fixedContent -replace 'ù', 'u' -replace 'ú', 'u' -replace 'û', 'u' -replace 'ü', 'u'
        $fixedContent = $fixedContent -replace 'ý', 'y' -replace 'ÿ', 'y'
        
        $fixedContent = $fixedContent -replace 'À', 'A' -replace 'Á', 'A' -replace 'Â', 'A' -replace 'Ä', 'A' -replace 'Ã', 'A' -replace 'Å', 'A'
        $fixedContent = $fixedContent -replace 'Ç', 'C'
        $fixedContent = $fixedContent -replace 'È', 'E' -replace 'É', 'E' -replace 'Ê', 'E' -replace 'Ë', 'E'
        $fixedContent = $fixedContent -replace 'Ì', 'I' -replace 'Í', 'I' -replace 'Î', 'I' -replace 'Ï', 'I'
        $fixedContent = $fixedContent -replace 'Ñ', 'N'
        $fixedContent = $fixedContent -replace 'Ò', 'O' -replace 'Ó', 'O' -replace 'Ô', 'O' -replace 'Õ', 'O' -replace 'Ö', 'O'
        $fixedContent = $fixedContent -replace 'Ù', 'U' -replace 'Ú', 'U' -replace 'Û', 'U' -replace 'Ü', 'U'
        $fixedContent = $fixedContent -replace 'Ý', 'Y' -replace 'Ÿ', 'Y'
        
        # Sauvegarder le fichier sans accents
        $outputPath = Join-Path -Path $outputDir -ChildPath $file.Name
        $fixedContent | Out-File -FilePath $outputPath -Encoding UTF8 -NoNewline
        
        Write-Host " - Succes!" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host " - Echec!" -ForegroundColor Red
        Write-Host "  Erreur: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nTraitement termine: $successCount/$($workflowFiles.Count) fichiers traites."
Write-Host "Les fichiers sans accents se trouvent dans le repertoire: $outputDir"
Write-Host "`nVous pouvez maintenant importer ces fichiers dans n8n."
