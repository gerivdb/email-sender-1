# Test-FixInvalidInfo.ps1
# Test d'intégration pour la correction d'informations invalides

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Test du workflow de correction d'informations invalides
Write-Host "Test du workflow de correction d'informations invalides" -ForegroundColor Cyan

# Étape 1: Créer différents types d'informations extraites invalides
Write-Host "Étape 1: Créer différents types d'informations extraites invalides" -ForegroundColor Cyan

# Créer une information de base invalide (ID vide)
$invalidIdInfo = New-ExtractedInfo -Source "Source1" -ExtractorName "BaseExtractor"
$invalidIdInfo.Id = ""
$invalidIdInfo.ProcessingState = "Processed"
$invalidIdInfo.ConfidenceScore = 75
$invalidIdInfo = Add-ExtractedInfoMetadata -Info $invalidIdInfo -Key "Category" -Value "Base"

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

# Vérifier que les informations ont été créées correctement
$tests1 = @(
    @{ Test = "L'information avec ID invalide n'est pas nulle"; Condition = $null -ne $invalidIdInfo }
    @{ Test = "L'information avec source invalide n'est pas nulle"; Condition = $null -ne $invalidSourceInfo }
    @{ Test = "L'information avec score invalide n'est pas nulle"; Condition = $null -ne $invalidScoreInfo }
    @{ Test = "L'information avec texte invalide n'est pas nulle"; Condition = $null -ne $invalidTextInfo }
    @{ Test = "L'information avec langue invalide n'est pas nulle"; Condition = $null -ne $invalidLanguageInfo }
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

# Étape 2: Valider les informations invalides pour confirmer qu'elles sont invalides
Write-Host "Étape 2: Valider les informations invalides pour confirmer qu'elles sont invalides" -ForegroundColor Cyan
$invalidIdValidation = Test-ExtractedInfo -Info $invalidIdInfo
$invalidSourceValidation = Test-ExtractedInfo -Info $invalidSourceInfo
$invalidScoreValidation = Test-ExtractedInfo -Info $invalidScoreInfo
$invalidTextValidation = Test-ExtractedInfo -Info $invalidTextInfo
$invalidLanguageValidation = Test-ExtractedInfo -Info $invalidLanguageInfo

# Vérifier que les validations ont fonctionné correctement
$tests2 = @(
    @{ Test = "L'information avec ID invalide est invalide"; Condition = $invalidIdValidation -eq $false }
    @{ Test = "L'information avec source invalide est invalide"; Condition = $invalidSourceValidation -eq $false }
    @{ Test = "L'information avec score invalide est invalide"; Condition = $invalidScoreValidation -eq $false }
    @{ Test = "L'information avec texte invalide est invalide"; Condition = $invalidTextValidation -eq $false }
    @{ Test = "L'information avec langue invalide est invalide"; Condition = $invalidLanguageValidation -eq $false }
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

# Étape 3: Corriger l'information avec ID invalide
Write-Host "Étape 3: Corriger l'information avec ID invalide" -ForegroundColor Cyan
$fixedIdInfo = $invalidIdInfo.Clone()
$fixedIdInfo.Id = [guid]::NewGuid().ToString()

# Vérifier que la correction a fonctionné correctement
$fixedIdValidation = Test-ExtractedInfo -Info $fixedIdInfo
$tests3 = @(
    @{ Test = "L'information corrigée n'est pas nulle"; Condition = $null -ne $fixedIdInfo }
    @{ Test = "L'ID a été corrigé"; Condition = -not [string]::IsNullOrEmpty($fixedIdInfo.Id) }
    @{ Test = "L'ID est un GUID valide"; Condition = [guid]::TryParse($fixedIdInfo.Id, [ref][guid]::Empty) }
    @{ Test = "L'information corrigée est valide"; Condition = $fixedIdValidation -eq $true }
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

# Étape 4: Corriger l'information avec source invalide
Write-Host "Étape 4: Corriger l'information avec source invalide" -ForegroundColor Cyan
$fixedSourceInfo = $invalidSourceInfo.Clone()
$fixedSourceInfo.Source = "FixedSource"

# Vérifier que la correction a fonctionné correctement
$fixedSourceValidation = Test-ExtractedInfo -Info $fixedSourceInfo
$tests4 = @(
    @{ Test = "L'information corrigée n'est pas nulle"; Condition = $null -ne $fixedSourceInfo }
    @{ Test = "La source a été corrigée"; Condition = -not [string]::IsNullOrEmpty($fixedSourceInfo.Source) }
    @{ Test = "La source est correcte"; Condition = $fixedSourceInfo.Source -eq "FixedSource" }
    @{ Test = "L'information corrigée est valide"; Condition = $fixedSourceValidation -eq $true }
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

# Étape 5: Corriger l'information avec score invalide
Write-Host "Étape 5: Corriger l'information avec score invalide" -ForegroundColor Cyan
$fixedScoreInfo = $invalidScoreInfo.Clone()
$fixedScoreInfo.ConfidenceScore = 100

# Vérifier que la correction a fonctionné correctement
$fixedScoreValidation = Test-ExtractedInfo -Info $fixedScoreInfo
$tests5 = @(
    @{ Test = "L'information corrigée n'est pas nulle"; Condition = $null -ne $fixedScoreInfo }
    @{ Test = "Le score a été corrigé"; Condition = $fixedScoreInfo.ConfidenceScore -le 100 -and $fixedScoreInfo.ConfidenceScore -ge 0 }
    @{ Test = "Le score est correct"; Condition = $fixedScoreInfo.ConfidenceScore -eq 100 }
    @{ Test = "L'information corrigée est valide"; Condition = $fixedScoreValidation -eq $true }
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

# Étape 6: Corriger l'information avec texte invalide
Write-Host "Étape 6: Corriger l'information avec texte invalide" -ForegroundColor Cyan
$fixedTextInfo = $invalidTextInfo.Clone()
$fixedTextInfo.Text = "This is a fixed text"

# Vérifier que la correction a fonctionné correctement
$fixedTextValidation = Test-ExtractedInfo -Info $fixedTextInfo
$tests6 = @(
    @{ Test = "L'information corrigée n'est pas nulle"; Condition = $null -ne $fixedTextInfo }
    @{ Test = "Le texte a été corrigé"; Condition = -not [string]::IsNullOrEmpty($fixedTextInfo.Text) }
    @{ Test = "Le texte est correct"; Condition = $fixedTextInfo.Text -eq "This is a fixed text" }
    @{ Test = "L'information corrigée est valide"; Condition = $fixedTextValidation -eq $true }
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

# Étape 7: Corriger l'information avec langue invalide
Write-Host "Étape 7: Corriger l'information avec langue invalide" -ForegroundColor Cyan
$fixedLanguageInfo = $invalidLanguageInfo.Clone()
$fixedLanguageInfo.Language = "fr"

# Vérifier que la correction a fonctionné correctement
$fixedLanguageValidation = Test-ExtractedInfo -Info $fixedLanguageInfo
$tests7 = @(
    @{ Test = "L'information corrigée n'est pas nulle"; Condition = $null -ne $fixedLanguageInfo }
    @{ Test = "La langue a été corrigée"; Condition = -not [string]::IsNullOrEmpty($fixedLanguageInfo.Language) }
    @{ Test = "La langue est correcte"; Condition = $fixedLanguageInfo.Language -eq "fr" }
    @{ Test = "L'information corrigée est valide"; Condition = $fixedLanguageValidation -eq $true }
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

# Étape 8: Créer une collection avec les informations invalides et corrigées
Write-Host "Étape 8: Créer une collection avec les informations invalides et corrigées" -ForegroundColor Cyan
$collection = New-ExtractedInfoCollection -Name "MixedInfoCollection"
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @(
    $invalidIdInfo, $invalidSourceInfo, $invalidScoreInfo, $invalidTextInfo, $invalidLanguageInfo,
    $fixedIdInfo, $fixedSourceInfo, $fixedScoreInfo, $fixedTextInfo, $fixedLanguageInfo
)

# Vérifier que la collection a été créée correctement
$tests8 = @(
    @{ Test = "La collection n'est pas nulle"; Condition = $null -ne $collection }
    @{ Test = "La collection contient 10 éléments"; Condition = $collection.Items.Count -eq 10 }
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

# Étape 9: Obtenir des statistiques sur la collection
Write-Host "Étape 9: Obtenir des statistiques sur la collection" -ForegroundColor Cyan
$stats = Get-ExtractedInfoCollectionStatistics -Collection $collection

# Vérifier que les statistiques sont correctes
$tests9 = @(
    @{ Test = "Les statistiques ne sont pas nulles"; Condition = $null -ne $stats }
    @{ Test = "Les statistiques indiquent 10 éléments au total"; Condition = $stats.TotalCount -eq 10 }
    @{ Test = "Les statistiques indiquent des éléments valides"; Condition = $stats.ValidCount -gt 0 }
    @{ Test = "Les statistiques indiquent des éléments invalides"; Condition = $stats.InvalidCount -gt 0 }
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

# Étape 10: Filtrer les éléments valides et invalides
Write-Host "Étape 10: Filtrer les éléments valides et invalides" -ForegroundColor Cyan

# Valider tous les éléments de la collection avec mise à jour
foreach ($item in $collection.Items) {
    $validationResult = Test-ExtractedInfo -Info $item -UpdateObject
}

# Filtrer les éléments valides et invalides
$validItems = $collection.Items | Where-Object { $_.IsValid -eq $true }
$invalidItems = $collection.Items | Where-Object { $_.IsValid -eq $false }

# Vérifier que le filtrage a fonctionné correctement
$tests10 = @(
    @{ Test = "Il y a des éléments valides"; Condition = $validItems.Count -gt 0 }
    @{ Test = "Il y a des éléments invalides"; Condition = $invalidItems.Count -gt 0 }
    @{ Test = "Le nombre d'éléments valides est correct"; Condition = $validItems.Count -eq 5 }
    @{ Test = "Le nombre d'éléments invalides est correct"; Condition = $invalidItems.Count -eq 5 }
)

$success10 = $true
foreach ($test in $tests10) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success10 = $false
    }
}

# Résultat final
$allSuccess = $success1 -and $success2 -and $success3 -and $success4 -and $success5 -and $success6 -and $success7 -and $success8 -and $success9 -and $success10

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}
