# MIGRATED TO QDRANT STANDALONE - 2025-05-25
# Alias de compatibilité pour Start-QdrantContainer.ps1
# Redirige vers le script QDrant standalone

[CmdletBinding()]
param (    [Parameter(Mandatory = False)]
    [ValidateSet("Start", "Stop", "Status", "Restart")]
    [string] = "Start",
    
    [Parameter(Mandatory = False)]
    [string],
    
    [Parameter(Mandatory = False)]
    [switch]False
)

Write-Warning "Ce script utilise maintenant QDrant standalone au lieu de Docker."
Write-Host "Redirection vers Start-QdrantStandalone.ps1..." -ForegroundColor Yellow

D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools\qdrant\Start-QdrantStandalone.ps1 = Join-Path D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools\qdrant "..\..\tools\qdrant\Start-QdrantStandalone.ps1"

if (Test-Path D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools\qdrant\Start-QdrantStandalone.ps1) {
    if ( -eq "Start") {
        & D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools\qdrant\Start-QdrantStandalone.ps1 -Action Start -Background -Force:False
    } else {
        & D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools\qdrant\Start-QdrantStandalone.ps1 -Action  -Force:False
    }
} else {
    Write-Error "Script QDrant standalone non trouvé: D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools\qdrant\Start-QdrantStandalone.ps1"
    exit 1
}
