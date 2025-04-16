# fix-mcp-configurations.ps1
# Script pour corriger et configurer les serveurs MCP dans VS Code
# Auteur: Augment Assistant
# Date: 2025-04-16
# Version: 2.0

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$InstallPackages = $false,

    [Parameter()]
    [string]$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",

    [Parameter()]
    [switch]$AuthGDrive = $false
)

# Fonction pour écrire des messages de log
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter()]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Level) {
        "INFO" { Write-Host "$timestamp [INFO] $Message" -ForegroundColor Cyan }
        "WARNING" { Write-Host "$timestamp [WARNING] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "$timestamp [ERROR] $Message" -ForegroundColor Red }
    }
}

# Fonction pour valider les prérequis
function Test-Prerequisites {
    Write-Log "Vérification des prérequis..."

    # Vérifier Node.js
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Log "Node.js n'est pas installé. Veuillez l'installer depuis https://nodejs.org/" -Level "ERROR"
        exit 1
    }

    # Vérifier npm
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Log "npm n'est pas installé. Veuillez installer Node.js correctement." -Level "ERROR"
        exit 1
    }

    # Vérifier PowerShell
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Log "PowerShell 5.0 ou supérieur requis. Version actuelle : $($PSVersionTable.PSVersion)" -Level "ERROR"
        exit 1
    }

    Write-Log "Tous les prérequis sont satisfaits."
}

# Fonction pour convertir un chemin en format valide
function ConvertTo-ValidPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Remplacer les caractères non conformes
    $validPath = $Path -replace '[<>:"|?*]', '_' -replace '\s+', '_'
    if ($validPath -ne $Path) {
        Write-Log "Chemin converti : $Path -> $validPath" -Level "WARNING"
    }
    return $validPath
}

