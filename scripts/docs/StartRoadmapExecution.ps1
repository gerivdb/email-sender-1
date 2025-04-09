# Script de démarrage rapide pour l'exécution de la roadmap
# Ce script permet de démarrer l'exécution automatique de la roadmap

param (
    [string]$RoadmapPath = ""Roadmap\roadmap_perso.md"",
    [switch]$AutoExecute = $true,
    [switch]$AutoUpdate = $true,
    [int]$MaxRetries = 3,
    [int]$RetryDelay = 5
)

# Exécuter le script d'administration de la roadmap
& ".\RoadmapAdmin.ps1" -RoadmapPath $RoadmapPath -AutoExecute:$AutoExecute -AutoUpdate:$AutoUpdate -MaxRetries $MaxRetries -RetryDelay $RetryDelay
