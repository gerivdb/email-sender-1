# Test-MediaExtractionWorkflow.ps1
# Test d'intégration pour l'extraction de médias et le stockage dans une collection

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer un répertoire temporaire pour les fichiers de test
$tempDir = [System.IO.Path]::GetTempPath()
$testDir = Join-Path -Path $tempDir -ChildPath "ExtractedInfoTest"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer des fichiers média simulés pour les tests
$imageFile1 = Join-Path -Path $testDir -ChildPath "image1.jpg"
$imageFile2 = Join-Path -Path $testDir -ChildPath "image2.png"
$videoFile = Join-Path -Path $testDir -ChildPath "video1.mp4"
$audioFile = Join-Path -Path $testDir -ChildPath "audio1.mp3"

# Créer des fichiers binaires simulés
$imageData1 = [byte[]]::new(1024) # 1 KB
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($imageData1)
[System.IO.File]::WriteAllBytes($imageFile1, $imageData1)

$imageData2 = [byte[]]::new(2048) # 2 KB
$rng.GetBytes($imageData2)
[System.IO.File]::WriteAllBytes($imageFile2, $imageData2)

$videoData = [byte[]]::new(4096) # 4 KB
$rng.GetBytes($videoData)
[System.IO.File]::WriteAllBytes($videoFile, $videoData)

$audioData = [byte[]]::new(3072) # 3 KB
$rng.GetBytes($audioData)
[System.IO.File]::WriteAllBytes($audioFile, $audioData)

# Fonction simulant un extracteur de médias
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
        ".mp4" { "Video" }
        ".avi" { "Video" }
        ".mov" { "Video" }
        ".mp3" { "Audio" }
        ".wav" { "Audio" }
        ".flac" { "Audio" }
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
    switch ($mediaType) {
        "Image" {
            $mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Width" -Value (Get-Random -Minimum 800 -Maximum 3000)
            $mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Height" -Value (Get-Random -Minimum 600 -Maximum 2000)
            $mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "ColorDepth" -Value "24-bit"
        }
        "Video" {
            $mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Duration" -Value (Get-Random -Minimum 30 -Maximum 600)
            $mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "FrameRate" -Value "30 fps"
            $mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Resolution" -Value "1920x1080"
        }
        "Audio" {
            $mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Duration" -Value (Get-Random -Minimum 60 -Maximum 300)
            $mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "BitRate" -Value "320 kbps"
            $mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Channels" -Value "Stereo"
        }
    }
    
    # Calculer un score de confiance basé sur le type de média et la taille du fichier
    $confidenceScore = switch ($mediaType) {
        "Image" { [Math]::Min(100, [Math]::Max(0, 70 + $fileInfo.Length / 1024)) }
        "Video" { [Math]::Min(100, [Math]::Max(0, 80 + $fileInfo.Length / 2048)) }
        "Audio" { [Math]::Min(100, [Math]::Max(0, 75 + $fileInfo.Length / 1536)) }
        default { 50 }
    }
    $mediaInfo.ConfidenceScore = $confidenceScore
    
    # Mettre à jour l'état de traitement
    $mediaInfo.ProcessingState = "Processed"
    
    # Valider l'information
    $isValid = Test-ExtractedInfo -Info $mediaInfo -UpdateObject
    
    return $mediaInfo
}

# Test du workflow complet
Write-Host "Test du workflow d'extraction de médias et stockage dans une collection" -ForegroundColor Cyan

# Étape 1: Créer une collection pour stocker les informations extraites
Write-Host "Étape 1: Créer une collection pour stocker les informations extraites" -ForegroundColor Cyan
$collection = New-ExtractedInfoCollection -Name "MediaExtractionCollection"

# Étape 2: Extraire les médias des fichiers
Write-Host "Étape 2: Extraire les médias des fichiers" -ForegroundColor Cyan
$mediaInfo1 = Extract-MediaFromFile -FilePath $imageFile1
$mediaInfo2 = Extract-MediaFromFile -FilePath $imageFile2
$mediaInfo3 = Extract-MediaFromFile -FilePath $videoFile
$mediaInfo4 = Extract-MediaFromFile -FilePath $audioFile

# Étape 3: Ajouter les informations extraites à la collection
Write-Host "Étape 3: Ajouter les informations extraites à la collection" -ForegroundColor Cyan
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @($mediaInfo1, $mediaInfo2, $mediaInfo3, $mediaInfo4)

# Étape 4: Vérifier que les informations ont été correctement ajoutées
Write-Host "Étape 4: Vérifier que les informations ont été correctement ajoutées" -ForegroundColor Cyan
$collectionItems = Get-ExtractedInfoFromCollection -Collection $collection

