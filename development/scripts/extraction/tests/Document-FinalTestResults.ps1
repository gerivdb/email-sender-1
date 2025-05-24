# Document-FinalTestResults.ps1
# Script pour documenter les résultats finaux des tests

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Définir le chemin du répertoire des résultats
$resultsDir = Join-Path -Path $PSScriptRoot -ChildPath "Results"
$fixedResultsDir = Join-Path -Path $resultsDir -ChildPath "Fixed"
$verificationDir = Join-Path -Path $resultsDir -ChildPath "Verification"
$docsDir = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Docs"

# Créer le répertoire de documentation s'il n'existe pas
if (-not (Test-Path -Path $docsDir)) {
    New-Item -Path $docsDir -ItemType Directory -Force | Out-Null
}

# Définir le fichier de documentation des résultats finaux
$finalResultsFile = Join-Path -Path $docsDir -ChildPath "FinalTestResults.md"

# Initialiser le fichier de documentation des résultats finaux
Set-Content -Path $finalResultsFile -Value "# Résultats finaux des tests du module ExtractedInfoModuleV2`r`n"
Add-Content -Path $finalResultsFile -Value "Date de documentation : $(Get-Date)`r`n"
Add-Content -Path $finalResultsFile -Value "Ce document présente les résultats finaux des tests du module ExtractedInfoModuleV2 après correction des problèmes identifiés.`r`n"

# Fonction pour extraire les résultats d'un fichier de vérification
function Export-VerificationResults {
    param (
        [string]$VerificationFile
    )
    
    if (-not (Test-Path -Path $VerificationFile)) {
        Write-Host "Le fichier de vérification n'existe pas : $VerificationFile" -ForegroundColor $errorColor
        return $null
    }
    
    $content = Get-Content -Path $VerificationFile -Raw
    if ([string]::IsNullOrEmpty($content)) {
        Write-Host "Le fichier de vérification est vide : $VerificationFile" -ForegroundColor $warningColor
        return $null
    }
    
    # Extraire les informations du résumé global
    $unitTestsTotal = 0
    $unitTestsPassed = 0
    $unitTestsFailed = 0
    $unitTestsSuccess = $false
    
    $integrationTestsTotal = 0
    $integrationTestsPassed = 0
    $integrationTestsFailed = 0
    $integrationTestsSuccess = $false
    
    $allTestsTotal = 0
    $allTestsPassed = 0
    $allTestsFailed = 0
    $allTestsSuccess = $false
    
    # Extraire les informations des tests unitaires
    if ($content -match "### Tests unitaires\r?\n\r?\n- Total des tests : (\d+)\r?\n- Tests réussis : (\d+)\r?\n- Tests échoués : (\d+)\r?\n- Statut global : (SUCCÈS|ÉCHEC)") {
        $unitTestsTotal = [int]$Matches[1]
        $unitTestsPassed = [int]$Matches[2]
        $unitTestsFailed = [int]$Matches[3]
        $unitTestsSuccess = ($Matches[4] -eq "SUCCÈS")
    }
    
    # Extraire les informations des tests d'intégration
    if ($content -match "### Tests d'intégration\r?\n\r?\n- Total des tests : (\d+)\r?\n- Tests réussis : (\d+)\r?\n- Tests échoués : (\d+)\r?\n- Statut global : (SUCCÈS|ÉCHEC)") {
        $integrationTestsTotal = [int]$Matches[1]
        $integrationTestsPassed = [int]$Matches[2]
        $integrationTestsFailed = [int]$Matches[3]
        $integrationTestsSuccess = ($Matches[4] -eq "SUCCÈS")
    }
    
    # Extraire les informations de tous les tests
    if ($content -match "### Tous les tests\r?\n\r?\n- Total des tests : (\d+)\r?\n- Tests réussis : (\d+)\r?\n- Tests échoués : (\d+)\r?\n- Statut global : (SUCCÈS|ÉCHEC)") {
        $allTestsTotal = [int]$Matches[1]
        $allTestsPassed = [int]$Matches[2]
        $allTestsFailed = [int]$Matches[3]
        $allTestsSuccess = ($Matches[4] -eq "SUCCÈS")
    }
    
    return @{
        UnitTests = @{
            Total = $unitTestsTotal
            Passed = $unitTestsPassed
            Failed = $unitTestsFailed
            Success = $unitTestsSuccess
        }
        IntegrationTests = @{
            Total = $integrationTestsTotal
            Passed = $integrationTestsPassed
            Failed = $integrationTestsFailed
            Success = $integrationTestsSuccess
        }
        AllTests = @{
            Total = $allTestsTotal
            Passed = $allTestsPassed
            Failed = $allTestsFailed
            Success = $allTestsSuccess
        }
    }
}

# Extraire les résultats de la vérification
$verificationFile = Join-Path -Path $verificationDir -ChildPath "AllTests_Verification.md"
$verificationResults = Export-VerificationResults -VerificationFile $verificationFile

