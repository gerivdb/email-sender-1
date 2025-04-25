# Script pour copier les fichiers créés dans un nouveau dossier

# Créer un dossier temporaire
$tempFolder = "temp-files"
New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null

# Copier les fichiers de commande à la racine
Copy-Item -Path "n8n-dashboard.cmd" -Destination "$tempFolder/" -Force
Copy-Item -Path "n8n-maintenance.cmd" -Destination "$tempFolder/" -Force
Copy-Item -Path "n8n-test.cmd" -Destination "$tempFolder/" -Force

# Créer les dossiers nécessaires
New-Item -Path "$tempFolder/dashboard" -ItemType Directory -Force | Out-Null
New-Item -Path "$tempFolder/maintenance" -ItemType Directory -Force | Out-Null
New-Item -Path "$tempFolder/tests" -ItemType Directory -Force | Out-Null
New-Item -Path "$tempFolder/docs" -ItemType Directory -Force | Out-Null

# Copier les fichiers du tableau de bord
Copy-Item -Path "n8n/automation/dashboard/*" -Destination "$tempFolder/dashboard/" -Force -Recurse

# Copier les fichiers de maintenance
Copy-Item -Path "n8n/automation/maintenance/*" -Destination "$tempFolder/maintenance/" -Force -Recurse

# Copier les fichiers de tests
Copy-Item -Path "n8n/automation/tests/*" -Destination "$tempFolder/tests/" -Force -Recurse

# Copier les fichiers de documentation
Copy-Item -Path "n8n/docs/architecture/dashboard.md" -Destination "$tempFolder/docs/dashboard.md" -Force
Copy-Item -Path "n8n/docs/architecture/maintenance.md" -Destination "$tempFolder/docs/maintenance.md" -Force
Copy-Item -Path "n8n/docs/architecture/integration-tests.md" -Destination "$tempFolder/docs/integration-tests.md" -Force
Copy-Item -Path "n8n/docs/architecture/system-overview.md" -Destination "$tempFolder/docs/system-overview.md" -Force
Copy-Item -Path "n8n/docs/examples/common-scenarios.md" -Destination "$tempFolder/docs/common-scenarios.md" -Force
Copy-Item -Path "n8n/docs/user-guide.md" -Destination "$tempFolder/docs/user-guide.md" -Force
Copy-Item -Path "n8n/docs/index.md" -Destination "$tempFolder/docs/index.md" -Force

Write-Host "Fichiers copiés dans le dossier $tempFolder"
