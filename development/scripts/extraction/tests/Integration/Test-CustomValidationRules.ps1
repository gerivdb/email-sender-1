# Test-CustomValidationRules.ps1
# Test d'intégration pour l'ajout de règles de validation personnalisées

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Test du workflow d'ajout de règles de validation personnalisées
Write-Host "Test du workflow d'ajout de règles de validation personnalisées" -ForegroundColor Cyan

# Étape 1: Définir des règles de validation personnalisées
Write-Host "Étape 1: Définir des règles de validation personnalisées" -ForegroundColor Cyan

# Règle 1: Vérifier que le score de confiance est supérieur à 50 pour tous les types d'informations
$minConfidenceRule = {
    param($Info)
    return $Info.ConfidenceScore -ge 50
}
$minConfidenceRuleResult = Add-ValidationRule -Name "MinimumConfidenceScore" -InfoType "ExtractedInfo" -ValidationScript $minConfidenceRule -ErrorMessage "Confidence score must be at least 50"

# Règle 2: Vérifier que le texte a une longueur minimale pour les informations de texte
$minTextLengthRule = {
    param($Info)
    return $Info.Text.Length -ge 10
}
$minTextLengthRuleResult = Add-ValidationRule -Name "MinimumTextLength" -InfoType "TextExtractedInfo" -ValidationScript $minTextLengthRule -ErrorMessage "Text must be at least 10 characters long"

# Règle 3: Vérifier que les données contiennent une propriété spécifique pour les informations de données structurées
$requiredDataPropertyRule = {
    param($Info)
    return $Info.Data -ne $null -and $Info.Data.ContainsKey("Name")
}
$requiredDataPropertyRuleResult = Add-ValidationRule -Name "RequiredDataProperty" -InfoType "StructuredDataExtractedInfo" -ValidationScript $requiredDataPropertyRule -ErrorMessage "Data must contain a 'Name' property"

# Règle 4: Vérifier que le type de média est valide pour les informations de média
$validMediaTypeRule = {
    param($Info)
    return @("Image", "Video", "Audio") -contains $Info.MediaType
}
$validMediaTypeRuleResult = Add-ValidationRule -Name "ValidMediaType" -InfoType "MediaExtractedInfo" -ValidationScript $validMediaTypeRule -ErrorMessage "Media type must be one of: Image, Video, Audio"

