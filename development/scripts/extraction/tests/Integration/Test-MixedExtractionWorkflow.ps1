# Test-MixedExtractionWorkflow.ps1
# Test d'intégration pour l'extraction de plusieurs types d'informations et le stockage dans une collection

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer un répertoire temporaire pour les fichiers de test
$tempDir = [System.IO.Path]::GetTempPath()
$testDir = Join-Path -Path $tempDir -ChildPath "ExtractedInfoTest"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer des fichiers de différents types pour les tests
$textFile = Join-Path -Path $testDir -ChildPath "sample.txt"
$jsonFile = Join-Path -Path $testDir -ChildPath "data.json"
$imageFile = Join-Path -Path $testDir -ChildPath "image.jpg"
$customFile = Join-Path -Path $testDir -ChildPath "custom.dat"

# Créer le contenu des fichiers
Set-Content -Path $textFile -Value "This is a sample text file for testing mixed extraction. It contains simple content for testing purposes."

$jsonData = @{
    Name = "Test Product"
    Price = 19.99
    InStock = $true
    Categories = @("Test", "Sample")
} | ConvertTo-Json
Set-Content -Path $jsonFile -Value $jsonData

# Créer un fichier binaire simulé pour l'image
$imageData = [byte[]]::new(1024) # 1 KB
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($imageData)
[System.IO.File]::WriteAllBytes($imageFile, $imageData)

# Créer un fichier personnalisé
Set-Content -Path $customFile -Value "Custom data format for testing extraction of unknown types."

# Fonctions d'extraction pour différents types de fichiers
# Fonction pour extraire du texte
function Extract-TextFromFile {
    param (
        [string]$FilePath,
        [string]$ExtractorName = "TextFileExtractor"
    )
    
    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "File not found: $FilePath"
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw
    
    # Créer une information extraite de type texte
    $textInfo = New-TextExtractedInfo -Source $FilePath -ExtractorName $ExtractorName -Text $content -Language "en"
    
    # Ajouter des métadonnées
    $textInfo = Add-ExtractedInfoMetadata -Info $textInfo -Key "FileSize" -Value (Get-Item -Path $FilePath).Length
    $textInfo = Add-ExtractedInfoMetadata -Info $textInfo -Key "FileCreationTime" -Value (Get-Item -Path $FilePath).CreationTime
    
    # Calculer un score de confiance
    $textInfo.ConfidenceScore = 85
    
    # Mettre à jour l'état de traitement
    $textInfo.ProcessingState = "Processed"
    
    # Valider l'information
    $isValid = Test-ExtractedInfo -Info $textInfo -UpdateObject
    
    return $textInfo
}

# Fonction pour extraire des données structurées
function Extract-StructuredDataFromFile {
    param (
        [string]$FilePath,
        [string]$ExtractorName = "JsonFileExtractor"
    )
    
    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "File not found: $FilePath"
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw
    
    # Convertir le contenu JSON en objet
    try {
        $data = ConvertFrom-Json -InputObject $content -ErrorAction Stop
        
        # Convertir l'objet en hashtable
        $hashtable = @{}
        foreach ($property in $data.PSObject.Properties) {
            $hashtable[$property.Name] = $property.Value
        }
        
        # Créer une information extraite de type données structurées
        $dataInfo = New-StructuredDataExtractedInfo -Source $FilePath -ExtractorName $ExtractorName -Data $hashtable -DataFormat "Hashtable"
        
        # Ajouter des métadonnées
        $dataInfo = Add-ExtractedInfoMetadata -Info $dataInfo -Key "FileSize" -Value (Get-Item -Path $FilePath).Length
        $dataInfo = Add-ExtractedInfoMetadata -Info $dataInfo -Key "FileCreationTime" -Value (Get-Item -Path $FilePath).CreationTime
        $dataInfo = Add-ExtractedInfoMetadata -Info $dataInfo -Key "DataFormat" -Value "JSON"
        
        # Calculer un score de confiance
        $dataInfo.ConfidenceScore = 90
        
        # Mettre à jour l'état de traitement
        $dataInfo.ProcessingState = "Processed"
        
        # Valider l'information
        $isValid = Test-ExtractedInfo -Info $dataInfo -UpdateObject
        
        return $dataInfo
    }
    catch {
        throw "Error extracting structured data from file: $_"
    }
}

