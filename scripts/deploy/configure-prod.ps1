# configure-prod.ps1 - Script de configuration pour l'environnement de PRODUCTION

Write-Host "Début de la configuration de l'environnement de production..."
Write-Warning "Ce script configure l'application pour un environnement de PRODUCTION. Soyez prudent avec les valeurs fournies."

# Demander les informations sensibles de manière interactive ou les lire depuis un endroit sécurisé
# NE PAS CODER EN DUR LES IDENTIFIANTS DE PRODUCTION ICI POUR DES RAISONS DE SÉCURITÉ

# Configuration de la base de données (PostgreSQL) - PRODUCTION
$dbHostProd = Read-Host -Prompt "Entrez l'hôte de la base de données de production (ex: prod.db.example.com)"
$dbPortProd = Read-Host -Prompt "Entrez le port de la base de données de production (ex: 5432)"
$dbUserProd = Read-Host -Prompt "Entrez l'utilisateur de la base de données de production"
$dbPasswordProd = Read-Host -Prompt "Entrez le mot de passe de la base de données de production" -AsSecureString
$dbNameProd = Read-Host -Prompt "Entrez le nom de la base de données de production"
$dbSslModeProd = Read-Host -Prompt "Entrez le mode SSL de la base de données de production (ex: require, verify-full)" # Typiquement 'require' ou 'verify-full' en prod

$env:DB_HOST = $dbHostProd
$env:DB_PORT = $dbPortProd
$env:DB_USER = $dbUserProd
$env:DB_PASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbPasswordProd)) # Convertir SecureString en String pour .env
$env:DB_NAME = $dbNameProd
$env:DB_SSL_MODE = $dbSslModeProd

Write-Host "Variables d'environnement pour la base de données (PROD) configurées (mot de passe non affiché)."

# Configuration de Qdrant (si utilisé) - PRODUCTION
$qdrantUrlProd = Read-Host -Prompt "Entrez l'URL de Qdrant en production (ex: http://qdrant.prod.example.com:6333)"
$env:QDRANT_URL = $qdrantUrlProd
Write-Host "Variable d'environnement pour Qdrant (PROD) configurée: $($env:QDRANT_URL)"

# Configuration du Logger - PRODUCTION
$env:LOG_LEVEL = "INFO"  # Niveau de log moins verbeux pour la prod
$env:LOG_FORMAT = "json" # Format structuré pour une meilleure analyse des logs
Write-Host "Variables d'environnement pour le Logger (PROD) configurées: LOG_LEVEL=$($env:LOG_LEVEL), LOG_FORMAT=$($env:LOG_FORMAT)"

# Autres configurations spécifiques à la production
# $env:API_KEY_PROD = Read-Host -Prompt "Entrez la clé API de production" -AsSecureString
# $env:SENTRY_DSN = Read-Host -Prompt "Entrez le DSN Sentry pour le suivi des erreurs"

# Création d'un fichier .env.prod ou configuration via un système de gestion de secrets
# Pour cet exemple, nous créons un .env.prod. En production réelle, utilisez des coffres-forts de secrets.
$projectRoot = Resolve-Path "..\.." # Remonte de deux niveaux pour atteindre la racine du projet
$envFilePathProd = Join-Path $projectRoot.Path ".env.prod"

Write-Host "Création/Mise à jour du fichier .env.prod à la racine du projet: $($envFilePathProd)"
$envContentProd = @(
    "# Fichier de configuration d'environnement pour la PRODUCTION",
    "# Généré par configure-prod.ps1",
    "# ATTENTION: Ce fichier contient des informations sensibles. Sécurisez-le de manière appropriée.",
    "",
    "# Base de données PostgreSQL",
    "DB_HOST=$($env:DB_HOST)",
    "DB_PORT=$($env:DB_PORT)",
    "DB_USER=$($env:DB_USER)",
    "DB_PASSWORD=$($env:DB_PASSWORD)", # Le mot de passe est en clair ici, ce qui n'est pas idéal.
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

Set-Content -Path $envFilePathProd -Value $envContentProd -Force
Write-Warning "Fichier .env.prod créé/mis à jour. Assurez-vous que ce fichier est correctement sécurisé et n'est pas versionné s'il contient des secrets."

Write-Host "Configuration de l'environnement de production terminée."
Write-Host "L'application peut maintenant être lancée en mode production."
Write-Host "Assurez-vous que les services externes (PostgreSQL, Qdrant) sont configurés et accessibles en production."
Write-Host "Si l'application lit le fichier .env.prod, les variables sont prêtes."
Write-Host "Sinon, ces variables sont définies pour la session PowerShell actuelle."
