<#
.SYNOPSIS
    CrÃ©e un nouveau script PowerShell dans la structure du projet.

.DESCRIPTION
    Ce script crÃ©e un nouveau script PowerShell dans la structure du projet,
    en utilisant un template prÃ©dÃ©fini.

.PARAMETER Name
    Nom du script Ã  crÃ©er.

.PARAMETER Category
    CatÃ©gorie/dossier oÃ¹ placer le script. Par dÃ©faut: 'maintenance'.

.PARAMETER Description
    Description du script. Par dÃ©faut: 'Script PowerShell'.

.PARAMETER Author
    Auteur du script. Par dÃ©faut: 'Augment Agent'.

.EXAMPLE
    .\new-script.ps1 -Name clean-temp-files

.EXAMPLE
    .\new-script.ps1 -Name optimize-database -Category database -Description "Optimise la base de donnÃ©es" -Author "John Doe"

.NOTES
    Auteur: Augment Agent
    Date de crÃ©ation: 28/04/2025
#>
param (
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [string]$Category = "maintenance",

    [string]$Description = "Script PowerShell",

    [string]$Author = "Augment Agent"
)

# Fonction principale
function New-ProjectScript {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [string]$Category = "maintenance",

        [string]$Description = "Script PowerShell",

        [string]$Author = "Augment Agent"
    )

    begin {
        Write-Host "CrÃ©ation d'un nouveau script PowerShell..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"

        # DÃ©terminer le chemin du script
        $scriptPath = Join-Path -Path (Get-Location).Path -ChildPath "development\scripts\$Category"
        $scriptFile = Join-Path -Path $scriptPath -ChildPath "$Name.ps1"

        # VÃ©rifier si le script existe dÃ©jÃ 
        if (Test-Path $scriptFile) {
            Write-Error "Le script '$Name.ps1' existe dÃ©jÃ  dans le dossier '$Category'."
            return $false
        }
    }

    process {
        try {
            # CrÃ©er le dossier de destination s'il n'existe pas
            if (-not (Test-Path $scriptPath)) {
                if ($PSCmdlet.ShouldProcess($scriptPath, "CrÃ©er le dossier")) {
                    New-Item -Path $scriptPath -ItemType Directory -Force | Out-Null
                    Write-Host "Dossier crÃ©Ã©: $scriptPath" -ForegroundColor Yellow
                }
            }

            # CrÃ©er le contenu du script
            $date = Get-Date -Format "dd/MM/yyyy"
            $scriptContent = @"
<#
.SYNOPSIS
    $Description

.DESCRIPTION
    $Description

.PARAMETER Param1
    Description du premier paramÃ¨tre

.EXAMPLE
    .\$Name.ps1 -Param1 "Valeur"

.NOTES
    Auteur: $Author
    Date de crÃ©ation: $date
#>
param (
    [string]`$Param1 = ""
)

# Fonction principale
function Main {
    [CmdletBinding(SupportsShouldProcess=`$true)]
    param()

    begin {
        Write-Verbose "DÃ©marrage du script $Name.ps1"
    }

    process {
        try {
            # Code principal ici
            if (`$PSCmdlet.ShouldProcess("$Name.ps1", "ExÃ©cuter")) {
                Write-Host "ExÃ©cution de $Name.ps1" -ForegroundColor Green

                if (`$Param1) {
                    Write-Host "ParamÃ¨tre fourni: `$Param1" -ForegroundColor Cyan
                }
            }
        }
        catch {
            Write-Error "Une erreur s'est produite: `$_"
        }
    }

    end {
        Write-Verbose "Fin du script $Name.ps1"
    }
}

# Appel de la fonction principale
Main
"@

            # CrÃ©er le script
            if ($PSCmdlet.ShouldProcess($scriptFile, "CrÃ©er le script")) {
                Set-Content -Path $scriptFile -Value $scriptContent -Encoding UTF8
                Write-Host "Script crÃ©Ã©: $scriptFile" -ForegroundColor Green
            }

            return $true
        } catch {
            Write-Error "Une erreur s'est produite lors de la crÃ©ation du script: $_"
            return $false
        }
    }

    end {
        if (Test-Path $scriptFile) {
            Write-Host "`nScript crÃ©Ã© avec succÃ¨s!" -ForegroundColor Cyan
            Write-Host "Chemin: $scriptFile" -ForegroundColor Cyan
        }
    }
}

# Appel de la fonction principale
New-ProjectScript -Name $Name -Category $Category -Description $Description -Author $Author
