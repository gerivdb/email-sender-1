<#
.SYNOPSIS
    Crée un nouveau script PowerShell dans la structure du projet.

.DESCRIPTION
    Ce script crée un nouveau script PowerShell dans la structure du projet,
    en utilisant un template prédéfini.

.PARAMETER Name
    Nom du script à créer.

.PARAMETER Category
    Catégorie/dossier où placer le script. Par défaut: 'maintenance'.

.PARAMETER Description
    Description du script. Par défaut: 'Script PowerShell'.

.PARAMETER Author
    Auteur du script. Par défaut: 'Augment Agent'.

.EXAMPLE
    .\new-script.ps1 -Name clean-temp-files

.EXAMPLE
    .\new-script.ps1 -Name optimize-database -Category database -Description "Optimise la base de données" -Author "John Doe"

.NOTES
    Auteur: Augment Agent
    Date de création: 28/04/2025
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
        Write-Host "Création d'un nouveau script PowerShell..." -ForegroundColor Cyan
        $ErrorActionPreference = "Stop"

        # Déterminer le chemin du script
        $scriptPath = Join-Path -Path (Get-Location).Path -ChildPath "development\scripts\$Category"
        $scriptFile = Join-Path -Path $scriptPath -ChildPath "$Name.ps1"

        # Vérifier si le script existe déjà
        if (Test-Path $scriptFile) {
            Write-Error "Le script '$Name.ps1' existe déjà dans le dossier '$Category'."
            return $false
        }
    }

    process {
        try {
            # Créer le dossier de destination s'il n'existe pas
            if (-not (Test-Path $scriptPath)) {
                if ($PSCmdlet.ShouldProcess($scriptPath, "Créer le dossier")) {
                    New-Item -Path $scriptPath -ItemType Directory -Force | Out-Null
                    Write-Host "Dossier créé: $scriptPath" -ForegroundColor Yellow
                }
            }

            # Créer le contenu du script
            $date = Get-Date -Format "dd/MM/yyyy"
            $scriptContent = @"
<#
.SYNOPSIS
    $Description

.DESCRIPTION
    $Description

.PARAMETER Param1
    Description du premier paramètre

.EXAMPLE
    .\$Name.ps1 -Param1 "Valeur"

.NOTES
    Auteur: $Author
    Date de création: $date
#>
param (
    [string]`$Param1 = ""
)

# Fonction principale
function Main {
    [CmdletBinding(SupportsShouldProcess=`$true)]
    param()

    begin {
        Write-Verbose "Démarrage du script $Name.ps1"
    }

    process {
        try {
            # Code principal ici
            if (`$PSCmdlet.ShouldProcess("$Name.ps1", "Exécuter")) {
                Write-Host "Exécution de $Name.ps1" -ForegroundColor Green

                if (`$Param1) {
                    Write-Host "Paramètre fourni: `$Param1" -ForegroundColor Cyan
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

            # Créer le script
            if ($PSCmdlet.ShouldProcess($scriptFile, "Créer le script")) {
                Set-Content -Path $scriptFile -Value $scriptContent -Encoding UTF8
                Write-Host "Script créé: $scriptFile" -ForegroundColor Green
            }

            return $true
        } catch {
            Write-Error "Une erreur s'est produite lors de la création du script: $_"
            return $false
        }
    }

    end {
        if (Test-Path $scriptFile) {
            Write-Host "`nScript créé avec succès!" -ForegroundColor Cyan
            Write-Host "Chemin: $scriptFile" -ForegroundColor Cyan
        }
    }
}

# Appel de la fonction principale
New-ProjectScript -Name $Name -Category $Category -Description $Description -Author $Author