# Étape 5: Sauvegarder la collection dans un fichier
Write-Host "Étape 5: Sauvegarder la collection dans un fichier" -ForegroundColor Cyan
$collectionFile = Join-Path -Path $testDir -ChildPath "mediaCollection.json"
$collectionJson = ConvertTo-ExtractedInfoJson -InputObject $collection -Depth 10
Set-Content -Path $collectionFile -Value $collectionJson

# Étape 6: Obtenir des statistiques sur la collection
Write-Host "Étape 6: Obtenir des statistiques sur la collection" -ForegroundColor Cyan
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection

# Vérifications
$tests = @(
    @{ Test = "La collection n'est pas nulle"; Condition = $null -ne $collection }
    @{ Test = "La collection contient 4 éléments"; Condition = $collection.Items.Count -eq 4 }
    @{ Test = "Tous les éléments sont de type MediaExtractedInfo"; Condition = ($collection.Items | Where-Object { $_._Type -eq "MediaExtractedInfo" }).Count -eq 4 }
    @{ Test = "Tous les éléments ont un ID valide"; Condition = ($collection.Items | Where-Object { [guid]::TryParse($_.Id, [ref][guid]::Empty) }).Count -eq 4 }
    @{ Test = "Tous les éléments ont une source valide"; Condition = ($collection.Items | Where-Object { -not [string]::IsNullOrEmpty($_.Source) }).Count -eq 4 }
    @{ Test = "Tous les éléments ont un chemin de média valide"; Condition = ($collection.Items | Where-Object { -not [string]::IsNullOrEmpty($_.MediaPath) }).Count -eq 4 }
    @{ Test = "Tous les éléments ont un type de média valide"; Condition = ($collection.Items | Where-Object { -not [string]::IsNullOrEmpty($_.MediaType) }).Count -eq 4 }
    @{ Test = "Il y a 2 éléments de type Image"; Condition = ($collection.Items | Where-Object { $_.MediaType -eq "Image" }).Count -eq 2 }
    @{ Test = "Il y a 1 élément de type Video"; Condition = ($collection.Items | Where-Object { $_.MediaType -eq "Video" }).Count -eq 1 }
    @{ Test = "Il y a 1 élément de type Audio"; Condition = ($collection.Items | Where-Object { $_.MediaType -eq "Audio" }).Count -eq 1 }
    @{ Test = "Tous les éléments ont des métadonnées FileSize"; Condition = ($collection.Items | Where-Object { $_.Metadata.ContainsKey("FileSize") }).Count -eq 4 }
    @{ Test = "Tous les éléments ont des métadonnées FileCreationTime"; Condition = ($collection.Items | Where-Object { $_.Metadata.ContainsKey("FileCreationTime") }).Count -eq 4 }
    @{ Test = "Tous les éléments ont des métadonnées FileExtension"; Condition = ($collection.Items | Where-Object { $_.Metadata.ContainsKey("FileExtension") }).Count -eq 4 }
    @{ Test = "Les éléments Image ont des métadonnées Width et Height"; Condition = ($collection.Items | Where-Object { $_.MediaType -eq "Image" -and $_.Metadata.ContainsKey("Width") -and $_.Metadata.ContainsKey("Height") }).Count -eq 2 }
    @{ Test = "L'élément Video a des métadonnées Duration et FrameRate"; Condition = ($collection.Items | Where-Object { $_.MediaType -eq "Video" -and $_.Metadata.ContainsKey("Duration") -and $_.Metadata.ContainsKey("FrameRate") }).Count -eq 1 }
    @{ Test = "L'élément Audio a des métadonnées Duration et BitRate"; Condition = ($collection.Items | Where-Object { $_.MediaType -eq "Audio" -and $_.Metadata.ContainsKey("Duration") -and $_.Metadata.ContainsKey("BitRate") }).Count -eq 1 }
    @{ Test = "Le fichier de collection a été créé"; Condition = Test-Path -Path $collectionFile }
    @{ Test = "Le fichier de collection n'est pas vide"; Condition = (Get-Item -Path $collectionFile).Length -gt 0 }
    @{ Test = "Les statistiques indiquent 4 éléments"; Condition = $stats.TotalCount -eq 4 }
    @{ Test = "Les statistiques indiquent que tous les éléments sont valides"; Condition = $stats.ValidCount -eq 4 }
    @{ Test = "Les statistiques indiquent le type MediaExtractedInfo"; Condition = $stats.TypeDistribution.ContainsKey("MediaExtractedInfo") -and $stats.TypeDistribution["MediaExtractedInfo"] -eq 4 }
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
