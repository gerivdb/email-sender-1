# Script pour remplacer les caractÃ¨res accentuÃ©s par des caractÃ¨res non accentuÃ©s dans les fichiers JSON
# tout en prÃ©servant la structure JSON

# Fonction pour remplacer les caractÃ¨res accentuÃ©s par des caractÃ¨res non accentuÃ©s
function Remove-Accents {
    param (
        [string]$text
    )
    
    $replacements = @{
        'Ã ' = 'a'; 'Ã¡' = 'a'; 'Ã¢' = 'a'; 'Ã£' = 'a'; 'Ã¤' = 'a'; 'Ã¥' = 'a'; 'Ã¦' = 'ae'
        'Ã§' = 'c'
        'Ã¨' = 'e'; 'Ã©' = 'e'; 'Ãª' = 'e'; 'Ã«' = 'e'
        'Ã¬' = 'i'; 'Ã­' = 'i'; 'Ã®' = 'i'; 'Ã¯' = 'i'
        'Ã±' = 'n'
        'Ã²' = 'o'; 'Ã³' = 'o'; 'Ã´' = 'o'; 'Ãµ' = 'o'; 'Ã¶' = 'o'; 'Ã¸' = 'o'; 'Å“' = 'oe'
        'Ã¹' = 'u'; 'Ãº' = 'u'; 'Ã»' = 'u'; 'Ã¼' = 'u'
        'Ã½' = 'y'; 'Ã¿' = 'y'
        'Ã€' = 'A'; 'Ã' = 'A'; 'Ã‚' = 'A'; 'Ãƒ' = 'A'; 'Ã„' = 'A'; 'Ã…' = 'A'; 'Ã†' = 'AE'
        'Ã‡' = 'C'
        'Ãˆ' = 'E'; 'Ã‰' = 'E'; 'ÃŠ' = 'E'; 'Ã‹' = 'E'
        'ÃŒ' = 'I'; 'Ã' = 'I'; 'ÃŽ' = 'I'; 'Ã' = 'I'
        'Ã‘' = 'N'
        'Ã’' = 'O'; 'Ã“' = 'O'; 'Ã”' = 'O'; 'Ã•' = 'O'; 'Ã–' = 'O'; 'Ã˜' = 'O'; 'Å’' = 'OE'
        'Ã™' = 'U'; 'Ãš' = 'U'; 'Ã›' = 'U'; 'Ãœ' = 'U'
        'Ã' = 'Y'; 'Å¸' = 'Y'
    }
    
    foreach ($key in $replacements.Keys) {
        $text = $text -replace $key, $replacements[$key]
    }
    
    return $text
}

# Fonction rÃ©cursive pour traiter tous les champs d'un objet JSON
function Process-JsonObject {
    param (
        $jsonObject
    )
    
    if ($null -eq $jsonObject) {
        return $null
    }
    
    if ($jsonObject -is [string]) {
        return Remove-Accents -text $jsonObject
    }
    
    if ($jsonObject -is [array]) {
        $result = @()
        foreach ($item in $jsonObject) {
            $result += Process-JsonObject -jsonObject $item
        }
        return $result
    }
    
    if ($jsonObject -is [System.Management.Automation.PSCustomObject]) {
        $properties = $jsonObject.PSObject.Properties
        foreach ($property in $properties) {
            $property.Value = Process-JsonObject -jsonObject $property.Value
        }
    }
    
    return $jsonObject
}

# CrÃ©er un rÃ©pertoire pour les fichiers sans accents
$outputDir = "workflows-no-accents"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
    Write-Host "RÃ©pertoire $outputDir crÃ©Ã©."
}

# Traiter tous les fichiers JSON dans le rÃ©pertoire workflows
$workflowsDir = Read-Host "Entrez le chemin du rÃ©pertoire contenant les fichiers JSON (par dÃ©faut: workflows)"
if ([string]::IsNullOrEmpty($workflowsDir)) {
    $workflowsDir = "workflows"
}

$workflowFiles = Get-ChildItem -Path $workflowsDir -Filter "*.json"
$successCount = 0

foreach ($file in $workflowFiles) {
    Write-Host "Traitement du fichier: $($file.Name)" -NoNewline
    
    try {
        # Lire le contenu du fichier
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # Convertir le contenu JSON en objet PowerShell
        $jsonObject = $content | ConvertFrom-Json
        
        # Traiter tous les champs de l'objet JSON
        $processedObject = Process-JsonObject -jsonObject $jsonObject
        
        # Convertir l'objet PowerShell en JSON
        $fixedContent = $processedObject | ConvertTo-Json -Depth 100
        
        # Sauvegarder le fichier sans accents
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

Write-Host "`nTraitement terminÃ©: $successCount/$($workflowFiles.Count) fichiers traitÃ©s."
Write-Host "Les fichiers sans accents se trouvent dans le rÃ©pertoire: $outputDir"
Write-Host "`nVous pouvez maintenant importer ces fichiers dans n8n."
