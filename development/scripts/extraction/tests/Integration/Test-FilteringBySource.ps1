# Test-FilteringBySource.ps1
# Test d'intégration pour le filtrage par source

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Test du workflow de filtrage par source
Write-Host "Test du workflow de filtrage par source" -ForegroundColor Cyan

# Étape 1: Créer une collection avec des éléments provenant de différentes sources
Write-Host "Étape 1: Créer une collection avec des éléments provenant de différentes sources" -ForegroundColor Cyan
$collection = New-ExtractedInfoCollection -Name "FilteringTestCollection"

# Créer des informations extraites avec différentes sources
# Source 1: "WebSource"
$webInfo1 = New-ExtractedInfo -Source "WebSource" -ExtractorName "WebExtractor"
$webInfo1.ProcessingState = "Processed"
$webInfo1.ConfidenceScore = 85
$webInfo1 = Add-ExtractedInfoMetadata -Info $webInfo1 -Key "URL" -Value "https://example.com/page1"

$webInfo2 = New-TextExtractedInfo -Source "WebSource" -ExtractorName "WebExtractor" -Text "This is text from a web page" -Language "en"
$webInfo2.ProcessingState = "Processed"
$webInfo2.ConfidenceScore = 90
$webInfo2 = Add-ExtractedInfoMetadata -Info $webInfo2 -Key "URL" -Value "https://example.com/page2"

$webInfo3 = New-StructuredDataExtractedInfo -Source "WebSource" -ExtractorName "WebExtractor" -Data @{
    Title = "Web Page Title"
    Author = "John Doe"
    Date = "2023-05-15"
} -DataFormat "Hashtable"
$webInfo3.ProcessingState = "Processed"
$webInfo3.ConfidenceScore = 95
$webInfo3 = Add-ExtractedInfoMetadata -Info $webInfo3 -Key "URL" -Value "https://example.com/page3"

# Source 2: "FileSource"
$fileInfo1 = New-ExtractedInfo -Source "FileSource" -ExtractorName "FileExtractor"
$fileInfo1.ProcessingState = "Processed"
$fileInfo1.ConfidenceScore = 80
$fileInfo1 = Add-ExtractedInfoMetadata -Info $fileInfo1 -Key "FilePath" -Value "C:\Data\file1.txt"

$fileInfo2 = New-TextExtractedInfo -Source "FileSource" -ExtractorName "FileExtractor" -Text "This is text from a file" -Language "en"
$fileInfo2.ProcessingState = "Processed"
$fileInfo2.ConfidenceScore = 85
$fileInfo2 = Add-ExtractedInfoMetadata -Info $fileInfo2 -Key "FilePath" -Value "C:\Data\file2.txt"

# Source 3: "APISource"
$apiInfo1 = New-ExtractedInfo -Source "APISource" -ExtractorName "APIExtractor"
$apiInfo1.ProcessingState = "Raw"
$apiInfo1.ConfidenceScore = 70
$apiInfo1 = Add-ExtractedInfoMetadata -Info $apiInfo1 -Key "Endpoint" -Value "/api/data/1"

$apiInfo2 = New-StructuredDataExtractedInfo -Source "APISource" -ExtractorName "APIExtractor" -Data @{
    ID = 123
    Name = "API Data"
    Status = "Active"
} -DataFormat "Hashtable"
$apiInfo2.ProcessingState = "Processed"
$apiInfo2.ConfidenceScore = 75
$apiInfo2 = Add-ExtractedInfoMetadata -Info $apiInfo2 -Key "Endpoint" -Value "/api/data/2"

# Ajouter toutes les informations à la collection
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @(
    $webInfo1, $webInfo2, $webInfo3,
    $fileInfo1, $fileInfo2,
    $apiInfo1, $apiInfo2
)

# Vérifier que la collection a été créée correctement
$tests1 = @(
    @{ Test = "La collection n'est pas nulle"; Condition = $null -ne $collection }
    @{ Test = "La collection contient 7 éléments"; Condition = $collection.Items.Count -eq 7 }
    @{ Test = "La collection contient 3 éléments de source 'WebSource'"; Condition = ($collection.Items | Where-Object { $_.Source -eq "WebSource" }).Count -eq 3 }
    @{ Test = "La collection contient 2 éléments de source 'FileSource'"; Condition = ($collection.Items | Where-Object { $_.Source -eq "FileSource" }).Count -eq 2 }
    @{ Test = "La collection contient 2 éléments de source 'APISource'"; Condition = ($collection.Items | Where-Object { $_.Source -eq "APISource" }).Count -eq 2 }
)

$success1 = $true
foreach ($test in $tests1) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success1 = $false
    }
}

# Étape 2: Filtrer les éléments par source "WebSource"
Write-Host "Étape 2: Filtrer les éléments par source 'WebSource'" -ForegroundColor Cyan
$webItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_.Source -eq "WebSource" }

