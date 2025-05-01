#Requires -Version 5.1
<#
.SYNOPSIS
    Détecte les dépendances de modules PowerShell dans un projet.

.DESCRIPTION
    Ce script analyse tous les fichiers PowerShell d'un projet pour détecter
    les instructions Import-Module et générer un rapport des dépendances.

.PARAMETER ProjectPath
    Chemin du répertoire du projet à analyser.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport des dépendances.
    Si non spécifié, le rapport est affiché dans la console.

.PARAMETER IncludeSubdirectories
    Indique si les sous-répertoires doivent être inclus dans l'analyse.

.PARAMETER ResolveModulePaths
    Indique si les chemins des modules doivent être résolus.

.EXAMPLE
    .\Find-ProjectModuleDependencies.ps1 -ProjectPath "C:\Projects\MyProject"

.EXAMPLE
    .\Find-ProjectModuleDependencies.ps1 -ProjectPath "C:\Projects\MyProject" -OutputPath "C:\Reports\dependencies.json" -IncludeSubdirectories -ResolveModulePaths

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeSubdirectories,

    [Parameter(Mandatory = $false)]
    [switch]$ResolveModulePaths
)

# Importer le module ModuleDependencyDetector
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# Vérifier que le répertoire du projet existe
if (-not (Test-Path -Path $ProjectPath -PathType Container)) {
    Write-Error "Le répertoire du projet spécifié n'existe pas : $ProjectPath"
    exit 1
}

# Obtenir tous les fichiers PowerShell du projet
$powerShellFiles = Get-ChildItem -Path $ProjectPath -Include "*.ps1", "*.psm1", "*.psd1" -File -Recurse:$IncludeSubdirectories

# Initialiser le rapport des dépendances
$dependencies = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[PSObject]]]::new()

# Analyser chaque fichier PowerShell
$totalFiles = $powerShellFiles.Count
$processedFiles = 0

foreach ($file in $powerShellFiles) {
    $processedFiles++
    $percentComplete = [math]::Round(($processedFiles / $totalFiles) * 100)
    Write-Progress -Activity "Analyse des dépendances de modules" -Status "Traitement de $file" -PercentComplete $percentComplete

    try {
        # Analyser le fichier pour détecter les instructions Import-Module
        $moduleImports = Find-ImportModuleInstruction -FilePath $file.FullName -ResolveModulePaths:$ResolveModulePaths -BaseDirectory $file.DirectoryName

        if ($moduleImports.Count -gt 0) {
            $dependencies[$file.FullName] = $moduleImports
        }
    } catch {
        Write-Warning "Erreur lors de l'analyse du fichier $($file.FullName) : $_"
    }
}

Write-Progress -Activity "Analyse des dépendances de modules" -Completed

# Générer le rapport des dépendances
$report = [PSCustomObject]@{
    ProjectPath           = $ProjectPath
    TotalFiles            = $totalFiles
    FilesWithDependencies = $dependencies.Count
    TotalDependencies     = ($dependencies.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum
    Dependencies          = $dependencies
    GeneratedAt           = Get-Date
}

# Afficher ou enregistrer le rapport
if ($OutputPath) {
    $report | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath
    Write-Host "Rapport des dépendances enregistré dans $OutputPath" -ForegroundColor Green
} else {
    # Afficher un résumé dans la console
    Write-Host "Rapport des dépendances de modules pour $ProjectPath" -ForegroundColor Cyan
    Write-Host "  Nombre total de fichiers PowerShell : $totalFiles" -ForegroundColor Yellow
    Write-Host "  Nombre de fichiers avec dépendances : $($dependencies.Count)" -ForegroundColor Yellow
    Write-Host "  Nombre total de dépendances : $($report.TotalDependencies)" -ForegroundColor Yellow

    # Afficher les dépendances par fichier
    foreach ($file in $dependencies.Keys) {
        $relativePath = $file.Substring($ProjectPath.Length).TrimStart('\', '/')
        Write-Host "`n  Fichier : $relativePath" -ForegroundColor Green

        foreach ($module in $dependencies[$file]) {
            $moduleInfo = "    - $($module.Name)"

            if ($module.ImportType) {
                $moduleInfo += " (Type: $($module.ImportType))"
            }

            if ($module.Version) {
                $moduleInfo += " (Version: $($module.Version))"
            }

            if ($module.Path) {
                $moduleInfo += " [Chemin: $($module.Path)]"
            }

            Write-Host $moduleInfo -ForegroundColor Gray
        }
    }
}

# Afficher les statistiques des modules les plus utilisés
$moduleStats = @{}
foreach ($file in $dependencies.Keys) {
    foreach ($module in $dependencies[$file]) {
        if (-not $moduleStats.ContainsKey($module.Name)) {
            $moduleStats[$module.Name] = 0
        }

        $moduleStats[$module.Name]++
    }
}

Write-Host "`nModules les plus utilisés :" -ForegroundColor Cyan
$moduleStats.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host "  $($_.Key) : $($_.Value) fichiers" -ForegroundColor Yellow
}
