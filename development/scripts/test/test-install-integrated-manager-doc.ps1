# Test de la documentation du script install-integrated-manager.ps1

# Définir le chemin du projet
$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

# Définir les chemins des fichiers
$scriptPath = Join-Path -Path $ProjectRoot -ChildPath "development\managers\integrated-manager\scripts\install-integrated-manager.ps1"
$docPath = Join-Path -Path $ProjectRoot -ChildPath "development\docs\guides\methodologies\install_integrated_manager.md"

# Vérifier que les fichiers existent
if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
    Write-Error "Le script install-integrated-manager.ps1 est introuvable : $scriptPath"
    exit 1
}

if (-not (Test-Path -Path $docPath -PathType Leaf)) {
    Write-Error "La documentation du script install-integrated-manager.ps1 est introuvable : $docPath"
    exit 1
}

# Lire le contenu des fichiers
$scriptContent = Get-Content -Path $scriptPath -Raw
$docContent = Get-Content -Path $docPath -Raw

# Vérifier que la documentation contient les sections requises
$sections = @(
    "## Introduction",
    "## Objectif",
    "## Prérequis",
    "## Paramètres",
    "## Fonctionnement détaillé",
    "## Exemples d'utilisation",
    "## Cas d'erreur et résolution",
    "## Bonnes pratiques",
    "## Intégration avec d'autres scripts",
    "## Conclusion"
)

$sectionResults = @()
foreach ($section in $sections) {
    $sectionExists = $docContent -match [regex]::Escape($section)
    if ($sectionExists) {
        Write-Host "Section trouvee : $section" -ForegroundColor Green
    } else {
        Write-Host "Section manquante : $section" -ForegroundColor Red
    }
    $sectionResults += [PSCustomObject]@{
        Section = $section
        Exists  = $sectionExists
    }
}

# Vérifier que la documentation mentionne les paramètres du script
$parameters = @(
    "ProjectRoot",
    "Force"
)

$parameterResults = @()
foreach ($parameter in $parameters) {
    $parameterExists = $docContent -match [regex]::Escape($parameter)
    if ($parameterExists) {
        Write-Host "Parametre documente : $parameter" -ForegroundColor Green
    } else {
        Write-Host "Parametre non documente : $parameter" -ForegroundColor Red
    }
    $parameterResults += [PSCustomObject]@{
        Parameter = $parameter
        Exists    = $parameterExists
    }
}

# Vérifier que la documentation contient une table des paramètres
$tableExists = $docContent -match "\| Parametre \|" -or $docContent -match "\| Paramètre \|"
if ($tableExists) {
    Write-Host "Table des parametres trouvee" -ForegroundColor Green
} else {
    Write-Host "Table des parametres manquante" -ForegroundColor Red
}

# Vérifier que la documentation contient des exemples d'utilisation
$examplesExist = $docContent -match "```powershell"
if ($examplesExist) {
    Write-Host "Exemples d'utilisation trouves" -ForegroundColor Green
} else {
    Write-Host "Exemples d'utilisation manquants" -ForegroundColor Red
}

# Vérifier que la documentation contient des cas d'erreur
$errorsExist = $docContent -match "\*\*Erreur :\*\*"
if ($errorsExist) {
    Write-Host "Cas d'erreur trouves" -ForegroundColor Green
} else {
    Write-Host "Cas d'erreur manquants" -ForegroundColor Red
}

# Afficher un résumé des résultats
Write-Host ""
Write-Host "Resume des tests" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan

$missingSections = $sectionResults | Where-Object { -not $_.Exists } | ForEach-Object { $_.Section }
$missingParameters = $parameterResults | Where-Object { -not $_.Exists } | ForEach-Object { $_.Parameter }

$allSectionsExist = ($missingSections.Count -eq 0)
$allParametersExist = ($missingParameters.Count -eq 0)
$allChecksPass = $allSectionsExist -and $allParametersExist -and $tableExists -and $examplesExist -and $errorsExist

if ($allSectionsExist) {
    Write-Host "Toutes les sections sont presentes" -ForegroundColor Green
} else {
    Write-Host "Sections manquantes : $($missingSections.Count)" -ForegroundColor Red
    foreach ($section in $missingSections) {
        Write-Host "  - $section" -ForegroundColor Red
    }
}

if ($allParametersExist) {
    Write-Host "Tous les parametres sont documentes" -ForegroundColor Green
} else {
    Write-Host "Parametres non documentes : $($missingParameters.Count)" -ForegroundColor Red
    foreach ($parameter in $missingParameters) {
        Write-Host "  - $parameter" -ForegroundColor Red
    }
}

if ($tableExists) {
    Write-Host "Table des parametres : Presente" -ForegroundColor Green
} else {
    Write-Host "Table des parametres : Manquante" -ForegroundColor Red
}

if ($examplesExist) {
    Write-Host "Exemples d'utilisation : Presents" -ForegroundColor Green
} else {
    Write-Host "Exemples d'utilisation : Manquants" -ForegroundColor Red
}

if ($errorsExist) {
    Write-Host "Cas d'erreur : Presents" -ForegroundColor Green
} else {
    Write-Host "Cas d'erreur : Manquants" -ForegroundColor Red
}

Write-Host ""
if ($allChecksPass) {
    Write-Host "Resultat final : SUCCES" -ForegroundColor Green
} else {
    Write-Host "Resultat final : ECHEC" -ForegroundColor Red
}

# Retourner un résultat
return @{
    SectionResults   = $sectionResults
    ParameterResults = $parameterResults
    TableExists      = $tableExists
    ExamplesExist    = $examplesExist
    ErrorsExist      = $errorsExist
    AllChecksPass    = $allChecksPass
}