# Fonction pour vérifier les ports utilisés
function Test-Port {
    param (
        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    $connection = Test-NetConnection -ComputerName "localhost" -Port $Port -ErrorAction SilentlyContinue
    if ($connection.TcpTestSucceeded) {
        Write-Log "Le port $Port est déjà utilisé. Vérifiez les services en cours d'exécution." -Level "ERROR"
        return $false
    }
    return $true
}

# Vérifier les prérequis
Test-Prerequisites

# Convertir le chemin du projet en format valide
$ProjectRoot = ConvertTo-ValidPath $ProjectRoot

# Vérifier si le répertoire du projet existe
if (-not (Test-Path -Path $ProjectRoot)) {
    Write-Log "Le répertoire du projet n'existe pas : $ProjectRoot" -Level "ERROR"
    exit 1
}

# Créer le répertoire .vscode
$vscodePath = Join-Path -Path $ProjectRoot -ChildPath ".vscode"
if (-not (Test-Path -Path $vscodePath)) {
    New-Item -Path $vscodePath -ItemType Directory -Force | Out-Null
    Write-Log "Répertoire .vscode créé : $vscodePath"
}

# Chemin du fichier settings.json
$settingsPath = Join-Path -Path $vscodePath -ChildPath "settings.json"

# Lire ou créer settings.json
$settings = if (Test-Path -Path $settingsPath) {
    try {
        Get-Content -Path $settingsPath -Raw | ConvertFrom-Json
        Write-Log "Fichier settings.json chargé"
    } catch {
        Write-Log "Erreur lors de la lecture de settings.json : $_" -Level "ERROR"
        [PSCustomObject]@{}
    }
} else {
    Write-Log "Création d'un nouveau fichier settings.json"
    [PSCustomObject]@{}
}

# Initialiser augment.mcpServers si absent
if (-not (Get-Member -InputObject $settings -Name "augment.mcpServers" -MemberType Properties)) {
    Add-Member -InputObject $settings -MemberType NoteProperty -Name "augment.mcpServers" -Value @()
}

# Définir les configurations des serveurs MCP
$mcpServers = @(
    @{
        name                 = "@modelcontextprotocol/server-filesystem"
        command              = "powershell -ExecutionPolicy Bypass -File `"$ProjectRoot\scripts\mcp\start-filesystem-mcp.ps1`""
        environmentVariables = @{}
    },
    @{
        name                 = "n8n-nodes-mcp"
        command              = "powershell -ExecutionPolicy Bypass -File `"$ProjectRoot\scripts\mcp\start-n8n-mcp.ps1`""
        environmentVariables = @{}
    },
    @{
        name                 = "@suekou/mcp-notion-server"
        command              = "powershell -ExecutionPolicy Bypass -File `"$ProjectRoot\scripts\mcp\start-notion-mcp.ps1`""
        environmentVariables = @{
            "NOTION_API_TOKEN" = "%NOTION_API_TOKEN%"
        }
    },
    @{
        name                 = "@modelcontextprotocol/server-gdrive"
        command              = "powershell -ExecutionPolicy Bypass -File `"$ProjectRoot\scripts\mcp\start-gdrive-mcp.ps1`" $(if ($AuthGDrive) { '-Auth' })"
        environmentVariables = @{}
    },
    @{
        name                 = "gcp-mcp"
        command              = "powershell -ExecutionPolicy Bypass -File `"$ProjectRoot\scripts\mcp\start-gcp-mcp.ps1`""
        environmentVariables = @{}
    },
    @{
        name                 = "@centralmind/gateway"
        command              = "powershell -ExecutionPolicy Bypass -File `"$ProjectRoot\scripts\mcp\start-gateway-mcp.ps1`""
        environmentVariables = @{}
    },
    @{
        name                 = "@adhikasp/mcp-git-ingest"
        command              = "powershell -ExecutionPolicy Bypass -File `"$ProjectRoot\scripts\mcp\start-git-ingest-mcp.ps1`""
        environmentVariables = @{}
    },
    @{
        name                 = "Bifrost"
        command              = "powershell -ExecutionPolicy Bypass -File `"$ProjectRoot\scripts\mcp\start-bifrost-mcp.ps1`""
        environmentVariables = @{}
    }
)

# Mettre à jour settings.json
$settings.'augment.mcpServers' = $mcpServers
$settingsJson = ConvertTo-Json -InputObject $settings -Depth 10
Set-Content -Path $settingsPath -Value $settingsJson -Encoding UTF8
Write-Log "Configuration des serveurs MCP mise à jour dans $settingsPath"

# Créer le répertoire scripts/mcp
$scriptsPath = Join-Path -Path $ProjectRoot -ChildPath "scripts\mcp"
if (-not (Test-Path -Path $scriptsPath)) {
    New-Item -Path $scriptsPath -ItemType Directory -Force | Out-Null
    Write-Log "Répertoire scripts/mcp créé : $scriptsPath"
}

# Script pour le serveur filesystem
$filesystemScript = @"
# start-filesystem-mcp.ps1
[CmdletBinding()]
param()
Write-Host "Démarrage du serveur MCP filesystem..." -ForegroundColor Cyan
try {
    npx -y @modelcontextprotocol/server-filesystem "$ProjectRoot"
}
catch {
    Write-Host "Erreur : $_" -ForegroundColor Red
    Write-Host "Vérifiez que le répertoire '$ProjectRoot' est accessible." -ForegroundColor Yellow
    exit 1
}
"@

Set-Content -Path (Join-Path -Path $scriptsPath -ChildPath "start-filesystem-mcp.ps1") -Value $filesystemScript -Encoding UTF8
Write-Log "Script start-filesystem-mcp.ps1 créé"

# Script pour le serveur n8n
$n8nScript = @"
# start-n8n-mcp.ps1
[CmdletBinding()]
param()
Write-Host "Démarrage du serveur MCP n8n..." -ForegroundColor Cyan
try {
    if (-not (Test-Path -Path "$ProjectRoot\node_modules\@modelcontextprotocol\server-n8n")) {
        Write-Host "Installation de @modelcontextprotocol/server-n8n..." -ForegroundColor Yellow
        npm install --no-save @modelcontextprotocol/server-n8n
    }
    node "$ProjectRoot\node_modules\@modelcontextprotocol\server-n8n\dist\index.js"
}
catch {
    Write-Host "Erreur : $_" -ForegroundColor Red
    Write-Host "Vérifiez que npm est configuré correctement et que le package existe." -ForegroundColor Yellow
    exit 1
}
"@

Set-Content -Path (Join-Path -Path $scriptsPath -ChildPath "start-n8n-mcp.ps1") -Value $n8nScript -Encoding UTF8
Write-Log "Script start-n8n-mcp.ps1 créé"

# Script pour le serveur notion
$notionScript = @"
# start-notion-mcp.ps1
[CmdletBinding()]
param()
if (-not [Environment]::GetEnvironmentVariable("NOTION_API_TOKEN")) {
    Write-Host "ERREUR: NOTION_API_TOKEN non défini." -ForegroundColor Red
    Write-Host "Définissez-le avec : `$env:NOTION_API_TOKEN = 'votre_token'" -ForegroundColor Yellow
    exit 1
}
Write-Host "Démarrage du serveur MCP notion..." -ForegroundColor Cyan
try {
    if (-not (Test-Path -Path "$ProjectRoot\node_modules\@suekou\mcp-notion-server")) {
        Write-Host "Installation de @suekou/mcp-notion-server..." -ForegroundColor Yellow
        npm install --no-save @suekou/mcp-notion-server
    }
    node "$ProjectRoot\node_modules\@suekou\mcp-notion-server\dist\index.js"
}
catch {
    Write-Host "Erreur : $_" -ForegroundColor Red
    Write-Host "Vérifiez votre token Notion et la disponibilité du package." -ForegroundColor Yellow
    exit 1
}
"@

Set-Content -Path (Join-Path -Path $scriptsPath -ChildPath "start-notion-mcp.ps1") -Value $notionScript -Encoding UTF8
Write-Log "Script start-notion-mcp.ps1 créé"

# Script pour le serveur gdrive
$gdriveScript = @"
# start-gdrive-mcp.ps1
[CmdletBinding()]
param([switch]$Auth = $false)
Write-Host "Démarrage du serveur MCP gdrive..." -ForegroundColor Cyan
try {
    if (-not (Test-Path -Path "$ProjectRoot\node_modules\@modelcontextprotocol\server-gdrive")) {
        Write-Host "Installation de @modelcontextprotocol/server-gdrive..." -ForegroundColor Yellow
        npm install --no-save @modelcontextprotocol/server-gdrive
    }
    if ($Auth) {
        Write-Host "Lancement de l'authentification..." -ForegroundColor Yellow
        node "$ProjectRoot\node_modules\@modelcontextprotocol\server-gdrive\dist\index.js" auth
    }
    else {
        node "$ProjectRoot\node_modules\@modelcontextprotocol\server-gdrive\dist\index.js"
    }
}
catch {
    Write-Host "Erreur : $_" -ForegroundColor Red
    Write-Host "Si les credentials sont manquants, exécutez avec -Auth." -ForegroundColor Yellow
    exit 1
}
"@

Set-Content -Path (Join-Path -Path $scriptsPath -ChildPath "start-gdrive-mcp.ps1") -Value $gdriveScript -Encoding UTF8
Write-Log "Script start-gdrive-mcp.ps1 créé"

# Script pour le serveur gcp
$gcpScript = @"
# start-gcp-mcp.ps1
[CmdletBinding()]
param()
Write-Host "Démarrage du serveur MCP gcp..." -ForegroundColor Cyan
try {
    if (-not (Test-Path -Path "$ProjectRoot\token.json")) {
        Write-Host "AVERTISSEMENT: token.json manquant." -ForegroundColor Yellow
    }
    if (-not (Test-Path -Path "$ProjectRoot\node_modules\@modelcontextprotocol\server-gcp")) {
        Write-Host "Installation de @modelcontextprotocol/server-gcp..." -ForegroundColor Yellow
        npm install --no-save @modelcontextprotocol/server-gcp
    }
    node "$ProjectRoot\node_modules\@modelcontextprotocol\server-gcp\dist\index.js"
}
catch {
    Write-Host "Erreur : $_" -ForegroundColor Red
    Write-Host "Vérifiez les chemins et les credentials GCP." -ForegroundColor Yellow
    exit 1
}
"@

Set-Content -Path (Join-Path -Path $scriptsPath -ChildPath "start-gcp-mcp.ps1") -Value $gcpScript -Encoding UTF8
Write-Log "Script start-gcp-mcp.ps1 créé"

# Script pour le serveur gateway
$gatewayScript = @"
# start-gateway-mcp.ps1
[CmdletBinding()]
param()
Write-Host "Démarrage du serveur MCP gateway..." -ForegroundColor Cyan
try {
    if (-not (Test-Path -Path "$ProjectRoot\node_modules\@centralmind\gateway")) {
        Write-Host "Installation de @centralmind/gateway..." -ForegroundColor Yellow
        npm install --no-save @centralmind/gateway
    }
    node "$ProjectRoot\node_modules\@centralmind\gateway\dist\index.js"
}
catch {
    Write-Host "Erreur : $_" -ForegroundColor Red
    Write-Host "Vérifiez la disponibilité du package @centralmind/gateway." -ForegroundColor Yellow
    exit 1
}
"@

Set-Content -Path (Join-Path -Path $scriptsPath -ChildPath "start-gateway-mcp.ps1") -Value $gatewayScript -Encoding UTF8
Write-Log "Script start-gateway-mcp.ps1 créé"

# Script pour le serveur git-ingest
$gitIngestScript = @"
# start-git-ingest-mcp.ps1
[CmdletBinding()]
param()
Write-Host "Démarrage du serveur MCP git-ingest..." -ForegroundColor Cyan
try {
    if (-not (Test-Path -Path "$ProjectRoot\node_modules\@adhikasp\mcp-git-ingest")) {
        Write-Host "Installation de @adhikasp/mcp-git-ingest..." -ForegroundColor Yellow
        npm install --no-save @adhikasp/mcp-git-ingest
    }
    node "$ProjectRoot\node_modules\@adhikasp\mcp-git-ingest\dist\index.js"
}
catch {
    Write-Host "Erreur : $_" -ForegroundColor Red
    Write-Host "Vérifiez la disponibilité du package @adhikasp/mcp-git-ingest." -ForegroundColor Yellow
    exit 1
}
"@

Set-Content -Path (Join-Path -Path $scriptsPath -ChildPath "start-git-ingest-mcp.ps1") -Value $gitIngestScript -Encoding UTF8
Write-Log "Script start-git-ingest-mcp.ps1 créé"

# Script pour le serveur bifrost
$bifrostScript = @"
# start-bifrost-mcp.ps1
[CmdletBinding()]
param()
Write-Host "Démarrage du serveur MCP bifrost..." -ForegroundColor Cyan
try {
    if (-not (Test-NetConnection -ComputerName "localhost" -Port 8009 -ErrorAction SilentlyContinue).TcpTestSucceeded) {
        Write-Host "AVERTISSEMENT: n8n non détecté sur le port 8009." -ForegroundColor Yellow
        Write-Host "Démarrez n8n avant de lancer Bifrost." -ForegroundColor Yellow
    }
    if (-not (Test-Path -Path "$ProjectRoot\node_modules\supergateway")) {
        Write-Host "Installation de supergateway..." -ForegroundColor Yellow
        npm install --no-save supergateway
    }
    node "$ProjectRoot\node_modules\supergateway\dist\index.js" --sse http://localhost:8009/email-sender-1/sse
}
catch {
    Write-Host "Erreur : $_" -ForegroundColor Red
    Write-Host "Vérifiez que n8n est en cours d'exécution sur le port 8009." -ForegroundColor Yellow
    exit 1
}
"@

Set-Content -Path (Join-Path -Path $scriptsPath -ChildPath "start-bifrost-mcp.ps1") -Value $bifrostScript -Encoding UTF8
Write-Log "Script start-bifrost-mcp.ps1 créé"

# Script pour démarrer tous les serveurs
$startAllScript = @"
# start-all-mcp-servers.ps1
[CmdletBinding()]
param(
    [switch]$ClearNotifications = $true,
    [switch]$ConfigureVSCode = $true,
    [switch]$AuthGDrive = $false
)

function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter()]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Level) {
        "INFO" { Write-Host "$timestamp [INFO] $Message" -ForegroundColor Cyan }
        "WARNING" { Write-Host "$timestamp [WARNING] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "$timestamp [ERROR] $Message" -ForegroundColor Red }
    }
}

