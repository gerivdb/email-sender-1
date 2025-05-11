<#
.SYNOPSIS
    Lance l'interface utilisateur pour le partage des vues RAG.

.DESCRIPTION
    Ce script lance l'interface utilisateur pour le partage des vues RAG.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer le module d'interface utilisateur
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$shareViewUIPath = Join-Path -Path $scriptDir -ChildPath "Share-ViewUI.ps1"

if (Test-Path -Path $shareViewUIPath) {
    . $shareViewUIPath
}
else {
    throw "Le module Share-ViewUI.ps1 est requis mais n'a pas été trouvé à l'emplacement: $shareViewUIPath"
}

# Lancer l'interface utilisateur
Start-SharingUI
