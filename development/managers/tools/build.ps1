# Build script pour Manager Toolkit avec la nouvelle structure de dossiers
# filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\tools\build.ps1

$ErrorActionPreference = "Stop"

Write-Host "--------------------------------------------" -ForegroundColor Cyan
Write-Host "Building Manager Toolkit (nouvelle structure)" -ForegroundColor Cyan
Write-Host "--------------------------------------------" -ForegroundColor Cyan

# Vérifier que nous sommes dans le bon répertoire
$currentDir = Get-Location
$toolsDir = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\tools"
if ($currentDir.Path -ne $toolsDir) {
   Set-Location $toolsDir
   Write-Host "Répertoire de travail modifié: $toolsDir" -ForegroundColor Yellow
}

# Vérifier que go.mod existe
if (-not (Test-Path ".\go.mod")) {
   Write-Host "Erreur: fichier go.mod non trouvé. Initialisation du module..." -ForegroundColor Red
   go mod init github.com/email-sender/tools
   if ($LASTEXITCODE -ne 0) {
      Write-Host "Erreur lors de l'initialisation du module Go" -ForegroundColor Red
      exit 1
   }
}

# Téléchargement des dépendances
Write-Host "Téléchargement des dépendances..." -ForegroundColor Cyan
go mod tidy

# Mettre à jour les imports 
Write-Host "Mise à jour des imports avec goimports..." -ForegroundColor Cyan
$goFiles = Get-ChildItem -Path . -Filter "*.go" -Recurse
foreach ($file in $goFiles) {
   goimports -w $file.FullName
}

# Compiler le projet
Write-Host "Compilation du projet..." -ForegroundColor Cyan
go build -v -o .\cmd\manager-toolkit\manager-toolkit.exe .\cmd\manager-toolkit\

# Vérifier si la compilation a réussi
if ($LASTEXITCODE -eq 0) {
   Write-Host "Compilation réussie!" -ForegroundColor Green
   Write-Host "Exécutable créé: .\cmd\manager-toolkit\manager-toolkit.exe" -ForegroundColor Green
}
else {
   Write-Host "Erreur lors de la compilation" -ForegroundColor Red
   exit 1
}

# Exécuter les tests unitaires
Write-Host "`nExécution des tests unitaires..." -ForegroundColor Cyan
go test ./... -v

# Afficher la nouvelle structure
Write-Host "`nNouvelle structure des dossiers:" -ForegroundColor Cyan
Get-ChildItem -Directory | ForEach-Object {
   Write-Host "- $_" -ForegroundColor Yellow
}

Write-Host "`nBuild terminée avec succès!" -ForegroundColor Green
