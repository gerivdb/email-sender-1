# Script pour remplacer les caractères accentués par des caractères non accentués dans les fichiers JSON
# tout en préservant la structure JSON

# Fonction pour remplacer les caractères accentués par des caractères non accentués
function Remove-Accents {
    param (
        [string]$text
    )
    
    $replacements = @{
        'à' = 'a'; 'á' = 'a'; 'â' = 'a'; 'ã' = 'a'; 'ä' = 'a'; 'å' = 'a'; 'æ' = 'ae'
        'ç' = 'c'
        'è' = 'e'; 'é' = 'e'; 'ê' = 'e'; 'ë' = 'e'
        'ì' = 'i'; 'í' = 'i'; 'î' = 'i'; 'ï' = 'i'
        'ñ' = 'n'
        'ò' = 'o'; 'ó' = 'o'; 'ô' = 'o'; 'õ' = 'o'; 'ö' = 'o'; 'ø' = 'o'; 'œ' = 'oe'
        'ù' = 'u'; 'ú' = 'u'; 'û' = 'u'; 'ü' = 'u'
        'ý' = 'y'; 'ÿ' = 'y'
        'À' = 'A'; 'Á' = 'A'; 'Â' = 'A'; 'Ã' = 'A'; 'Ä' = 'A'; 'Å' = 'A'; 'Æ' = 'AE'
        'Ç' = 'C'
        'È' = 'E'; 'É' = 'E'; 'Ê' = 'E'; 'Ë' = 'E'
        'Ì' = 'I'; 'Í' = 'I'; 'Î' = 'I'; 'Ï' = 'I'
        'Ñ' = 'N'
        'Ò' = 'O'; 'Ó' = 'O'; 'Ô' = 'O'; 'Õ' = 'O'; 'Ö' = 'O'; 'Ø' = 'O'; 'Œ' = 'OE'
        'Ù' = 'U'; 'Ú' = 'U'; 'Û' = 'U'; 'Ü' = 'U'
        'Ý' = 'Y'; 'Ÿ' = 'Y'
    }
    
    foreach ($key in $replacements.Keys) {
        $text = $text -replace $key, $replacements[$key]
    }
    
    return $text
}

# Fonction récursive pour traiter tous les champs d'un objet JSON
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

# Créer un répertoire pour les fichiers sans accents
$outputDir = "workflows-no-accents"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
    Write-Host "Répertoire $outputDir créé."
}

# Traiter tous les fichiers JSON dans le répertoire workflows
$workflowsDir = Read-Host "Entrez le chemin du répertoire contenant les fichiers JSON (par défaut: workflows)"
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
        
        Write-Host " - Succès!" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host " - Échec!" -ForegroundColor Red
        Write-Host "  Erreur: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nTraitement terminé: $successCount/$($workflowFiles.Count) fichiers traités."
Write-Host "Les fichiers sans accents se trouvent dans le répertoire: $outputDir"
Write-Host "`nVous pouvez maintenant importer ces fichiers dans n8n."
