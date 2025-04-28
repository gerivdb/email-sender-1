# Script pour copier les fichiers de documentation

# CrÃ©er le dossier de documentation
New-Item -Path "temp-files/docs" -ItemType Directory -Force | Out-Null

# Copier les fichiers de documentation
Copy-Item -Path "n8n/docs/architecture/dashboard.md" -Destination "temp-files/docs/dashboard.md" -Force
Copy-Item -Path "n8n/docs/architecture/maintenance.md" -Destination "temp-files/docs/maintenance.md" -Force
Copy-Item -Path "n8n/docs/architecture/integration-tests.md" -Destination "temp-files/docs/integration-tests.md" -Force
Copy-Item -Path "n8n/docs/architecture/system-overview.md" -Destination "temp-files/docs/system-overview.md" -Force
Copy-Item -Path "n8n/docs/examples/common-scenarios.md" -Destination "temp-files/docs/common-scenarios.md" -Force
Copy-Item -Path "n8n/docs/user-guide.md" -Destination "temp-files/docs/user-guide.md" -Force
Copy-Item -Path "n8n/docs/index.md" -Destination "temp-files/docs/index.md" -Force

Write-Host "Fichiers de documentation copiÃ©s dans le dossier temp-files/docs"
