#Requires -Version 5.1
<#
.SYNOPSIS
    Corrige les problèmes d'importation des modules PowerShell.
.DESCRIPTION
    Ce script corrige les problèmes d'importation des modules PowerShell en ajoutant
    les chemins des modules au PSModulePath et en créant des liens symboliques si nécessaire.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
#>

# Chemin du répertoire des modules
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "."
$modulesPath = Resolve-Path -Path $modulesPath

# Modules à corriger
$modules = @(
    "CycleDetector",
    "DependencyCycleResolver"
)

# Vérifier si les modules existent
foreach ($module in $modules) {
    $modulePath = Join-Path -Path $modulesPath -ChildPath "$module.psm1"
    if (-not (Test-Path -Path $modulePath)) {
        Write-Error "Le module $module.psm1 n'existe pas à l'emplacement spécifié: $modulePath"
        exit 1
    }
}

# Ajouter le chemin des modules au PSModulePath
$currentPSModulePath = [Environment]::GetEnvironmentVariable("PSModulePath", "Process")
if (-not $currentPSModulePath.Contains($modulesPath)) {
    [Environment]::SetEnvironmentVariable("PSModulePath", "$currentPSModulePath;$modulesPath", "Process")
    Write-Host "Chemin des modules ajouté au PSModulePath: $modulesPath" -ForegroundColor Green
} else {
    Write-Host "Le chemin des modules est déjà dans le PSModulePath: $modulesPath" -ForegroundColor Yellow
}

# Créer des dossiers pour chaque module
foreach ($module in $modules) {
    $moduleFolder = Join-Path -Path $modulesPath -ChildPath $module
    $moduleFile = Join-Path -Path $modulesPath -ChildPath "$module.psm1"
    $moduleManifest = Join-Path -Path $moduleFolder -ChildPath "$module.psd1"

    # Créer le dossier du module s'il n'existe pas
    if (-not (Test-Path -Path $moduleFolder)) {
        New-Item -Path $moduleFolder -ItemType Directory -Force | Out-Null
        Write-Host "Dossier cree pour le module $module - $moduleFolder" -ForegroundColor Green
    }

    # Créer un manifeste de module s'il n'existe pas
    if (-not (Test-Path -Path $moduleManifest)) {
        $manifestParams = @{
            Path              = $moduleManifest
            RootModule        = "$module.psm1"
            ModuleVersion     = "1.0.0"
            Author            = "EMAIL_SENDER_1 Team"
            Description       = "Module $module"
            PowerShellVersion = "5.1"
            FunctionsToExport = "*"
            CmdletsToExport   = @()
            VariablesToExport = @()
            AliasesToExport   = @()
        }

        New-ModuleManifest @manifestParams
        Write-Host "Manifeste cree pour le module $module - $moduleManifest" -ForegroundColor Green
    }

    # Créer un lien symbolique vers le fichier du module
    $moduleLink = Join-Path -Path $moduleFolder -ChildPath "$module.psm1"
    if (-not (Test-Path -Path $moduleLink)) {
        try {
            # Essayer de créer un lien symbolique (nécessite des droits d'administrateur)
            New-Item -Path $moduleLink -ItemType SymbolicLink -Value $moduleFile -Force | Out-Null
            Write-Host "Lien symbolique cree pour le module $module - $moduleLink -> $moduleFile" -ForegroundColor Green
        } catch {
            # Si la création du lien symbolique échoue, copier le fichier
            Copy-Item -Path $moduleFile -Destination $moduleLink -Force
            Write-Host "Fichier copie pour le module $module - $moduleFile -> $moduleLink" -ForegroundColor Yellow
            Write-Host "Note: Pour créer des liens symboliques, exécutez ce script en tant qu'administrateur." -ForegroundColor Yellow
        }
    }
}

# Tester l'importation des modules
Write-Host "`nTest d'importation des modules..." -ForegroundColor Yellow
foreach ($module in $modules) {
    try {
        # Supprimer le module s'il est déjà importé
        if (Get-Module -Name $module) {
            Remove-Module -Name $module -Force
        }

        # Importer le module
        Import-Module -Name $module -Force

        # Vérifier que le module est importé
        $importedModule = Get-Module -Name $module
        if ($importedModule) {
            Write-Host "Module $module importé avec succès." -ForegroundColor Green
            Write-Host "  Version: $($importedModule.Version)"
            Write-Host "  Chemin: $($importedModule.Path)"

            # Afficher les fonctions exportées
            $functions = Get-Command -Module $module
            Write-Host "  Fonctions exportées: $($functions.Count)"
            foreach ($function in $functions) {
                Write-Host "    - $($function.Name)"
            }
        } else {
            Write-Host "Échec de l'importation du module $module." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de l'importation du module $module - $_" -ForegroundColor Red
    }
}

Write-Host "`nCorrection des problèmes d'importation terminée." -ForegroundColor Green
Write-Host "Vous pouvez maintenant importer les modules en utilisant la commande 'Import-Module -Name <nom_du_module>'." -ForegroundColor Green
