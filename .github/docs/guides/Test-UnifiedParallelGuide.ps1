# Script de test pour vérifier le guide d'utilisation du module UnifiedParallel
#Requires -Version 5.1

# Chemin du guide d'utilisation
$guidePath = Join-Path -Path $PSScriptRoot -ChildPath "UnifiedParallel-Guide.md"

# Vérifier que le fichier existe
if (-not (Test-Path -Path $guidePath)) {
    Write-Error "Le guide d'utilisation n'existe pas à l'emplacement spécifié: $guidePath"
    exit 1
}

# Lire le contenu du guide
$guideContent = Get-Content -Path $guidePath -Raw -Encoding UTF8

# Vérifier l'encodage
$encoding = [System.Text.Encoding]::UTF8
$bytes = $encoding.GetBytes($guideContent)
$hasBOM = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF

Write-Host "Vérification du guide d'utilisation..." -ForegroundColor Cyan
Write-Host "Chemin: $guidePath" -ForegroundColor Cyan
Write-Host "Taille: $([Math]::Round(([System.IO.FileInfo]::new($guidePath).Length / 1KB), 2)) KB" -ForegroundColor Cyan
Write-Host "Encodage UTF-8 avec BOM: $hasBOM" -ForegroundColor $(if ($hasBOM) { "Green" } else { "Yellow" })

# Vérifier les sections obligatoires
$requiredSections = @(
    "Introduction",
    "Installation et prérequis",
    "Utilisation de base",
    "Fonctionnalités avancées",
    "Bonnes pratiques",
    "Exemples de cas d'utilisation",
    "Compatibilité",
    "Référence des fonctions"
)

$missingSections = @()
foreach ($section in $requiredSections) {
    if ($guideContent -notmatch $section) {
        $missingSections += $section
    }
}

if ($missingSections.Count -gt 0) {
    Write-Host "Sections manquantes:" -ForegroundColor Red
    foreach ($section in $missingSections) {
        Write-Host "- $section" -ForegroundColor Red
    }
} else {
    Write-Host "Toutes les sections obligatoires sont présentes." -ForegroundColor Green
}

# Vérifier les fonctions documentées
$requiredFunctions = @(
    "Initialize-UnifiedParallel",
    "Invoke-UnifiedParallel",
    "Clear-UnifiedParallel",
    "Get-OptimalThreadCount",
    "New-UnifiedError",
    "Get-RunspacePoolCacheInfo",
    "Clear-RunspacePoolCache",
    "Get-RunspacePoolFromCache",
    "New-RunspaceBatch",
    "Get-ModuleInitialized",
    "Set-ModuleInitialized",
    "Get-ModuleConfig",
    "Set-ModuleConfig",
    "Initialize-EncodingSettings"
)

$missingFunctions = @()
foreach ($function in $requiredFunctions) {
    if ($guideContent -notmatch $function) {
        $missingFunctions += $function
    }
}

if ($missingFunctions.Count -gt 0) {
    Write-Host "Fonctions non documentées:" -ForegroundColor Red
    foreach ($function in $missingFunctions) {
        Write-Host "- $function" -ForegroundColor Red
    }
} else {
    Write-Host "Toutes les fonctions principales sont documentées." -ForegroundColor Green
}

# Vérifier les exemples de code
$codeBlockCount = ([regex]::Matches($guideContent, "```powershell")).Count
Write-Host "Nombre de blocs de code PowerShell: $codeBlockCount" -ForegroundColor $(if ($codeBlockCount -ge 5) { "Green" } else { "Yellow" })

# Vérifier les fonctionnalités avancées
$advancedFeatures = @(
    "Gestion des ressources système",
    "Backpressure",
    "Throttling adaptatif",
    "Gestion des erreurs standardisée",
    "Cache de runspaces"
)

$missingFeatures = @()
foreach ($feature in $advancedFeatures) {
    if ($guideContent -notmatch $feature) {
        $missingFeatures += $feature
    }
}

if ($missingFeatures.Count -gt 0) {
    Write-Host "Fonctionnalités avancées non documentées:" -ForegroundColor Red
    foreach ($feature in $missingFeatures) {
        Write-Host "- $feature" -ForegroundColor Red
    }
} else {
    Write-Host "Toutes les fonctionnalités avancées sont documentées." -ForegroundColor Green
}

