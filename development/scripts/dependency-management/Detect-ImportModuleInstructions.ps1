#Requires -Version 5.1
<#
.SYNOPSIS
    Détecte les instructions Import-Module dans un script PowerShell.

.DESCRIPTION
    Ce script analyse un fichier PowerShell pour détecter les instructions Import-Module
    et affiche des informations détaillées sur chaque module importé.

.PARAMETER FilePath
    Chemin du fichier PowerShell à analyser.

.PARAMETER ResolveModulePaths
    Indique si les chemins des modules doivent être résolus.

.PARAMETER OutputFormat
    Format de sortie des résultats (Text, JSON, CSV).

.EXAMPLE
    .\Detect-ImportModuleInstructions.ps1 -FilePath "C:\Scripts\MyScript.ps1"

.EXAMPLE
    .\Detect-ImportModuleInstructions.ps1 -FilePath "C:\Scripts\MyScript.ps1" -ResolveModulePaths -OutputFormat JSON

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2023-06-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [switch]$ResolveModulePaths,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Text", "JSON", "CSV")]
    [string]$OutputFormat = "Text"
)

# Importer le module ModuleDependencyDetector
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ModuleDependencyDetector.psm1"
Import-Module $modulePath -Force

# Vérifier que le fichier existe
if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
    Write-Error "Le fichier spécifié n'existe pas : $FilePath"
    exit 1
}

# Analyser le fichier pour détecter les instructions Import-Module
try {
    $moduleImports = Find-ImportModuleInstruction -FilePath $FilePath -ResolveModulePaths:$ResolveModulePaths

    # Afficher les résultats selon le format demandé
    switch ($OutputFormat) {
        "JSON" {
            $moduleImports | ConvertTo-Json -Depth 5
        }
        "CSV" {
            $moduleImports | ConvertTo-Csv -NoTypeInformation
        }
        default {
            # Format texte par défaut
            Write-Host "Instructions d'importation de modules détectées dans $FilePath :" -ForegroundColor Cyan

            if ($moduleImports.Count -eq 0) {
                Write-Host "  Aucune instruction d'importation de module détectée." -ForegroundColor Yellow
            } else {
                # Compter les différents types d'importation
                $importModules = @($moduleImports | Where-Object { $_.ImportType -eq "Import-Module" })
                $usingModules = @($moduleImports | Where-Object { $_.ImportType -eq "using module" })
                $importModuleCount = $importModules.Count
                $usingModuleCount = $usingModules.Count

                Write-Verbose "Nombre total d'instructions trouvées : $($moduleImports.Count)"
                Write-Verbose "Instructions Import-Module : $importModuleCount"
                Write-Verbose "Instructions using module : $usingModuleCount"

                # Afficher les détails de chaque instruction pour le débogage
                Write-Verbose "Détails de toutes les instructions détectées :"
                foreach ($module in $moduleImports) {
                    Write-Verbose "Module : $($module.Name), Type : $($module.ImportType), Ligne : $($module.LineNumber), ArgumentType : $($module.ArgumentType)"
                }

                # Afficher les détails des instructions using module
                Write-Verbose "Détails des instructions using module :"
                $usingModules = $moduleImports | Where-Object { $_.ImportType -eq "using module" }
                foreach ($module in $usingModules) {
                    Write-Verbose "  Module : $($module.Name), Ligne : $($module.LineNumber), ArgumentType : $($module.ArgumentType)"
                }

                Write-Host "  Nombre total d'instructions trouvées : $($moduleImports.Count)" -ForegroundColor Yellow
                Write-Host "    - Instructions Import-Module : $importModuleCount" -ForegroundColor Yellow
                Write-Host "    - Instructions using module : $usingModuleCount" -ForegroundColor Yellow

                # Afficher les instructions using module d'abord
                if ($usingModules.Count -gt 0) {
                    Write-Host "`n  Instructions using module :" -ForegroundColor Cyan
                    foreach ($module in $usingModules) {
                        Write-Host "    Module : $($module.Name)" -ForegroundColor Green
                        Write-Host "      Ligne : $($module.LineNumber), Colonne : $($module.ColumnNumber)" -ForegroundColor Gray
                        Write-Host "      Instruction : $($module.RawCommand)" -ForegroundColor Gray

                        if ($module.Path) {
                            Write-Host "      Chemin résolu : $($module.Path)" -ForegroundColor Gray
                        }
                    }
                } else {
                    Write-Verbose "Aucune instruction using module trouvée à afficher"
                }

                # Afficher les instructions Import-Module ensuite
                if ($importModules.Count -gt 0) {
                    Write-Host "`n  Instructions Import-Module :" -ForegroundColor Cyan
                    foreach ($module in $importModules) {
                        Write-Host "    Module : $($module.Name)" -ForegroundColor Green
                        Write-Host "      Ligne : $($module.LineNumber), Colonne : $($module.ColumnNumber)" -ForegroundColor Gray
                        Write-Host "      Commande : $($module.RawCommand)" -ForegroundColor Gray

                        if ($module.Path) {
                            Write-Host "      Chemin résolu : $($module.Path)" -ForegroundColor Gray
                        }

                        if ($module.Version) {
                            Write-Host "      Version : $($module.Version)" -ForegroundColor Gray
                        }

                        if ($module.Global) {
                            Write-Host "      Portée : Globale" -ForegroundColor Gray
                        }

                        if ($module.Force) {
                            Write-Host "      Force : Oui" -ForegroundColor Gray
                        }

                        if ($module.Prefix) {
                            Write-Host "      Préfixe : $($module.Prefix)" -ForegroundColor Gray
                        }

                        Write-Host "      Type d'argument : $($module.ArgumentType)" -ForegroundColor Gray
                    }
                }
            }
        }
    }
} catch {
    Write-Error "Erreur lors de l'analyse du fichier : $_"
    exit 1
}
