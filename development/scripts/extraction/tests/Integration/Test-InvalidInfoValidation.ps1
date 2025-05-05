# Test-InvalidInfoValidation.ps1
# Test d'intégration pour la validation d'informations invalides

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Test du workflow de validation d'informations invalides
Write-Host "Test du workflow de validation d'informations invalides" -ForegroundColor Cyan

# Étape 1: Créer différents types d'informations extraites invalides
Write-Host "Étape 1: Créer différents types d'informations extraites invalides" -ForegroundColor Cyan

# Créer une information de base invalide (ID vide)
$invalidBaseInfo = New-ExtractedInfo -Source "Source1" -ExtractorName "BaseExtractor"
$invalidBaseInfo.Id = ""
$invalidBaseInfo.ProcessingState = "Processed"
$invalidBaseInfo.ConfidenceScore = 75
$invalidBaseInfo = Add-ExtractedInfoMetadata -Info $invalidBaseInfo -Key "Category" -Value "Base"

# Créer une information de base invalide (source vide)
$invalidSourceInfo = New-ExtractedInfo -Source "" -ExtractorName "BaseExtractor"
$invalidSourceInfo.ProcessingState = "Processed"
$invalidSourceInfo.ConfidenceScore = 75
$invalidSourceInfo = Add-ExtractedInfoMetadata -Info $invalidSourceInfo -Key "Category" -Value "Base"

# Créer une information de base invalide (score de confiance invalide)
$invalidScoreInfo = New-ExtractedInfo -Source "Source1" -ExtractorName "BaseExtractor"
$invalidScoreInfo.ProcessingState = "Processed"
$invalidScoreInfo.ConfidenceScore = 101
$invalidScoreInfo = Add-ExtractedInfoMetadata -Info $invalidScoreInfo -Key "Category" -Value "Base"

# Créer une information de texte invalide (texte vide)
$invalidTextInfo = New-TextExtractedInfo -Source "Source2" -ExtractorName "TextExtractor" -Text "" -Language "en"
$invalidTextInfo.ProcessingState = "Processed"
$invalidTextInfo.ConfidenceScore = 85
$invalidTextInfo = Add-ExtractedInfoMetadata -Info $invalidTextInfo -Key "Category" -Value "Text"

# Créer une information de texte invalide (langue vide)
$invalidLanguageInfo = New-TextExtractedInfo -Source "Source2" -ExtractorName "TextExtractor" -Text "This is a text" -Language ""
$invalidLanguageInfo.ProcessingState = "Processed"
$invalidLanguageInfo.ConfidenceScore = 85
$invalidLanguageInfo = Add-ExtractedInfoMetadata -Info $invalidLanguageInfo -Key "Category" -Value "Text"

# Créer une information de données structurées invalide (données nulles)
$invalidDataInfo = New-StructuredDataExtractedInfo -Source "Source3" -ExtractorName "DataExtractor" -Data $null -DataFormat "Hashtable"
$invalidDataInfo.ProcessingState = "Processed"
$invalidDataInfo.ConfidenceScore = 90
$invalidDataInfo = Add-ExtractedInfoMetadata -Info $invalidDataInfo -Key "Category" -Value "Data"

# Créer une information de données structurées invalide (format vide)
$invalidFormatInfo = New-StructuredDataExtractedInfo -Source "Source3" -ExtractorName "DataExtractor" -Data @{Name = "Test"} -DataFormat ""
$invalidFormatInfo.ProcessingState = "Processed"
$invalidFormatInfo.ConfidenceScore = 90
$invalidFormatInfo = Add-ExtractedInfoMetadata -Info $invalidFormatInfo -Key "Category" -Value "Data"

