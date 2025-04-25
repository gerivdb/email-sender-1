#Requires -Version 5.1
<#
.SYNOPSIS
    Utilise un serveur MCP pour exécuter des outils.
.DESCRIPTION
    Ce script montre comment utiliser un serveur MCP pour exécuter des outils.
.PARAMETER ServerPath
    Le chemin vers le script du serveur MCP.
.PARAMETER Tool
    Le nom de l'outil à exécuter.
.PARAMETER Parameters
    Les paramètres à passer à l'outil, au format JSON.
.EXAMPLE
    .\Use-MCPServer.ps1 -ServerPath "scripts\python\mcp_example.py" -Tool "add" -Parameters '{"a": 2, "b": 3}'
    Exécute l'outil "add" avec les paramètres a=2 et b=3.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-18
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ServerPath,

    [Parameter(Mandatory = $true)]
    [string]$Tool,

    [Parameter(Mandatory = $false)]
    [string]$Parameters = "{}"
)

# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
}

# Vérifier si Python est installé
$pythonPath = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $pythonPath) {
    Write-Log "Python n'est pas installé ou n'est pas dans le PATH. Veuillez installer Python 3.11 ou supérieur." -Level "ERROR"
    exit 1
}

# Vérifier si le script du serveur MCP existe
if (-not (Test-Path $ServerPath)) {
    Write-Log "Script du serveur MCP introuvable à $ServerPath" -Level "ERROR"
    exit 1
}

# Construire la requête JSON-RPC
$request = @{
    jsonrpc = "2.0"
    id      = 1
    method  = "callTool"
    params  = @{
        name       = $Tool
        parameters = $Parameters | ConvertFrom-Json
    }
} | ConvertTo-Json -Depth 10

Write-Log "Requête: $request" -Level "DEBUG"

# Exécuter le serveur MCP et envoyer la requête
try {
    Write-Log "Exécution du serveur MCP: $ServerPath" -Level "INFO"

    # Créer un processus pour le serveur MCP
    $process = Start-Process -FilePath "python" -ArgumentList $ServerPath -NoNewWindow -PassThru -RedirectStandardInput ([System.IO.Path]::GetTempFileName()) -RedirectStandardOutput ([System.IO.Path]::GetTempFileName()) -RedirectStandardError ([System.IO.Path]::GetTempFileName())

    # Attendre que le processus démarre
    Start-Sleep -Seconds 1

    # Envoyer la requête au serveur
    $request | Out-File -FilePath $process.StartInfo.RedirectStandardInput -Encoding utf8

    # Attendre que le processus se termine
    $process.WaitForExit(5000)

    # Lire la sortie du serveur
    $stdout = Get-Content -Path $process.StartInfo.RedirectStandardOutput -Raw
    $stderr = Get-Content -Path $process.StartInfo.RedirectStandardError -Raw

    # Afficher la sortie du serveur
    if ($stderr) {
        Write-Log "Erreur du serveur: $stderr" -Level "ERROR"
    }

    Write-Log "Réponse brute: $stdout" -Level "DEBUG"

    # Extraire la réponse JSON
    $response = $stdout | ConvertFrom-Json

    if ($response.result) {
        Write-Log "Résultat: $($response.result)" -Level "SUCCESS"
    } elseif ($response.error) {
        Write-Log "Erreur du serveur: $($response.error)" -Level "ERROR"
    } else {
        Write-Log "Aucune réponse valide du serveur" -Level "ERROR"
    }
} catch {
    Write-Log "Erreur lors de l'appel a l'outil ${Tool}: $($_.Exception.Message)" -Level "ERROR"
}
