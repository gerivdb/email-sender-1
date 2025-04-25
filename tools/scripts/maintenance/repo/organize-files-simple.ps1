


# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
# Script simplifiÃ© pour organiser les fichiers
# Ce script organise les fichiers dans des sous-dossiers appropriÃ©s

# Organiser les fichiers dans le dossier scripts
Write-Host "Organisation des fichiers dans le dossier scripts..." -ForegroundColor Cyan

# DÃ©placer les scripts Python de vÃ©rification vers workflow/validation
$validationFiles = Get-ChildItem -Path "scripts" -Filter "check_*.py" -File | 
                  Where-Object { $_.DirectoryName -eq (Resolve-Path "scripts").Path }
foreach ($file in $validationFiles) {
    $destination = "scripts\workflow\validation"
    $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
    
    if (-not (Test-Path -Path $destinationFile)) {
        Write-Host "DÃ©placement de $($file.Name) vers $destination" -ForegroundColor Yellow
        Move-Item -Path $file.FullName -Destination $destination -Force
    }
}

# DÃ©placer les scripts de correction d'encodage vers maintenance/encoding
$encodingFiles = Get-ChildItem -Path "scripts" -Filter "fix_*.py" -File | 
                Where-Object { $_.DirectoryName -eq (Resolve-Path "scripts").Path }
foreach ($file in $encodingFiles) {
    $destination = "scripts\maintenance\encoding"
    $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
    
    if (-not (Test-Path -Path $destinationFile)) {
        Write-Host "DÃ©placement de $($file.Name) vers $destination" -ForegroundColor Yellow
        Move-Item -Path $file.FullName -Destination $destination -Force
    }
}

# DÃ©placer les scripts de configuration MCP vers setup/mcp
$mcpSetupFiles = Get-ChildItem -Path "scripts" -Filter "configure-*.ps1" -File | 
                Where-Object { $_.DirectoryName -eq (Resolve-Path "scripts").Path }
foreach ($file in $mcpSetupFiles) {
    $destination = "scripts\setup\mcp"
    $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
    
    if (-not (Test-Path -Path $destinationFile)) {
        Write-Host "DÃ©placement de $($file.Name) vers $destination" -ForegroundColor Yellow
        Move-Item -Path $file.FullName -Destination $destination -Force
    }
}

# DÃ©placer les scripts de diagnostic MCP vers maintenance/mcp
$mcpMaintenanceFiles = Get-ChildItem -Path "scripts" -Filter "mcp-*.ps1" -File | 
                      Where-Object { $_.DirectoryName -eq (Resolve-Path "scripts").Path }
foreach ($file in $mcpMaintenanceFiles) {
    $destination = "scripts\maintenance\mcp"
    $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
    
    if (-not (Test-Path -Path $destinationFile)) {
        Write-Host "DÃ©placement de $($file.Name) vers $destination" -ForegroundColor Yellow
        Move-Item -Path $file.FullName -Destination $destination -Force
    }
}

# DÃ©placer les scripts d'organisation vers maintenance/repo
$repoFiles = Get-ChildItem -Path "scripts" -Filter "organize-*.ps1" -File | 
            Where-Object { $_.DirectoryName -eq (Resolve-Path "scripts").Path }
foreach ($file in $repoFiles) {
    $destination = "scripts\maintenance\repo"
    $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
    
    if (-not (Test-Path -Path $destinationFile)) {
        Write-Host "DÃ©placement de $($file.Name) vers $destination" -ForegroundColor Yellow
        Move-Item -Path $file.FullName -Destination $destination -Force
    }
}

# Organiser les fichiers CMD
Write-Host "Organisation des fichiers CMD..." -ForegroundColor Cyan

# DÃ©placer les fichiers CMD de la racine vers les sous-dossiers appropriÃ©s
$cmdFiles = Get-ChildItem -Path "." -Filter "*.cmd" -File

foreach ($file in $cmdFiles) {
    $destination = ""
    
    # DÃ©terminer le dossier de destination en fonction du nom du fichier
    if ($file.Name -like "augment-mcp-*") {
        $destination = "scripts\cmd\augment"
    } elseif ($file.Name -like "*mcp*") {
        $destination = "scripts\cmd\mcp"
    } else {
        $destination = "scripts\cmd\batch"
    }
    
    $destinationFile = Join-Path -Path $destination -ChildPath $file.Name
    
    if (-not (Test-Path -Path $destinationFile)) {
        Write-Host "DÃ©placement de $($file.Name) vers $destination" -ForegroundColor Yellow
        Copy-Item -Path $file.FullName -Destination $destination -Force
        Remove-Item -Path $file.FullName -Force
    }
}

# CrÃ©er un fichier README dans le dossier cmd
$readmePath = "repo\README.md"
    
$readmeContent = @"
# Scripts CMD

Ce dossier contient les scripts CMD utilisÃ©s dans le projet Email Sender.

## Structure des sous-dossiers

- **augment/** - Scripts CMD pour Augment MCP
  - augment-mcp-disabled.cmd - Script pour dÃ©sactiver les MCP dans Augment
  - augment-mcp-gateway.cmd - Script pour configurer le MCP Gateway dans Augment
  - augment-mcp-git-ingest.cmd - Script pour configurer le MCP Git Ingest dans Augment
  - augment-mcp-notion.cmd - Script pour configurer le MCP Notion dans Augment
  - augment-mcp-standard.cmd - Script pour configurer le MCP Standard dans Augment

- **mcp/** - Scripts CMD pour les MCP
  - Scripts de configuration et d'exÃ©cution des MCP

- **batch/** - Scripts batch divers
  - Scripts batch pour diverses tÃ¢ches

## Utilisation

Les scripts CMD peuvent Ãªtre exÃ©cutÃ©s directement depuis l'explorateur Windows ou depuis la ligne de commande.

### Exemple d'utilisation

```cmd
cd scripts\cmd\augment
augment-mcp-notion.cmd
```
"@
    
Set-Content -Path $readmePath -Value $readmeContent
Write-Host "Fichier README.md crÃ©Ã© dans le dossier scripts\cmd" -ForegroundColor Green

Write-Host "`nOrganisation des fichiers terminÃ©e avec succÃ¨s!" -ForegroundColor Green


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