# Vérifier les cas d'utilisation
$useCases = @(
    "Traitement de fichiers",
    "Requêtes API",
    "Calculs intensifs",
    "Gestion des erreurs"
)

$missingUseCases = @()
foreach ($useCase in $useCases) {
    if ($guideContent -notmatch $useCase) {
        $missingUseCases += $useCase
    }
}

if ($missingUseCases.Count -gt 0) {
    Write-Host "Cas d'utilisation non documentés:" -ForegroundColor Red
    foreach ($useCase in $missingUseCases) {
        Write-Host "- $useCase" -ForegroundColor Red
    }
} else {
    Write-Host "Tous les cas d'utilisation sont documentés." -ForegroundColor Green
}

# Vérifier la compatibilité PowerShell
if ($guideContent -match "PowerShell 5.1" -and $guideContent -match "PowerShell 7") {
    Write-Host "La compatibilité PowerShell est documentée." -ForegroundColor Green
} else {
    Write-Host "La compatibilité PowerShell n'est pas correctement documentée." -ForegroundColor Red
}

# Résumé
Write-Host "`nRésumé de la vérification:" -ForegroundColor Cyan
Write-Host "- Sections obligatoires: $(if ($missingSections.Count -eq 0) { "OK" } else { "Manquantes: $($missingSections.Count)" })" -ForegroundColor $(if ($missingSections.Count -eq 0) { "Green" } else { "Red" })
Write-Host "- Fonctions documentées: $(if ($missingFunctions.Count -eq 0) { "OK" } else { "Manquantes: $($missingFunctions.Count)" })" -ForegroundColor $(if ($missingFunctions.Count -eq 0) { "Green" } else { "Red" })
Write-Host "- Blocs de code: $(if ($codeBlockCount -ge 5) { "OK ($codeBlockCount)" } else { "Insuffisants ($codeBlockCount)" })" -ForegroundColor $(if ($codeBlockCount -ge 5) { "Green" } else { "Yellow" })
Write-Host "- Fonctionnalités avancées: $(if ($missingFeatures.Count -eq 0) { "OK" } else { "Manquantes: $($missingFeatures.Count)" })" -ForegroundColor $(if ($missingFeatures.Count -eq 0) { "Green" } else { "Red" })
Write-Host "- Cas d'utilisation: $(if ($missingUseCases.Count -eq 0) { "OK" } else { "Manquants: $($missingUseCases.Count)" })" -ForegroundColor $(if ($missingUseCases.Count -eq 0) { "Green" } else { "Red" })
Write-Host "- Compatibilité PowerShell: $(if ($guideContent -match "PowerShell 5.1" -and $guideContent -match "PowerShell 7") { "OK" } else { "Non documentée" })" -ForegroundColor $(if ($guideContent -match "PowerShell 5.1" -and $guideContent -match "PowerShell 7") { "Green" } else { "Red" })

# Vérifier si le guide est complet
$isComplete = ($missingSections.Count -eq 0) -and ($missingFunctions.Count -eq 0) -and ($codeBlockCount -ge 5) -and ($missingFeatures.Count -eq 0) -and ($missingUseCases.Count -eq 0) -and ($guideContent -match "PowerShell 5.1" -and $guideContent -match "PowerShell 7")

Write-Host "`nStatut global: $(if ($isComplete) { "COMPLET" } else { "INCOMPLET" })" -ForegroundColor $(if ($isComplete) { "Green" } else { "Red" })

# Vérifier l'encodage et corriger si nécessaire
if (-not $hasBOM) {
    Write-Host "`nLe fichier n'est pas encodé en UTF-8 avec BOM. Correction..." -ForegroundColor Yellow
    
    # Lire le contenu sans BOM
    $contentWithoutBOM = Get-Content -Path $guidePath -Raw
    
    # Écrire le contenu avec BOM
    [System.IO.File]::WriteAllText($guidePath, $contentWithoutBOM, [System.Text.UTF8Encoding]::new($true))
    
    Write-Host "Encodage corrigé: UTF-8 avec BOM." -ForegroundColor Green
}

# Retourner le statut
return $isComplete