$projectRoot = "$ProjectRoot"

if ($ClearNotifications) {
    Write-Log "Nettoyage des notifications..."
    & "$projectRoot\scripts\mcp\clear-mcp-notifications.ps1"
}

if ($ConfigureVSCode) {
    Write-Log "Configuration de VS Code..."
    & "$projectRoot\scripts\mcp\fix-mcp-configurations.ps1" -AuthGDrive:$AuthGDrive
}

Write-Log "Démarrage des serveurs MCP..."
$servers = @(
    "filesystem",
    "gdrive",
    "n8n",
    "notion",
    "gcp",
    "gateway",
    "git-ingest",
    "bifrost"
)

foreach ($server in $servers) {
    $scriptPath = "$projectRoot\scripts\mcp\start-$server-mcp.ps1"
    $args = if ($server -eq "gdrive" -and $AuthGDrive) { "-Auth" } else { "" }
    Write-Log "Démarrage du serveur $server..."
    Start-Process -FilePath "powershell" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`" $args" -WindowStyle Normal
    Start-Sleep -Seconds 2
}

Write-Log "Tous les serveurs MCP ont été démarrés."
"@

Set-Content -Path (Join-Path -Path $scriptsPath -ChildPath "start-all-mcp-servers.ps1") -Value $startAllScript -Encoding UTF8
Write-Log "Script start-all-mcp-servers.ps1 créé"

# Script pour nettoyer les notifications
$clearNotificationsScript = @"
# clear-mcp-notifications.ps1
[CmdletBinding()]
param (
    [string]$VSCodePath = "$env:APPDATA\Code\User\globalStorage\augment.augment"
)

function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter()]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    switch ($Level) {
        "INFO" { Write-Host "$timestamp [INFO] $Message" -ForegroundColor Cyan }
        "WARNING" { Write-Host "$timestamp [WARNING] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "$timestamp [ERROR] $Message" -ForegroundColor Red }
    }
}

if (-not (Test-Path -Path $VSCodePath)) {
    Write-Log "Répertoire VS Code introuvable : $VSCodePath" -Level "WARNING"
    exit 0
}

$notificationFiles = Get-ChildItem -Path $VSCodePath -Filter "*.notification" -Recurse
if ($notificationFiles.Count -eq 0) {
    Write-Log "Aucune notification trouvée."
    exit 0
}

$mcpNotifications = $notificationFiles | Where-Object {
    $content = Get-Content -Path $_.FullName -Raw -ErrorAction SilentlyContinue
    $content -match "MCP error|Failed to start the MCP server"
}

if ($mcpNotifications.Count -eq 0) {
    Write-Log "Aucune notification MCP trouvée."
    exit 0
}

foreach ($notification in $mcpNotifications) {
    try {
        Remove-Item -Path $notification.FullName -Force
        Write-Log "Notification supprimée : $($notification.FullName)"
    }
    catch {
        Write-Log "Erreur lors de la suppression de $($notification.FullName) : $_" -Level "ERROR"
    }
}

Write-Log "Nettoyage des notifications terminé."
"@

Set-Content -Path (Join-Path -Path $scriptsPath -ChildPath "clear-mcp-notifications.ps1") -Value $clearNotificationsScript -Encoding UTF8
Write-Log "Script clear-mcp-notifications.ps1 créé"

# Installer les packages npm si demandé
if ($InstallPackages) {
    Write-Log "Installation des packages npm..."

    $packageJsonPath = Join-Path -Path $ProjectRoot -ChildPath "package.json"
    if (-not (Test-Path -Path $packageJsonPath)) {
        $packageJson = @{
            name         = "email-sender-1-mcp-servers"
            version      = "1.0.0"
            description  = "Packages pour les serveurs MCP"
            dependencies = @{}
        } | ConvertTo-Json
        Set-Content -Path $packageJsonPath -Value $packageJson -Encoding UTF8
        Write-Log "Fichier package.json créé"
    }

    $packages = @(
        "@modelcontextprotocol/server-filesystem",
        "@modelcontextprotocol/server-n8n",
        "@suekou/mcp-notion-server",
        "@modelcontextprotocol/server-gdrive",
        "@modelcontextprotocol/server-gcp",
        "@centralmind/gateway",
        "@adhikasp/mcp-git-ingest",
        "supergateway"
    )

    foreach ($package in $packages) {
        if (-not (Test-Path -Path "$ProjectRoot\node_modules\$package")) {
            Write-Log "Installation de $package..."
            try {
                npm install --no-save $package
            } catch {
                Write-Log "Erreur lors de l'installation de $package : $_" -Level "ERROR"
                Write-Log "Vérifiez la disponibilité du package dans le registre npm." -Level "WARNING"
            }
        } else {
            Write-Log "$package est déjà installé."
        }
    }
}

# Vérifier le port 8009 pour Bifrost
if (-not (Test-Port -Port 8009)) {
    Write-Log "Assurez-vous que n8n est démarré sur le port 8009 pour Bifrost." -Level "WARNING"
}

Write-Log "Configuration terminée. Exécutez .\scripts\mcp\start-all-mcp-servers.ps1 pour démarrer les serveurs."
