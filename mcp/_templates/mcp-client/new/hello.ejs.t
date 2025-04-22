---
to: mcp/core/client/<%= name %>.ps1
---
#Requires -Version 5.1
<#
.SYNOPSIS
    <%= description %>

.DESCRIPTION
    <%= description %>
    
.PARAMETER ServerUrl
    URL du serveur MCP.
    
.PARAMETER Timeout
    Délai d'attente en secondes pour les requêtes HTTP.
    
.EXAMPLE
    .\<%= name %>.ps1 -ServerUrl "http://localhost:8000"
    Se connecte au serveur MCP local sur le port 8000.
    
.NOTES
    Version: 1.0.0
    Auteur: <%= author || 'MCP Team' %>
    Date de création: <%= new Date().toISOString().split('T')[0] %>
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$ServerUrl,
    
    [Parameter(Mandatory=$false)]
    [int]$Timeout = 30
)

# Importer les modules nécessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules"
Import-Module -Name (Join-Path -Path $modulesPath -ChildPath "MCPClient.psm1") -Force

# Initialiser la connexion au serveur MCP
$connected = Initialize-MCPConnection -ServerUrl $ServerUrl -Timeout $Timeout
if (-not $connected) {
    Write-Error "Impossible de se connecter au serveur MCP à l'adresse $ServerUrl"
    exit 1
}

# Récupérer la liste des outils disponibles
$tools = Get-MCPTools
if (-not $tools) {
    Write-Error "Impossible de récupérer la liste des outils disponibles"
    exit 1
}

Write-Host "Outils disponibles sur le serveur MCP :" -ForegroundColor Cyan
foreach ($tool in $tools) {
    Write-Host "- $($tool.name): $($tool.description)" -ForegroundColor Green
}

# Exemple d'utilisation d'un outil
try {
    $systemInfo = Get-MCPSystemInfo
    
    Write-Host "`nInformations système :" -ForegroundColor Cyan
    Write-Host "- Système d'exploitation : $($systemInfo.os)" -ForegroundColor Green
    Write-Host "- Nom d'hôte : $($systemInfo.hostname)" -ForegroundColor Green
    Write-Host "- Utilisateur : $($systemInfo.username)" -ForegroundColor Green
    Write-Host "- Nombre de processeurs : $($systemInfo.cpu_count)" -ForegroundColor Green
    Write-Host "- Mémoire totale : $([math]::Round($systemInfo.memory_total / 1GB, 2)) GB" -ForegroundColor Green
    Write-Host "- Version PowerShell : $($systemInfo.powershell_version)" -ForegroundColor Green
}
catch {
    Write-Error "Erreur lors de la récupération des informations système : $_"
}

# Fonction principale
function Start-Client {
    [CmdletBinding()]
    param()
    
    Write-Host "`nBienvenue dans le client MCP <%= name %>" -ForegroundColor Cyan
    Write-Host "Connecté au serveur : $ServerUrl" -ForegroundColor Cyan
    
    # Boucle interactive
    $continue = $true
    while ($continue) {
        Write-Host "`nOptions disponibles :" -ForegroundColor Yellow
        Write-Host "1. Exécuter une commande PowerShell" -ForegroundColor Yellow
        Write-Host "2. Obtenir des informations système" -ForegroundColor Yellow
        Write-Host "3. Lister les outils disponibles" -ForegroundColor Yellow
        Write-Host "4. Quitter" -ForegroundColor Yellow
        
        $choice = Read-Host "Votre choix"
        
        switch ($choice) {
            "1" {
                $command = Read-Host "Entrez la commande PowerShell à exécuter"
                try {
                    $result = Invoke-MCPPowerShell -Command $command
                    Write-Host "`nRésultat :" -ForegroundColor Cyan
                    $result.result | Format-Table -AutoSize
                }
                catch {
                    Write-Error "Erreur lors de l'exécution de la commande : $_"
                }
            }
            "2" {
                try {
                    $systemInfo = Get-MCPSystemInfo
                    
                    Write-Host "`nInformations système :" -ForegroundColor Cyan
                    Write-Host "- Système d'exploitation : $($systemInfo.os)" -ForegroundColor Green
                    Write-Host "- Nom d'hôte : $($systemInfo.hostname)" -ForegroundColor Green
                    Write-Host "- Utilisateur : $($systemInfo.username)" -ForegroundColor Green
                    Write-Host "- Nombre de processeurs : $($systemInfo.cpu_count)" -ForegroundColor Green
                    Write-Host "- Mémoire totale : $([math]::Round($systemInfo.memory_total / 1GB, 2)) GB" -ForegroundColor Green
                    Write-Host "- Version PowerShell : $($systemInfo.powershell_version)" -ForegroundColor Green
                }
                catch {
                    Write-Error "Erreur lors de la récupération des informations système : $_"
                }
            }
            "3" {
                $tools = Get-MCPTools -ForceRefresh
                
                Write-Host "`nOutils disponibles sur le serveur MCP :" -ForegroundColor Cyan
                foreach ($tool in $tools) {
                    Write-Host "- $($tool.name): $($tool.description)" -ForegroundColor Green
                }
            }
            "4" {
                $continue = $false
                Write-Host "`nAu revoir !" -ForegroundColor Cyan
            }
            default {
                Write-Host "`nOption invalide. Veuillez réessayer." -ForegroundColor Red
            }
        }
    }
}

# Démarrer le client
Start-Client
