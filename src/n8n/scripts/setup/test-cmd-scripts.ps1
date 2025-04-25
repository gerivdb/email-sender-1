<#
.SYNOPSIS
    Script de test des scripts CMD pour Hygen.

.DESCRIPTION
    Ce script teste les scripts CMD pour Hygen en vérifiant qu'ils peuvent être exécutés
    et qu'ils appellent correctement les scripts PowerShell sous-jacents.

.PARAMETER Interactive
    Si spécifié, le script sera exécuté en mode interactif, permettant à l'utilisateur de répondre aux prompts.

.EXAMPLE
    .\test-cmd-scripts.ps1
    Teste les scripts CMD en mode non interactif.

.EXAMPLE
    .\test-cmd-scripts.ps1 -Interactive
    Teste les scripts CMD en mode interactif.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-10
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [switch]$Interactive = $false
)

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Fonction pour afficher un message de succès
function Write-Success {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✓ $Message" -ForegroundColor $successColor
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✗ $Message" -ForegroundColor $errorColor
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "ℹ $Message" -ForegroundColor $infoColor
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "⚠ $Message" -ForegroundColor $warningColor
}

# Fonction pour obtenir le chemin du projet
function Get-ProjectPath {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.Parent.FullName
    return $projectRoot
}

# Fonction pour tester un script CMD
function Test-CmdScript {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory=$false)]
        [switch]$Interactive = $false
    )
    
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le script CMD n'existe pas: $ScriptPath"
        return $false
    }
    
    # Vérifier le contenu du script
    $content = Get-Content -Path $ScriptPath -Raw
    $success = $true
    
    # Vérifier si le script contient des appels à PowerShell
    if ($content -match "powershell") {
        Write-Success "Le script contient des appels à PowerShell"
    } else {
        Write-Error "Le script ne contient pas d'appels à PowerShell"
        $success = $false
    }
    
    # Vérifier si le script contient des options
    if ($content -match "Options disponibles") {
        Write-Success "Le script contient des options"
    } else {
        Write-Warning "Le script ne contient pas d'options"
    }
    
    # Vérifier si le script contient des messages d'erreur
    if ($content -match "ERRORLEVEL") {
        Write-Success "Le script contient des vérifications d'erreurs"
    } else {
        Write-Warning "Le script ne contient pas de vérifications d'erreurs"
    }
    
    # Exécuter le script si le mode interactif est activé
    if ($Interactive) {
        if ($PSCmdlet.ShouldProcess($ScriptPath, "Exécuter en mode interactif")) {
            Write-Info "Exécution du script CMD en mode interactif..."
            Write-Info "Veuillez répondre aux prompts ou quitter le script"
            
            try {
                Start-Process -FilePath $ScriptPath -Wait
                
                # Demander à l'utilisateur si le test a réussi
                $confirmation = Read-Host "Le script s'est-il exécuté correctement? (O/N)"
                if ($confirmation -eq "O" -or $confirmation -eq "o") {
                    Write-Success "Test interactif réussi"
                } else {
                    Write-Error "Test interactif échoué"
                    $success = $false
                }
            }
            catch {
                Write-Error "Erreur lors de l'exécution du script en mode interactif: $_"
                $success = $false
            }
        }
    } else {
        Write-Info "Test interactif ignoré (utilisez -Interactive pour l'activer)"
    }
    
    return $success
}

# Fonction pour tester tous les scripts CMD
function Test-AllCmdScripts {
    $projectRoot = Get-ProjectPath
    $cmdFolder = Join-Path -Path $projectRoot -ChildPath "n8n\cmd\utils"
    
    if (-not (Test-Path -Path $cmdFolder)) {
        Write-Error "Le dossier des scripts CMD n'existe pas: $cmdFolder"
        return $false
    }
    
    $results = @{}
    
    # Tester le script generate-component.cmd
    $generateComponentPath = Join-Path -Path $cmdFolder -ChildPath "generate-component.cmd"
    Write-Info "`nTest du script generate-component.cmd..."
    $results["generate-component"] = Test-CmdScript -ScriptPath $generateComponentPath -Interactive:$Interactive
    
    # Tester le script install-hygen.cmd
    $installHygenPath = Join-Path -Path $cmdFolder -ChildPath "install-hygen.cmd"
    Write-Info "`nTest du script install-hygen.cmd..."
    $results["install-hygen"] = Test-CmdScript -ScriptPath $installHygenPath -Interactive:$Interactive
    
    # Tester le script validate-templates.cmd
    $validateTemplatesPath = Join-Path -Path $cmdFolder -ChildPath "validate-templates.cmd"
    Write-Info "`nTest du script validate-templates.cmd..."
    $results["validate-templates"] = Test-CmdScript -ScriptPath $validateTemplatesPath -Interactive:$Interactive
    
    # Tester le script finalize-hygen.cmd
    $finalizeHygenPath = Join-Path -Path $cmdFolder -ChildPath "finalize-hygen.cmd"
    Write-Info "`nTest du script finalize-hygen.cmd..."
    $results["finalize-hygen"] = Test-CmdScript -ScriptPath $finalizeHygenPath -Interactive:$Interactive
    
    # Afficher le résultat global
    Write-Host "`nRésultat des tests par script CMD:" -ForegroundColor $infoColor
    foreach ($key in $results.Keys) {
        $status = if ($results[$key]) { "Réussi" } else { "Échoué" }
        Write-Host "- Script $key : $status" -ForegroundColor $(if ($results[$key]) { $successColor } else { $errorColor })
    }
    
    return $results.Values -notcontains $false
}

# Fonction principale
function Start-CmdScriptsTest {
    Write-Info "Test des scripts CMD pour Hygen..."
    
    # Tester tous les scripts CMD
    $cmdScriptsValid = Test-AllCmdScripts
    
    # Afficher le résultat global
    Write-Host "`nRésultat du test:" -ForegroundColor $infoColor
    if ($cmdScriptsValid) {
        Write-Success "Les scripts CMD sont valides"
        return $true
    } else {
        Write-Error "Les scripts CMD sont invalides"
        return $false
    }
}

# Exécuter le test
Start-CmdScriptsTest
