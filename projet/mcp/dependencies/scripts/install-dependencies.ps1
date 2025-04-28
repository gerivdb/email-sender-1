#Requires -Version 5.1
<#
.SYNOPSIS
    Installe toutes les dépendances nécessaires pour les serveurs MCP.
.DESCRIPTION
    Ce script installe les dépendances npm, pip et binaires nécessaires
    pour le fonctionnement des serveurs MCP.
.PARAMETER SkipNpm
    Ignore l'installation des dépendances npm.
.PARAMETER SkipPip
    Ignore l'installation des dépendances pip.
.PARAMETER SkipBinary
    Ignore l'installation des dépendances binaires.
.EXAMPLE
    .\install-dependencies.ps1
    Installe toutes les dépendances.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$SkipNpm,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipPip,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipBinary
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$dependenciesRoot = (Get-Item $scriptPath).Parent.FullName
$projectRoot = (Get-Item $dependenciesRoot).Parent.Parent.FullName

# Fonctions d'aide
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "TITLE" { "Cyan" }
        default { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Corps principal du script
try {
    Write-Log "Installation des dépendances MCP..." -Level "TITLE"
    
    # Installation des dépendances npm
    if (-not $SkipNpm) {
        Write-Log "Installation des dépendances npm..." -Level "INFO"
        $npmPath = Join-Path -Path $dependenciesRoot -ChildPath "npm"
        
        if (Test-Path (Join-Path -Path $npmPath -ChildPath "package.json")) {
            Push-Location $npmPath
            try {
                npm install
                Write-Log "Dépendances npm installées avec succès." -Level "SUCCESS"
            }
            catch {
                Write-Log "Erreur lors de l'installation des dépendances npm: $_" -Level "ERROR"
            }
            finally {
                Pop-Location
            }
        }
        else {
            Write-Log "Fichier package.json non trouvé dans $npmPath" -Level "WARNING"
            
            # Créer le fichier package.json
            $packageJson = @{
                name = "mcp-dependencies"
                version = "1.0.0"
                description = "Dépendances MCP pour EMAIL_SENDER_1"
                dependencies = @{
                    "@modelcontextprotocol/server-filesystem" = "latest"
                    "@modelcontextprotocol/server-github" = "latest"
                    "gcp-mcp" = "latest"
                    "@suekou/mcp-notion-server" = "latest"
                }
            }
            
            if (-not (Test-Path $npmPath)) {
                New-Item -Path $npmPath -ItemType Directory -Force | Out-Null
            }
            
            $packageJsonPath = Join-Path -Path $npmPath -ChildPath "package.json"
            $packageJson | ConvertTo-Json -Depth 5 | Set-Content -Path $packageJsonPath
            
            Write-Log "Fichier package.json créé: $packageJsonPath" -Level "SUCCESS"
            
            # Installer les dépendances
            Push-Location $npmPath
            try {
                npm install
                Write-Log "Dépendances npm installées avec succès." -Level "SUCCESS"
            }
            catch {
                Write-Log "Erreur lors de l'installation des dépendances npm: $_" -Level "ERROR"
            }
            finally {
                Pop-Location
            }
        }
    }
    
    # Installation des dépendances pip
    if (-not $SkipPip) {
        Write-Log "Installation des dépendances pip..." -Level "INFO"
        $pipPath = Join-Path -Path $dependenciesRoot -ChildPath "pip"
        $requirementsPath = Join-Path -Path $pipPath -ChildPath "requirements.txt"
        
        if (Test-Path $requirementsPath) {
            try {
                pip install -r $requirementsPath
                Write-Log "Dépendances pip installées avec succès." -Level "SUCCESS"
            }
            catch {
                Write-Log "Erreur lors de l'installation des dépendances pip: $_" -Level "ERROR"
            }
        }
        else {
            Write-Log "Fichier requirements.txt non trouvé dans $pipPath" -Level "WARNING"
            
            # Créer le fichier requirements.txt
            $requirements = @"
pymcpfy>=0.1.0
mcp-git-ingest>=0.1.0
"@
            
            if (-not (Test-Path $pipPath)) {
                New-Item -Path $pipPath -ItemType Directory -Force | Out-Null
            }
            
            Set-Content -Path $requirementsPath -Value $requirements
            
            Write-Log "Fichier requirements.txt créé: $requirementsPath" -Level "SUCCESS"
            
            # Installer les dépendances
            try {
                pip install -r $requirementsPath
                Write-Log "Dépendances pip installées avec succès." -Level "SUCCESS"
            }
            catch {
                Write-Log "Erreur lors de l'installation des dépendances pip: $_" -Level "ERROR"
            }
        }
    }
    
    # Installation des dépendances binaires
    if (-not $SkipBinary) {
        Write-Log "Installation des dépendances binaires..." -Level "INFO"
        $binaryPath = Join-Path -Path $dependenciesRoot -ChildPath "binary"
        
        # Installation de Gateway
        $gatewayPath = Join-Path -Path $binaryPath -ChildPath "gateway"
        if (-not (Test-Path $gatewayPath)) {
            New-Item -Path $gatewayPath -ItemType Directory -Force | Out-Null
        }
        
        $gatewayExePath = Join-Path -Path $gatewayPath -ChildPath "gateway.exe"
        if (-not (Test-Path $gatewayExePath)) {
            Write-Log "Téléchargement de Gateway..." -Level "INFO"
            
            # URL de téléchargement (à remplacer par l'URL réelle)
            $gatewayUrl = "https://github.com/centralmind/gateway/releases/latest/download/gateway-windows-amd64.zip"
            $gatewayZipPath = Join-Path -Path $gatewayPath -ChildPath "gateway.zip"
            
            try {
                # Télécharger le fichier ZIP
                Invoke-WebRequest -Uri $gatewayUrl -OutFile $gatewayZipPath
                
                # Extraire le fichier ZIP
                Expand-Archive -Path $gatewayZipPath -DestinationPath $gatewayPath -Force
                
                # Supprimer le fichier ZIP
                Remove-Item -Path $gatewayZipPath -Force
                
                Write-Log "Gateway installé avec succès." -Level "SUCCESS"
            }
            catch {
                Write-Log "Erreur lors de l'installation de Gateway: $_" -Level "ERROR"
            }
        }
        else {
            Write-Log "Gateway déjà installé: $gatewayExePath" -Level "INFO"
        }
    }
    
    Write-Log "Installation des dépendances terminée." -Level "SUCCESS"
} catch {
    Write-Log "Erreur lors de l'installation des dépendances: $_" -Level "ERROR"
    exit 1
}
