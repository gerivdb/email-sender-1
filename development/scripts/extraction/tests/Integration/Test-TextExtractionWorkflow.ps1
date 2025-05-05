# Test-TextExtractionWorkflow.ps1
# Test d'intégration pour l'extraction de texte et le stockage dans une collection

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer un répertoire temporaire pour les fichiers de test
$tempDir = [System.IO.Path]::GetTempPath()
$testDir = Join-Path -Path $tempDir -ChildPath "ExtractedInfoTest"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer des fichiers texte pour les tests
$textFile1 = Join-Path -Path $testDir -ChildPath "sample1.txt"
$textFile2 = Join-Path -Path $testDir -ChildPath "sample2.txt"
$textFile3 = Join-Path -Path $testDir -ChildPath "sample3.txt"

Set-Content -Path $textFile1 -Value "This is a sample text file for testing text extraction. It contains simple content for testing purposes."
Set-Content -Path $textFile2 -Value "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
Set-Content -Path $textFile3 -Value "The quick brown fox jumps over the lazy dog. This sentence contains all letters of the English alphabet."

# Fonction simulant un extracteur de texte
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
    
    # Calculer un score de confiance basé sur la longueur du texte (exemple simple)
    $confidenceScore = [Math]::Min(100, [Math]::Max(0, $content.Length / 10))
    $textInfo.ConfidenceScore = $confidenceScore
    
    # Mettre à jour l'état de traitement
    $textInfo.ProcessingState = "Processed"
    
    # Valider l'information
    $isValid = Test-ExtractedInfo -Info $textInfo -UpdateObject
    
    return $textInfo
}

# Test du workflow complet
Write-Host "Test du workflow d'extraction de texte et stockage dans une collection" -ForegroundColor Cyan

# Étape 1: Créer une collection pour stocker les informations extraites
Write-Host "Étape 1: Créer une collection pour stocker les informations extraites" -ForegroundColor Cyan
$collection = New-ExtractedInfoCollection -Name "TextExtractionCollection"

# Étape 2: Extraire le texte des fichiers
Write-Host "Étape 2: Extraire le texte des fichiers" -ForegroundColor Cyan
$textInfo1 = Extract-TextFromFile -FilePath $textFile1
$textInfo2 = Extract-TextFromFile -FilePath $textFile2
$textInfo3 = Extract-TextFromFile -FilePath $textFile3

# Étape 3: Ajouter les informations extraites à la collection
Write-Host "Étape 3: Ajouter les informations extraites à la collection" -ForegroundColor Cyan
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @($textInfo1, $textInfo2, $textInfo3)

# Étape 4: Vérifier que les informations ont été correctement ajoutées
Write-Host "Étape 4: Vérifier que les informations ont été correctement ajoutées" -ForegroundColor Cyan
$collectionItems = Get-ExtractedInfoFromCollection -Collection $collection

# Étape 5: Sauvegarder la collection dans un fichier
Write-Host "Étape 5: Sauvegarder la collection dans un fichier" -ForegroundColor Cyan
$collectionFile = Join-Path -Path $testDir -ChildPath "textCollection.json"
$collectionJson = ConvertTo-ExtractedInfoJson -InputObject $collection -Depth 10
Set-Content -Path $collectionFile -Value $collectionJson

# Étape 6: Obtenir des statistiques sur la collection
Write-Host "Étape 6: Obtenir des statistiques sur la collection" -ForegroundColor Cyan
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection

# Vérifications
$tests = @(
    @{ Test = "La collection n'est pas nulle"; Condition = $null -ne $collection }
    @{ Test = "La collection contient 3 éléments"; Condition = $collection.Items.Count -eq 3 }
    @{ Test = "Tous les éléments sont de type TextExtractedInfo"; Condition = ($collection.Items | Where-Object { $_._Type -eq "TextExtractedInfo" }).Count -eq 3 }
    @{ Test = "Tous les éléments ont un ID valide"; Condition = ($collection.Items | Where-Object { [guid]::TryParse($_.Id, [ref][guid]::Empty) }).Count -eq 3 }
    @{ Test = "Tous les éléments ont une source valide"; Condition = ($collection.Items | Where-Object { -not [string]::IsNullOrEmpty($_.Source) }).Count -eq 3 }
    @{ Test = "Tous les éléments ont un texte non vide"; Condition = ($collection.Items | Where-Object { -not [string]::IsNullOrEmpty($_.Text) }).Count -eq 3 }
    @{ Test = "Tous les éléments ont des métadonnées FileSize"; Condition = ($collection.Items | Where-Object { $_.Metadata.ContainsKey("FileSize") }).Count -eq 3 }
    @{ Test = "Tous les éléments ont des métadonnées FileCreationTime"; Condition = ($collection.Items | Where-Object { $_.Metadata.ContainsKey("FileCreationTime") }).Count -eq 3 }
    @{ Test = "Le fichier de collection a été créé"; Condition = Test-Path -Path $collectionFile }
    @{ Test = "Le fichier de collection n'est pas vide"; Condition = (Get-Item -Path $collectionFile).Length -gt 0 }
    @{ Test = "Les statistiques indiquent 3 éléments"; Condition = $stats.TotalCount -eq 3 }
    @{ Test = "Les statistiques indiquent que tous les éléments sont valides"; Condition = $stats.ValidCount -eq 3 }
    @{ Test = "Les statistiques indiquent le type TextExtractedInfo"; Condition = $stats.TypeDistribution.ContainsKey("TextExtractedInfo") -and $stats.TypeDistribution["TextExtractedInfo"] -eq 3 }
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
