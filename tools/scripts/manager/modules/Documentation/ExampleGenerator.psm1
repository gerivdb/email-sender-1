# Module de génération d'exemples pour le Script Manager
# Ce module génère des exemples d'utilisation pour les scripts
# Author: Script Manager
# Version: 1.0
# Tags: documentation, examples, scripts

function New-ScriptExamples {
    <#
    .SYNOPSIS
        Génère des exemples d'utilisation pour les scripts
    .DESCRIPTION
        Analyse les scripts et génère des exemples d'utilisation adaptés
    .PARAMETER Script
        Objet script pour lequel générer des exemples
    .PARAMETER OutputPath
        Chemin où enregistrer les exemples
    .EXAMPLE
        New-ScriptExamples -Script $script -OutputPath "docs/examples"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    # Créer le dossier d'exemples s'il n'existe pas
    $ExamplesPath = Join-Path -Path $OutputPath -ChildPath "examples"
    if (-not (Test-Path -Path $ExamplesPath)) {
        New-Item -ItemType Directory -Path $ExamplesPath -Force | Out-Null
    }
    
    # Créer le dossier pour le type de script
    $ScriptTypeFolder = Join-Path -Path $ExamplesPath -ChildPath $Script.Type
    if (-not (Test-Path -Path $ScriptTypeFolder)) {
        New-Item -ItemType Directory -Path $ScriptTypeFolder -Force | Out-Null
    }
    
    # Créer le nom du fichier d'exemple
    $ExampleFileName = [System.IO.Path]::GetFileNameWithoutExtension($Script.Name) + "_example" + [System.IO.Path]::GetExtension($Script.Name)
    $ExampleFilePath = Join-Path -Path $ScriptTypeFolder -ChildPath $ExampleFileName
    
    # Générer le contenu de l'exemple
    $ExampleContent = Get-ScriptExampleContent -Script $Script
    
    # Enregistrer l'exemple
    try {
        Set-Content -Path $ExampleFilePath -Value $ExampleContent
        Write-Host "  Exemple généré: $ExampleFilePath" -ForegroundColor Green
        
        return [PSCustomObject]@{
            ScriptPath = $Script.Path
            ScriptName = $Script.Name
            ExamplePath = $ExampleFilePath
            Type = $Script.Type
            Success = $true
        }
    } catch {
        Write-Warning "Erreur lors de la création de l'exemple pour $($Script.Path) : $_"
        
        return [PSCustomObject]@{
            ScriptPath = $Script.Path
            ScriptName = $Script.Name
            ExamplePath = $ExampleFilePath
            Type = $Script.Type
            Success = $false
            Error = $_.ToString()
        }
    }
}

function Get-ScriptExampleContent {
    <#
    .SYNOPSIS
        Génère le contenu d'un exemple pour un script
    .DESCRIPTION
        Crée un contenu d'exemple adapté au type de script
    .PARAMETER Script
        Objet script pour lequel générer un exemple
    .EXAMPLE
        Get-ScriptExampleContent -Script $script
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script
    )
    
    # Générer un exemple adapté au type de script
    switch ($Script.Type) {
        "PowerShell" {
            @"
# Exemple d'utilisation de $($Script.Name)
# Cet exemple montre comment utiliser le script $($Script.Name)
# Généré automatiquement par le Script Manager

# Importer le script si nécessaire (pour les fonctions)
# . .\$($Script.Name)

# Définir les paramètres
`$Param1 = "Valeur1"
`$Param2 = "Valeur2"

# Appeler le script ou ses fonctions
Write-Host "Exécution de $($Script.Name) avec les paramètres :`n- Param1: `$Param1`n- Param2: `$Param2" -ForegroundColor Cyan

# Exemple d'appel du script avec des paramètres
# .\$($Script.Name) -Param1 `$Param1 -Param2 `$Param2

# Si le script contient des fonctions, les appeler directement
$($Script.StaticAnalysis.Functions | Select-Object -First 1 | ForEach-Object {
"# $_ -Param1 `$Param1 -Param2 `$Param2"
})

# Afficher un message de succès
Write-Host "Exemple terminé avec succès!" -ForegroundColor Green
"@
        }
        "Python" {
            @"
#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Exemple d'utilisation de $($Script.Name)
# Cet exemple montre comment utiliser le script $($Script.Name)
# Généré automatiquement par le Script Manager

# Importer les modules nécessaires
import os
import sys

# Définir les paramètres
param1 = "Valeur1"
param2 = "Valeur2"

# Afficher les informations
print(f"Exécution de $($Script.Name) avec les paramètres :")
print(f"- param1: {param1}")
print(f"- param2: {param2}")

# Exemple d'appel du script
# exec(open("$($Script.Name)").read())

# Si le script contient des fonctions, les importer et les appeler
# from $([System.IO.Path]::GetFileNameWithoutExtension($Script.Name)) import *
$($Script.StaticAnalysis.Functions | Select-Object -First 1 | ForEach-Object {
"# $_(param1, param2)"
})

# Afficher un message de succès
print("Exemple terminé avec succès!")
"@
        }
        "Batch" {
            @"
@echo off
REM Exemple d'utilisation de $($Script.Name)
REM Cet exemple montre comment utiliser le script $($Script.Name)
REM Généré automatiquement par le Script Manager

REM Définir les paramètres
SET PARAM1=Valeur1
SET PARAM2=Valeur2

REM Afficher les informations
ECHO Exécution de $($Script.Name) avec les paramètres :
ECHO - PARAM1: %PARAM1%
ECHO - PARAM2: %PARAM2%

REM Exemple d'appel du script
REM CALL $($Script.Name) %PARAM1% %PARAM2%

REM Afficher un message de succès
ECHO Exemple terminé avec succès!
"@
        }
        "Shell" {
            @"
#!/bin/bash
# Exemple d'utilisation de $($Script.Name)
# Cet exemple montre comment utiliser le script $($Script.Name)
# Généré automatiquement par le Script Manager

# Définir les paramètres
PARAM1="Valeur1"
PARAM2="Valeur2"

# Afficher les informations
echo "Exécution de $($Script.Name) avec les paramètres :"
echo "- PARAM1: \$PARAM1"
echo "- PARAM2: \$PARAM2"

# Exemple d'appel du script
# bash $($Script.Name) "\$PARAM1" "\$PARAM2"

# Afficher un message de succès
echo "Exemple terminé avec succès!"
"@
        }
        default {
            @"
# Exemple d'utilisation de $($Script.Name)
# Cet exemple montre comment utiliser le script $($Script.Name)
# Généré automatiquement par le Script Manager

# Définir les paramètres
Param1 = "Valeur1"
Param2 = "Valeur2"

# Afficher les informations
print("Exécution de $($Script.Name) avec les paramètres :")
print("- Param1: " + Param1)
print("- Param2: " + Param2)

# Exemple d'appel du script
# (Dépend du type de script)

# Afficher un message de succès
print("Exemple terminé avec succès!")
"@
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-ScriptExamples, Get-ScriptExampleContent
