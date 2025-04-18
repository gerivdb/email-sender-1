#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple simple d'utilisation d'un serveur MCP.
.DESCRIPTION
    Ce script montre comment utiliser un serveur MCP pour additionner deux nombres.
.EXAMPLE
    .\Use-MCPExample.ps1
    Exécute l'outil "add" avec les paramètres a=2 et b=3.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-18
#>
[CmdletBinding()]
param ()

# Chemin vers le script du serveur MCP
$serverPath = "scripts\python\mcp_example.py"

# Vérifier si Python est installé
$pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $pythonPath) {
    Write-Error "Python n'est pas installé ou n'est pas dans le PATH. Veuillez installer Python 3.11 ou supérieur."
    exit 1
}

# Vérifier si le script du serveur MCP existe
if (-not (Test-Path $serverPath)) {
    Write-Error "Script du serveur MCP introuvable à $serverPath"
    exit 1
}

# Construire la requête JSON-RPC
$request = @{
    jsonrpc = "2.0"
    id = 1
    method = "callTool"
    params = @{
        name = "add"
        parameters = @{
            a = 2
            b = 3
        }
    }
} | ConvertTo-Json -Depth 10

Write-Host "Requête: $request" -ForegroundColor Cyan

# Créer un fichier temporaire pour la requête
$requestFile = [System.IO.Path]::GetTempFileName()
$request | Out-File -FilePath $requestFile -Encoding utf8

# Créer un fichier temporaire pour la réponse
$responseFile = [System.IO.Path]::GetTempFileName()

# Exécuter le serveur MCP avec la requête
Write-Host "Exécution du serveur MCP: $serverPath" -ForegroundColor Green
$process = Start-Process -FilePath "python" -ArgumentList $serverPath -NoNewWindow -PassThru -RedirectStandardInput $requestFile -RedirectStandardOutput $responseFile

# Attendre que le processus se termine
$process.WaitForExit(5000)

# Lire la réponse
$response = Get-Content -Path $responseFile -Raw
Write-Host "Réponse brute: $response" -ForegroundColor Yellow

# Nettoyer les fichiers temporaires
Remove-Item -Path $requestFile -Force
Remove-Item -Path $responseFile -Force

Write-Host "Terminé." -ForegroundColor Green
