#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour les templates de modules PowerShell.
.DESCRIPTION
    Ce script teste la génération de modules PowerShell à partir des templates Hygen.
.PARAMETER OutputFolder
    Dossier de sortie pour les modules générés. Par défaut, un dossier temporaire est créé.
.PARAMETER KeepGeneratedFiles
    Si spécifié, les fichiers générés ne seront pas supprimés après les tests.
.PARAMETER TestStandard
    Si spécifié, seul le template de module standard sera testé.
.PARAMETER TestAdvanced
    Si spécifié, seul le template de module avancé sera testé.
.PARAMETER TestExtension
    Si spécifié, seul le template de module d'extension sera testé.
.EXAMPLE
    .\Test-PowerShellModuleTemplates.ps1
    Teste tous les templates de modules PowerShell.
.EXAMPLE
    .\Test-PowerShellModuleTemplates.ps1 -TestStandard -KeepGeneratedFiles
    Teste uniquement le template de module standard et conserve les fichiers générés.
.NOTES
    Version: 1.0.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "",

    [Parameter(Mandatory = $false)]
    [switch]$KeepGeneratedFiles,

    [Parameter(Mandatory = $false)]
    [switch]$TestStandard,

    [Parameter(Mandatory = $false)]
    [switch]$TestAdvanced,

    [Parameter(Mandatory = $false)]
    [switch]$TestExtension
)

# Fonction pour obtenir le chemin du projet
function Get-ProjectPath {
    # Chemin absolu du projet
    return "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
}

# Fonction pour générer un module PowerShell avec Hygen
function New-PowerShellModule {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [string]$Category,

        [Parameter(Mandatory = $true)]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [string]$Author = "Test User",

        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = ""
    )

    $projectRoot = Get-ProjectPath

    # Déterminer le dossier de sortie
    if ([string]::IsNullOrEmpty($OutputFolder)) {
        $outputFolder = Join-Path -Path $env:TEMP -ChildPath "PowerShellModuleTest_$(Get-Random)"
        New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
    }

    # Préparer les arguments pour Hygen
    $hygenArgs = @(
        "hygen",
        "powershell-module",
        "new",
        "--name",
        $Name,
        "--description",
        $Description,
        "--category",
        $Category,
        "--type",
        $Type,
        "--author",
        $Author
    )

    # Exécuter Hygen
    if ($PSCmdlet.ShouldProcess("Hygen", "Générer un module PowerShell")) {
        try {
            # Sauvegarder le répertoire courant
            $currentLocation = Get-Location

            # Changer le répertoire courant pour le projet
            Set-Location -Path $projectRoot

            # Vérifier si Hygen est installé
            $hygenInstalled = $null
            try {
                $hygenInstalled = Get-Command "hygen" -ErrorAction SilentlyContinue
            } catch {
                Write-Verbose "Hygen n'est pas installé globalement, utilisation de npx"
            }

            # Exécuter Hygen
            if ($hygenInstalled) {
                # Utiliser Hygen directement s'il est installé
                $hygenArgs = $hygenArgs | Select-Object -Skip 1
                Write-Host "Exécution de hygen $($hygenArgs -join ' ')" -ForegroundColor Cyan
                & hygen $hygenArgs
            } else {
                # Utiliser npx si Hygen n'est pas installé
                Write-Host "Exécution de npx hygen $($hygenArgs[1..$hygenArgs.Length] -join ' ')" -ForegroundColor Cyan
                & npx hygen $hygenArgs[1..$hygenArgs.Length]
            }

            # Vérifier si la commande a réussi
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Hygen a échoué avec le code de sortie $LASTEXITCODE"
                return $null
            }

            # Retourner le chemin du module généré
            $modulePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\$Category\modules\$Name"
            return $modulePath
        } catch {
            Write-Error "Une erreur s'est produite lors de la génération du module : $_"
            return $null
        } finally {
            # Restaurer le répertoire courant
            Set-Location -Path $currentLocation
        }
    }
}

