# Test-ValidInfoValidation.ps1
# Test d'intégration pour la validation d'informations valides

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Test du workflow de validation d'informations valides
Write-Host "Test du workflow de validation d'informations valides" -ForegroundColor Cyan

# Étape 1: Créer différents types d'informations extraites valides
Write-Host "Étape 1: Créer différents types d'informations extraites valides" -ForegroundColor Cyan

# Créer une information de base valide
$baseInfo = New-ExtractedInfo -Source "Source1" -ExtractorName "BaseExtractor"
$baseInfo.ProcessingState = "Processed"
$baseInfo.ConfidenceScore = 75
$baseInfo = Add-ExtractedInfoMetadata -Info $baseInfo -Key "Category" -Value "Base"

# Créer une information de texte valide
$textInfo = New-TextExtractedInfo -Source "Source2" -ExtractorName "TextExtractor" -Text "This is a valid text" -Language "en"
$textInfo.ProcessingState = "Processed"
$textInfo.ConfidenceScore = 85
$textInfo = Add-ExtractedInfoMetadata -Info $textInfo -Key "Category" -Value "Text"

# Créer une information de données structurées valide
$dataInfo = New-StructuredDataExtractedInfo -Source "Source3" -ExtractorName "DataExtractor" -Data @{
    Name = "Valid Data"
    Value = 123
    IsActive = $true
} -DataFormat "Hashtable"
$dataInfo.ProcessingState = "Processed"
$dataInfo.ConfidenceScore = 90
$dataInfo = Add-ExtractedInfoMetadata -Info $dataInfo -Key "Category" -Value "Data"

# Créer une information de média valide
$mediaInfo = New-MediaExtractedInfo -Source "Source4" -ExtractorName "MediaExtractor" -MediaPath "valid.jpg" -MediaType "Image"
$mediaInfo.ProcessingState = "Processed"
$mediaInfo.ConfidenceScore = 80
$mediaInfo = Add-ExtractedInfoMetadata -Info $mediaInfo -Key "Category" -Value "Media"