# Fonction pour extraire des médias
function Extract-MediaFromFile {
    param (
        [string]$FilePath,
        [string]$ExtractorName = "MediaFileExtractor"
    )
    
    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "File not found: $FilePath"
    }
    
    # Déterminer le type de média en fonction de l'extension
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $mediaType = switch ($extension) {
        ".jpg" { "Image" }
        ".jpeg" { "Image" }
        ".png" { "Image" }
        ".gif" { "Image" }
        default { "Unknown" }
    }
    
    # Créer une information extraite de type média
    $mediaInfo = New-MediaExtractedInfo -Source $FilePath -ExtractorName $ExtractorName -MediaPath $FilePath -MediaType $mediaType
    
    # Ajouter des métadonnées
    $fileInfo = Get-Item -Path $FilePath
    $mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "FileSize" -Value $fileInfo.Length
    $mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "FileCreationTime" -Value $fileInfo.CreationTime
    $mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "FileExtension" -Value $extension
    
    # Ajouter des métadonnées spécifiques au type de média (simulées)
    $mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Width" -Value 1024
    $mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Height" -Value 768
    $mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "ColorDepth" -Value "24-bit"
    
    # Calculer un score de confiance
    $mediaInfo.ConfidenceScore = 80
    
    # Mettre à jour l'état de traitement
    $mediaInfo.ProcessingState = "Processed"
    
    # Valider l'information
    $isValid = Test-ExtractedInfo -Info $mediaInfo -UpdateObject
    
    return $mediaInfo
}

# Fonction pour extraire des informations personnalisées
function Extract-CustomInfo {
    param (
        [string]$FilePath,
        [string]$ExtractorName = "CustomExtractor"
    )
    
    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "File not found: $FilePath"
    }
    
    # Créer une information extraite de base
    $customInfo = New-ExtractedInfo -Source $FilePath -ExtractorName $ExtractorName
    
    # Ajouter des métadonnées
    $customInfo = Add-ExtractedInfoMetadata -Info $customInfo -Key "FileSize" -Value (Get-Item -Path $FilePath).Length
    $customInfo = Add-ExtractedInfoMetadata -Info $customInfo -Key "FileCreationTime" -Value (Get-Item -Path $FilePath).CreationTime
    $customInfo = Add-ExtractedInfoMetadata -Info $customInfo -Key "FileExtension" -Value [System.IO.Path]::GetExtension($FilePath).ToLower()
    $customInfo = Add-ExtractedInfoMetadata -Info $customInfo -Key "CustomType" -Value "Unknown"
    $customInfo = Add-ExtractedInfoMetadata -Info $customInfo -Key "ProcessingNotes" -Value "This is a custom file type that requires special processing."
    
    # Calculer un score de confiance
    $customInfo.ConfidenceScore = 60
    
    # Mettre à jour l'état de traitement
    $customInfo.ProcessingState = "Processed"
    
    # Valider l'information
    $isValid = Test-ExtractedInfo -Info $customInfo -UpdateObject
    
    return $customInfo
}

# Test du workflow complet
Write-Host "Test du workflow d'extraction de plusieurs types d'informations et stockage dans une collection" -ForegroundColor Cyan

# Étape 1: Créer une collection pour stocker les informations extraites
Write-Host "Étape 1: Créer une collection pour stocker les informations extraites" -ForegroundColor Cyan
$collection = New-ExtractedInfoCollection -Name "MixedExtractionCollection"

# Étape 2: Extraire les informations des fichiers
Write-Host "Étape 2: Extraire les informations des fichiers" -ForegroundColor Cyan
$textInfo = Extract-TextFromFile -FilePath $textFile
$dataInfo = Extract-StructuredDataFromFile -FilePath $jsonFile
$mediaInfo = Extract-MediaFromFile -FilePath $imageFile
$customInfo = Extract-CustomInfo -FilePath $customFile

# Étape 3: Ajouter les informations extraites à la collection
Write-Host "Étape 3: Ajouter les informations extraites à la collection" -ForegroundColor Cyan
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @($textInfo, $dataInfo, $mediaInfo, $customInfo)

# Étape 4: Vérifier que les informations ont été correctement ajoutées
Write-Host "Étape 4: Vérifier que les informations ont été correctement ajoutées" -ForegroundColor Cyan
$collectionItems = Get-ExtractedInfoFromCollection -Collection $collection

# Étape 5: Sauvegarder la collection dans un fichier
Write-Host "Étape 5: Sauvegarder la collection dans un fichier" -ForegroundColor Cyan
$collectionFile = Join-Path -Path $testDir -ChildPath "mixedCollection.json"
$collectionJson = ConvertTo-ExtractedInfoJson -InputObject $collection -Depth 10
Set-Content -Path $collectionFile -Value $collectionJson