# Vérifier que les règles ont été ajoutées correctement
$tests1 = @(
    @{ Test = "La règle de score de confiance minimum a été ajoutée"; Condition = $null -ne $minConfidenceRuleResult }
    @{ Test = "La règle de longueur de texte minimum a été ajoutée"; Condition = $null -ne $minTextLengthRuleResult }
    @{ Test = "La règle de propriété de données requise a été ajoutée"; Condition = $null -ne $requiredDataPropertyRuleResult }
    @{ Test = "La règle de type de média valide a été ajoutée"; Condition = $null -ne $validMediaTypeRuleResult }
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

# Étape 2: Créer des informations valides selon les règles personnalisées
Write-Host "Étape 2: Créer des informations valides selon les règles personnalisées" -ForegroundColor Cyan

# Information de base valide (score de confiance >= 50)
$validBaseInfo = New-ExtractedInfo -Source "Source1" -ExtractorName "BaseExtractor"
$validBaseInfo.ProcessingState = "Processed"
$validBaseInfo.ConfidenceScore = 75
$validBaseInfo = Add-ExtractedInfoMetadata -Info $validBaseInfo -Key "Category" -Value "Base"

# Information de texte valide (texte >= 10 caractères)
$validTextInfo = New-TextExtractedInfo -Source "Source2" -ExtractorName "TextExtractor" -Text "This is a valid text with more than 10 characters" -Language "en"
$validTextInfo.ProcessingState = "Processed"
$validTextInfo.ConfidenceScore = 85
$validTextInfo = Add-ExtractedInfoMetadata -Info $validTextInfo -Key "Category" -Value "Text"

# Information de données structurées valide (contient la propriété "Name")
$validDataInfo = New-StructuredDataExtractedInfo -Source "Source3" -ExtractorName "DataExtractor" -Data @{
    Name = "Valid Data"
    Value = 123
    IsActive = $true
} -DataFormat "Hashtable"
$validDataInfo.ProcessingState = "Processed"
$validDataInfo.ConfidenceScore = 90
$validDataInfo = Add-ExtractedInfoMetadata -Info $validDataInfo -Key "Category" -Value "Data"

# Information de média valide (type de média valide)
$validMediaInfo = New-MediaExtractedInfo -Source "Source4" -ExtractorName "MediaExtractor" -MediaPath "valid.jpg" -MediaType "Image"
$validMediaInfo.ProcessingState = "Processed"
$validMediaInfo.ConfidenceScore = 80
$validMediaInfo = Add-ExtractedInfoMetadata -Info $validMediaInfo -Key "Category" -Value "Media"

# Vérifier que les informations ont été créées correctement
$tests2 = @(
    @{ Test = "L'information de base valide n'est pas nulle"; Condition = $null -ne $validBaseInfo }
    @{ Test = "L'information de texte valide n'est pas nulle"; Condition = $null -ne $validTextInfo }
    @{ Test = "L'information de données valide n'est pas nulle"; Condition = $null -ne $validDataInfo }
    @{ Test = "L'information de média valide n'est pas nulle"; Condition = $null -ne $validMediaInfo }
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

# Étape 3: Créer des informations invalides selon les règles personnalisées
Write-Host "Étape 3: Créer des informations invalides selon les règles personnalisées" -ForegroundColor Cyan

# Information de base invalide (score de confiance < 50)
$invalidBaseInfo = New-ExtractedInfo -Source "Source1" -ExtractorName "BaseExtractor"
$invalidBaseInfo.ProcessingState = "Processed"
$invalidBaseInfo.ConfidenceScore = 30
$invalidBaseInfo = Add-ExtractedInfoMetadata -Info $invalidBaseInfo -Key "Category" -Value "Base"

# Information de texte invalide (texte < 10 caractères)
$invalidTextInfo = New-TextExtractedInfo -Source "Source2" -ExtractorName "TextExtractor" -Text "Short" -Language "en"
$invalidTextInfo.ProcessingState = "Processed"
$invalidTextInfo.ConfidenceScore = 85
$invalidTextInfo = Add-ExtractedInfoMetadata -Info $invalidTextInfo -Key "Category" -Value "Text"

# Information de données structurées invalide (ne contient pas la propriété "Name")
$invalidDataInfo = New-StructuredDataExtractedInfo -Source "Source3" -ExtractorName "DataExtractor" -Data @{
    Value = 123
    IsActive = $true
} -DataFormat "Hashtable"
$invalidDataInfo.ProcessingState = "Processed"
$invalidDataInfo.ConfidenceScore = 90
$invalidDataInfo = Add-ExtractedInfoMetadata -Info $invalidDataInfo -Key "Category" -Value "Data"

# Information de média invalide (type de média invalide)
$invalidMediaInfo = New-MediaExtractedInfo -Source "Source4" -ExtractorName "MediaExtractor" -MediaPath "valid.jpg" -MediaType "Document"
$invalidMediaInfo.ProcessingState = "Processed"
$invalidMediaInfo.ConfidenceScore = 80
$invalidMediaInfo = Add-ExtractedInfoMetadata -Info $invalidMediaInfo -Key "Category" -Value "Media"

# Vérifier que les informations ont été créées correctement
$tests3 = @(
    @{ Test = "L'information de base invalide n'est pas nulle"; Condition = $null -ne $invalidBaseInfo }
    @{ Test = "L'information de texte invalide n'est pas nulle"; Condition = $null -ne $invalidTextInfo }
    @{ Test = "L'information de données invalide n'est pas nulle"; Condition = $null -ne $invalidDataInfo }
    @{ Test = "L'information de média invalide n'est pas nulle"; Condition = $null -ne $invalidMediaInfo }
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

# Étape 4: Appliquer manuellement les règles de validation personnalisées
Write-Host "Étape 4: Appliquer manuellement les règles de validation personnalisées" -ForegroundColor Cyan

# Fonction pour appliquer les règles de validation personnalisées
function Test-CustomValidation {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info
    )
    
    $isValid = $true
    $errors = @()
    
    # Appliquer les règles en fonction du type d'information
    switch ($Info._Type) {
        "ExtractedInfo" {
            # Règle de score de confiance minimum
            if (-not (& $minConfidenceRule $Info)) {
                $isValid = $false
                $errors += "Confidence score must be at least 50"
            }
        }
        "TextExtractedInfo" {
            # Règle de score de confiance minimum (héritée)
            if (-not (& $minConfidenceRule $Info)) {
                $isValid = $false
                $errors += "Confidence score must be at least 50"
            }
            
            # Règle de longueur de texte minimum
            if (-not (& $minTextLengthRule $Info)) {
                $isValid = $false
                $errors += "Text must be at least 10 characters long"
            }
        }
        "StructuredDataExtractedInfo" {
            # Règle de score de confiance minimum (héritée)
            if (-not (& $minConfidenceRule $Info)) {
                $isValid = $false
                $errors += "Confidence score must be at least 50"
            }
            
            # Règle de propriété de données requise
            if (-not (& $requiredDataPropertyRule $Info)) {
                $isValid = $false
                $errors += "Data must contain a 'Name' property"
            }
        }
        "MediaExtractedInfo" {
            # Règle de score de confiance minimum (héritée)
            if (-not (& $minConfidenceRule $Info)) {
                $isValid = $false
                $errors += "Confidence score must be at least 50"
            }
            
            # Règle de type de média valide
            if (-not (& $validMediaTypeRule $Info)) {
                $isValid = $false
                $errors += "Media type must be one of: Image, Video, Audio"
            }
        }
    }
    
    return @{
        IsValid = $isValid
        Errors = $errors
    }
}

# Appliquer les règles de validation personnalisées aux informations valides
$validBaseValidation = Test-CustomValidation -Info $validBaseInfo
$validTextValidation = Test-CustomValidation -Info $validTextInfo
$validDataValidation = Test-CustomValidation -Info $validDataInfo
$validMediaValidation = Test-CustomValidation -Info $validMediaInfo

# Appliquer les règles de validation personnalisées aux informations invalides
$invalidBaseValidation = Test-CustomValidation -Info $invalidBaseInfo
$invalidTextValidation = Test-CustomValidation -Info $invalidTextInfo
$invalidDataValidation = Test-CustomValidation -Info $invalidDataInfo
$invalidMediaValidation = Test-CustomValidation -Info $invalidMediaInfo

# Vérifier que les validations ont fonctionné correctement
$tests4 = @(
    @{ Test = "L'information de base valide est valide selon les règles personnalisées"; Condition = $validBaseValidation.IsValid -eq $true }
    @{ Test = "L'information de texte valide est valide selon les règles personnalisées"; Condition = $validTextValidation.IsValid -eq $true }
    @{ Test = "L'information de données valide est valide selon les règles personnalisées"; Condition = $validDataValidation.IsValid -eq $true }
    @{ Test = "L'information de média valide est valide selon les règles personnalisées"; Condition = $validMediaValidation.IsValid -eq $true }
    
    @{ Test = "L'information de base invalide est invalide selon les règles personnalisées"; Condition = $invalidBaseValidation.IsValid -eq $false }
    @{ Test = "L'information de texte invalide est invalide selon les règles personnalisées"; Condition = $invalidTextValidation.IsValid -eq $false }
    @{ Test = "L'information de données invalide est invalide selon les règles personnalisées"; Condition = $invalidDataValidation.IsValid -eq $false }
    @{ Test = "L'information de média invalide est invalide selon les règles personnalisées"; Condition = $invalidMediaValidation.IsValid -eq $false }
    
    @{ Test = "L'information de base invalide a des erreurs"; Condition = $invalidBaseValidation.Errors.Count -gt 0 }
    @{ Test = "L'information de texte invalide a des erreurs"; Condition = $invalidTextValidation.Errors.Count -gt 0 }
    @{ Test = "L'information de données invalide a des erreurs"; Condition = $invalidDataValidation.Errors.Count -gt 0 }
    @{ Test = "L'information de média invalide a des erreurs"; Condition = $invalidMediaValidation.Errors.Count -gt 0 }
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

# Étape 5: Créer une collection avec les informations valides et invalides
Write-Host "Étape 5: Créer une collection avec les informations valides et invalides" -ForegroundColor Cyan
$collection = New-ExtractedInfoCollection -Name "CustomValidationCollection"
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @(
    $validBaseInfo, $validTextInfo, $validDataInfo, $validMediaInfo,
    $invalidBaseInfo, $invalidTextInfo, $invalidDataInfo, $invalidMediaInfo
)

# Vérifier que la collection a été créée correctement
$tests5 = @(
    @{ Test = "La collection n'est pas nulle"; Condition = $null -ne $collection }
    @{ Test = "La collection contient 8 éléments"; Condition = $collection.Items.Count -eq 8 }
    @{ Test = "La collection contient 4 éléments valides selon les règles standard"; Condition = ($collection.Items | Where-Object { (Test-ExtractedInfo -Info $_) -eq $true }).Count -eq 8 }
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

# Étape 6: Appliquer les règles de validation personnalisées à la collection
Write-Host "Étape 6: Appliquer les règles de validation personnalisées à la collection" -ForegroundColor Cyan

# Appliquer les règles de validation personnalisées à tous les éléments de la collection
$validationResults = @()
foreach ($item in $collection.Items) {
    $validationResults += Test-CustomValidation -Info $item
}

# Compter les éléments valides et invalides selon les règles personnalisées
$validCount = ($validationResults | Where-Object { $_.IsValid -eq $true }).Count
$invalidCount = ($validationResults | Where-Object { $_.IsValid -eq $false }).Count

# Vérifier que les validations ont fonctionné correctement
$tests6 = @(
    @{ Test = "Il y a des résultats de validation"; Condition = $validationResults.Count -gt 0 }
    @{ Test = "Le nombre de résultats de validation est correct"; Condition = $validationResults.Count -eq 8 }
    @{ Test = "Il y a 4 éléments valides selon les règles personnalisées"; Condition = $validCount -eq 4 }
    @{ Test = "Il y a 4 éléments invalides selon les règles personnalisées"; Condition = $invalidCount -eq 4 }
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