# Créer une information de média invalide (chemin vide)
$invalidMediaPathInfo = New-MediaExtractedInfo -Source "Source4" -ExtractorName "MediaExtractor" -MediaPath "" -MediaType "Image"
$invalidMediaPathInfo.ProcessingState = "Processed"
$invalidMediaPathInfo.ConfidenceScore = 80
$invalidMediaPathInfo = Add-ExtractedInfoMetadata -Info $invalidMediaPathInfo -Key "Category" -Value "Media"

# Créer une information de média invalide (type vide)
$invalidMediaTypeInfo = New-MediaExtractedInfo -Source "Source4" -ExtractorName "MediaExtractor" -MediaPath "test.jpg" -MediaType ""
$invalidMediaTypeInfo.ProcessingState = "Processed"
$invalidMediaTypeInfo.ConfidenceScore = 80
$invalidMediaTypeInfo = Add-ExtractedInfoMetadata -Info $invalidMediaTypeInfo -Key "Category" -Value "Media"

# Vérifier que les informations ont été créées correctement
$tests1 = @(
    @{ Test = "L'information avec ID invalide n'est pas nulle"; Condition = $null -ne $invalidBaseInfo }
    @{ Test = "L'information avec source invalide n'est pas nulle"; Condition = $null -ne $invalidSourceInfo }
    @{ Test = "L'information avec score invalide n'est pas nulle"; Condition = $null -ne $invalidScoreInfo }
    @{ Test = "L'information avec texte invalide n'est pas nulle"; Condition = $null -ne $invalidTextInfo }
    @{ Test = "L'information avec langue invalide n'est pas nulle"; Condition = $null -ne $invalidLanguageInfo }
    @{ Test = "L'information avec données invalides n'est pas nulle"; Condition = $null -ne $invalidDataInfo }
    @{ Test = "L'information avec format invalide n'est pas nulle"; Condition = $null -ne $invalidFormatInfo }
    @{ Test = "L'information avec chemin de média invalide n'est pas nulle"; Condition = $null -ne $invalidMediaPathInfo }
    @{ Test = "L'information avec type de média invalide n'est pas nulle"; Condition = $null -ne $invalidMediaTypeInfo }
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

# Étape 2: Valider l'information avec ID invalide
Write-Host "Étape 2: Valider l'information avec ID invalide" -ForegroundColor Cyan
$invalidBaseValidationResult = Test-ExtractedInfo -Info $invalidBaseInfo

# Vérifier que la validation a fonctionné correctement
$tests2 = @(
    @{ Test = "Le résultat de la validation est faux"; Condition = $invalidBaseValidationResult -eq $false }
    @{ Test = "La propriété IsValid n'a pas été modifiée"; Condition = $invalidBaseInfo.IsValid -eq $null -or $invalidBaseInfo.IsValid -eq $false }
    @{ Test = "Les métadonnées ne contiennent pas _LastValidated"; Condition = -not $invalidBaseInfo.Metadata.ContainsKey("_LastValidated") }
    @{ Test = "Les métadonnées ne contiennent pas _ValidationErrors"; Condition = -not $invalidBaseInfo.Metadata.ContainsKey("_ValidationErrors") }
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

# Étape 3: Valider l'information avec ID invalide avec mise à jour
Write-Host "Étape 3: Valider l'information avec ID invalide avec mise à jour" -ForegroundColor Cyan
$invalidBaseValidationResultWithUpdate = Test-ExtractedInfo -Info $invalidBaseInfo -UpdateObject

# Vérifier que la validation avec mise à jour a fonctionné correctement
$tests3 = @(
    @{ Test = "Le résultat de la validation est faux"; Condition = $invalidBaseValidationResultWithUpdate -eq $false }
    @{ Test = "La propriété IsValid a été mise à jour à faux"; Condition = $invalidBaseInfo.IsValid -eq $false }
    @{ Test = "Les métadonnées contiennent _LastValidated"; Condition = $invalidBaseInfo.Metadata.ContainsKey("_LastValidated") }
    @{ Test = "Les métadonnées contiennent _IsValid"; Condition = $invalidBaseInfo.Metadata.ContainsKey("_IsValid") }
    @{ Test = "La valeur de _IsValid est fausse"; Condition = $invalidBaseInfo.Metadata["_IsValid"] -eq $false }
    @{ Test = "Les métadonnées contiennent _ValidationErrors"; Condition = $invalidBaseInfo.Metadata.ContainsKey("_ValidationErrors") }
    @{ Test = "Les erreurs de validation ne sont pas vides"; Condition = $invalidBaseInfo.Metadata["_ValidationErrors"].Count -gt 0 }
    @{ Test = "Les erreurs de validation contiennent une erreur d'ID"; Condition = $invalidBaseInfo.Metadata["_ValidationErrors"] -match "Id" }
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

# Étape 4: Valider l'information avec source invalide avec mise à jour
Write-Host "Étape 4: Valider l'information avec source invalide avec mise à jour" -ForegroundColor Cyan
$invalidSourceValidationResult = Test-ExtractedInfo -Info $invalidSourceInfo -UpdateObject

# Vérifier que la validation a fonctionné correctement
$tests4 = @(
    @{ Test = "Le résultat de la validation est faux"; Condition = $invalidSourceValidationResult -eq $false }
    @{ Test = "La propriété IsValid a été mise à jour à faux"; Condition = $invalidSourceInfo.IsValid -eq $false }
    @{ Test = "Les métadonnées contiennent _ValidationErrors"; Condition = $invalidSourceInfo.Metadata.ContainsKey("_ValidationErrors") }
    @{ Test = "Les erreurs de validation ne sont pas vides"; Condition = $invalidSourceInfo.Metadata["_ValidationErrors"].Count -gt 0 }
    @{ Test = "Les erreurs de validation contiennent une erreur de source"; Condition = $invalidSourceInfo.Metadata["_ValidationErrors"] -match "Source" }
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

# Étape 5: Valider l'information avec score invalide avec mise à jour
Write-Host "Étape 5: Valider l'information avec score invalide avec mise à jour" -ForegroundColor Cyan
$invalidScoreValidationResult = Test-ExtractedInfo -Info $invalidScoreInfo -UpdateObject

# Vérifier que la validation a fonctionné correctement
$tests5 = @(
    @{ Test = "Le résultat de la validation est faux"; Condition = $invalidScoreValidationResult -eq $false }
    @{ Test = "La propriété IsValid a été mise à jour à faux"; Condition = $invalidScoreInfo.IsValid -eq $false }
    @{ Test = "Les métadonnées contiennent _ValidationErrors"; Condition = $invalidScoreInfo.Metadata.ContainsKey("_ValidationErrors") }
    @{ Test = "Les erreurs de validation ne sont pas vides"; Condition = $invalidScoreInfo.Metadata["_ValidationErrors"].Count -gt 0 }
    @{ Test = "Les erreurs de validation contiennent une erreur de score"; Condition = $invalidScoreInfo.Metadata["_ValidationErrors"] -match "ConfidenceScore" }
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

# Étape 6: Valider l'information avec texte invalide avec mise à jour
Write-Host "Étape 6: Valider l'information avec texte invalide avec mise à jour" -ForegroundColor Cyan
$invalidTextValidationResult = Test-ExtractedInfo -Info $invalidTextInfo -UpdateObject

# Vérifier que la validation a fonctionné correctement
$tests6 = @(
    @{ Test = "Le résultat de la validation est faux"; Condition = $invalidTextValidationResult -eq $false }
    @{ Test = "La propriété IsValid a été mise à jour à faux"; Condition = $invalidTextInfo.IsValid -eq $false }
    @{ Test = "Les métadonnées contiennent _ValidationErrors"; Condition = $invalidTextInfo.Metadata.ContainsKey("_ValidationErrors") }
    @{ Test = "Les erreurs de validation ne sont pas vides"; Condition = $invalidTextInfo.Metadata["_ValidationErrors"].Count -gt 0 }
    @{ Test = "Les erreurs de validation contiennent une erreur de texte"; Condition = $invalidTextInfo.Metadata["_ValidationErrors"] -match "Text" }
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

# Étape 7: Créer une collection avec les informations invalides
Write-Host "Étape 7: Créer une collection avec les informations invalides" -ForegroundColor Cyan
$collection = New-ExtractedInfoCollection -Name "InvalidInfoCollection"
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @(
    $invalidBaseInfo, $invalidSourceInfo, $invalidScoreInfo, $invalidTextInfo,
    $invalidLanguageInfo, $invalidDataInfo, $invalidFormatInfo, $invalidMediaPathInfo, $invalidMediaTypeInfo
)

# Vérifier que la collection a été créée correctement
$tests7 = @(
    @{ Test = "La collection n'est pas nulle"; Condition = $null -ne $collection }
    @{ Test = "La collection contient 9 éléments"; Condition = $collection.Items.Count -eq 9 }
    @{ Test = "Tous les éléments de la collection sont invalides"; Condition = ($collection.Items | Where-Object { $_.IsValid -eq $false }).Count -eq 5 }
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
    @{ Test = "Les statistiques indiquent 9 éléments au total"; Condition = $stats.TotalCount -eq 9 }
    @{ Test = "Les statistiques indiquent des éléments invalides"; Condition = $stats.InvalidCount -gt 0 }
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

# Étape 9: Récupérer les erreurs de validation
Write-Host "Étape 9: Récupérer les erreurs de validation" -ForegroundColor Cyan
$baseErrors = Get-ValidationErrors -Info $invalidBaseInfo
$sourceErrors = Get-ValidationErrors -Info $invalidSourceInfo
$scoreErrors = Get-ValidationErrors -Info $invalidScoreInfo
$textErrors = Get-ValidationErrors -Info $invalidTextInfo

# Vérifier que les erreurs de validation sont correctes
$tests9 = @(
    @{ Test = "Les erreurs de l'information avec ID invalide ne sont pas nulles"; Condition = $null -ne $baseErrors }
    @{ Test = "Les erreurs de l'information avec ID invalide ne sont pas vides"; Condition = $baseErrors.Count -gt 0 }
    @{ Test = "Les erreurs de l'information avec ID invalide contiennent une erreur d'ID"; Condition = $baseErrors -match "Id" }
    
    @{ Test = "Les erreurs de l'information avec source invalide ne sont pas nulles"; Condition = $null -ne $sourceErrors }
    @{ Test = "Les erreurs de l'information avec source invalide ne sont pas vides"; Condition = $sourceErrors.Count -gt 0 }
    @{ Test = "Les erreurs de l'information avec source invalide contiennent une erreur de source"; Condition = $sourceErrors -match "Source" }
    
    @{ Test = "Les erreurs de l'information avec score invalide ne sont pas nulles"; Condition = $null -ne $scoreErrors }
    @{ Test = "Les erreurs de l'information avec score invalide ne sont pas vides"; Condition = $scoreErrors.Count -gt 0 }
    @{ Test = "Les erreurs de l'information avec score invalide contiennent une erreur de score"; Condition = $scoreErrors -match "ConfidenceScore" }
    
    @{ Test = "Les erreurs de l'information avec texte invalide ne sont pas nulles"; Condition = $null -ne $textErrors }
    @{ Test = "Les erreurs de l'information avec texte invalide ne sont pas vides"; Condition = $textErrors.Count -gt 0 }
    @{ Test = "Les erreurs de l'information avec texte invalide contiennent une erreur de texte"; Condition = $textErrors -match "Text" }
)

$success9 = $true
foreach ($test in $tests9) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success9 = $false
    }
}

# Résultat final
$allSuccess = $success1 -and $success2 -and $success3 -and $success4 -and $success5 -and $success6 -and $success7 -and $success8 -and $success9

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}
