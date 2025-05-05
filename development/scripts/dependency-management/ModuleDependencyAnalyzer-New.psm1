#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'analyse des dÃ©pendances entre modules PowerShell.

.DESCRIPTION
    Ce module permet d'analyser les dÃ©pendances entre modules PowerShell,
    en dÃ©tectant les dÃ©pendances via les manifestes (.psd1) et l'analyse du code.

.NOTES
    Auteur: Dependency Management Team
    Version: 1.0
#>

# Importer les sous-modules
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "Modules"
$subModules = @(
    "DependencyUtils.psm1",
    "ManifestAnalyzer.psm1",
    "CodeAnalyzer.psm1"
)

foreach ($subModule in $subModules) {
    $subModulePath = Join-Path -Path $modulesPath -ChildPath $subModule
    if (Test-Path -Path $subModulePath) {
        Import-Module -Name $subModulePath -Force
    } else {
        Write-Warning "Sub-module not found: $subModulePath"
    }
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-PowerShellManifestStructure, Get-ModuleDependenciesFromManifest, Get-ModuleDependenciesFromCode, Test-SystemModule, Find-ModulePath, Get-ModuleDependencyGraph, Export-DependencyGraphToJson, Export-DependencyGraphToDOT, Export-DependencyGraphToHTML
