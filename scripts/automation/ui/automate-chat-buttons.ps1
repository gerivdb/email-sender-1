# Ajout d'une option pour choisir entre 'Keep', 'Undo' et 'Continue'
# Ce script automatise l'interaction avec les boutons de dialogue de GitHub Copilot dans VS Code
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DelayBetweenActions', Justification = 'Parameter is used in multiple Start-Sleep calls throughout the script')]
param (
    [string]$Action = "Keep",  # Par défaut, l'action est 'Keep'
    [int]$DelayBetweenActions = 1  # Délai en secondes entre les actions, utilisé dans Send-Key et Start-Sleep
)

# Journalisation avec horodatage
function Write-AutomationLog {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Information "[$timestamp] $Message" -InformationAction Continue
}

Write-AutomationLog "Démarrage du script avec l'action: $Action"

try {
    Add-Type -AssemblyName System.Windows.Forms
    Write-AutomationLog "Bibliothèque System.Windows.Forms chargée avec succès"
}
catch {
    Write-AutomationLog "ERREUR: Impossible de charger System.Windows.Forms: $_"
    exit 1
}

# Fonction pour envoyer une touche ou une combinaison de touches
function Send-Key {
    param (
        [string]$keys,
        [string]$description = ""
    )
    try {
        [System.Windows.Forms.SendKeys]::SendWait($keys)
        if ($description) {
            Write-AutomationLog "Touche envoyée: $keys ($description)"
        } else {
            Write-AutomationLog "Touche envoyée: $keys"
        }
        Start-Sleep -Milliseconds ($DelayBetweenActions * 500)  # Utiliser le paramètre DelayBetweenActions
    } catch {
        Write-AutomationLog "ERREUR: Échec de l'envoi de touche $keys : $_"
    }
}

# Utiliser un bloc de code C# pour définir la fonction native
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class VSCodeWindow {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
}
'@

# Fonction pour amener VS Code au premier plan
function Set-VSCodeForeground {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Boolean])]
    param()

    try {
        # Gérer le cas où plusieurs instances de VS Code sont ouvertes
        $processes = Get-Process -Name "code" -ErrorAction SilentlyContinue
        if ($processes.Count -gt 0) {
            # Trier par taille de fenêtre, privilégier les fenêtres grandes (probablement la principale)
            $mainProcess = $processes | Where-Object { $_.MainWindowHandle -ne 0 } |
                           Sort-Object { $_.MainWindowWidth * $_.MainWindowHeight } -Descending |
                           Select-Object -First 1

            if ($mainProcess) {
                if ($PSCmdlet.ShouldProcess("VS Code", "Mettre au premier plan")) {
                    $hwnd = $mainProcess.MainWindowHandle
                    $result = [VSCodeWindow]::SetForegroundWindow($hwnd)
                    if ($result) {
                        Write-AutomationLog "VS Code mis au premier plan avec succès"
                    } else {
                        Write-AutomationLog "AVERTISSEMENT: Impossible de mettre VS Code au premier plan"
                    }
                    # Attendre que la fenêtre ait le focus
                    Start-Sleep -Seconds $DelayBetweenActions
                    return $true
                }
            } else {
                Write-AutomationLog "AVERTISSEMENT: Aucune fenêtre VS Code principale trouvée"
                return $false
            }
        } else {
            Write-AutomationLog "ERREUR: VS Code n'est pas en cours d'exécution"
            return $false
        }
    } catch {
        Write-AutomationLog "ERREUR lors de la mise au premier plan de VS Code: $_"
        return $false
    }
}

# Appeler la fonction pour amener VS Code au premier plan avant d'envoyer les touches
$success = Set-VSCodeForeground -WhatIf:$false
if (-not $success) {
    Write-AutomationLog "Impossible de continuer sans VS Code au premier plan"
    exit 1
}

# Simuler un clic sur le bouton en fonction de l'action
Write-AutomationLog "Simulation d'un clic sur le bouton '$Action'..."

# Définir une fonction pour effectuer une action avec les touches de manière fiable
function Invoke-ButtonAction {
    param (
        [string]$ActionName,
        [int]$TabCount
    )

    try {
        # Focus sur la zone de chat (au cas où)
        Send-Key("%") # Alt key pour activer le menu
        Start-Sleep -Milliseconds ($DelayBetweenActions * 300)
        Send-Key("{ESC}") # Échap pour fermer le menu
        Start-Sleep -Milliseconds ($DelayBetweenActions * 300)

        # Naviguer vers les boutons
        for ($i = 1; $i -le $TabCount; $i++) {
            Send-Key("{TAB}", "Navigation TAB #$i")
            Start-Sleep -Milliseconds ($DelayBetweenActions * 300)
        }

        # Valider l'action
        Send-Key("{ENTER}", "Confirmation de l'action $ActionName")

        Write-AutomationLog "Action $ActionName effectuée avec succès"
        return $true
    }
    catch {
        Write-AutomationLog "ERREUR lors de l'exécution de l'action $ActionName : $_"
        return $false
    }
}

# Exécuter l'action appropriée selon le paramètre
switch ($Action) {
    "Keep" {
        $success = Invoke-ButtonAction -ActionName "Keep" -TabCount 1
    }
    "Undo" {
        $success = Invoke-ButtonAction -ActionName "Undo" -TabCount 2
    }
    "Continue" {
        $success = Invoke-ButtonAction -ActionName "Continue" -TabCount 3
    }
    default {
        Write-AutomationLog "ERREUR: Action inconnue : $Action. Utilisez 'Keep', 'Undo' ou 'Continue'."
        exit 1
    }
}

# Vérifier si l'action a réussi
if ($success) {
    Write-AutomationLog "Le script a terminé l'exécution avec succès"
} else {
    Write-AutomationLog "AVERTISSEMENT: Le script pourrait ne pas avoir correctement exécuté l'action"
}
