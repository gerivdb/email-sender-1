# install.ps1 - Script d'installation pour le projet EMAIL_SENDER_1 et ses managers
# Ce script vérifie les dépendances et prépare l'environnement pour la compilation/exécution.

Write-Host "Début du script d'installation..."

# Vérification de Go
Write-Host "Vérification de l'installation de Go..."
try {
   $goVersion = go version
   Write-Host "Go est installé: $goVersion"
}
catch {
   Write-Error "Go n'est pas installé ou n'est pas dans le PATH. Veuillez l'installer et le configurer."
   exit 1
}

# Vérification de Docker
Write-Host "Vérification de l'installation de Docker..."
try {
   $dockerVersion = docker --version
   Write-Host "Docker est installé: $dockerVersion"
   # Vérifier si Docker Desktop est en cours d'exécution (ou le daemon Docker)
   $dockerRunning = docker ps
   if ($LASTEXITCODE -ne 0) {
      Write-Warning "Docker daemon ne semble pas être en cours d'exécution. Veuillez le démarrer."
   }
   else {
      Write-Host "Docker daemon est en cours d'exécution."
   }
}
catch {
   Write-Error "Docker n'est pas installé ou n'est pas dans le PATH. Veuillez l'installer et le configurer."
   # Optionnel: proposer de l'installer ou de continuer sans Docker si certains composants sont optionnels.
   # exit 1 # Décommenter si Docker est strictement requis pour l'installation de base.
}

# Installation des dépendances Go du projet principal
# Assumant que ce script est exécuté depuis la racine du projet ou que le chemin vers go.mod est connu.
# Pour cet exemple, on suppose que le script est dans `scripts/deploy` et go.mod à la racine.
$projectRoot = Resolve-Path "..\.." # Remonte de deux niveaux pour atteindre la racine du projet
Write-Host "Téléchargement des dépendances Go pour le projet situé dans: $($projectRoot.Path)"
Push-Location $projectRoot.Path
try {
   go mod tidy
   go mod download
   Write-Host "Dépendances Go téléchargées avec succès."
}
catch {
   Write-Error "Erreur lors du téléchargement des dépendances Go: $($_.Exception.Message)"
   Pop-Location
   exit 1
}
Pop-Location

# Instructions pour la compilation (exemple)
# Le gestionnaire d'erreurs est un package Go, il sera compilé avec le binaire principal.
# Cette étape peut être étendue pour compiler des binaires spécifiques si nécessaire.
Write-Host "Pour compiler le projet, naviguez à la racine du projet et exécutez 'go build'."
Write-Host "Exemple: go build -o email_sender.exe ."

# Vérification et démarrage des conteneurs Docker (PostgreSQL, Qdrant)
# Ceci suppose qu'un fichier docker-compose.yml existe à la racine du projet.
Write-Host "Vérification de la configuration Docker Compose..."
if (Test-Path (Join-Path $projectRoot.Path "docker-compose.yml")) {
   Write-Host "Fichier docker-compose.yml trouvé."
   Write-Host "Tentative de démarrage des services définis (ex: postgres, qdrant) en mode détaché..."
   Push-Location $projectRoot.Path
   try {
      docker-compose up -d --remove-orphans
      Write-Host "Services Docker (potentiellement PostgreSQL, Qdrant) démarrés via docker-compose."
   }
   catch {
      Write-Warning "Erreur lors du démarrage des services avec docker-compose: $($_.Exception.Message). Assurez-vous que Docker est configuré et en cours d'exécution."
   }
   Pop-Location
}
else {
   Write-Warning "Fichier docker-compose.yml non trouvé à la racine du projet. La configuration de la base de données et de Qdrant pourrait nécessiter des étapes manuelles."
}

Write-Host "Script d'installation terminé."
Write-Host "Prochaines étapes suggérées:"
Write-Host "- Exécutez configure-dev.ps1 pour configurer l'environnement de développement."
Write-Host "- Ou exécutez configure-prod.ps1 pour un environnement de production."
