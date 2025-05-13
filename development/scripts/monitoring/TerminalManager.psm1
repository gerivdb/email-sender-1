#Requires -Version 5.1
<#
.SYNOPSIS
    Module de gestion des terminaux multi-instances.
.DESCRIPTION
    Ce module fournit des fonctions pour creer, gerer et controler plusieurs
    terminaux PowerShell en parallele, avec suivi des ressources et controle
    centralise.
.NOTES
    Nom: TerminalManager.psm1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de creation: 2025-05-20
#>

# Variables globales du module
$script:Terminals = @{}
$script:TerminalCounter = 0
$script:ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "config"
$script:DataPath = Join-Path -Path $PSScriptRoot -ChildPath "data"

# Creer les dossiers necessaires s'ils n'existent pas
if (-not (Test-Path -Path $script:ConfigPath)) {
    New-Item -Path $script:ConfigPath -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path -Path $script:DataPath)) {
    New-Item -Path $script:DataPath -ItemType Directory -Force | Out-Null
}

# Fonction pour creer un nouveau terminal
function New-Terminal {
    <#
    .SYNOPSIS
        Cree un nouveau terminal PowerShell.
    .DESCRIPTION
        Cette fonction cree un nouveau terminal PowerShell et execute le script
        ou la commande specifiee.
    .PARAMETER Name
        Nom du terminal. Si non specifie, un nom unique sera genere.
    .PARAMETER ScriptBlock
        Bloc de script a executer dans le terminal.
    .PARAMETER ArgumentList
        Liste d'arguments a passer au bloc de script.
    .PARAMETER WorkingDirectory
        Repertoire de travail pour le terminal. Par defaut: repertoire courant.
    .PARAMETER NoExit
        Si specifie, le terminal reste ouvert apres l'execution du script.
    .PARAMETER ResourceLimits
        Limites de ressources pour le terminal (CPU, memoire).
    .EXAMPLE
        New-Terminal -Name "MonTerminal" -ScriptBlock { Write-Host "Hello World" }
    .OUTPUTS
        [PSCustomObject] avec les informations sur le terminal cree
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [object[]]$ArgumentList,
        
        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory = (Get-Location).Path,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoExit,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ResourceLimits
    )
    
    # Generer un nom unique si non specifie
    if ([string]::IsNullOrEmpty($Name)) {
        $script:TerminalCounter++
        $Name = "Terminal_$script:TerminalCounter"
    }
    
    # Verifier si un terminal avec ce nom existe deja
    if ($script:Terminals.ContainsKey($Name)) {
        Write-Warning "Un terminal avec le nom '$Name' existe deja."
        return $null
    }
    
    # Preparer le script a executer
    $scriptPath = Join-Path -Path $script:DataPath -ChildPath "$Name.ps1"
    
    # Creer le contenu du script
    $scriptContent = @"
# Script genere pour le terminal '$Name'
`$ErrorActionPreference = 'Stop'
Set-Location -Path '$WorkingDirectory'

# Definir la fonction pour enregistrer l'etat
function Write-TerminalState {
    param(
        [string]`$Status,
        [string]`$Message = ""
    )
    
    `$state = @{
        Status = `$Status
        Timestamp = Get-Date
        Message = `$Message
        PID = `$PID
    }
    
    `$state | ConvertTo-Json | Out-File -FilePath '$script:DataPath\$Name.state.json' -Force
}

# Enregistrer l'etat initial
Write-TerminalState -Status "Running" -Message "Terminal demarre"

try {
    # Executer le script principal
    `$scriptBlock = {$ScriptBlock}
    
    # Executer avec les arguments si specifies
    if (`$args.Count -gt 0) {
        & `$scriptBlock @args
    } else {
        & `$scriptBlock
    }
    
    # Enregistrer l'etat final
    Write-TerminalState -Status "Completed" -Message "Execution terminee avec succes"
} catch {
    # Enregistrer l'erreur
    Write-TerminalState -Status "Error" -Message "Erreur: `$_"
    Write-Error "Erreur dans le terminal '$Name': `$_"
}

