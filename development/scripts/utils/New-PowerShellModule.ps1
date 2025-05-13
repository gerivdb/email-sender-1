#Requires -Version 5.1
<#
.SYNOPSIS
    Génère un nouveau module PowerShell à partir des templates Hygen.
.DESCRIPTION
    Ce script utilise Hygen pour générer un nouveau module PowerShell basé sur les templates disponibles.
    Il prend en charge trois types de modules : standard, avancé et extension.
.PARAMETER Name
    Nom du module PowerShell à générer.
.PARAMETER Description
    Description du module PowerShell.
.PARAMETER Category
    Catégorie du module (core, utils, analysis, reporting, integration, maintenance, testing, documentation, optimization).
.PARAMETER Type
    Type de module (standard, advanced, extension).
.PARAMETER Author
    Auteur du module.
.PARAMETER Force
    Si spécifié, écrase le module existant s'il existe déjà.
.EXAMPLE
    .\New-PowerShellModule.ps1 -Name "ConfigManager" -Description "Module de gestion de configuration" -Category "core" -Type "standard"
    Génère un module PowerShell standard nommé "ConfigManager" dans la catégorie "core".
.EXAMPLE
    .\New-PowerShellModule.ps1 -Name "StateManager" -Description "Module de gestion d'état" -Category "utils" -Type "advanced" -Author "John Doe"
    Génère un module PowerShell avancé nommé "StateManager" dans la catégorie "utils" avec "John Doe" comme auteur.
.NOTES
    Version: 1.0.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,
    
    [Parameter(Mandatory = $false, Position = 1)]
    [string]$Description = "Module PowerShell",
    
    [Parameter(Mandatory = $false, Position = 2)]
    [ValidateSet("core", "utils", "analysis", "reporting", "integration", "maintenance", "testing", "documentation", "optimization")]
    [string]$Category = "core",
    
    [Parameter(Mandatory = $false, Position = 3)]
    [ValidateSet("standard", "advanced", "extension")]
    [string]$Type = "standard",
    
    [Parameter(Mandatory = $false, Position = 4)]
    [string]$Author = "Augment Agent",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Fonction pour obtenir le chemin du projet
function Get-ProjectRoot {
    # Chemin absolu du projet
    return "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
}

# Fonction pour vérifier si Hygen est installé
function Test-HygenInstalled {
    try {
        $null = Get-Command "npx" -ErrorAction Stop
        return $true
    }
    catch {
        Write-Error "npx n'est pas installé. Veuillez installer Node.js et npm."
        return $false
    }
}

# Fonction pour vérifier si le module existe déjà
function Test-ModuleExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath
    )
    
    return Test-Path -Path $ModulePath
}

# Fonction principale
function New-Module {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    
    # Vérifier si Hygen est installé
    if (-not (Test-HygenInstalled)) {
        return
    }
    
    # Obtenir le chemin du projet
    $projectRoot = Get-ProjectRoot
    
    # Construire le chemin du module
    $modulePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\$Category\modules\$Name"
    
    # Vérifier si le module existe déjà
    if (Test-ModuleExists -ModulePath $modulePath) {
        if (-not $Force) {
            Write-Error "Le module '$Name' existe déjà dans la catégorie '$Category'. Utilisez -Force pour écraser."
            return
        }
        else {
            if ($PSCmdlet.ShouldProcess($modulePath, "Supprimer le module existant")) {
                Remove-Item -Path $modulePath -Recurse -Force
                Write-Verbose "Module existant supprimé : $modulePath"
            }
        }
    }
    
    # Construire la commande Hygen
    $hygenArgs = @(
        "powershell-module",
        "new",
        "--name", $Name,
        "--description", "`"$Description`"",
        "--category", $Category,
        "--type", $Type,
        "--author", "`"$Author`""
    )
    
    $hygenCommand = "npx hygen $($hygenArgs -join ' ')"
    
    # Exécuter la commande Hygen
    if ($PSCmdlet.ShouldProcess("Hygen", "Générer un module PowerShell")) {
        try {
            Write-Verbose "Exécution de la commande : $hygenCommand"
            
            # Sauvegarder le répertoire courant
            $currentLocation = Get-Location
            
            # Changer le répertoire courant pour le projet
            Set-Location -Path $projectRoot
            
            # Exécuter la commande Hygen
            $output = Invoke-Expression $hygenCommand
            
            # Restaurer le répertoire courant
            Set-Location -Path $currentLocation
            
            # Vérifier si la commande a réussi
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Module PowerShell généré avec succès : $modulePath" -ForegroundColor Green
                
                # Créer les dossiers nécessaires s'ils n'existent pas
                $foldersToCreate = @(
                    (Join-Path -Path $modulePath -ChildPath "Public"),
                    (Join-Path -Path $modulePath -ChildPath "Private"),
                    (Join-Path -Path $modulePath -ChildPath "Tests"),
                    (Join-Path -Path $modulePath -ChildPath "config"),
                    (Join-Path -Path $modulePath -ChildPath "logs"),
                    (Join-Path -Path $modulePath -ChildPath "data")
                )
                
                if ($Type -eq "advanced") {
                    $foldersToCreate += @(
                        (Join-Path -Path $modulePath -ChildPath "state"),
                        (Join-Path -Path $modulePath -ChildPath "state\backup")
                    )
                }
                
                if ($Type -eq "extension") {
                    $foldersToCreate += @(
                        (Join-Path -Path $modulePath -ChildPath "extensions")
                    )
                }
                
                foreach ($folder in $foldersToCreate) {
                    if (-not (Test-Path -Path $folder)) {
                        if ($PSCmdlet.ShouldProcess($folder, "Créer le dossier")) {
                            New-Item -Path $folder -ItemType Directory -Force | Out-Null
                            Write-Verbose "Dossier créé : $folder"
                        }
                    }
                }
                
                return $true
            }
            else {
                Write-Error "Erreur lors de la génération du module PowerShell"
                Write-Error $output
                return $false
            }
        }
        catch {
            Write-Error "Erreur lors de l'exécution de la commande Hygen : $_"
            return $false
        }
    }
}

# Exécuter la fonction principale
New-Module
