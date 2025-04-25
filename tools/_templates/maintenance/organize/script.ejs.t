<#
---
to: D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/maintenance/organize/<%= name %>.ps1
---
<#
.SYNOPSIS
    <%= description %>

.DESCRIPTION
    Ce script organise le répertoire <%= targetDir %> selon une structure prédéfinie.
    Il crée les dossiers nécessaires et déplace les fichiers vers leurs emplacements appropriés.

.PARAMETER DryRun
    Si spécifié, le script affiche les actions qui seraient effectuées sans les exécuter.

.PARAMETER Force
    Si spécifié, le script écrase les fichiers existants sans demander de confirmation.

.EXAMPLE
    .\<%= name %>.ps1 -DryRun

.EXAMPLE
    .\<%= name %>.ps1 -Force

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

Write-Host "Organisation du répertoire : $targetDir" -ForegroundColor Cyan

# Définir la structure de dossiers à créer
$folders = @(
<% if (type === 'structure') { %>
    "core",
    "core/parser",
    "core/model",
    "core/converter",
    "core/structure",
    "utils",
    "utils/helpers",
    "utils/export",
    "utils/import",
    "docs",
    "docs/examples",
    "docs/guides"
<% } else if (type === 'modules') { %>
    "modules",
    "modules/core",
    "modules/utils",
    "modules/analysis",
    "modules/reporting",
    "modules/tests"
<% } else if (type === 'scripts') { %>
    "scripts",
    "scripts/daily",
    "scripts/weekly",
    "scripts/monthly",
    "scripts/on-demand"
<% } else if (type === 'docs') { %>
    "docs",
    "docs/guides",
    "docs/api",
    "docs/examples",
    "docs/tutorials",
    "docs/references"
<% } else { %>
    # Ajoutez ici les dossiers personnalisés
    "custom_folder_1",
    "custom_folder_2",
    "custom_folder_3"
<% } %>
)

# Créer les dossiers
foreach ($folder in $folders) {
    $folderPath = Join-Path -Path $targetDir -ChildPath $folder
    
    if (-not (Test-Path -Path $folderPath)) {
        if ($DryRun) {
            Write-Host "[DRYRUN] Création du dossier : $folderPath" -ForegroundColor Yellow
        } else {
            if ($PSCmdlet.ShouldProcess($folderPath, "Créer le dossier")) {
                New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
                Write-Host "Dossier créé : $folderPath" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "Le dossier existe déjà : $folderPath" -ForegroundColor Gray
    }
}

# Définir les mappages de fichiers vers les nouveaux emplacements
$fileMappings = @{
<% if (type === 'structure') { %>
    # Exemples de mappages pour la structure
    "*.ps1" = "core"
    "*.psm1" = "core/modules"
    "*.psd1" = "core/modules"
    "*.md" = "docs"
    "README.md" = "."  # Garder à la racine
<% } else if (type === 'modules') { %>
    # Exemples de mappages pour les modules
    "*-core-*.ps1" = "modules/core"
    "*-utils-*.ps1" = "modules/utils"
    "*-analysis-*.ps1" = "modules/analysis"
    "*-report-*.ps1" = "modules/reporting"
    "*-test-*.ps1" = "modules/tests"
<% } else if (type === 'scripts') { %>
    # Exemples de mappages pour les scripts
    "*-daily-*.ps1" = "scripts/daily"
    "*-weekly-*.ps1" = "scripts/weekly"
    "*-monthly-*.ps1" = "scripts/monthly"
    "*-ondemand-*.ps1" = "scripts/on-demand"
<% } else if (type === 'docs') { %>
    # Exemples de mappages pour la documentation
    "guide-*.md" = "docs/guides"
    "api-*.md" = "docs/api"
    "example-*.md" = "docs/examples"
    "tutorial-*.md" = "docs/tutorials"
    "reference-*.md" = "docs/references"
<% } else { %>
    # Ajoutez ici les mappages personnalisés
    "*.txt" = "custom_folder_1"
    "*.csv" = "custom_folder_2"
    "*.json" = "custom_folder_3"
<% } %>
}

# Fonction pour déplacer un fichier
function Move-FileToNewLocation {
    param (
        [string]$SourceFile,
        [string]$DestinationFolder
    )
    
    $fileName = Split-Path -Path $SourceFile -Leaf
    $destinationPath = Join-Path -Path $DestinationFolder -ChildPath $fileName
    
    if (Test-Path -Path $destinationPath) {
        if ($Force) {
            $shouldContinue = $true
        } else {
            $shouldContinue = $PSCmdlet.ShouldContinue("Le fichier existe déjà : $destinationPath. Voulez-vous le remplacer ?", "Confirmation")
        }
    } else {
        $shouldContinue = $true
    }
    
    if ($shouldContinue) {
        if ($DryRun) {
            Write-Host "[DRYRUN] Déplacement du fichier : $SourceFile -> $destinationPath" -ForegroundColor Yellow
        } else {
            if ($PSCmdlet.ShouldProcess($SourceFile, "Déplacer vers $destinationPath")) {
                Move-Item -Path $SourceFile -Destination $destinationPath -Force
                Write-Host "Fichier déplacé : $SourceFile -> $destinationPath" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "Déplacement ignoré : $SourceFile" -ForegroundColor Gray
    }
}

# Parcourir les fichiers du répertoire cible
$files = Get-ChildItem -Path $targetDir -File -Recurse | Where-Object { $_.DirectoryName -eq $targetDir }

foreach ($file in $files) {
    $matched = $false
    
    foreach ($pattern in $fileMappings.Keys) {
        if ($file.Name -like $pattern) {
            $destinationFolder = Join-Path -Path $targetDir -ChildPath $fileMappings[$pattern]
            Move-FileToNewLocation -SourceFile $file.FullName -DestinationFolder $destinationFolder
            $matched = $true
            break
        }
    }
    
    if (-not $matched) {
        Write-Host "Aucun mapping trouvé pour le fichier : $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host "Organisation terminée." -ForegroundColor Cyan
<% if (createCleanup) { %>
Write-Host "Un script de nettoyage a également été créé : cleanup-<%= name %>.ps1" -ForegroundColor Cyan
<% } %>
