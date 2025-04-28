<#
.SYNOPSIS
    Initialise le projet pour le développement.

.DESCRIPTION
    Ce script initialise le projet pour le développement en installant les dépendances,
    configurant les hooks Git et en organisant les fichiers.

.EXAMPLE
    .\initialize-project.ps1

.NOTES
    Auteur: Augment Agent
    Date de création: 28/04/2025
#>
param (
    [switch]$Force
)

# Fonction principale
function Initialize-Project {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Force
    )

    begin {
        Write-Host "Initialisation du projet..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"
    }

    process {
        try {
            # 1. Installer les dépendances npm
            Write-Host "1. Installation des dépendances npm..." -ForegroundColor Green
            if ($PSCmdlet.ShouldProcess("npm install", "Exécuter")) {
                npm install
            }

            # 2. Configurer Husky
            Write-Host "2. Configuration de Husky..." -ForegroundColor Green
            if ($PSCmdlet.ShouldProcess("npx husky install", "Exécuter")) {
                npx husky install

                # Créer le hook pre-commit
                $hookPath = ".husky/pre-commit"
                if (-not (Test-Path $hookPath) -or $Force) {
                    npx husky add $hookPath "powershell.exe -ExecutionPolicy Bypass -File `"./development/scripts/maintenance/repo/organize-scripts.ps1`""
                    Write-Host "   Hook pre-commit créé." -ForegroundColor Green
                } else {
                    Write-Host "   Hook pre-commit existe déjà. Utilisez -Force pour le remplacer." -ForegroundColor Yellow
                }
            }

            # 3. Organiser les fichiers existants
            Write-Host "3. Organisation des fichiers existants..." -ForegroundColor Green
            if ($PSCmdlet.ShouldProcess("./development/scripts/maintenance/repo/organize-scripts.ps1", "Exécuter")) {
                & "$PSScriptRoot\organize-scripts.ps1"
            }

            # 3.1 Synchroniser les fichiers de configuration Augment
            Write-Host "3.1 Synchronisation des fichiers de configuration Augment..." -ForegroundColor Green
            $augmentSyncScript = Join-Path -Path (Get-Location).Path -ChildPath "development\scripts\maintenance\augment\sync-augment-settings.ps1"
            if (Test-Path $augmentSyncScript) {
                if ($PSCmdlet.ShouldProcess($augmentSyncScript, "Exécuter avec -Direction ToRoot")) {
                    & $augmentSyncScript -Direction ToRoot
                }
            } else {
                Write-Host "   Script de synchronisation Augment non trouvé. Ignoré." -ForegroundColor Yellow
            }

            # 4. Vérifier la configuration VS Code
            Write-Host "4. Vérification de la configuration VS Code..." -ForegroundColor Green
            $vscodePath = ".vscode"
            if (-not (Test-Path $vscodePath)) {
                if ($PSCmdlet.ShouldProcess(".vscode directory", "Créer")) {
                    New-Item -Path $vscodePath -ItemType Directory -Force | Out-Null
                    Write-Host "   Dossier .vscode créé." -ForegroundColor Green
                }
            }

            $tasksPath = ".vscode/tasks.json"
            if (-not (Test-Path $tasksPath) -or $Force) {
                if ($PSCmdlet.ShouldProcess("tasks.json", "Créer")) {
                    $tasksContent = @{
                        version = "2.0.0"
                        tasks   = @(
                            @{
                                label          = "Maintenance: Organiser les scripts"
                                type           = "shell"
                                command        = "powershell.exe -ExecutionPolicy Bypass -File `"```${workspaceFolder}/development/scripts/maintenance/repo/organize-scripts.ps1`""
                                problemMatcher = @()
                                group          = "none"
                                presentation   = @{
                                    reveal           = "silent"
                                    panel            = "shared"
                                    showReuseMessage = $false
                                }
                                runOptions     = @{
                                    runOn = "folderOpen"
                                }
                            }
                        )
                    }
                    $tasksContent | ConvertTo-Json -Depth 10 | Set-Content -Path $tasksPath -Encoding UTF8
                    Write-Host "   Fichier tasks.json créé." -ForegroundColor Green
                } else {
                    Write-Host "   Fichier tasks.json existe déjà. Utilisez -Force pour le remplacer." -ForegroundColor Yellow
                }
            }
        } catch {
            Write-Error "Une erreur s'est produite lors de l'initialisation du projet: $_"
            return $false
        }
    }

    end {
        Write-Host "`nInitialisation du projet terminée avec succès!" -ForegroundColor Cyan
        Write-Host "`nPour créer un nouveau script, utilisez la commande suivante:" -ForegroundColor Yellow
        Write-Host "npx hygen script new --name nom-du-script --category maintenance/sous-dossier" -ForegroundColor White
        Write-Host "`nPour organiser manuellement les scripts, utilisez la tâche VS Code 'Maintenance: Organiser les scripts'" -ForegroundColor Yellow
        return $true
    }
}

# Appel de la fonction principale
Initialize-Project -Force:$Force
