# Script d'installation des dÃ©pendances pour les modÃ¨les prÃ©dictifs
# Auteur: EMAIL_SENDER_1 Team
# Version: 1.0.0

# VÃ©rifier si Python est installÃ©
try {
    $pythonVersion = python --version
    Write-Host "Python dÃ©tectÃ©: $pythonVersion" -ForegroundColor Green
}
catch {
    Write-Error "Python n'est pas installÃ© ou n'est pas dans le PATH. Veuillez installer Python 3.8+ et rÃ©essayer."
    exit 1
}

# VÃ©rifier si pip est installÃ©
try {
    $pipVersion = pip --version
    Write-Host "Pip dÃ©tectÃ©: $pipVersion" -ForegroundColor Green
}
catch {
    Write-Error "Pip n'est pas installÃ© ou n'est pas dans le PATH. Veuillez installer pip et rÃ©essayer."
    exit 1
}

# Liste des dÃ©pendances Ã  installer
$dependencies = @(
    "numpy",
    "pandas",
    "scikit-learn",
    "joblib",
    "matplotlib"
)

# Installer les dÃ©pendances
Write-Host "Installation des dÃ©pendances Python..." -ForegroundColor Cyan
foreach ($dependency in $dependencies) {
    Write-Host "Installation de $dependency..." -ForegroundColor Yellow
    pip install $dependency
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Erreur lors de l'installation de $dependency."
        exit 1
    }
}

Write-Host "Toutes les dÃ©pendances ont Ã©tÃ© installÃ©es avec succÃ¨s." -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser le module PerformancePredictor." -ForegroundColor Green
