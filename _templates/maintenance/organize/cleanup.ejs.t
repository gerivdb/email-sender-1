<#
---
to: "<%= createCleanup ? 'D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/maintenance/cleanup/cleanup-' + name + '.ps1' : null %>"
---
<#
.SYNOPSIS
    Script de nettoyage pour <%= description.toLowerCase() %>

.DESCRIPTION
    Ce script supprime les fichiers originaux qui ont été déplacés lors de l'organisation
    du répertoire <%= targetDir %>.

.PARAMETER DryRun
    Si spécifié, le script affiche les actions qui seraient effectuées sans les exécuter.

.PARAMETER Force
    Si spécifié, le script supprime les fichiers sans demander de confirmation.

.EXAMPLE
    .\cleanup-<%= name %>.ps1 -DryRun

.EXAMPLE
    .\cleanup-<%= name %>.ps1 -Force

.NOTES
    Auteur: Maintenance Team
    Version: 1.0
    Date de création: <%= new Date().toISOString().split('T')[0] %>
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Définir le répertoire cible
$targetDir = "<%= targetDir %>"
if (-not [System.IO.Path]::IsPathRooted($targetDir)) {
    $targetDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\$targetDir"
}
$targetDir = [System.IO.Path]::GetFullPath($targetDir)

# Vérifier que le répertoire cible existe
if (-not (Test-Path -Path $targetDir -PathType Container)) {
    throw "Le répertoire cible n'existe pas : $targetDir"
}

Write-Host "Nettoyage du répertoire : $targetDir" -ForegroundColor Cyan

# Liste des fichiers à supprimer
$filesToRemove = @(
<% if (type === 'structure') { %>
    # Exemples de fichiers pour la structure
    "*.ps1",
    "*.psm1",
    "*.psd1"
<% } else if (type === 'modules') { %>
    # Exemples de fichiers pour les modules
    "*-core-*.ps1",
    "*-utils-*.ps1",
    "*-analysis-*.ps1",
    "*-report-*.ps1",
    "*-test-*.ps1"
<% } else if (type === 'scripts') { %>
    # Exemples de fichiers pour les scripts
    "*-daily-*.ps1",
    "*-weekly-*.ps1",
    "*-monthly-*.ps1",
    "*-ondemand-*.ps1"
<% } else if (type === 'docs') { %>
    # Exemples de fichiers pour la documentation
    "guide-*.md",
    "api-*.md",
    "example-*.md",
    "tutorial-*.md",
    "reference-*.md"
<% } else { %>
    # Ajoutez ici les fichiers personnalisés à supprimer
    "*.txt",
    "*.csv",
    "*.json"
<% } %>
)

# Fonction pour supprimer un fichier
function Remove-FileIfExists {
    param (
        [string]$FilePath
    )
    
    if (Test-Path -Path $FilePath) {
        if ($Force) {
            $shouldContinue = $true
        } else {
            $shouldContinue = $PSCmdlet.ShouldContinue("Voulez-vous supprimer le fichier : $FilePath ?", "Confirmation")
        }
        
        if ($shouldContinue) {
            if ($DryRun) {
                Write-Host "[DRYRUN] Suppression du fichier : $FilePath" -ForegroundColor Yellow
            } else {
                if ($PSCmdlet.ShouldProcess($FilePath, "Supprimer")) {
                    Remove-Item -Path $FilePath -Force
                    Write-Host "Fichier supprimé : $FilePath" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "Suppression ignorée : $FilePath" -ForegroundColor Gray
        }
    } else {
        Write-Host "Le fichier n'existe pas : $FilePath" -ForegroundColor Gray
    }
}

# Parcourir les fichiers du répertoire cible
foreach ($pattern in $filesToRemove) {
    $files = Get-ChildItem -Path $targetDir -Filter $pattern -File | Where-Object { $_.DirectoryName -eq $targetDir }
    
    foreach ($file in $files) {
        Remove-FileIfExists -FilePath $file.FullName
    }
}

Write-Host "Nettoyage terminé." -ForegroundColor Cyan
