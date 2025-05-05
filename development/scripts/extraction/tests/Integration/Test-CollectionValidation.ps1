# Test-CollectionValidation.ps1
# Test d'intégration pour la validation d'une collection complète

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Test du workflow de validation d'une collection complète
Write-Host "Test du workflow de validation d'une collection complète" -ForegroundColor Cyan

# Étape 1: Créer différents types d'informations extraites valides et invalides
Write-Host "Étape 1: Créer différents types d'informations extraites valides et invalides" -ForegroundColor Cyan

# Informations valides
$validBaseInfo = New-ExtractedInfo -Source "Source1" -ExtractorName "BaseExtractor"
$validBaseInfo.ProcessingState = "Processed"
$validBaseInfo.ConfidenceScore = 75
$validBaseInfo = Add-ExtractedInfoMetadata -Info $validBaseInfo -Key "Category" -Value "Base"

$validTextInfo = New-TextExtractedInfo -Source "Source2" -ExtractorName "TextExtractor" -Text "This is a valid text" -Language "en"
$validTextInfo.ProcessingState = "Processed"
$validTextInfo.ConfidenceScore = 85
$validTextInfo = Add-ExtractedInfoMetadata -Info $validTextInfo -Key "Category" -Value "Text"

$validDataInfo = New-StructuredDataExtractedInfo -Source "Source3" -ExtractorName "DataExtractor" -Data @{
    Name = "Valid Data"
    Value = 123
    IsActive = $true
} -DataFormat "Hashtable"
$validDataInfo.ProcessingState = "Processed"
$validDataInfo.ConfidenceScore = 90
$validDataInfo = Add-ExtractedInfoMetadata -Info $validDataInfo -Key "Category" -Value "Data"

$validMediaInfo = New-MediaExtractedInfo -Source "Source4" -ExtractorName "MediaExtractor" -MediaPath "valid.jpg" -MediaType "Image"
$validMediaInfo.ProcessingState = "Processed"
$validMediaInfo.ConfidenceScore = 80
$validMediaInfo = Add-ExtractedInfoMetadata -Info $validMediaInfo -Key "Category" -Value "Media"

# Informations invalides
$invalidIdInfo = New-ExtractedInfo -Source "Source1" -ExtractorName "BaseExtractor"
$invalidIdInfo.Id = ""
$invalidIdInfo.ProcessingState = "Processed"
$invalidIdInfo.ConfidenceScore = 75
$invalidIdInfo = Add-ExtractedInfoMetadata -Info $invalidIdInfo -Key "Category" -Value "Base"

$invalidTextInfo = New-TextExtractedInfo -Source "Source2" -ExtractorName "TextExtractor" -Text "" -Language "en"
$invalidTextInfo.ProcessingState = "Processed"
$invalidTextInfo.ConfidenceScore = 85
$invalidTextInfo = Add-ExtractedInfoMetadata -Info $invalidTextInfo -Key "Category" -Value "Text"

$invalidDataInfo = New-StructuredDataExtractedInfo -Source "Source3" -ExtractorName "DataExtractor" -Data $null -DataFormat "Hashtable"
$invalidDataInfo.ProcessingState = "Processed"
$invalidDataInfo.ConfidenceScore = 90
$invalidDataInfo = Add-ExtractedInfoMetadata -Info $invalidDataInfo -Key "Category" -Value "Data"

$invalidMediaInfo = New-MediaExtractedInfo -Source "Source4" -ExtractorName "MediaExtractor" -MediaPath "" -MediaType "Image"
$invalidMediaInfo.ProcessingState = "Processed"
$invalidMediaInfo.ConfidenceScore = 80
$invalidMediaInfo = Add-ExtractedInfoMetadata -Info $invalidMediaInfo -Key "Category" -Value "Media"

