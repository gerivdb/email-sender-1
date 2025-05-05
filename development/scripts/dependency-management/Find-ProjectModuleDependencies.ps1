#Requires -Version 5.1
<#
.SYNOPSIS
    DÃ©tecte les dÃ©pendances de modules PowerShell dans un projet.

.DESCRIPTION
    Ce script analyse tous les fichiers PowerShell d'un projet pour dÃ©tecter
    les instructions Import-Module et gÃ©nÃ©rer un rapport des dÃ©pendances.

.PARAMETER ProjectPath
    Chemin du rÃ©pertoire du projet Ã  analyser.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport des dÃ©pendances.
    Si non spÃ©cifiÃ©, le rapport est affichÃ© dans la console.

.PARAMETER IncludeSubdirectories
    Indique si les sous-rÃ©pertoires doivent Ãªtre inclus dans l'analyse.

.PARAMETER ResolveModulePaths
    Indique si les chemins des modules doivent Ãªtre rÃ©solus.

.EXAMPLE
    .\Find-ProjectModuleDependencies.ps1 -ProjectPath "C:\Projects\MyProject"

.EXAMPLE
    .\Find-ProjectModuleDependencies.ps1 -ProjectPath "C:\Projects\MyProject" -OutputPath "C:\Reports\dependencies.json" -IncludeSubdirectories -ResolveModulePaths

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2023-06-15
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

# VÃ©rifier que le rÃ©pertoire du projet existe
if (-not (Test-Path -Path $ProjectPath -PathType Container)) {
    Write-Error "Le rÃ©pertoire du projet spÃ©cifiÃ© n'existe pas : $ProjectPath"
    exit 1
}

# Obtenir tous les fichiers PowerShell du projet
$powerShellFiles = Get-ChildItem -Path $ProjectPath -Include "*.ps1", "*.psm1", "*.psd1" -File -Recurse:$IncludeSubdirectories

# Initialiser le rapport des dÃ©pendances
$dependencies = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[PSObject]]]::new()

# Analyser chaque fichier PowerShell
$totalFiles = $powerShellFiles.Count
$processedFiles = 0

foreach ($file in $powerShellFiles) {
    $processedFiles++
    $percentComplete = [math]::Round(($processedFiles / $totalFiles) * 100)
    Write-Progress -Activity "Analyse des dÃ©pendances de modules" -Status "Traitement de $file" -PercentComplete $percentComplete

    try {
        # Analyser le fichier pour dÃ©tecter les instructions Import-Module
        $moduleImports = Find-ImportModuleInstruction -FilePath $file.FullName -ResolveModulePaths:$ResolveModulePaths -BaseDirectory $file.DirectoryName

        if ($moduleImports.Count -gt 0) {
            $dependencies[$file.FullName] = $moduleImports
        }
    } catch {
        Write-Warning "Erreur lors de l'analyse du fichier $($file.FullName) : $_"
    }
}

Write-Progress -Activity "Analyse des dÃ©pendances de modules" -Completed

# GÃ©nÃ©rer le rapport des dÃ©pendances
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
    Write-Host "Rapport des dÃ©pendances enregistrÃ© dans $OutputPath" -ForegroundColor Green
} else {
    # Afficher un rÃ©sumÃ© dans la console
    Write-Host "Rapport des dÃ©pendances de modules pour $ProjectPath" -ForegroundColor Cyan
    Write-Host "  Nombre total de fichiers PowerShell : $totalFiles" -ForegroundColor Yellow
    Write-Host "  Nombre de fichiers avec dÃ©pendances : $($dependencies.Count)" -ForegroundColor Yellow
    Write-Host "  Nombre total de dÃ©pendances : $($report.TotalDependencies)" -ForegroundColor Yellow

    # Afficher les dÃ©pendances par fichier
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

# Afficher les statistiques des modules les plus utilisÃ©s
$moduleStats = @{}
foreach ($file in $dependencies.Keys) {
    foreach ($module in $dependencies[$file]) {
        if (-not $moduleStats.ContainsKey($module.Name)) {
            $moduleStats[$module.Name] = 0
        }

        $moduleStats[$module.Name]++
    }
}

Write-Host "`nModules les plus utilisÃ©s :" -ForegroundColor Cyan
$moduleStats.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10 | ForEach-Object {
    Write-Host "  $($_.Key) : $($_.Value) fichiers" -ForegroundColor Yellow
}