# Étape 6: Obtenir des statistiques sur la collection
Write-Host "Étape 6: Obtenir des statistiques sur la collection" -ForegroundColor Cyan
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection

# Vérifications
$tests = @(
    @{ Test = "La collection n'est pas nulle"; Condition = $null -ne $collection }
    @{ Test = "La collection contient 4 éléments"; Condition = $collection.Items.Count -eq 4 }
    @{ Test = "La collection contient 1 élément de type TextExtractedInfo"; Condition = ($collection.Items | Where-Object { $_._Type -eq "TextExtractedInfo" }).Count -eq 1 }
    @{ Test = "La collection contient 1 élément de type StructuredDataExtractedInfo"; Condition = ($collection.Items | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" }).Count -eq 1 }
    @{ Test = "La collection contient 1 élément de type MediaExtractedInfo"; Condition = ($collection.Items | Where-Object { $_._Type -eq "MediaExtractedInfo" }).Count -eq 1 }
    @{ Test = "La collection contient 1 élément de type ExtractedInfo (custom)"; Condition = ($collection.Items | Where-Object { $_._Type -eq "ExtractedInfo" }).Count -eq 1 }
    @{ Test = "Tous les éléments ont un ID valide"; Condition = ($collection.Items | Where-Object { [guid]::TryParse($_.Id, [ref][guid]::Empty) }).Count -eq 4 }
    @{ Test = "Tous les éléments ont une source valide"; Condition = ($collection.Items | Where-Object { -not [string]::IsNullOrEmpty($_.Source) }).Count -eq 4 }
    @{ Test = "Tous les éléments ont un état de traitement 'Processed'"; Condition = ($collection.Items | Where-Object { $_.ProcessingState -eq "Processed" }).Count -eq 4 }
    @{ Test = "Tous les éléments ont un score de confiance > 0"; Condition = ($collection.Items | Where-Object { $_.ConfidenceScore -gt 0 }).Count -eq 4 }
    @{ Test = "Tous les éléments sont valides"; Condition = ($collection.Items | Where-Object { $_.IsValid -eq $true }).Count -eq 4 }
    @{ Test = "Tous les éléments ont des métadonnées FileSize"; Condition = ($collection.Items | Where-Object { $_.Metadata.ContainsKey("FileSize") }).Count -eq 4 }
    @{ Test = "Tous les éléments ont des métadonnées FileCreationTime"; Condition = ($collection.Items | Where-Object { $_.Metadata.ContainsKey("FileCreationTime") }).Count -eq 4 }
    @{ Test = "L'élément TextExtractedInfo a un texte non vide"; Condition = ($collection.Items | Where-Object { $_._Type -eq "TextExtractedInfo" -and -not [string]::IsNullOrEmpty($_.Text) }).Count -eq 1 }
    @{ Test = "L'élément StructuredDataExtractedInfo a des données non nulles"; Condition = ($collection.Items | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" -and $null -ne $_.Data }).Count -eq 1 }
    @{ Test = "L'élément MediaExtractedInfo a un chemin de média valide"; Condition = ($collection.Items | Where-Object { $_._Type -eq "MediaExtractedInfo" -and -not [string]::IsNullOrEmpty($_.MediaPath) }).Count -eq 1 }
    @{ Test = "L'élément custom a des métadonnées CustomType"; Condition = ($collection.Items | Where-Object { $_._Type -eq "ExtractedInfo" -and $_.Metadata.ContainsKey("CustomType") }).Count -eq 1 }
    @{ Test = "Le fichier de collection a été créé"; Condition = Test-Path -Path $collectionFile }
    @{ Test = "Le fichier de collection n'est pas vide"; Condition = (Get-Item -Path $collectionFile).Length -gt 0 }
    @{ Test = "Les statistiques indiquent 4 éléments"; Condition = $stats.TotalCount -eq 4 }
    @{ Test = "Les statistiques indiquent que tous les éléments sont valides"; Condition = $stats.ValidCount -eq 4 }
    @{ Test = "Les statistiques indiquent 3 types différents"; Condition = $stats.TypeDistribution.Count -eq 3 }
)

# Exécuter les tests
$success = $true
foreach ($test in $tests) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success = $false
    }
}

# Nettoyer les fichiers temporaires
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

# Résultat final
if ($success) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}
