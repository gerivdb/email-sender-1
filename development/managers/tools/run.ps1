# Script d'exécution du Manager Toolkit avec la nouvelle structure
# filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\tools\run.ps1

$ErrorActionPreference = "Stop"

Write-Host "-------------------------------------" -ForegroundColor Cyan
Write-Host "Exécution du Manager Toolkit v3.0.0" -ForegroundColor Cyan 
Write-Host "-------------------------------------" -ForegroundColor Cyan

# Vérifier que nous sommes dans le bon répertoire
$toolsDir = "d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\tools"
$currentDir = Get-Location
if ($currentDir.Path -ne $toolsDir) {
   Set-Location $toolsDir
   Write-Host "Répertoire de travail modifié: $toolsDir" -ForegroundColor Yellow
}

# Vérifier si l'exécutable existe
$executablePath = ".\cmd\manager-toolkit\manager-toolkit.exe"
if (-not (Test-Path $executablePath)) {
   Write-Host "Exécutable non trouvé! Compilation du projet..." -ForegroundColor Red
   & .\build.ps1
   if ($LASTEXITCODE -ne 0) {
      Write-Host "Échec de la compilation." -ForegroundColor Red
      exit 1
   }
}

# Récupérer les arguments passés au script
$toolkitArgs = $args

# Exécuter l'outil
Write-Host "Exécution de Manager Toolkit avec les arguments: $toolkitArgs" -ForegroundColor Cyan
& $executablePath $toolkitArgs

# Afficher le code de retour
if ($LASTEXITCODE -eq 0) {
   Write-Host "Exécution terminée avec succès!" -ForegroundColor Green
}
else {
   Write-Host "Exécution terminée avec des erreurs (code: $LASTEXITCODE)" -ForegroundColor Red
}

exit $LASTEXITCODE
