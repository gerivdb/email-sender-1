# Script pour remplacer les caractÃ¨res accentuÃ©s par des caractÃ¨res non accentuÃ©s dans les fichiers JSON

# CrÃ©er un rÃ©pertoire pour les fichiers sans accents
$outputDir = "workflows-no-accents-reference"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
    Write-Host "Repertoire $outputDir cree."
}

# Traiter tous les fichiers JSON dans le rÃ©pertoire de rÃ©fÃ©rence
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
        
        # Remplacer les caractÃ¨res accentuÃ©s par des caractÃ¨res non accentuÃ©s
        $fixedContent = $content -replace 'Ã ', 'a' -replace 'Ã¡', 'a' -replace 'Ã¢', 'a' -replace 'Ã¤', 'a' -replace 'Ã£', 'a' -replace 'Ã¥', 'a'
        $fixedContent = $fixedContent -replace 'Ã§', 'c'
        $fixedContent = $fixedContent -replace 'Ã¨', 'e' -replace 'Ã©', 'e' -replace 'Ãª', 'e' -replace 'Ã«', 'e'
        $fixedContent = $fixedContent -replace 'Ã¬', 'i' -replace 'Ã­', 'i' -replace 'Ã®', 'i' -replace 'Ã¯', 'i'
        $fixedContent = $fixedContent -replace 'Ã±', 'n'
        $fixedContent = $fixedContent -replace 'Ã²', 'o' -replace 'Ã³', 'o' -replace 'Ã´', 'o' -replace 'Ãµ', 'o' -replace 'Ã¶', 'o'
        $fixedContent = $fixedContent -replace 'Ã¹', 'u' -replace 'Ãº', 'u' -replace 'Ã»', 'u' -replace 'Ã¼', 'u'
        $fixedContent = $fixedContent -replace 'Ã½', 'y' -replace 'Ã¿', 'y'
        
        $fixedContent = $fixedContent -replace 'Ã€', 'A' -replace 'Ã', 'A' -replace 'Ã‚', 'A' -replace 'Ã„', 'A' -replace 'Ãƒ', 'A' -replace 'Ã…', 'A'
        $fixedContent = $fixedContent -replace 'Ã‡', 'C'
        $fixedContent = $fixedContent -replace 'Ãˆ', 'E' -replace 'Ã‰', 'E' -replace 'ÃŠ', 'E' -replace 'Ã‹', 'E'
        $fixedContent = $fixedContent -replace 'ÃŒ', 'I' -replace 'Ã', 'I' -replace 'ÃŽ', 'I' -replace 'Ã', 'I'
        $fixedContent = $fixedContent -replace 'Ã‘', 'N'
        $fixedContent = $fixedContent -replace 'Ã’', 'O' -replace 'Ã“', 'O' -replace 'Ã”', 'O' -replace 'Ã•', 'O' -replace 'Ã–', 'O'
        $fixedContent = $fixedContent -replace 'Ã™', 'U' -replace 'Ãš', 'U' -replace 'Ã›', 'U' -replace 'Ãœ', 'U'
        $fixedContent = $fixedContent -replace 'Ã', 'Y' -replace 'Å¸', 'Y'
        
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
