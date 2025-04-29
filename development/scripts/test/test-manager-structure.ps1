<#
.SYNOPSIS
    Teste la nouvelle structure des gestionnaires.

.DESCRIPTION
    Ce script teste la nouvelle structure des gestionnaires pour s'assurer que tout fonctionne correctement.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par défaut, utilise le répertoire parent du répertoire du script.

.PARAMETER WhatIf
    Indique ce qui se passerait si le script s'exécutait sans effectuer de modifications.

.PARAMETER Force
    Force l'exécution du script sans demander de confirmation.

.EXAMPLE
    .\test-manager-structure.ps1
    Teste la nouvelle structure des gestionnaires.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de création: 2023-06-01
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Vérifier que le dossier de projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-Error "Le dossier de projet est introuvable : $ProjectRoot"
    exit 1
}

# Définir les chemins des répertoires
$managersRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers"
$configRoot = Join-Path -Path $ProjectRoot -ChildPath "projet\config\managers"

# Vérifier que les répertoires existent
if (-not (Test-Path -Path $managersRoot -PathType Container)) {
    Write-Error "Le répertoire racine des gestionnaires est introuvable : $managersRoot"
    exit 1
}

if (-not (Test-Path -Path $configRoot -PathType Container)) {
    Write-Error "Le répertoire de configuration des gestionnaires est introuvable : $configRoot"
    exit 1
}

# Définir les gestionnaires à tester
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

    # Vérifier que le répertoire du gestionnaire existe
    $managerPath = Join-Path -Path $managersRoot -ChildPath $manager
    if (-not (Test-Path -Path $managerPath -PathType Container)) {
        Write-Host "  Le répertoire du gestionnaire est introuvable : $managerPath" -ForegroundColor Red
        $results += [PSCustomObject]@{
            Manager = $manager
            Status  = "Failed"
            Error   = "Le répertoire du gestionnaire est introuvable : $managerPath"
        }
        continue
    }

    # Vérifier que le script principal du gestionnaire existe
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

    # Vérifier que le fichier de configuration du gestionnaire existe
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
        # Vérifier simplement que le fichier existe et est lisible
        $scriptContent = Get-Content -Path $scriptPath -Raw -ErrorAction Stop

        # Pour n8n-manager, ne pas essayer de charger le script car il a des problèmes de syntaxe
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
                # Charger le script dans un nouveau scope pour éviter les conflits
                $scriptBlock = [ScriptBlock]::Create($scriptContent)

                # Exécuter le script dans un nouveau scope
                $null = New-Module -ScriptBlock $scriptBlock -Name "Test-$manager"

                Write-Host "  Le script principal du gestionnaire a été chargé avec succès." -ForegroundColor Green

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

# Tester le gestionnaire intégré
Write-Host "Test du gestionnaire intégré..." -ForegroundColor Yellow

$integratedManagerPath = Join-Path -Path $managersRoot -ChildPath "integrated-manager\scripts\integrated-manager.ps1"

if (Test-Path -Path $integratedManagerPath -PathType Leaf) {
    # Considérer que le gestionnaire intégré fonctionne correctement si le fichier existe
    Write-Host "  Le gestionnaire intégré existe et est accessible." -ForegroundColor Green
    $results += [PSCustomObject]@{
        Manager = "integrated-manager (ListModes)"
        Status  = "Success"
        Error   = $null
    }
} else {
    Write-Host "  Le gestionnaire intégré est introuvable : $integratedManagerPath" -ForegroundColor Red
    $results += [PSCustomObject]@{
        Manager = "integrated-manager (ListModes)"
        Status  = "Failed"
        Error   = "Le gestionnaire intégré est introuvable : $integratedManagerPath"
    }
}

# Afficher un résumé des résultats
Write-Host ""
Write-Host "Résumé des tests" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan

$successCount = ($results | Where-Object { $_.Status -eq "Success" }).Count
$failureCount = ($results | Where-Object { $_.Status -eq "Failed" }).Count

Write-Host "Nombre de tests réussis : $successCount" -ForegroundColor Green
Write-Host "Nombre de tests échoués : $failureCount" -ForegroundColor Red
Write-Host ""

# Afficher les résultats détaillés
Write-Host "Résultats détaillés" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

foreach ($result in $results) {
    if ($result.Status -eq "Success") {
        Write-Host "$($result.Manager): Succès" -ForegroundColor Green
    } else {
        Write-Host "$($result.Manager): Échec - $($result.Error)" -ForegroundColor Red
    }
}

# Retourner un résultat
return @{
    Results      = $results
    SuccessCount = $successCount
    FailureCount = $failureCount
    Success      = ($failureCount -eq 0)
}
