<#
.SYNOPSIS
    Script de test créé avec PowerShell

.DESCRIPTION
    Script de test créé avec PowerShell

.PARAMETER Param1
    Description du premier paramÃ¨tre

.EXAMPLE
    .\test-powershell-script.ps1 -Param1 "Valeur"

.NOTES
    Auteur: Augment Agent
    Date de crÃ©ation: 28/04/2025
#>
param (
    [string]$Param1 = ""
)

# Fonction principale
function Main {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    begin {
        Write-Verbose "DÃ©marrage du script test-powershell-script.ps1"
    }

    process {
        try {
            # Code principal ici
            if ($PSCmdlet.ShouldProcess("test-powershell-script.ps1", "Exécuter")) {
                Write-Host "Exécution de test-powershell-script.ps1" -ForegroundColor Green

                if ($Param1) {
                    Write-Host "Paramètre fourni: $Param1" -ForegroundColor Cyan
                }
            }
        } catch {
            Write-Error "Une erreur s'est produite: $_"
        }
    }

    end {
        Write-Verbose "Fin du script test-powershell-script.ps1"
    }
}

# Appel de la fonction principale
Main
