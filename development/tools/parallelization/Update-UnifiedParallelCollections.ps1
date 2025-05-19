﻿#Requires -Version 5.1

<#
.SYNOPSIS
    Met à jour le module UnifiedParallel avec les nouvelles fonctionnalités de collection.

.DESCRIPTION
    Ce script met à jour le module UnifiedParallel en intégrant les nouvelles fonctionnalités de collection.
    Il ajoute les classes et fonctions définies dans CollectionWrapper.ps1 et CollectionExtensions.ps1 au module.

.PARAMETER ModulePath
    Chemin du module UnifiedParallel. Par défaut, le chemin relatif "../UnifiedParallel.psm1".

.PARAMETER BackupModule
    Indique s'il faut créer une sauvegarde du module avant de le modifier. Par défaut, $true.

.PARAMETER BackupPath
    Chemin où stocker la sauvegarde du module. Par défaut, "../Backup".

.EXAMPLE
    .\Update-UnifiedParallelCollections.ps1
    Met à jour le module UnifiedParallel avec les nouvelles fonctionnalités de collection.

.EXAMPLE
    .\Update-UnifiedParallelCollections.ps1 -ModulePath "C:\Path\To\UnifiedParallel.psm1" -BackupModule $false
    Met à jour le module UnifiedParallel spécifié sans créer de sauvegarde.

.NOTES
    Version: 1.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-20
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$ModulePath = "..\UnifiedParallel.psm1",

    [Parameter(Mandatory = $false)]
    [bool]$BackupModule = $true,

    [Parameter(Mandatory = $false)]
    [string]$BackupPath = "..\Backup"
)

# Vérifier que le module existe
$modulePath = Resolve-Path -Path $ModulePath -ErrorAction Stop
if (-not (Test-Path -Path $modulePath)) {
    throw "Le module UnifiedParallel n'existe pas à l'emplacement spécifié : $modulePath"
}

# Créer une sauvegarde du module
if ($BackupModule) {
    $backupPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath $BackupPath
    if (-not (Test-Path -Path $backupPath)) {
        New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
    }

    $backupFile = Join-Path -Path $backupPath -ChildPath "UnifiedParallel_$(Get-Date -Format 'yyyyMMdd_HHmmss').psm1"
    if ($PSCmdlet.ShouldProcess("Créer une sauvegarde du module", "Backup")) {
        Copy-Item -Path $modulePath -Destination $backupFile -Force
        Write-Host "Sauvegarde du module créée : $backupFile" -ForegroundColor Green
    }
}

# Lire le contenu du module
$moduleContent = Get-Content -Path $modulePath -Raw

# Lire le contenu des fichiers de collection
$wrapperPath = Join-Path -Path $PSScriptRoot -ChildPath "CollectionWrapper.ps1"
$extensionsPath = Join-Path -Path $PSScriptRoot -ChildPath "CollectionExtensions.ps1"

if (-not (Test-Path -Path $wrapperPath)) {
    throw "Le fichier CollectionWrapper.ps1 n'existe pas à l'emplacement spécifié : $wrapperPath"
}

if (-not (Test-Path -Path $extensionsPath)) {
    throw "Le fichier CollectionExtensions.ps1 n'existe pas à l'emplacement spécifié : $extensionsPath"
}

$wrapperContent = Get-Content -Path $wrapperPath -Raw
$extensionsContent = Get-Content -Path $extensionsPath -Raw

# Extraire les définitions de types et de fonctions
$wrapperTypeDefinition = [regex]::Match($wrapperContent, 'Add-Type -TypeDefinition @"(.*?)"@', [System.Text.RegularExpressions.RegexOptions]::Singleline).Groups[1].Value
$extensionsTypeDefinition = [regex]::Match($extensionsContent, 'Add-Type -TypeDefinition @"(.*?)"@', [System.Text.RegularExpressions.RegexOptions]::Singleline).Groups[1].Value

$wrapperFunctions = [regex]::Matches($wrapperContent, 'function ([A-Za-z0-9\-]+) \{(.*?)\}', [System.Text.RegularExpressions.RegexOptions]::Singleline)
$extensionsFunctions = [regex]::Matches($extensionsContent, 'function ([A-Za-z0-9\-]+) \{(.*?)\}', [System.Text.RegularExpressions.RegexOptions]::Singleline)

# Vérifier si les définitions de types existent déjà dans le module
$typeDefinitionsExist = $moduleContent -match 'namespace UnifiedParallel\.Collections'

# Préparer le contenu à ajouter
$contentToAdd = @"

#region Collections
# Définitions de types pour les collections
"@

if (-not $typeDefinitionsExist) {
    $contentToAdd += @"

Add-Type -TypeDefinition @"
$wrapperTypeDefinition
$extensionsTypeDefinition
"@
    "@
}

$contentToAdd += @"

    # Fonctions pour les collections
    "@

foreach ($function in $wrapperFunctions) {
    $functionName = $function.Groups[1].Value
    $functionBody = $function.Groups[0].Value
    $contentToAdd += "`n$functionBody`n"
}

foreach ($function in $extensionsFunctions) {
    $functionName = $function.Groups[1].Value
    $functionBody = $function.Groups[0].Value
    $contentToAdd += "`n$functionBody`n"
}

$contentToAdd += @"

    #endregion Collections
    "@

# Trouver l'emplacement où ajouter le contenu
$exportModuleMembersPattern = '# Exporter les fonctions publiques\r?\nExport-ModuleMember -Function'
$exportModuleMembersMatch = [regex]::Match($moduleContent, $exportModuleMembersPattern)

if (-not $exportModuleMembersMatch.Success) {
    throw "Impossible de trouver l'instruction Export-ModuleMember dans le module."
}

$insertPosition = $exportModuleMembersMatch.Index
$newModuleContent = $moduleContent.Substring(0, $insertPosition) + $contentToAdd + "`n`n" + $moduleContent.Substring($insertPosition)

# Mettre à jour la liste des fonctions exportées
$exportFunctionsPattern = 'Export-ModuleMember -Function (.*)'
$exportFunctionsMatch = [regex]::Match($newModuleContent, $exportFunctionsPattern)

if ($exportFunctionsMatch.Success) {
    $exportedFunctions = $exportFunctionsMatch.Groups[1].Value.Trim()
    $newFunctions = @()

    foreach ($function in $wrapperFunctions) {
        $functionName = $function.Groups[1].Value
        $newFunctions += $functionName
    }

    foreach ($function in $extensionsFunctions) {
        $functionName = $function.Groups[1].Value
        $newFunctions += $functionName
    }

    $newExportedFunctions = "$exportedFunctions, " + ($newFunctions -join ", ")
    $newModuleContent = $newModuleContent -replace $exportFunctionsPattern, "Export-ModuleMember -Function $newExportedFunctions"
}

# Écrire le nouveau contenu dans le module
if ($PSCmdlet.ShouldProcess("Mettre à jour le module avec les nouvelles fonctionnalités de collection", "Update")) {
    Set-Content -Path $modulePath -Value $newModuleContent -Encoding UTF8
    Write-Host "Le module UnifiedParallel a été mis à jour avec les nouvelles fonctionnalités de collection." -ForegroundColor Green
}

# Afficher les nouvelles fonctions ajoutées
Write-Host "Nouvelles fonctions ajoutées au module :" -ForegroundColor Cyan
foreach ($function in $wrapperFunctions) {
    $functionName = $function.Groups[1].Value
    Write-Host "- $functionName" -ForegroundColor White
}

foreach ($function in $extensionsFunctions) {
    $functionName = $function.Groups[1].Value
    Write-Host "- $functionName" -ForegroundColor White
}
