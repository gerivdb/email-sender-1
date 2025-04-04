# Script simplifie pour organiser les fichiers
# Ce script organise les fichiers dans des sous-dossiers appropries

# Organiser les fichiers dans le dossier scripts
Write-Host "Organisation des fichiers dans le dossier scripts..." -ForegroundColor Cyan

# Deplacer les scripts Python de verification vers workflow/validation
$validationFiles = Get-ChildItem -Path "scripts" -Filter "check_*.py" -File | 
                  Where-Object { $_.DirectoryName -eq (Resolve-Path "scripts").Path }
foreach ($file in $validationFiles) {
    $destination = "scripts\workflow\validation"
    $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
    
    if (-not (Test-Path -Path $destinationFile)) {
        Write-Host "Deplacement de $($file.Name) vers $destination" -ForegroundColor Yellow
        Move-Item -Path $file.FullName -Destination $destination -Force
    }
}

# Deplacer les scripts de correction d'encodage vers maintenance/encoding
$encodingFiles = Get-ChildItem -Path "scripts" -Filter "fix_*.py" -File | 
                Where-Object { $_.DirectoryName -eq (Resolve-Path "scripts").Path }
foreach ($file in $encodingFiles) {
    $destination = "scripts\maintenance\encoding"
    $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
    
    if (-not (Test-Path -Path $destinationFile)) {
        Write-Host "Deplacement de $($file.Name) vers $destination" -ForegroundColor Yellow
        Move-Item -Path $file.FullName -Destination $destination -Force
    }
}

# Deplacer les scripts de configuration MCP vers setup/mcp
$mcpSetupFiles = Get-ChildItem -Path "scripts" -Filter "configure-*.ps1" -File | 
                Where-Object { $_.DirectoryName -eq (Resolve-Path "scripts").Path }
foreach ($file in $mcpSetupFiles) {
    $destination = "scripts\setup\mcp"
    $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
    
    if (-not (Test-Path -Path $destinationFile)) {
        Write-Host "Deplacement de $($file.Name) vers $destination" -ForegroundColor Yellow
        Move-Item -Path $file.FullName -Destination $destination -Force
    }
}

# Deplacer les scripts de diagnostic MCP vers maintenance/mcp
$mcpMaintenanceFiles = Get-ChildItem -Path "scripts" -Filter "mcp-*.ps1" -File | 
                      Where-Object { $_.DirectoryName -eq (Resolve-Path "scripts").Path }
foreach ($file in $mcpMaintenanceFiles) {
    $destination = "scripts\maintenance\mcp"
    $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
    
    if (-not (Test-Path -Path $destinationFile)) {
        Write-Host "Deplacement de $($file.Name) vers $destination" -ForegroundColor Yellow
        Move-Item -Path $file.FullName -Destination $destination -Force
    }
}

# Deplacer les scripts d'organisation vers maintenance/repo
$repoFiles = Get-ChildItem -Path "scripts" -Filter "organize-*.ps1" -File | 
            Where-Object { $_.DirectoryName -eq (Resolve-Path "scripts").Path }
foreach ($file in $repoFiles) {
    $destination = "scripts\maintenance\repo"
    $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
    
    if (-not (Test-Path -Path $destinationFile)) {
        Write-Host "Deplacement de $($file.Name) vers $destination" -ForegroundColor Yellow
        Move-Item -Path $file.FullName -Destination $destination -Force
    }
}

# Organiser les fichiers CMD
Write-Host "Organisation des fichiers CMD..." -ForegroundColor Cyan

# Deplacer les fichiers CMD de la racine vers les sous-dossiers appropries
$cmdFiles = Get-ChildItem -Path "." -Filter "*.cmd" -File

foreach ($file in $cmdFiles) {
    $destination = ""
    
    # Determiner le dossier de destination en fonction du nom du fichier
    if ($file.Name -like "augment-mcp-*") {
        $destination = "scripts\cmd\augment"
    } elseif ($file.Name -like "*mcp*") {
        $destination = "scripts\cmd\mcp"
    } else {
        $destination = "scripts\cmd\batch"
    }
    
    $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
    
    if (-not (Test-Path -Path $destinationFile)) {
        Write-Host "Deplacement de $($file.Name) vers $destination" -ForegroundColor Yellow
        Copy-Item -Path $file.FullName -Destination $destination -Force
        Remove-Item -Path $file.FullName -Force
    }
}

# Creer un fichier README dans le dossier cmd
$readmePath = "scripts\cmd\README.md"
$readmeContent = "# Scripts CMD

Ce dossier contient les scripts CMD utilises dans le projet Email Sender.

## Structure des sous-dossiers

- **augment/** - Scripts CMD pour Augment MCP
  - augment-mcp-disabled.cmd - Script pour desactiver les MCP dans Augment
  - augment-mcp-gateway.cmd - Script pour configurer le MCP Gateway dans Augment
  - augment-mcp-git-ingest.cmd - Script pour configurer le MCP Git Ingest dans Augment
  - augment-mcp-notion.cmd - Script pour configurer le MCP Notion dans Augment
  - augment-mcp-standard.cmd - Script pour configurer le MCP Standard dans Augment

- **mcp/** - Scripts CMD pour les MCP
  - Scripts de configuration et d'execution des MCP

- **batch/** - Scripts batch divers
  - Scripts batch pour diverses taches

## Utilisation

Les scripts CMD peuvent etre executes directement depuis l'explorateur Windows ou depuis la ligne de commande.

### Exemple d'utilisation

```cmd
cd scripts\cmd\augment
augment-mcp-notion.cmd
```"
    
Set-Content -Path $readmePath -Value $readmeContent
Write-Host "Fichier README.md cree dans le dossier scripts\cmd" -ForegroundColor Green

Write-Host "`nOrganisation des fichiers terminee avec succes!" -ForegroundColor Green
