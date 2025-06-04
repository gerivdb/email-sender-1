# configure-dev.ps1 - Script de configuration pour l'environnement de DÉVELOPPEMENT

Write-Host "Début de la configuration de l'environnement de développement..."

# Variables d'environnement spécifiques au développement
# Ces variables peuvent être lues par l'application Go.

# Configuration de la base de données (PostgreSQL)
# Ces valeurs doivent correspondre à celles utilisées dans votre docker-compose.yml ou votre instance de dev
$env:DB_HOST = "localhost"
$env:DB_PORT = "5432"
$env:DB_USER = "email_sender_user" # Ou votre utilisateur de dev
$env:DB_PASSWORD = "your_dev_password"  # Sécuriser ce mot de passe si nécessaire
$env:DB_NAME = "email_sender_db_dev"
$env:DB_SSL_MODE = "disable" # Généralement 'disable' pour le dev local

Write-Host "Variables d'environnement pour la base de données (DEV):"
Write-Host "  DB_HOST: $env:DB_HOST"
Write-Host "  DB_PORT: $env:DB_PORT"
Write-Host "  DB_USER: $env:DB_USER"
Write-Host "  DB_PASSWORD: (non affiché)"
Write-Host "  DB_NAME: $env:DB_NAME"
Write-Host "  DB_SSL_MODE: $env:DB_SSL_MODE"

# Configuration de Qdrant (si utilisé)
$env:QDRANT_URL = "http://localhost:6333"
Write-Host "Variable d'environnement pour Qdrant (DEV):"
Write-Host "  QDRANT_URL: $env:QDRANT_URL"

# Configuration du Logger
$env:LOG_LEVEL = "DEBUG"  # Niveau de log plus verbeux pour le dev
$env:LOG_FORMAT = "text" # 'text' pour la lisibilité, 'json' pour la production
Write-Host "Variables d'environnement pour le Logger (DEV):"
Write-Host "  LOG_LEVEL: $env:LOG_LEVEL"
Write-Host "  LOG_FORMAT: $env:LOG_FORMAT"

# Autres configurations spécifiques au développement
# $env:API_KEY_DEV = "votre_cle_api_de_dev"
# $env:FEATURE_FLAGS = "enable_feature_x,disable_feature_y"

# Création d'un fichier .env si l'application le supporte
# Cela permet de persister les variables d'environnement pour ne pas avoir à les redéfinir à chaque session.
# Le format est VARIABLE=VALEUR
$projectRoot = Resolve-Path "..\.." # Remonte de deux niveaux pour atteindre la racine du projet
$envFilePath = Join-Path $projectRoot.Path ".env.dev"

Write-Host "Création/Mise à jour du fichier .env.dev à la racine du projet: $($envFilePath)"
$envContent = @(
    "# Fichier de configuration d'environnement pour le développement",
    "# Généré par configure-dev.ps1",
    "",
    "# Base de données PostgreSQL",
    "DB_HOST=$($env:DB_HOST)",
    "DB_PORT=$($env:DB_PORT)",
    "DB_USER=$($env:DB_USER)",
    "DB_PASSWORD=$($env:DB_PASSWORD)",
    "DB_NAME=$($env:DB_NAME)",
    "DB_SSL_MODE=$($env:DB_SSL_MODE)",
    "",
    "# Qdrant",
    "QDRANT_URL=$($env:QDRANT_URL)",
    "",
    "# Logger",
    "LOG_LEVEL=$($env:LOG_LEVEL)",
    "LOG_FORMAT=$($env:LOG_FORMAT)"
    # Ajoutez d'autres variables ici si nécessaire
)

Set-Content -Path $envFilePath -Value $envContent -Force
Write-Host "Fichier .env.dev créé/mis à jour avec succès."

Write-Host "Configuration de l'environnement de développement terminée."
Write-Host "Vous pouvez maintenant lancer l'application en mode développement."
Write-Host "Assurez-vous que les services externes (PostgreSQL, Qdrant) sont démarrés (voir install.ps1)."
Write-Host "Si l'application lit le fichier .env.dev, les variables sont prêtes."
Write-Host "Sinon, ces variables sont définies pour la session PowerShell actuelle."