# Vérifier que les informations ont été créées correctement
$tests1 = @(
    @{ Test = "L'information de base valide n'est pas nulle"; Condition = $null -ne $validBaseInfo }
    @{ Test = "L'information de texte valide n'est pas nulle"; Condition = $null -ne $validTextInfo }
    @{ Test = "L'information de données valide n'est pas nulle"; Condition = $null -ne $validDataInfo }
    @{ Test = "L'information de média valide n'est pas nulle"; Condition = $null -ne $validMediaInfo }
    @{ Test = "L'information avec ID invalide n'est pas nulle"; Condition = $null -ne $invalidIdInfo }
    @{ Test = "L'information avec texte invalide n'est pas nulle"; Condition = $null -ne $invalidTextInfo }
    @{ Test = "L'information avec données invalides n'est pas nulle"; Condition = $null -ne $invalidDataInfo }
    @{ Test = "L'information avec chemin de média invalide n'est pas nulle"; Condition = $null -ne $invalidMediaInfo }
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

# Étape 2: Créer une collection avec les informations valides et invalides
Write-Host "Étape 2: Créer une collection avec les informations valides et invalides" -ForegroundColor Cyan
$collection = New-ExtractedInfoCollection -Name "MixedValidationCollection"
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @(
    $validBaseInfo, $validTextInfo, $validDataInfo, $validMediaInfo,
    $invalidIdInfo, $invalidTextInfo, $invalidDataInfo, $invalidMediaInfo
)

# Vérifier que la collection a été créée correctement
$tests2 = @(
    @{ Test = "La collection n'est pas nulle"; Condition = $null -ne $collection }
    @{ Test = "La collection contient 8 éléments"; Condition = $collection.Items.Count -eq 8 }
    @{ Test = "La collection contient 4 informations valides"; Condition = ($collection.Items | Where-Object { $_.Id -eq $validBaseInfo.Id -or $_.Id -eq $validTextInfo.Id -or $_.Id -eq $validDataInfo.Id -or $_.Id -eq $validMediaInfo.Id }).Count -eq 4 }
    @{ Test = "La collection contient 4 informations invalides"; Condition = ($collection.Items | Where-Object { $_.Id -eq $invalidIdInfo.Id -or $_.Id -eq $invalidTextInfo.Id -or $_.Id -eq $invalidDataInfo.Id -or $_.Id -eq $invalidMediaInfo.Id }).Count -eq 3 }
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

# Étape 3: Valider tous les éléments de la collection
Write-Host "Étape 3: Valider tous les éléments de la collection" -ForegroundColor Cyan

# Fonction pour valider tous les éléments d'une collection
function Test-ExtractedInfoCollection {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Collection,
        
        [Parameter(Mandatory = $false)]
        [switch]$UpdateObjects
    )
    
    $validCount = 0
    $invalidCount = 0
    $validationResults = @()
    
    foreach ($item in $Collection.Items) {
        $validationResult = Test-ExtractedInfo -Info $item -UpdateObject:$UpdateObjects
        $validationResults += @{
            Info = $item
            IsValid = $validationResult
        }
        
        if ($validationResult) {
            $validCount++
        } else {
            $invalidCount++
        }
    }
    
    return @{
        TotalCount = $Collection.Items.Count
        ValidCount = $validCount
        InvalidCount = $invalidCount
        ValidationResults = $validationResults
    }
}

# Valider la collection sans mise à jour des objets
$validationResults = Test-ExtractedInfoCollection -Collection $collection

# Vérifier que la validation a fonctionné correctement
$tests3 = @(
    @{ Test = "Les résultats de validation ne sont pas nuls"; Condition = $null -ne $validationResults }
    @{ Test = "Le nombre total d'éléments est correct"; Condition = $validationResults.TotalCount -eq 8 }
    @{ Test = "Il y a des éléments valides"; Condition = $validationResults.ValidCount -gt 0 }
    @{ Test = "Il y a des éléments invalides"; Condition = $validationResults.InvalidCount -gt 0 }
    @{ Test = "Le nombre d'éléments valides est correct"; Condition = $validationResults.ValidCount -eq 4 }
    @{ Test = "Le nombre d'éléments invalides est correct"; Condition = $validationResults.InvalidCount -eq 4 }
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

# Étape 4: Valider tous les éléments de la collection avec mise à jour des objets
Write-Host "Étape 4: Valider tous les éléments de la collection avec mise à jour des objets" -ForegroundColor Cyan

# Valider la collection avec mise à jour des objets
$validationResultsWithUpdate = Test-ExtractedInfoCollection -Collection $collection -UpdateObjects

# Vérifier que la validation avec mise à jour a fonctionné correctement
$tests4 = @(
    @{ Test = "Les résultats de validation ne sont pas nuls"; Condition = $null -ne $validationResultsWithUpdate }
    @{ Test = "Le nombre total d'éléments est correct"; Condition = $validationResultsWithUpdate.TotalCount -eq 8 }
    @{ Test = "Il y a des éléments valides"; Condition = $validationResultsWithUpdate.ValidCount -gt 0 }
    @{ Test = "Il y a des éléments invalides"; Condition = $validationResultsWithUpdate.InvalidCount -gt 0 }
    @{ Test = "Le nombre d'éléments valides est correct"; Condition = $validationResultsWithUpdate.ValidCount -eq 4 }
    @{ Test = "Le nombre d'éléments invalides est correct"; Condition = $validationResultsWithUpdate.InvalidCount -eq 4 }
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

# Étape 5: Vérifier que les objets ont été mis à jour correctement
Write-Host "Étape 5: Vérifier que les objets ont été mis à jour correctement" -ForegroundColor Cyan

# Vérifier que les objets valides ont été mis à jour correctement
$validItemsUpdated = $collection.Items | Where-Object { $_.Id -eq $validBaseInfo.Id -or $_.Id -eq $validTextInfo.Id -or $_.Id -eq $validDataInfo.Id -or $_.Id -eq $validMediaInfo.Id }

$tests5a = @(
    @{ Test = "Les objets valides ont été mis à jour"; Condition = $validItemsUpdated.Count -eq 4 }
    @{ Test = "Tous les objets valides ont IsValid = true"; Condition = ($validItemsUpdated | Where-Object { $_.IsValid -eq $true }).Count -eq 4 }
    @{ Test = "Tous les objets valides ont _LastValidated dans les métadonnées"; Condition = ($validItemsUpdated | Where-Object { $_.Metadata.ContainsKey("_LastValidated") }).Count -eq 4 }
    @{ Test = "Tous les objets valides ont _IsValid = true dans les métadonnées"; Condition = ($validItemsUpdated | Where-Object { $_.Metadata.ContainsKey("_IsValid") -and $_.Metadata["_IsValid"] -eq $true }).Count -eq 4 }
    @{ Test = "Aucun objet valide n'a _ValidationErrors dans les métadonnées"; Condition = ($validItemsUpdated | Where-Object { $_.Metadata.ContainsKey("_ValidationErrors") }).Count -eq 0 }
)

$success5a = $true
foreach ($test in $tests5a) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success5a = $false
    }
}

# Vérifier que les objets invalides ont été mis à jour correctement
$invalidItemsUpdated = $collection.Items | Where-Object { ($_.Id -eq $invalidIdInfo.Id -and $_.Id -ne "") -or $_.Id -eq $invalidTextInfo.Id -or $_.Id -eq $invalidDataInfo.Id -or $_.Id -eq $invalidMediaInfo.Id }

$tests5b = @(
    @{ Test = "Les objets invalides ont été mis à jour"; Condition = $invalidItemsUpdated.Count -gt 0 }
    @{ Test = "Tous les objets invalides ont IsValid = false"; Condition = ($invalidItemsUpdated | Where-Object { $_.IsValid -eq $false }).Count -eq $invalidItemsUpdated.Count }
    @{ Test = "Tous les objets invalides ont _LastValidated dans les métadonnées"; Condition = ($invalidItemsUpdated | Where-Object { $_.Metadata.ContainsKey("_LastValidated") }).Count -eq $invalidItemsUpdated.Count }
    @{ Test = "Tous les objets invalides ont _IsValid = false dans les métadonnées"; Condition = ($invalidItemsUpdated | Where-Object { $_.Metadata.ContainsKey("_IsValid") -and $_.Metadata["_IsValid"] -eq $false }).Count -eq $invalidItemsUpdated.Count }
    @{ Test = "Tous les objets invalides ont _ValidationErrors dans les métadonnées"; Condition = ($invalidItemsUpdated | Where-Object { $_.Metadata.ContainsKey("_ValidationErrors") }).Count -eq $invalidItemsUpdated.Count }
    @{ Test = "Tous les objets invalides ont des erreurs de validation non vides"; Condition = ($invalidItemsUpdated | Where-Object { $_.Metadata.ContainsKey("_ValidationErrors") -and $_.Metadata["_ValidationErrors"].Count -gt 0 }).Count -eq $invalidItemsUpdated.Count }
)

$success5b = $true
foreach ($test in $tests5b) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success5b = $false
    }
}

