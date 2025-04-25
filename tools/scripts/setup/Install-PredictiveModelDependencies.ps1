# Script d'installation des dépendances pour les modèles prédictifs
# Auteur: EMAIL_SENDER_1 Team
# Version: 1.0.0

# Vérifier si Python est installé
try {
    $pythonVersion = python --version
    Write-Host "Python détecté: $pythonVersion" -ForegroundColor Green
}
catch {
    Write-Error "Python n'est pas installé ou n'est pas dans le PATH. Veuillez installer Python 3.8+ et réessayer."
    exit 1
}

# Vérifier si pip est installé
try {
    $pipVersion = pip --version
    Write-Host "Pip détecté: $pipVersion" -ForegroundColor Green
}
catch {
    Write-Error "Pip n'est pas installé ou n'est pas dans le PATH. Veuillez installer pip et réessayer."
    exit 1
}

# Liste des dépendances à installer
$dependencies = @(
    "numpy",
    "pandas",
    "scikit-learn",
    "joblib",
    "matplotlib"
)

# Installer les dépendances
Write-Host "Installation des dépendances Python..." -ForegroundColor Cyan
foreach ($dependency in $dependencies) {
    Write-Host "Installation de $dependency..." -ForegroundColor Yellow
    pip install $dependency
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Erreur lors de l'installation de $dependency."
        exit 1
    }
}

Write-Host "Toutes les dépendances ont été installées avec succès." -ForegroundColor Green
Write-Host "Vous pouvez maintenant utiliser le module PerformancePredictor." -ForegroundColor Green
