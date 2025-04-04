# Script pour mettre à jour les paramètres VS Code avec la configuration MCP Git Ingest

Write-Host "=== Mise à jour des paramètres VS Code avec MCP Git Ingest ===" -ForegroundColor Cyan

# Chemin vers le fichier settings.json
$settingsPath = "$env:APPDATA\Code\User\settings.json"

# Vérifier si le fichier existe
if (-not (Test-Path $settingsPath)) {
    Write-Host "❌ Le fichier settings.json n'existe pas à l'emplacement : $settingsPath" -ForegroundColor Red
    Write-Host "Création d'un nouveau fichier settings.json..." -ForegroundColor Yellow

    # Créer le répertoire parent si nécessaire
    $settingsDir = Split-Path -Parent $settingsPath
    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }

    # Créer un fichier settings.json vide avec une structure de base
    $baseSettings = @{
        "augment.mcpServers" = @()
    } | ConvertTo-Json -Depth 10

    Set-Content -Path $settingsPath -Value $baseSettings
    Write-Host "✅ Nouveau fichier settings.json créé" -ForegroundColor Green
}

# Lire le fichier settings.json existant
try {
    $settings = Get-Content -Path $settingsPath -Raw | ConvertFrom-Json -ErrorAction Stop
    Write-Host "✅ Fichier settings.json lu avec succès" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors de la lecture du fichier settings.json : $_" -ForegroundColor Red
    exit 1
}

# Convertir en PSCustomObject si nécessaire
if ($settings -is [string]) {
    try {
        $settings = $settings | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Host "❌ Erreur lors de la conversion du fichier settings.json : $_" -ForegroundColor Red
        exit 1
    }
}

# Chemin vers le script MCP Git Ingest
$mcpGitIngestCmd = (Get-ChildItem -Path "scripts\cmd\augment\augment-mcp-git-ingest.cmd" -ErrorAction SilentlyContinue).FullName
if (-not $mcpGitIngestCmd) {
    Write-Host "❌ Le script MCP Git Ingest n'a pas été trouvé" -ForegroundColor Red
    exit 1
}
$mcpGitIngestCmdEscaped = $mcpGitIngestCmd -replace '\\', '\\'

# Vérifier si le script existe
if (-not (Test-Path $mcpGitIngestCmd)) {
    Write-Host "❌ Le script MCP Git Ingest n'existe pas à l'emplacement : $mcpGitIngestCmd" -ForegroundColor Red
    exit 1
}

# Créer l'objet de configuration MCP Git Ingest
$mcpGitIngestConfig = [PSCustomObject]@{
    name = "MCP Git Ingest"
    type = "command"
    command = $mcpGitIngestCmdEscaped
}

# Vérifier si la propriété augment.mcpServers existe
if (-not (Get-Member -InputObject $settings -Name "augment.mcpServers" -MemberType Properties)) {
    # Ajouter la propriété si elle n'existe pas
    $settings | Add-Member -NotePropertyName "augment.mcpServers" -NotePropertyValue @()
    Write-Host "✅ Propriété augment.mcpServers ajoutée" -ForegroundColor Green
}

# Convertir en tableau si ce n'est pas déjà le cas
if ($settings."augment.mcpServers" -isnot [System.Collections.IList]) {
    $settings."augment.mcpServers" = @()
}

# Vérifier si MCP Git Ingest est déjà configuré
$mcpGitIngestExists = $false
foreach ($server in $settings."augment.mcpServers") {
    if ($server.name -eq "MCP Git Ingest") {
        $mcpGitIngestExists = $true
        $server.command = $mcpGitIngestCmdEscaped
        Write-Host "✅ Configuration MCP Git Ingest mise à jour" -ForegroundColor Green
        break
    }
}

# Ajouter MCP Git Ingest s'il n'existe pas
if (-not $mcpGitIngestExists) {
    $settings."augment.mcpServers" += $mcpGitIngestConfig
    Write-Host "✅ Configuration MCP Git Ingest ajoutée" -ForegroundColor Green
}

# Sauvegarder les modifications
try {
    $settingsJson = $settings | ConvertTo-Json -Depth 10
    Set-Content -Path $settingsPath -Value $settingsJson
    Write-Host "✅ Fichier settings.json mis à jour avec succès" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors de la sauvegarde du fichier settings.json : $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Configuration terminée ===" -ForegroundColor Cyan
Write-Host "Le MCP Git Ingest a été configuré dans VS Code."
Write-Host "Redémarrez VS Code pour appliquer les changements."