if ($null -eq $verificationResults) {
    Write-Host "Impossible d'extraire les résultats de la vérification." -ForegroundColor $errorColor
    Add-Content -Path $finalResultsFile -Value "## Erreur`r`n"
    Add-Content -Path $finalResultsFile -Value "Impossible d'extraire les résultats de la vérification.`r`n"
    exit 1
}

# Documenter les résultats des tests unitaires
Add-Content -Path $finalResultsFile -Value "## Résultats des tests unitaires`r`n"
Add-Content -Path $finalResultsFile -Value "### Résumé`r`n"
Add-Content -Path $finalResultsFile -Value "- Total des tests : $($verificationResults.UnitTests.Total)"
Add-Content -Path $finalResultsFile -Value "- Tests réussis : $($verificationResults.UnitTests.Passed)"
Add-Content -Path $finalResultsFile -Value "- Tests échoués : $($verificationResults.UnitTests.Failed)"
Add-Content -Path $finalResultsFile -Value "- Statut global : $($verificationResults.UnitTests.Success ? 'SUCCÈS' : 'ÉCHEC')`r`n"

Add-Content -Path $finalResultsFile -Value "### Catégories de tests unitaires`r`n"
Add-Content -Path $finalResultsFile -Value "Les tests unitaires couvrent les fonctionnalités suivantes :"
Add-Content -Path $finalResultsFile -Value "- Fonctions de base (New-ExtractedInfo, New-TextExtractedInfo, etc.)"
Add-Content -Path $finalResultsFile -Value "- Fonctions de métadonnées (Add-ExtractedInfoMetadata, Get-ExtractedInfoMetadata, etc.)"
Add-Content -Path $finalResultsFile -Value "- Fonctions de collection (New-ExtractedInfoCollection, Add-ExtractedInfoToCollection, etc.)"
Add-Content -Path $finalResultsFile -Value "- Fonctions de sérialisation (ConvertTo-ExtractedInfoJson, Save-ExtractedInfoToFile, etc.)"
Add-Content -Path $finalResultsFile -Value "- Fonctions de validation (Test-ExtractedInfo, Get-ValidationErrors, etc.)`r`n"

# Documenter les résultats des tests d'intégration
Add-Content -Path $finalResultsFile -Value "## Résultats des tests d'intégration`r`n"
Add-Content -Path $finalResultsFile -Value "### Résumé`r`n"
Add-Content -Path $finalResultsFile -Value "- Total des tests : $($verificationResults.IntegrationTests.Total)"
Add-Content -Path $finalResultsFile -Value "- Tests réussis : $($verificationResults.IntegrationTests.Passed)"
Add-Content -Path $finalResultsFile -Value "- Tests échoués : $($verificationResults.IntegrationTests.Failed)"
Add-Content -Path $finalResultsFile -Value "- Statut global : $($verificationResults.IntegrationTests.Success ? 'SUCCÈS' : 'ÉCHEC')`r`n"

Add-Content -Path $finalResultsFile -Value "### Catégories de tests d'intégration`r`n"
Add-Content -Path $finalResultsFile -Value "Les tests d'intégration couvrent les workflows suivants :"
Add-Content -Path $finalResultsFile -Value "- Workflow d'extraction et stockage (extraction de texte, données structurées, médias, etc.)"
Add-Content -Path $finalResultsFile -Value "- Workflow de collection et filtrage (création de collection, filtrage par source, type, etc.)"
Add-Content -Path $finalResultsFile -Value "- Workflow de sérialisation et chargement (sérialisation en JSON, sauvegarde dans un fichier, etc.)"
Add-Content -Path $finalResultsFile -Value "- Workflow de validation et correction (validation d'informations, correction d'erreurs, etc.)`r`n"

# Documenter les résultats globaux
Add-Content -Path $finalResultsFile -Value "## Résultats globaux`r`n"
Add-Content -Path $finalResultsFile -Value "### Résumé`r`n"
Add-Content -Path $finalResultsFile -Value "- Total des tests : $($verificationResults.AllTests.Total)"
Add-Content -Path $finalResultsFile -Value "- Tests réussis : $($verificationResults.AllTests.Passed)"
Add-Content -Path $finalResultsFile -Value "- Tests échoués : $($verificationResults.AllTests.Failed)"
Add-Content -Path $finalResultsFile -Value "- Statut global : $($verificationResults.AllTests.Success ? 'SUCCÈS' : 'ÉCHEC')`r`n"

