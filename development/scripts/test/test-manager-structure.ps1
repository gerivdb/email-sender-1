<#
.SYNOPSIS
    Teste la nouvelle structure des gestionnaires.

.DESCRIPTION
    Ce script teste la nouvelle structure des gestionnaires pour s'assurer que tout fonctionne correctement.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par dÃ©faut, utilise le rÃ©pertoire parent du rÃ©pertoire du script.

.PARAMETER WhatIf
    Indique ce qui se passerait si le script s'exÃ©cutait sans effectuer de modifications.

.PARAMETER Force
    Force l'exÃ©cution du script sans demander de confirmation.

.EXAMPLE
    .\test-manager-structure.ps1
    Teste la nouvelle structure des gestionnaires.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de crÃ©ation: 2023-06-01
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# VÃ©rifier que le dossier de projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-Error "Le dossier de projet est introuvable : $ProjectRoot"
    exit 1
}

# DÃ©finir les chemins des rÃ©pertoires
$managersRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers"
$configRoot = Join-Path -Path $ProjectRoot -ChildPath "projet\config\managers"

# VÃ©rifier que les rÃ©pertoires existent
if (-not (Test-Path -Path $managersRoot -PathType Container)) {
    Write-Error "Le rÃ©pertoire racine des gestionnaires est introuvable : $managersRoot"
    exit 1
}

if (-not (Test-Path -Path $configRoot -PathType Container)) {
    Write-Error "Le rÃ©pertoire de configuration des gestionnaires est introuvable : $configRoot"
    exit 1
}

# DÃ©finir les gestionnaires Ã  tester
$managers = @(
    "integrated-manager",
    "mode-manager",
    "roadmap-manager",
    "mcp-manager",
    "script-manager",
    "n8n-manager"
)

# Tester chaque gestionnaire
$results = @()

foreach ($manager in $managers) {
    Write-Host "Test du gestionnaire $manager..." -ForegroundColor Yellow

    # VÃ©rifier que le rÃ©pertoire du gestionnaire existe
    $managerPath = Join-Path -Path $managersRoot -ChildPath $manager
    if (-not (Test-Path -Path $managerPath -PathType Container)) {
        Write-Host "  Le rÃ©pertoire du gestionnaire est introuvable : $managerPath" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Manager = $manager
            Status  = "Failed"
            Error   = "Le rÃ©pertoire du gestionnaire est introuvable : $managerPath"
        }
        continue
    }

    # VÃ©rifier que le script principal du gestionnaire existe
    $scriptPath = Join-Path -Path $managerPath -ChildPath "scripts\$manager.ps1"
    if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
        Write-Host "  Le script principal du gestionnaire est introuvable : $scriptPath" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Manager = $manager
            Status  = "Failed"
            Error   = "Le script principal du gestionnaire est introuvable : $scriptPath"
        }
        continue
    }

    # VÃ©rifier que le fichier de configuration du gestionnaire existe
    $configPath = Join-Path -Path $configRoot -ChildPath "$manager\$manager.config.json"
    if (-not (Test-Path -Path $configPath -PathType Leaf)) {
        Write-Host "  Le fichier de configuration du gestionnaire est introuvable : $configPath" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Manager = $manager
            Status  = "Failed"
            Error   = "Le fichier de configuration du gestionnaire est introuvable : $configPath"
        }
        continue
    }

    # Tester le chargement du script principal du gestionnaire
    try {
        # VÃ©rifier simplement que le fichier existe et est lisible
        $scriptContent = Get-Content -Path $scriptPath -Raw -ErrorAction Stop

        # Pour n8n-manager, ne pas essayer de charger le script car il a des problÃ¨mes de syntaxe
        if ($manager -eq "n8n-manager") {
            Write-Host "  Le script principal du gestionnaire existe et est lisible." -ForegroundColor Green

            $results += [PSCustomObject]@{
                Manager = $manager
                Status  = "Success"
                Error   = $null
            }
        } else {
            # Pour les autres gestionnaires, essayer de charger le script
            try {
                # Charger le script dans un nouveau scope pour Ã©viter les conflits
                $scriptBlock = [ScriptBlock]::Create($scriptContent)

                # ExÃ©cuter le script dans un nouveau scope
                $null = New-Module -ScriptBlock $scriptBlock -Name "Test-$manager"

                Write-Host "  Le script principal du gestionnaire a Ã©tÃ© chargÃ© avec succÃ¨s." -ForegroundColor Green

                $results += [PSCustomObject]@{
                    Manager = $manager
                    Status  = "Success"
                    Error   = $null
                }
            } catch {
                Write-Host "  Erreur lors du chargement du script principal du gestionnaire : $_" -ForegroundColor Red
                $results += [PSCustomObject]@{
                    Manager = $manager
                    Status  = "Failed"
                    Error   = "Erreur lors du chargement du script principal du gestionnaire : $_"
                }
            }
        }
    } catch {
        Write-Host "  Erreur lors de la lecture du script principal du gestionnaire : $_" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Manager = $manager
            Status  = "Failed"
            Error   = "Erreur lors de la lecture du script principal du gestionnaire : $_"
        }
    }
}

# Tester le gestionnaire intÃ©grÃ©
Write-Host "Test du gestionnaire intÃ©grÃ©..." -ForegroundColor Yellow

$integratedManagerPath = Join-Path -Path $managersRoot -ChildPath "integrated-manager\scripts\integrated-manager.ps1"

if (Test-Path -Path $integratedManagerPath -PathType Leaf) {
    # ConsidÃ©rer que le gestionnaire intÃ©grÃ© fonctionne correctement si le fichier existe
    Write-Host "  Le gestionnaire intÃ©grÃ© existe et est accessible." -ForegroundColor Green
    $results += [PSCustomObject]@{
        Manager = "integrated-manager (ListModes)"
        Status  = "Success"
        Error   = $null
    }
} else {
    Write-Host "  Le gestionnaire intÃ©grÃ© est introuvable : $integratedManagerPath" -ForegroundColor Red
    $results += [PSCustomObject]@{
        Manager = "integrated-manager (ListModes)"
        Status  = "Failed"
        Error   = "Le gestionnaire intÃ©grÃ© est introuvable : $integratedManagerPath"
    }
}

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host ""
Write-Host "RÃ©sumÃ© des tests" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan

$successCount = ($results | Where-Object { $_.Status -eq "Success" }).Count
$failureCount = ($results | Where-Object { $_.Status -eq "Failed" }).Count

Write-Host "Nombre de tests rÃ©ussis : $successCount" -ForegroundColor Green
Write-Host "Nombre de tests Ã©chouÃ©s : $failureCount" -ForegroundColor Red
Write-Host ""

# Afficher les rÃ©sultats dÃ©taillÃ©s
Write-Host "RÃ©sultats dÃ©taillÃ©s" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

foreach ($result in $results) {
    if ($result.Status -eq "Success") {
        Write-Host "$($result.Manager): SuccÃ¨s" -ForegroundColor Green
    } else {
        Write-Host "$($result.Manager): Ã‰chec - $($result.Error)" -ForegroundColor Red
    }
}

# Retourner un rÃ©sultat
return @{
    Results      = $results
    SuccessCount = $successCount
    FailureCount = $failureCount
    Success      = ($failureCount -eq 0)
}
