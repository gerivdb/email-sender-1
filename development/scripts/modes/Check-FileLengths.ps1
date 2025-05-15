#Requires -Version 5.1
<#
.SYNOPSIS
    Vérifie la longueur des fichiers dans le projet selon les standards définis.

.DESCRIPTION
    Ce script analyse tous les fichiers du projet et identifie ceux qui dépassent
    les limites de longueur recommandées. Il génère un rapport détaillé et peut
    suggérer des stratégies de refactorisation.

.PARAMETER Path
    Chemin du répertoire racine à analyser. Par défaut, le répertoire courant.

.PARAMETER ReportPath
    Chemin où enregistrer le rapport. Par défaut, "reports/file-lengths-report.md".

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par défaut, ".augment/config.json".

.PARAMETER Verbose
    Affiche des informations détaillées pendant l'exécution.

.EXAMPLE
    .\Check-FileLengths.ps1 -Path "D:\MonProjet" -ReportPath "reports/longueur-fichiers.md"

.NOTES
    Version: 1.1
    Auteur: Généré automatiquement
    Date de création: 2025-05-25
    Date de mise à jour: 2025-05-25
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Path = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [string]$ReportPath = "reports/file-lengths-report.md",

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = ".augment/config.json"
)

# Importer le module FileLengthAnalyzer
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\FileLengthAnalyzer"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module FileLengthAnalyzer introuvable dans le chemin: $modulePath"
    exit 1
}

try {
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Verbose "Module FileLengthAnalyzer importé avec succès."
} catch {
    Write-Error "Erreur lors de l'importation du module FileLengthAnalyzer: $_"
    exit 1
}

# Exécuter l'analyse
try {
    $results = Start-FileLengthAnalysis -Path $Path -ReportPath $ReportPath -ConfigPath $ConfigPath

    # Afficher les résultats
    $results | Format-Table -AutoSize
} catch {
    Write-Error "Erreur lors de l'analyse des fichiers: $_"
    exit 1
}