# Documenter la couverture des tests
Add-Content -Path $finalResultsFile -Value "## Couverture des tests`r`n"
Add-Content -Path $finalResultsFile -Value "### Fonctionnalités couvertes`r`n"
Add-Content -Path $finalResultsFile -Value "Les tests couvrent les fonctionnalités suivantes du module ExtractedInfoModuleV2 :"
Add-Content -Path $finalResultsFile -Value "- Création et manipulation d'informations extraites (texte, données structurées, médias)"
Add-Content -Path $finalResultsFile -Value "- Gestion des métadonnées associées aux informations extraites"
Add-Content -Path $finalResultsFile -Value "- Création et manipulation de collections d'informations extraites"
Add-Content -Path $finalResultsFile -Value "- Sérialisation et désérialisation des informations extraites (JSON)"
Add-Content -Path $finalResultsFile -Value "- Sauvegarde et chargement des informations extraites depuis des fichiers"
Add-Content -Path $finalResultsFile -Value "- Validation et correction des informations extraites"
Add-Content -Path $finalResultsFile -Value "- Filtrage des informations extraites selon différents critères`r`n"

# Documenter les problèmes corrigés
Add-Content -Path $finalResultsFile -Value "## Problèmes corrigés`r`n"
Add-Content -Path $finalResultsFile -Value "Les problèmes suivants ont été identifiés et corrigés :"
Add-Content -Path $finalResultsFile -Value "- Problèmes dans les fonctions de base (génération d'ID, initialisation des métadonnées, etc.)"
Add-Content -Path $finalResultsFile -Value "- Problèmes dans les fonctions de métadonnées (ajout, récupération, suppression de métadonnées)"
Add-Content -Path $finalResultsFile -Value "- Problèmes dans les fonctions de collection (création, ajout, suppression d'éléments)"
Add-Content -Path $finalResultsFile -Value "- Problèmes dans les fonctions de sérialisation (conversion en JSON, sauvegarde dans un fichier)"
Add-Content -Path $finalResultsFile -Value "- Problèmes dans les fonctions de validation (validation des informations, règles de validation)`r`n"

# Documenter la conclusion
Add-Content -Path $finalResultsFile -Value "## Conclusion`r`n"

if ($verificationResults.AllTests.Success) {
    Add-Content -Path $finalResultsFile -Value "**Tous les tests ont réussi!** Le module ExtractedInfoModuleV2 fonctionne correctement et est prêt à être utilisé en production."
    Add-Content -Path $finalResultsFile -Value "`r`nLe module a été testé de manière approfondie, couvrant toutes les fonctionnalités principales et les workflows d'utilisation typiques. Les problèmes identifiés ont été corrigés avec succès."
} else {
    Add-Content -Path $finalResultsFile -Value "**Certains tests ont échoué.** Des problèmes subsistent dans le module ExtractedInfoModuleV2."
    Add-Content -Path $finalResultsFile -Value "`r`nBien que la plupart des problèmes aient été corrigés, certains tests échouent encore. Des investigations supplémentaires sont nécessaires pour résoudre ces problèmes avant de pouvoir utiliser le module en production."
}

# Afficher le résumé
Write-Host "`nRésumé de la documentation des résultats finaux :" -ForegroundColor $infoColor
Write-Host "  Tests unitaires :" -ForegroundColor $infoColor
Write-Host "    Total des tests : $($verificationResults.UnitTests.Total)" -ForegroundColor $infoColor
Write-Host "    Tests réussis : $($verificationResults.UnitTests.Passed)" -ForegroundColor $successColor
Write-Host "    Tests échoués : $($verificationResults.UnitTests.Failed)" -ForegroundColor $errorColor
Write-Host "    Statut global : $($verificationResults.UnitTests.Success ? 'SUCCÈS' : 'ÉCHEC')" -ForegroundColor ($verificationResults.UnitTests.Success ? $successColor : $errorColor)

Write-Host "`n  Tests d'intégration :" -ForegroundColor $infoColor
Write-Host "    Total des tests : $($verificationResults.IntegrationTests.Total)" -ForegroundColor $infoColor
Write-Host "    Tests réussis : $($verificationResults.IntegrationTests.Passed)" -ForegroundColor $successColor
Write-Host "    Tests échoués : $($verificationResults.IntegrationTests.Failed)" -ForegroundColor $errorColor
Write-Host "    Statut global : $($verificationResults.IntegrationTests.Success ? 'SUCCÈS' : 'ÉCHEC')" -ForegroundColor ($verificationResults.IntegrationTests.Success ? $successColor : $errorColor)

Write-Host "`n  Tous les tests :" -ForegroundColor $infoColor
Write-Host "    Total des tests : $($verificationResults.AllTests.Total)" -ForegroundColor $infoColor
Write-Host "    Tests réussis : $($verificationResults.AllTests.Passed)" -ForegroundColor $successColor
Write-Host "    Tests échoués : $($verificationResults.AllTests.Failed)" -ForegroundColor $errorColor
Write-Host "    Statut global : $($verificationResults.AllTests.Success ? 'SUCCÈS' : 'ÉCHEC')" -ForegroundColor ($verificationResults.AllTests.Success ? $successColor : $errorColor)

Write-Host "`nLa documentation des résultats finaux a été créée avec succès : $finalResultsFile" -ForegroundColor $successColor

# Retourner le code de sortie
exit 0

