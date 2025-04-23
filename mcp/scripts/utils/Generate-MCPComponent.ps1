<#
.SYNOPSIS
    Script de génération de composants MCP à l'aide de Hygen.

.DESCRIPTION
    Ce script utilise Hygen pour générer différents types de composants MCP
    (scripts serveur, scripts client, modules, documentation).

.PARAMETER Type
    Type de composant à générer (server, client, module, doc).

.PARAMETER Name
    Nom du composant à générer.

.PARAMETER Category
    Catégorie du composant (pour les documents) ou sous-système (pour les scripts).

.PARAMETER Description
    Description du composant.

.PARAMETER Author
    Auteur du composant.

.PARAMETER OutputFolder
    Dossier de sortie pour le composant généré. Si non spécifié, le composant sera généré
    dans le dossier par défaut selon son type.

.EXAMPLE
    .\Generate-MCPComponent.ps1 -Type server -Name "api-server" -Description "Serveur API MCP" -Author "John Doe"
    Génère un script serveur MCP nommé "api-server".

.EXAMPLE
    .\Generate-MCPComponent.ps1 -Type client -Name "admin-client" -Description "Client d'administration MCP" -Author "Jane Smith"
    Génère un script client MCP nommé "admin-client".

.EXAMPLE
    .\Generate-MCPComponent.ps1 -Type module -Name "MCPUtils" -Description "Utilitaires MCP" -Author "Dev Team"
    Génère un module MCP nommé "MCPUtils".

.EXAMPLE
    .\Generate-MCPComponent.ps1 -Type doc -Name "installation-guide" -Category "guides" -Description "Guide d'installation MCP" -Author "Doc Team"
    Génère un document MCP nommé "installation-guide" dans la catégorie "guides".

.NOTES
    Version: 1.0.0
    Auteur: MCP Team
    Date de création: 2023-05-15
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("server", "client", "module", "doc")]
    [string]$Type,

    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $false)]
    [string]$Category = "",

    [Parameter(Mandatory = $false)]
    [string]$Description = "",

    [Parameter(Mandatory = $false)]
    [string]$Author = "",

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = ""
)

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Fonction pour afficher un message de succès
function Write-Success {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "✓ $Message" -ForegroundColor $successColor
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "✗ $Message" -ForegroundColor $errorColor
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "ℹ $Message" -ForegroundColor $infoColor
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host "⚠ $Message" -ForegroundColor $warningColor
}

# Fonction pour obtenir le chemin du projet
function Get-ProjectPath {
    $scriptPath = $PSScriptRoot
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.Parent.FullName
    return $projectRoot
}

# Fonction pour générer un composant
function Generate-Component {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    $projectRoot = Get-ProjectPath

    # Vérifier si Hygen est installé
    try {
        $hygenVersion = npx hygen --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Hygen n'est pas installé. Veuillez l'installer avec 'npm install -g hygen' ou 'npm install --save-dev hygen'."
            return $false
        }
    } catch {
        Write-Error "Erreur lors de la vérification de Hygen : $_"
        return $false
    }

    # Déterminer le générateur à utiliser
    switch ($Type) {
        "server" {
            Write-Info "Génération d'un script serveur MCP..." -ForegroundColor Cyan
            $generator = "mcp-server"
        }
        "client" {
            Write-Info "Génération d'un script client MCP..." -ForegroundColor Cyan
            $generator = "mcp-client"
        }
        "module" {
            Write-Info "Génération d'un module MCP..." -ForegroundColor Cyan
            $generator = "mcp-module"
        }
        "doc" {
            Write-Info "Génération d'une documentation MCP..." -ForegroundColor Cyan
            $generator = "mcp-doc"
        }
        default {
            Write-Error "Type de composant non reconnu: $Type"
            return $false
        }
    }

    # Construire la commande Hygen
    $hygenCommand = "npx hygen $generator new"

    # Ajouter les paramètres
    $hygenParams = @()
    $hygenParams += "--name `"$Name`""

    if (-not [string]::IsNullOrEmpty($Description)) {
        $hygenParams += "--description `"$Description`""
    }

    if (-not [string]::IsNullOrEmpty($Author)) {
        $hygenParams += "--author `"$Author`""
    }

    if (-not [string]::IsNullOrEmpty($Category)) {
        $hygenParams += "--category `"$Category`""
    }

    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $hygenParams += "--out-dir `"$OutputFolder`""
    }

    # Exécuter la commande Hygen
    $fullCommand = "$hygenCommand $($hygenParams -join ' ')"

    if ($PSCmdlet.ShouldProcess("Hygen", $fullCommand)) {
        try {
            Write-Info "Exécution de la commande: $fullCommand"

            # Changer le répertoire de travail pour le répertoire du projet
            $currentLocation = Get-Location
            Set-Location -Path $projectRoot

            # Exécuter la commande Hygen
            $output = Invoke-Expression $fullCommand

            # Restaurer le répertoire de travail
            Set-Location -Path $currentLocation

            # Vérifier si la commande a réussi
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Composant généré avec succès"
                return $true
            } else {
                Write-Error "Erreur lors de la génération du composant"
                Write-Error $output
                return $false
            }
        } catch {
            Write-Error "Erreur lors de l'exécution de la commande Hygen : $_"
            return $false
        } finally {
            # S'assurer que le répertoire de travail est restauré
            if ((Get-Location).Path -ne $currentLocation.Path) {
                Set-Location -Path $currentLocation
            }
        }
    } else {
        return $true
    }
}

# Fonction principale
function Start-ComponentGeneration {
    Write-Info "Génération d'un composant MCP de type '$Type'..."

    # Générer le composant
    $result = Generate-Component -Type $Type

    # Afficher le résultat
    if ($result) {
        Write-Success "Composant MCP de type '$Type' généré avec succès"

        # Afficher le chemin du composant généré
        switch ($Type) {
            "server" {
                Write-Info "Le script serveur a été généré dans: mcp/core/server/$Name.ps1"
            }
            "client" {
                Write-Info "Le script client a été généré dans: mcp/core/client/$Name.ps1"
            }
            "module" {
                Write-Info "Le module a été généré dans: mcp/modules/$Name.psm1"
            }
            "doc" {
                Write-Info "La documentation a été générée dans: mcp/docs/$Category/$Name.md"
            }
        }
    } else {
        Write-Error "Échec de la génération du composant MCP de type '$Type'"
    }

    return $result
}

# Exécuter la génération du composant
Start-ComponentGeneration