# Fonction pour tester un module PowerShell généré
function Test-GeneratedModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $true)]
        [string]$ModuleType
    )

    $errors = 0
    $warnings = 0

    # Vérifier l'existence des fichiers principaux
    $requiredFiles = @(
        "$ModuleName.psm1",
        "$ModuleName.psd1",
        "README.md",
        "Public\README.md",
        "Private\README.md",
        "Tests\$ModuleName.Tests.ps1"
    )

    foreach ($file in $requiredFiles) {
        $filePath = Join-Path -Path $ModulePath -ChildPath $file
        if (-not (Test-Path -Path $filePath)) {
            Write-Error "Fichier requis non trouvé : $file"
            $errors++
        } else {
            Write-Host "Fichier trouvé : $file" -ForegroundColor Green
        }
    }

    # Vérifier le contenu du fichier de module
    $moduleFilePath = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psm1"
    if (Test-Path -Path $moduleFilePath) {
        $moduleContent = Get-Content -Path $moduleFilePath -Raw

        # Vérifier les éléments spécifiques au type de module
        switch ($ModuleType) {
            "standard" {
                if ($moduleContent -notmatch "Initialize-\w+Module") {
                    Write-Warning "Le module standard ne contient pas la fonction d'initialisation attendue"
                    $warnings++
                }
            }
            "advanced" {
                if ($moduleContent -notmatch "Get-ModuleStateValue|Set-ModuleStateValue|Remove-ModuleStateValue") {
                    Write-Warning "Le module avancé ne contient pas les fonctions de gestion d'état attendues"
                    $warnings++
                }
            }
            "extension" {
                if ($moduleContent -notmatch "Register-ExtensionPoint|Register-ExtensionHandler|Invoke-ExtensionPoint") {
                    Write-Warning "Le module d'extension ne contient pas les fonctions d'extension attendues"
                    $warnings++
                }
            }
        }
    }

    # Vérifier le manifeste du module
    $manifestFilePath = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"
    if (Test-Path -Path $manifestFilePath) {
        try {
            # Tester le manifeste sans stocker le résultat
            Test-ModuleManifest -Path $manifestFilePath -ErrorAction Stop | Out-Null
            Write-Host "Manifeste du module valide" -ForegroundColor Green
        } catch {
            Write-Error "Manifeste du module invalide : $_"
            $errors++
        }
    }

    # Retourner le résultat du test
    return [PSCustomObject]@{
        ModuleName = $ModuleName
        ModuleType = $ModuleType
        ModulePath = $ModulePath
        Errors     = $errors
        Warnings   = $warnings
        Success    = ($errors -eq 0)
    }
}

# Fonction principale
function Main {
    # Obtenir le chemin du projet
    $projectRoot = Get-ProjectPath
    Write-Host "Chemin du projet : $projectRoot" -ForegroundColor Cyan

    # Créer un dossier temporaire pour les tests si nécessaire
    if ([string]::IsNullOrEmpty($OutputFolder)) {
        $OutputFolder = Join-Path -Path $env:TEMP -ChildPath "PowerShellModuleTest_$(Get-Random)"
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
        Write-Host "Dossier de sortie créé : $OutputFolder" -ForegroundColor Cyan
    }

    # Déterminer quels templates tester
    $templatesTypes = @()
    if ($TestStandard -or (-not ($TestStandard -or $TestAdvanced -or $TestExtension))) {
        $templatesTypes += "standard"
    }
    if ($TestAdvanced -or (-not ($TestStandard -or $TestAdvanced -or $TestExtension))) {
        $templatesTypes += "advanced"
    }
    if ($TestExtension -or (-not ($TestStandard -or $TestAdvanced -or $TestExtension))) {
        $templatesTypes += "extension"
    }

    Write-Host "Templates à tester : $($templatesTypes -join ', ')" -ForegroundColor Cyan

    # Tester chaque type de template
    $results = @()
    foreach ($type in $templatesTypes) {
        $moduleName = "Test$($type.Substring(0,1).ToUpper() + $type.Substring(1))Module"
        $description = "Module de test pour le template $type"
        $category = "testing"

        Write-Host "`nTest du template de module $type" -ForegroundColor Yellow
        Write-Host "Génération du module $moduleName..." -ForegroundColor Cyan

        $modulePath = New-PowerShellModule -Name $moduleName -Description $description -Category $category -Type $type -OutputFolder $OutputFolder

        if ($modulePath -and (Test-Path -Path $modulePath)) {
            Write-Host "Module généré avec succès : $modulePath" -ForegroundColor Green

            # Tester le module généré
            $testResult = Test-GeneratedModule -ModulePath $modulePath -ModuleName $moduleName -ModuleType $type
            $results += $testResult

            # Afficher le résultat du test
            if ($testResult.Success) {
                Write-Host "Test réussi pour le module $moduleName ($type)" -ForegroundColor Green
            } else {
                Write-Host "Test échoué pour le module $moduleName ($type) : $($testResult.Errors) erreurs, $($testResult.Warnings) avertissements" -ForegroundColor Red
            }
        } else {
            Write-Error "Échec de la génération du module $moduleName"
        }
    }

    # Afficher le résumé des tests
    Write-Host "`nRésumé des tests :" -ForegroundColor Yellow
    foreach ($result in $results) {
        $statusColor = if ($result.Success) { "Green" } else { "Red" }
        $status = if ($result.Success) { "Réussi" } else { "Échoué" }
        Write-Host "$($result.ModuleName) ($($result.ModuleType)) : $status - $($result.Errors) erreurs, $($result.Warnings) avertissements" -ForegroundColor $statusColor
    }

    # Nettoyer les fichiers générés si nécessaire
    if (-not $KeepGeneratedFiles) {
        Write-Host "`nNettoyage des fichiers générés..." -ForegroundColor Cyan
        foreach ($result in $results) {
            if (Test-Path -Path $result.ModulePath) {
                Remove-Item -Path $result.ModulePath -Recurse -Force
                Write-Host "Module supprimé : $($result.ModulePath)" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "`nLes fichiers générés ont été conservés dans :" -ForegroundColor Cyan
        foreach ($result in $results) {
            Write-Host "- $($result.ModulePath)" -ForegroundColor Gray
        }
    }
}

# Exécuter la fonction principale
Main
