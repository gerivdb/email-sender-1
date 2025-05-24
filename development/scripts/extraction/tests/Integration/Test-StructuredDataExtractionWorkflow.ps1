# Test-StructuredDataExtractionWorkflow.ps1
# Test d'intégration pour l'extraction de données structurées et le stockage dans une collection

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer un répertoire temporaire pour les fichiers de test
$tempDir = [System.IO.Path]::GetTempPath()
$testDir = Join-Path -Path $tempDir -ChildPath "ExtractedInfoTest"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer des fichiers JSON pour les tests
$jsonFile1 = Join-Path -Path $testDir -ChildPath "data1.json"
$jsonFile2 = Join-Path -Path $testDir -ChildPath "data2.json"
$jsonFile3 = Join-Path -Path $testDir -ChildPath "data3.json"

$jsonData1 = @{
    Name = "Product 1"
    Price = 19.99
    InStock = $true
    Categories = @("Electronics", "Gadgets")
    Specifications = @{
        Weight = "250g"
        Dimensions = "10x5x2 cm"
        Color = "Black"
    }
} | ConvertTo-Json -Depth 5

$jsonData2 = @{
    Name = "Product 2"
    Price = 29.99
    InStock = $false
    Categories = @("Home", "Kitchen")
    Specifications = @{
        Weight = "500g"
        Dimensions = "20x15x10 cm"
        Color = "White"
    }
} | ConvertTo-Json -Depth 5

$jsonData3 = @{
    Name = "Product 3"
    Price = 9.99
    InStock = $true
    Categories = @("Office", "Supplies")
    Specifications = @{
        Weight = "100g"
        Dimensions = "15x3x1 cm"
        Color = "Blue"
    }
} | ConvertTo-Json -Depth 5

Set-Content -Path $jsonFile1 -Value $jsonData1
Set-Content -Path $jsonFile2 -Value $jsonData2
Set-Content -Path $jsonFile3 -Value $jsonData3

# Fonction simulant un extracteur de données structurées
function Export-StructuredDataFromFile {
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
            if ($property.Value -is [PSCustomObject]) {
                $nestedHashtable = @{}
                foreach ($nestedProperty in $property.Value.PSObject.Properties) {
                    $nestedHashtable[$nestedProperty.Name] = $nestedProperty.Value
                }
                $hashtable[$property.Name] = $nestedHashtable
            } else {
                $hashtable[$property.Name] = $property.Value
            }
        }
        
        # Créer une information extraite de type données structurées
        $dataInfo = New-StructuredDataExtractedInfo -Source $FilePath -ExtractorName $ExtractorName -Data $hashtable -DataFormat "Hashtable"
        
        # Ajouter des métadonnées
        $dataInfo = Add-ExtractedInfoMetadata -Info $dataInfo -Key "FileSize" -Value (Get-Item -Path $FilePath).Length
        $dataInfo = Add-ExtractedInfoMetadata -Info $dataInfo -Key "FileCreationTime" -Value (Get-Item -Path $FilePath).CreationTime
        $dataInfo = Add-ExtractedInfoMetadata -Info $dataInfo -Key "DataFormat" -Value "JSON"
        
        # Calculer un score de confiance basé sur la complexité des données (exemple simple)
        $confidenceScore = [Math]::Min(100, [Math]::Max(0, $hashtable.Count * 10))
        $dataInfo.ConfidenceScore = $confidenceScore
        
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

# Test du workflow complet
Write-Host "Test du workflow d'extraction de données structurées et stockage dans une collection" -ForegroundColor Cyan

# Étape 1: Créer une collection pour stocker les informations extraites
Write-Host "Étape 1: Créer une collection pour stocker les informations extraites" -ForegroundColor Cyan
$collection = New-ExtractedInfoCollection -Name "StructuredDataExtractionCollection"