# Vérifier que les informations ont été créées correctement
$tests1 = @(
    @{ Test = "L'information de base n'est pas nulle"; Condition = $null -ne $baseInfo }
    @{ Test = "L'information de texte n'est pas nulle"; Condition = $null -ne $textInfo }
    @{ Test = "L'information de données n'est pas nulle"; Condition = $null -ne $dataInfo }
    @{ Test = "L'information de média n'est pas nulle"; Condition = $null -ne $mediaInfo }
    @{ Test = "L'information de base a un ID valide"; Condition = [guid]::TryParse($baseInfo.Id, [ref][guid]::Empty) }
    @{ Test = "L'information de texte a un ID valide"; Condition = [guid]::TryParse($textInfo.Id, [ref][guid]::Empty) }
    @{ Test = "L'information de données a un ID valide"; Condition = [guid]::TryParse($dataInfo.Id, [ref][guid]::Empty) }
    @{ Test = "L'information de média a un ID valide"; Condition = [guid]::TryParse($mediaInfo.Id, [ref][guid]::Empty) }
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

# Étape 2: Valider l'information de base sans mise à jour
Write-Host "Étape 2: Valider l'information de base sans mise à jour" -ForegroundColor Cyan
$baseValidationResult = Test-ExtractedInfo -Info $baseInfo

# Vérifier que la validation a fonctionné correctement
$tests2 = @(
    @{ Test = "Le résultat de la validation est vrai"; Condition = $baseValidationResult -eq $true }
    @{ Test = "La propriété IsValid n'a pas été modifiée"; Condition = $baseInfo.IsValid -eq $null -or $baseInfo.IsValid -eq $false }
    @{ Test = "Les métadonnées ne contiennent pas _LastValidated"; Condition = -not $baseInfo.Metadata.ContainsKey("_LastValidated") }
    @{ Test = "Les métadonnées ne contiennent pas _ValidationErrors"; Condition = -not $baseInfo.Metadata.ContainsKey("_ValidationErrors") }
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

# Étape 3: Valider l'information de base avec mise à jour
Write-Host "Étape 3: Valider l'information de base avec mise à jour" -ForegroundColor Cyan
$baseValidationResultWithUpdate = Test-ExtractedInfo -Info $baseInfo -UpdateObject

# Vérifier que la validation avec mise à jour a fonctionné correctement
$tests3 = @(
    @{ Test = "Le résultat de la validation est vrai"; Condition = $baseValidationResultWithUpdate -eq $true }
    @{ Test = "La propriété IsValid a été mise à jour à vrai"; Condition = $baseInfo.IsValid -eq $true }
    @{ Test = "Les métadonnées contiennent _LastValidated"; Condition = $baseInfo.Metadata.ContainsKey("_LastValidated") }
    @{ Test = "Les métadonnées contiennent _IsValid"; Condition = $baseInfo.Metadata.ContainsKey("_IsValid") }
    @{ Test = "La valeur de _IsValid est vraie"; Condition = $baseInfo.Metadata["_IsValid"] -eq $true }
    @{ Test = "Les métadonnées ne contiennent pas _ValidationErrors"; Condition = -not $baseInfo.Metadata.ContainsKey("_ValidationErrors") }
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

# Étape 4: Valider l'information de texte avec mise à jour
Write-Host "Étape 4: Valider l'information de texte avec mise à jour" -ForegroundColor Cyan
$textValidationResult = Test-ExtractedInfo -Info $textInfo -UpdateObject

# Vérifier que la validation a fonctionné correctement
$tests4 = @(
    @{ Test = "Le résultat de la validation est vrai"; Condition = $textValidationResult -eq $true }
    @{ Test = "La propriété IsValid a été mise à jour à vrai"; Condition = $textInfo.IsValid -eq $true }
    @{ Test = "Les métadonnées contiennent _LastValidated"; Condition = $textInfo.Metadata.ContainsKey("_LastValidated") }
    @{ Test = "Les métadonnées contiennent _IsValid"; Condition = $textInfo.Metadata.ContainsKey("_IsValid") }
    @{ Test = "La valeur de _IsValid est vraie"; Condition = $textInfo.Metadata["_IsValid"] -eq $true }
    @{ Test = "Les métadonnées ne contiennent pas _ValidationErrors"; Condition = -not $textInfo.Metadata.ContainsKey("_ValidationErrors") }
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

# Étape 5: Valider l'information de données structurées avec mise à jour
Write-Host "Étape 5: Valider l'information de données structurées avec mise à jour" -ForegroundColor Cyan
$dataValidationResult = Test-ExtractedInfo -Info $dataInfo -UpdateObject

# Vérifier que la validation a fonctionné correctement
$tests5 = @(
    @{ Test = "Le résultat de la validation est vrai"; Condition = $dataValidationResult -eq $true }
    @{ Test = "La propriété IsValid a été mise à jour à vrai"; Condition = $dataInfo.IsValid -eq $true }
    @{ Test = "Les métadonnées contiennent _LastValidated"; Condition = $dataInfo.Metadata.ContainsKey("_LastValidated") }
    @{ Test = "Les métadonnées contiennent _IsValid"; Condition = $dataInfo.Metadata.ContainsKey("_IsValid") }
    @{ Test = "La valeur de _IsValid est vraie"; Condition = $dataInfo.Metadata["_IsValid"] -eq $true }
    @{ Test = "Les métadonnées ne contiennent pas _ValidationErrors"; Condition = -not $dataInfo.Metadata.ContainsKey("_ValidationErrors") }
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

# Étape 6: Valider l'information de média avec mise à jour
Write-Host "Étape 6: Valider l'information de média avec mise à jour" -ForegroundColor Cyan
$mediaValidationResult = Test-ExtractedInfo -Info $mediaInfo -UpdateObject

# Vérifier que la validation a fonctionné correctement
$tests6 = @(
    @{ Test = "Le résultat de la validation est vrai"; Condition = $mediaValidationResult -eq $true }
    @{ Test = "La propriété IsValid a été mise à jour à vrai"; Condition = $mediaInfo.IsValid -eq $true }
    @{ Test = "Les métadonnées contiennent _LastValidated"; Condition = $mediaInfo.Metadata.ContainsKey("_LastValidated") }
    @{ Test = "Les métadonnées contiennent _IsValid"; Condition = $mediaInfo.Metadata.ContainsKey("_IsValid") }
    @{ Test = "La valeur de _IsValid est vraie"; Condition = $mediaInfo.Metadata["_IsValid"] -eq $true }
    @{ Test = "Les métadonnées ne contiennent pas _ValidationErrors"; Condition = -not $mediaInfo.Metadata.ContainsKey("_ValidationErrors") }
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

# Étape 7: Créer une collection avec les informations valides
Write-Host "Étape 7: Créer une collection avec les informations valides" -ForegroundColor Cyan
$collection = New-ExtractedInfoCollection -Name "ValidInfoCollection"
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @($baseInfo, $textInfo, $dataInfo, $mediaInfo)

# Vérifier que la collection a été créée correctement
$tests7 = @(
    @{ Test = "La collection n'est pas nulle"; Condition = $null -ne $collection }
    @{ Test = "La collection contient 4 éléments"; Condition = $collection.Items.Count -eq 4 }
    @{ Test = "Tous les éléments de la collection sont valides"; Condition = ($collection.Items | Where-Object { $_.IsValid -eq $true }).Count -eq 4 }
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

# Étape 8: Obtenir des statistiques sur la collection
Write-Host "Étape 8: Obtenir des statistiques sur la collection" -ForegroundColor Cyan
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection

# Vérifier que les statistiques sont correctes
$tests8 = @(
    @{ Test = "Les statistiques ne sont pas nulles"; Condition = $null -ne $stats }
    @{ Test = "Les statistiques indiquent 4 éléments au total"; Condition = $stats.TotalCount -eq 4 }
    @{ Test = "Les statistiques indiquent 4 éléments valides"; Condition = $stats.ValidCount -eq 4 }
    @{ Test = "Les statistiques indiquent 0 élément invalide"; Condition = $stats.InvalidCount -eq 0 }
)

$success8 = $true
foreach ($test in $tests8) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success8 = $false
    }
}

# Résultat final
$allSuccess = $success1 -and $success2 -and $success3 -and $success4 -and $success5 -and $success6 -and $success7 -and $success8

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}