# Étape 6: Obtenir des statistiques sur la collection
Write-Host "Étape 6: Obtenir des statistiques sur la collection" -ForegroundColor Cyan
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection

# Vérifier que les statistiques sont correctes
$tests6 = @(
    @{ Test = "Les statistiques ne sont pas nulles"; Condition = $null -ne $stats }
    @{ Test = "Les statistiques indiquent 8 éléments au total"; Condition = $stats.TotalCount -eq 8 }
    @{ Test = "Les statistiques indiquent des éléments valides"; Condition = $stats.ValidCount -gt 0 }
    @{ Test = "Les statistiques indiquent des éléments invalides"; Condition = $stats.InvalidCount -gt 0 }
    @{ Test = "Le nombre d'éléments valides est correct"; Condition = $stats.ValidCount -eq 4 }
    @{ Test = "Le nombre d'éléments invalides est correct"; Condition = $stats.InvalidCount -eq 4 }
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

# Étape 7: Filtrer les éléments valides et invalides
Write-Host "Étape 7: Filtrer les éléments valides et invalides" -ForegroundColor Cyan

# Filtrer les éléments valides et invalides
$validItems = $collection.Items | Where-Object { $_.IsValid -eq $true }
$invalidItems = $collection.Items | Where-Object { $_.IsValid -eq $false }

# Vérifier que le filtrage a fonctionné correctement
$tests7 = @(
    @{ Test = "Il y a des éléments valides"; Condition = $validItems.Count -gt 0 }
    @{ Test = "Il y a des éléments invalides"; Condition = $invalidItems.Count -gt 0 }
    @{ Test = "Le nombre d'éléments valides est correct"; Condition = $validItems.Count -eq 4 }
    @{ Test = "Le nombre d'éléments invalides est correct"; Condition = $invalidItems.Count -eq 4 }
)

$success7 = $true
foreach ($test in $tests7) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success7 = $false
    }
}

# Résultat final
$allSuccess = $success1 -and $success2 -and $success3 -and $success4 -and $success5a -and $success5b -and $success6 -and $success7

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}