$tests2 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $webItems }
    @{ Test = "Le résultat contient 3 éléments"; Condition = $webItems.Count -eq 3 }
    @{ Test = "Tous les éléments ont la source 'WebSource'"; Condition = ($webItems | Where-Object { $_.Source -eq "WebSource" }).Count -eq 3 }
    @{ Test = "Les éléments ont les bons IDs"; Condition = ($webItems | Where-Object { $_.Id -eq $webInfo1.Id -or $_.Id -eq $webInfo2.Id -or $_.Id -eq $webInfo3.Id }).Count -eq 3 }
    @{ Test = "Tous les éléments ont des métadonnées URL"; Condition = ($webItems | Where-Object { $_.Metadata.ContainsKey("URL") }).Count -eq 3 }
)

$success2 = $true
foreach ($test in $tests2) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success2 = $false
    }
}

# Étape 3: Filtrer les éléments par source "FileSource"
Write-Host "Étape 3: Filtrer les éléments par source 'FileSource'" -ForegroundColor Cyan
$fileItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_.Source -eq "FileSource" }

$tests3 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $fileItems }
    @{ Test = "Le résultat contient 2 éléments"; Condition = $fileItems.Count -eq 2 }
    @{ Test = "Tous les éléments ont la source 'FileSource'"; Condition = ($fileItems | Where-Object { $_.Source -eq "FileSource" }).Count -eq 2 }
    @{ Test = "Les éléments ont les bons IDs"; Condition = ($fileItems | Where-Object { $_.Id -eq $fileInfo1.Id -or $_.Id -eq $fileInfo2.Id }).Count -eq 2 }
    @{ Test = "Tous les éléments ont des métadonnées FilePath"; Condition = ($fileItems | Where-Object { $_.Metadata.ContainsKey("FilePath") }).Count -eq 2 }
)

$success3 = $true
foreach ($test in $tests3) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success3 = $false
    }
}

# Étape 4: Filtrer les éléments par source "APISource"
Write-Host "Étape 4: Filtrer les éléments par source 'APISource'" -ForegroundColor Cyan
$apiItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_.Source -eq "APISource" }

$tests4 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $apiItems }
    @{ Test = "Le résultat contient 2 éléments"; Condition = $apiItems.Count -eq 2 }
    @{ Test = "Tous les éléments ont la source 'APISource'"; Condition = ($apiItems | Where-Object { $_.Source -eq "APISource" }).Count -eq 2 }
    @{ Test = "Les éléments ont les bons IDs"; Condition = ($apiItems | Where-Object { $_.Id -eq $apiInfo1.Id -or $_.Id -eq $apiInfo2.Id }).Count -eq 2 }
    @{ Test = "Tous les éléments ont des métadonnées Endpoint"; Condition = ($apiItems | Where-Object { $_.Metadata.ContainsKey("Endpoint") }).Count -eq 2 }
)

$success4 = $true
foreach ($test in $tests4) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success4 = $false
    }
}

# Étape 5: Filtrer par une source inexistante
Write-Host "Étape 5: Filtrer par une source inexistante" -ForegroundColor Cyan
$nonExistentItems = Get-ExtractedInfoFromCollection -Collection $collection | Where-Object { $_.Source -eq "NonExistentSource" }

$tests5 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $nonExistentItems }
    @{ Test = "Le résultat est un tableau vide"; Condition = $nonExistentItems.Count -eq 0 }
)

$success5 = $true
foreach ($test in $tests5) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success5 = $false
    }
}

# Étape 6: Obtenir des statistiques sur la distribution des sources
Write-Host "Étape 6: Obtenir des statistiques sur la distribution des sources" -ForegroundColor Cyan
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection

$tests6 = @(
    @{ Test = "Les statistiques ne sont pas nulles"; Condition = $null -ne $stats }
    @{ Test = "Les statistiques contiennent la distribution par source"; Condition = $null -ne $stats.SourceDistribution }
    @{ Test = "La distribution par source contient 3 sources"; Condition = $stats.SourceDistribution.Count -eq 3 }
    @{ Test = "La source 'WebSource' a 3 éléments"; Condition = $stats.SourceDistribution["WebSource"] -eq 3 }
    @{ Test = "La source 'FileSource' a 2 éléments"; Condition = $stats.SourceDistribution["FileSource"] -eq 2 }
    @{ Test = "La source 'APISource' a 2 éléments"; Condition = $stats.SourceDistribution["APISource"] -eq 2 }
)

$success6 = $true
foreach ($test in $tests6) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success6 = $false
    }
}

# Résultat final
$allSuccess = $success1 -and $success2 -and $success3 -and $success4 -and $success5 -and $success6

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}
