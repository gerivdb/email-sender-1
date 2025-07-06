<#
.SYNOPSIS
    Triggers the documentation update process using the Go docmanager CLI.

.DESCRIPTION
    This script is called by the Git post-commit hook. It executes the
    `docmanager.exe` CLI tool to synchronize and update documentation
    with the Doc Manager API.

.NOTES
    Version: 1.0
    Date: 2025-07-03
    Author: Cline (AI Assistant)
    License: MIT

.EXAMPLE
    .\trigger-doc-update.ps1
    This will execute the docmanager CLI to synchronize documentation.
#>

try {
   Write-Host "Déclenchement de la mise à jour de la documentation via docmanager CLI..." -ForegroundColor Green

   # Chemin relatif vers l'exécutable Go docmanager
   $docManagerCliPath = "integration/cmd/docmanager/docmanager.exe"

   # Vérifier si l'exécutable existe
   if (-not (Test-Path $docManagerCliPath)) {
      Write-Error "L'exécutable docmanager.exe n'a pas été trouvé à: $docManagerCliPath. Veuillez le construire d'abord."
      exit 1
   }

   # Exécuter la commande de synchronisation
   # Vous devrez peut-être configurer les variables d'environnement pour l'authentification
   # ou les passer en paramètres ici. Pour l'instant, utilisons des placeholders.
   # Assurez-vous que le serveur Doc Manager est en cours d'exécution.
   & $docManagerCliPath sync --source-path "docs/" --force-update --username "your_api_username" --password "your_api_password" --base-url "http://localhost:8080"

   if ($LASTEXITCODE -ne 0) {
      Write-Error "La commande docmanager sync a échoué avec le code de sortie: $LASTEXITCODE"
      exit $LASTEXITCODE
   }

   Write-Host "Mise à jour de la documentation déclenchée avec succès." -ForegroundColor Green

}
catch {
   Write-Error "Une erreur inattendue est survenue: $($_.Exception.Message)"
   exit 1
}