# Maintenir la fenetre ouverte si demande
if (`$true -eq `$$NoExit) {
    Write-Host "Appuyez sur une touche pour fermer le terminal..." -ForegroundColor Yellow
    [Console]::ReadKey() | Out-Null
}
"@
    
    # Ecrire le script dans un fichier
    $scriptContent | Out-File -FilePath $scriptPath -Encoding utf8 -Force
    
    # Preparer les arguments pour PowerShell
    $psArgs = "-ExecutionPolicy Bypass -File `"$scriptPath`""
    
    if ($ArgumentList -and $ArgumentList.Count -gt 0) {
        $argString = $ArgumentList -join " "
        $psArgs += " $argString"
    }
    
    # Demarrer le processus PowerShell
    $process = Start-Process -FilePath "powershell.exe" -ArgumentList $psArgs -PassThru -WindowStyle Normal
    
    # Creer l'objet terminal
    $terminal = [PSCustomObject]@{
        Name = $Name
        Process = $process
        PID = $process.Id
        StartTime = Get-Date
        ScriptPath = $scriptPath
        WorkingDirectory = $WorkingDirectory
        ResourceLimits = $ResourceLimits
        Status = "Running"
    }
    
    # Enregistrer le terminal
    $script:Terminals[$Name] = $terminal
    
    # Retourner l'objet terminal
    return $terminal
}

# Fonction pour obtenir un terminal
function Get-Terminal {
    <#
    .SYNOPSIS
        Obtient les informations sur un ou plusieurs terminaux.
    .DESCRIPTION
        Cette fonction recupere les informations sur un terminal specifique
        ou sur tous les terminaux si aucun nom n'est specifie.
    .PARAMETER Name
        Nom du terminal a recuperer. Si non specifie, tous les terminaux sont retournes.
    .EXAMPLE
        Get-Terminal -Name "MonTerminal"
    .EXAMPLE
        Get-Terminal
    .OUTPUTS
        [PSCustomObject] ou [PSCustomObject[]] avec les informations sur le(s) terminal(aux)
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name
    )
    
    # Si un nom est specifie, retourner ce terminal specifique
    if (-not [string]::IsNullOrEmpty($Name)) {
        if ($script:Terminals.ContainsKey($Name)) {
            $terminal = $script:Terminals[$Name]
            
            # Mettre a jour le statut du terminal
            $statePath = Join-Path -Path $script:DataPath -ChildPath "$Name.state.json"
            if (Test-Path -Path $statePath) {
                try {
                    $state = Get-Content -Path $statePath -Raw | ConvertFrom-Json
                    $terminal.Status = $state.Status
                } catch {
                    Write-Warning "Impossible de lire l'etat du terminal '$Name': $_"
                }
            }
            
            # Verifier si le processus est toujours en cours d'execution
            if (-not $terminal.Process.HasExited) {
                # Mettre a jour les informations du processus
                try {
                    $process = Get-Process -Id $terminal.PID -ErrorAction SilentlyContinue
                    if ($process) {
                        $terminal | Add-Member -MemberType NoteProperty -Name "CPU" -Value $process.CPU -Force
                        $terminal | Add-Member -MemberType NoteProperty -Name "Memory" -Value ($process.WorkingSet64 / 1MB) -Force
                    }
                } catch {
                    # Ignorer les erreurs lors de la recuperation des informations du processus
                }
            } else {
                $terminal.Status = "Stopped"
            }
            
            return $terminal
        } else {
            Write-Warning "Aucun terminal avec le nom '$Name' n'a ete trouve."
            return $null
        }
    }
    
    # Sinon, retourner tous les terminaux
    $result = @()
    foreach ($terminalName in $script:Terminals.Keys) {
        $result += Get-Terminal -Name $terminalName
    }
    
    return $result
}

# Fonction pour arreter un terminal
function Stop-Terminal {
    <#
    .SYNOPSIS
        Arrete un terminal PowerShell.
    .DESCRIPTION
        Cette fonction arrete un terminal PowerShell precedemment cree avec New-Terminal.
    .PARAMETER Name
        Nom du terminal a arreter.
    .PARAMETER Force
        Si specifie, le terminal est arrete de force.
    .EXAMPLE
        Stop-Terminal -Name "MonTerminal"
    .OUTPUTS
        [bool] Indique si l'arret a reussi
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Verifier si le terminal existe
    if (-not $script:Terminals.ContainsKey($Name)) {
        Write-Warning "Aucun terminal avec le nom '$Name' n'a ete trouve."
        return $false
    }
    
    # Recuperer le terminal
    $terminal = $script:Terminals[$Name]
    
    # Verifier si le processus est toujours en cours d'execution
    if (-not $terminal.Process.HasExited) {
        try {
            if ($Force) {
                # Arreter le processus de force
                $terminal.Process.Kill()
            } else {
                # Envoyer un signal de fermeture au processus
                $terminal.Process.CloseMainWindow() | Out-Null
                
                # Attendre que le processus se termine (max 5 secondes)
                $terminal.Process.WaitForExit(5000) | Out-Null
                
                # Si le processus est toujours en cours d'execution, le tuer
                if (-not $terminal.Process.HasExited) {
                    $terminal.Process.Kill()
                }
            }
            
            # Mettre a jour le statut du terminal
            $terminal.Status = "Stopped"
            
            # Enregistrer l'etat final
            $statePath = Join-Path -Path $script:DataPath -ChildPath "$Name.state.json"
            if (Test-Path -Path $statePath) {
                try {
                    $state = Get-Content -Path $statePath -Raw | ConvertFrom-Json
                    $state.Status = "Stopped"
                    $state.Timestamp = Get-Date
                    $state.Message = "Terminal arrete manuellement"
                    $state | ConvertTo-Json | Out-File -FilePath $statePath -Force
                } catch {
                    Write-Warning "Impossible de mettre a jour l'etat du terminal '$Name': $_"
                }
            }
            
            return $true
        } catch {
            Write-Error "Erreur lors de l'arret du terminal '$Name': $_"
            return $false
        }
    } else {
        # Le processus est deja arrete
        $terminal.Status = "Stopped"
        return $true
    }
}

# Fonction pour envoyer une commande a un terminal
function Send-TerminalCommand {
    <#
    .SYNOPSIS
        Envoie une commande a un terminal PowerShell.
    .DESCRIPTION
        Cette fonction envoie une commande a un terminal PowerShell en cours d'execution.
        Note: Cette fonction a des limitations et peut ne pas fonctionner avec tous les terminaux.
    .PARAMETER Name
        Nom du terminal auquel envoyer la commande.
    .PARAMETER Command
        Commande a envoyer au terminal.
    .EXAMPLE
        Send-TerminalCommand -Name "MonTerminal" -Command "Get-Process"
    .OUTPUTS
        [bool] Indique si l'envoi a reussi
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    # Verifier si le terminal existe
    if (-not $script:Terminals.ContainsKey($Name)) {
        Write-Warning "Aucun terminal avec le nom '$Name' n'a ete trouve."
        return $false
    }
    
    # Recuperer le terminal
    $terminal = $script:Terminals[$Name]
    
    # Verifier si le processus est toujours en cours d'execution
    if ($terminal.Process.HasExited) {
        Write-Warning "Le terminal '$Name' n'est plus en cours d'execution."
        return $false
    }
    
    try {
        # Cette methode a des limitations et peut ne pas fonctionner avec tous les terminaux
        # Une approche alternative serait d'utiliser des fichiers de communication ou des pipes nommes
        [System.Windows.Forms.SendKeys]::SendWait("$Command`r`n")
        return $true
    } catch {
        Write-Error "Erreur lors de l'envoi de la commande au terminal '$Name': $_"
        return $false
    }
}

# Fonction pour nettoyer les terminaux inactifs
function Remove-InactiveTerminals {
    <#
    .SYNOPSIS
        Supprime les terminaux inactifs de la liste.
    .DESCRIPTION
        Cette fonction supprime les terminaux qui ne sont plus en cours d'execution
        de la liste des terminaux geres.
    .PARAMETER RemoveFiles
        Si specifie, les fichiers associes aux terminaux sont egalement supprimes.
    .EXAMPLE
        Remove-InactiveTerminals -RemoveFiles
    .OUTPUTS
        [int] Nombre de terminaux supprimes
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$RemoveFiles
    )
    
    $removedCount = 0
    $terminalsToRemove = @()
    
    # Identifier les terminaux inactifs
    foreach ($terminalName in $script:Terminals.Keys) {
        $terminal = $script:Terminals[$terminalName]
        
        if ($terminal.Process.HasExited) {
            $terminalsToRemove += $terminalName
        }
    }
    
    # Supprimer les terminaux inactifs
    foreach ($terminalName in $terminalsToRemove) {
        $terminal = $script:Terminals[$terminalName]
        
        # Supprimer les fichiers associes si demande
        if ($RemoveFiles) {
            $scriptPath = $terminal.ScriptPath
            $statePath = Join-Path -Path $script:DataPath -ChildPath "$terminalName.state.json"
            
            if (Test-Path -Path $scriptPath) {
                Remove-Item -Path $scriptPath -Force -ErrorAction SilentlyContinue
            }
            
            if (Test-Path -Path $statePath) {
                Remove-Item -Path $statePath -Force -ErrorAction SilentlyContinue
            }
        }
        
        # Supprimer le terminal de la liste
        $script:Terminals.Remove($terminalName)
        $removedCount++
    }
    
    return $removedCount
}

# Exporter les fonctions du module
Export-ModuleMember -Function New-Terminal, Get-Terminal, Stop-Terminal, 
                              Send-TerminalCommand, Remove-InactiveTerminals