# Étape 2: Extraire les données structurées des fichiers
Write-Host "Étape 2: Extraire les données structurées des fichiers" -ForegroundColor Cyan
$dataInfo1 = Export-StructuredDataFromFile -FilePath $jsonFile1
$dataInfo2 = Export-StructuredDataFromFile -FilePath $jsonFile2
$dataInfo3 = Export-StructuredDataFromFile -FilePath $jsonFile3

# Étape 3: Ajouter les informations extraites à la collection
Write-Host "Étape 3: Ajouter les informations extraites à la collection" -ForegroundColor Cyan
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @($dataInfo1, $dataInfo2, $dataInfo3)

# Étape 4: Vérifier que les informations ont été correctement ajoutées
Write-Host "Étape 4: Vérifier que les informations ont été correctement ajoutées" -ForegroundColor Cyan
$collectionItems = Get-ExtractedInfoFromCollection -Collection $collection

# Étape 5: Sauvegarder la collection dans un fichier
Write-Host "Étape 5: Sauvegarder la collection dans un fichier" -ForegroundColor Cyan
$collectionFile = Join-Path -Path $testDir -ChildPath "dataCollection.json"
$collectionJson = ConvertTo-ExtractedInfoJson -InputObject $collection -Depth 10
Set-Content -Path $collectionFile -Value $collectionJson

# Étape 6: Obtenir des statistiques sur la collection
Write-Host "Étape 6: Obtenir des statistiques sur la collection" -ForegroundColor Cyan
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection

# Vérifications
$tests = @(
    @{ Test = "La collection n'est pas nulle"; Condition = $null -ne $collection }
    @{ Test = "La collection contient 3 éléments"; Condition = $collection.Items.Count -eq 3 }
    @{ Test = "Tous les éléments sont de type StructuredDataExtractedInfo"; Condition = ($collection.Items | Where-Object { $_._Type -eq "StructuredDataExtractedInfo" }).Count -eq 3 }
    @{ Test = "Tous les éléments ont un ID valide"; Condition = ($collection.Items | Where-Object { [guid]::TryParse($_.Id, [ref][guid]::Empty) }).Count -eq 3 }
    @{ Test = "Tous les éléments ont une source valide"; Condition = ($collection.Items | Where-Object { -not [string]::IsNullOrEmpty($_.Source) }).Count -eq 3 }
    @{ Test = "Tous les éléments ont des données non nulles"; Condition = ($collection.Items | Where-Object { $null -ne $_.Data }).Count -eq 3 }
    @{ Test = "Tous les éléments ont un format de données 'Hashtable'"; Condition = ($collection.Items | Where-Object { $_.DataFormat -eq "Hashtable" }).Count -eq 3 }
    @{ Test = "Tous les éléments ont des métadonnées FileSize"; Condition = ($collection.Items | Where-Object { $_.Metadata.ContainsKey("FileSize") }).Count -eq 3 }
    @{ Test = "Tous les éléments ont des métadonnées FileCreationTime"; Condition = ($collection.Items | Where-Object { $_.Metadata.ContainsKey("FileCreationTime") }).Count -eq 3 }
    @{ Test = "Tous les éléments ont des métadonnées DataFormat"; Condition = ($collection.Items | Where-Object { $_.Metadata.ContainsKey("DataFormat") }).Count -eq 3 }
    @{ Test = "Le fichier de collection a été créé"; Condition = Test-Path -Path $collectionFile }
    @{ Test = "Le fichier de collection n'est pas vide"; Condition = (Get-Item -Path $collectionFile).Length -gt 0 }
    @{ Test = "Les statistiques indiquent 3 éléments"; Condition = $stats.TotalCount -eq 3 }
    @{ Test = "Les statistiques indiquent que tous les éléments sont valides"; Condition = $stats.ValidCount -eq 3 }
    @{ Test = "Les statistiques indiquent le type StructuredDataExtractedInfo"; Condition = $stats.TypeDistribution.ContainsKey("StructuredDataExtractedInfo") -and $stats.TypeDistribution["StructuredDataExtractedInfo"] -eq 3 }
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

