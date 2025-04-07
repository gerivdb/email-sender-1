# Script pour mettre Ã  jour les paramÃ¨tres VS Code avec la configuration MCP Git Ingest

Write-Host "=== Mise Ã  jour des paramÃ¨tres VS Code avec MCP Git Ingest ===" -ForegroundColor Cyan

# Chemin vers le fichier settings.json
$settingsPath = "$env:APPDATA\Code\User\settings.json"

# VÃ©rifier si le fichier existe
if (-not (Test-Path $settingsPath)) {
    Write-Host "âŒ Le fichier settings.json n'existe pas Ã  l'emplacement : $settingsPath" -ForegroundColor Red
    Write-Host "CrÃ©ation d'un nouveau fichier settings.json..." -ForegroundColor Yellow

    # CrÃ©er le rÃ©pertoire parent si nÃ©cessaire
    $settingsDir = Split-Path -Parent $settingsPath
    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }

    # CrÃ©er un fichier settings.json vide avec une structure de base
    $baseSettings = @{
        "augment.mcpServers" = @()
    } | ConvertTo-Json -Depth 10

    Set-Content -Path $settingsPath -Value $baseSettings
    Write-Host "âœ… Nouveau fichier settings.json crÃ©Ã©" -ForegroundColor Green
}

# Lire le fichier settings.json existant
try {
    $settings = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json -ErrorAction Stop
    Write-Host "âœ… Fichier settings.json lu avec succÃ¨s" -ForegroundColor Green
} catch {
    Write-Host "âŒ Erreur lors de la lecture du fichier settings.json : $_" -ForegroundColor Red
    exit 1
}

# Convertir en PSCustomObject si nÃ©cessaire
if ($settings -is [string]) {
    try {
        $settings = $settings | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Host "âŒ Erreur lors de la conversion du fichier settings.json : $_" -ForegroundColor Red
        exit 1
    }
}

# Chemin vers le script MCP Git Ingest
$mcpGitIngestCmd = (Get-ChildItem -Path "scripts\cmd\augment\augment-mcp-git-ingest.cmd" -ErrorAction SilentlyContinue).FullName
if (-not $mcpGitIngestCmd) {
    Write-Host "âŒ Le script MCP Git Ingest n'a pas Ã©tÃ© trouvÃ©" -ForegroundColor Red
    exit 1
}
$mcpGitIngestCmdEscaped = $mcpGitIngestCmd -replace '\\', '\\'

# VÃ©rifier si le script existe
if (-not (Test-Path $mcpGitIngestCmd)) {
    Write-Host "âŒ Le script MCP Git Ingest n'existe pas Ã  l'emplacement : $mcpGitIngestCmd" -ForegroundColor Red
    exit 1
}

# CrÃ©er l'objet de configuration MCP Git Ingest
$mcpGitIngestConfig = [PSCustomObject]@{
    name = "MCP Git Ingest"
    type = "command"
    command = $mcpGitIngestCmdEscaped
}

# VÃ©rifier si la propriÃ©tÃ© augment.mcpServers existe
if (-not (Get-Member -InputObject $settings -Name "augment.mcpServers" -MemberType Properties)) {
    # Ajouter la propriÃ©tÃ© si elle n'existe pas
    $settings | Add-Member -NotePropertyName "augment.mcpServers" -NotePropertyValue @()
    Write-Host "âœ… PropriÃ©tÃ© augment.mcpServers ajoutÃ©e" -ForegroundColor Green
}

# Convertir en tableau si ce n'est pas dÃ©jÃ  le cas
if ($settings."augment.mcpServers" -isnot [System.Collections.IList]) {
    $settings."augment.mcpServers" = @()
}

# VÃ©rifier si MCP Git Ingest est dÃ©jÃ  configurÃ©
$mcpGitIngestExists = $false
foreach ($server in $settings."augment.mcpServers") {
    if ($server.name -eq "MCP Git Ingest") {
        $mcpGitIngestExists = $true
        $server.command = $mcpGitIngestCmdEscaped
        Write-Host "âœ… Configuration MCP Git Ingest mise Ã  jour" -ForegroundColor Green
        break
    }
}

# Ajouter MCP Git Ingest s'il n'existe pas
if (-not $mcpGitIngestExists) {
    $settings."augment.mcpServers" += $mcpGitIngestConfig
    Write-Host "âœ… Configuration MCP Git Ingest ajoutÃ©e" -ForegroundColor Green
}

# Sauvegarder les modifications
try {
    $settingsJson = $settings | ConvertTo-Json -Depth 10
    Set-Content -Path $settingsPath -Value $settingsJson
    Write-Host "âœ… Fichier settings.json mis Ã  jour avec succÃ¨s" -ForegroundColor Green
} catch {
    Write-Host "âŒ Erreur lors de la sauvegarde du fichier settings.json : $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Configuration terminÃ©e ===" -ForegroundColor Cyan
Write-Host "Le MCP Git Ingest a Ã©tÃ© configurÃ© dans VS Code."
Write-Host "RedÃ©marrez VS Code pour appliquer les changements."
