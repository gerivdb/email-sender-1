# Module de gÃ©nÃ©ration d'exemples pour le Script Manager
# Ce module gÃ©nÃ¨re des exemples d'utilisation pour les scripts
# Author: Script Manager
# Version: 1.0
# Tags: documentation, examples, scripts

function New-ScriptExamples {
    <#
    .SYNOPSIS
        GÃ©nÃ¨re des exemples d'utilisation pour les scripts
    .DESCRIPTION
        Analyse les scripts et gÃ©nÃ¨re des exemples d'utilisation adaptÃ©s
    .PARAMETER Script
        Objet script pour lequel gÃ©nÃ©rer des exemples
    .PARAMETER OutputPath
        Chemin oÃ¹ enregistrer les exemples
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
    
    # CrÃ©er le dossier d'exemples s'il n'existe pas
    $ExamplesPath = Join-Path -Path $OutputPath -ChildPath "examples"
    if (-not (Test-Path -Path $ExamplesPath)) {
        New-Item -ItemType Directory -Path $ExamplesPath -Force | Out-Null
    }
    
    # CrÃ©er le dossier pour le type de script
    $ScriptTypeFolder = Join-Path -Path $ExamplesPath -ChildPath $Script.Type
    if (-not (Test-Path -Path $ScriptTypeFolder)) {
        New-Item -ItemType Directory -Path $ScriptTypeFolder -Force | Out-Null
    }
    
    # CrÃ©er le nom du fichier d'exemple
    $ExampleFileName = [System.IO.Path]::GetFileNameWithoutExtension($Script.Name) + "_example" + [System.IO.Path]::GetExtension($Script.Name)
    $ExampleFilePath = Join-Path -Path $ScriptTypeFolder -ChildPath $ExampleFileName
    
    # GÃ©nÃ©rer le contenu de l'exemple
    $ExampleContent = Get-ScriptExampleContent -Script $Script
    
    # Enregistrer l'exemple
    try {
        Set-Content -Path $ExampleFilePath -Value $ExampleContent
        Write-Host "  Exemple gÃ©nÃ©rÃ©: $ExampleFilePath" -ForegroundColor Green
        
        return [PSCustomObject]@{
            ScriptPath = $Script.Path
            ScriptName = $Script.Name
            ExamplePath = $ExampleFilePath
            Type = $Script.Type
            Success = $true
        }
    } catch {
        Write-Warning "Erreur lors de la crÃ©ation de l'exemple pour $($Script.Path) : $_"
        
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
        GÃ©nÃ¨re le contenu d'un exemple pour un script
    .DESCRIPTION
        CrÃ©e un contenu d'exemple adaptÃ© au type de script
    .PARAMETER Script
        Objet script pour lequel gÃ©nÃ©rer un exemple
    .EXAMPLE
        Get-ScriptExampleContent -Script $script
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script
    )
    
    # GÃ©nÃ©rer un exemple adaptÃ© au type de script
    switch ($Script.Type) {
        "PowerShell" {
            @"
# Exemple d'utilisation de $($Script.Name)
# Cet exemple montre comment utiliser le script $($Script.Name)
# GÃ©nÃ©rÃ© automatiquement par le Script Manager

# Importer le script si nÃ©cessaire (pour les fonctions)
# . .\$($Script.Name)

# DÃ©finir les paramÃ¨tres
`$Param1 = "Valeur1"
`$Param2 = "Valeur2"

# Appeler le script ou ses fonctions
Write-Host "ExÃ©cution de $($Script.Name) avec les paramÃ¨tres :`n- Param1: `$Param1`n- Param2: `$Param2" -ForegroundColor Cyan

# Exemple d'appel du script avec des paramÃ¨tres
# .\$($Script.Name) -Param1 `$Param1 -Param2 `$Param2

# Si le script contient des fonctions, les appeler directement
$($Script.StaticAnalysis.Functions | Select-Object -First 1 | ForEach-Object {
"# $_ -Param1 `$Param1 -Param2 `$Param2"
})

# Afficher un message de succÃ¨s
Write-Host "Exemple terminÃ© avec succÃ¨s!" -ForegroundColor Green
"@
        }
        "Python" {
            @"
#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Exemple d'utilisation de $($Script.Name)
# Cet exemple montre comment utiliser le script $($Script.Name)
# GÃ©nÃ©rÃ© automatiquement par le Script Manager

# Importer les modules nÃ©cessaires
import os
import sys

# DÃ©finir les paramÃ¨tres
param1 = "Valeur1"
param2 = "Valeur2"

# Afficher les informations
print(f"ExÃ©cution de $($Script.Name) avec les paramÃ¨tres :")
print(f"- param1: {param1}")
print(f"- param2: {param2}")

# Exemple d'appel du script
# exec(open("$($Script.Name)").read())

# Si le script contient des fonctions, les importer et les appeler
# from $([System.IO.Path]::GetFileNameWithoutExtension($Script.Name)) import *
$($Script.StaticAnalysis.Functions | Select-Object -First 1 | ForEach-Object {
"# $_(param1, param2)"
})

# Afficher un message de succÃ¨s
print("Exemple terminÃ© avec succÃ¨s!")
"@
        }
        "Batch" {
            @"
@echo off
REM Exemple d'utilisation de $($Script.Name)
REM Cet exemple montre comment utiliser le script $($Script.Name)
REM GÃ©nÃ©rÃ© automatiquement par le Script Manager

REM DÃ©finir les paramÃ¨tres
SET PARAM1=Valeur1
SET PARAM2=Valeur2

REM Afficher les informations
ECHO ExÃ©cution de $($Script.Name) avec les paramÃ¨tres :
ECHO - PARAM1: %PARAM1%
ECHO - PARAM2: %PARAM2%

REM Exemple d'appel du script
REM CALL $($Script.Name) %PARAM1% %PARAM2%

REM Afficher un message de succÃ¨s
ECHO Exemple terminÃ© avec succÃ¨s!
"@
        }
        "Shell" {
            @"
#!/bin/bash
# Exemple d'utilisation de $($Script.Name)
# Cet exemple montre comment utiliser le script $($Script.Name)
# GÃ©nÃ©rÃ© automatiquement par le Script Manager

# DÃ©finir les paramÃ¨tres
PARAM1="Valeur1"
PARAM2="Valeur2"

# Afficher les informations
echo "ExÃ©cution de $($Script.Name) avec les paramÃ¨tres :"
echo "- PARAM1: \$PARAM1"
echo "- PARAM2: \$PARAM2"

# Exemple d'appel du script
# bash $($Script.Name) "\$PARAM1" "\$PARAM2"

# Afficher un message de succÃ¨s
echo "Exemple terminÃ© avec succÃ¨s!"
"@
        }
        default {
            @"
# Exemple d'utilisation de $($Script.Name)
# Cet exemple montre comment utiliser le script $($Script.Name)
# GÃ©nÃ©rÃ© automatiquement par le Script Manager

# DÃ©finir les paramÃ¨tres
Param1 = "Valeur1"
Param2 = "Valeur2"

# Afficher les informations
print("ExÃ©cution de $($Script.Name) avec les paramÃ¨tres :")
print("- Param1: " + Param1)
print("- Param2: " + Param2)

# Exemple d'appel du script
# (DÃ©pend du type de script)

# Afficher un message de succÃ¨s
print("Exemple terminÃ© avec succÃ¨s!")
"@
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-ScriptExamples, Get-ScriptExampleContent
