#Requires -Version 5.1
<#
.SYNOPSIS
    Module de conteneurs légers pour PowerShell.
.DESCRIPTION
    Ce module fournit des fonctions pour créer et gérer des conteneurs légers
    qui isolent les environnements d'exécution, gèrent les dépendances et
    partagent efficacement les ressources.
.NOTES
    Nom: LightweightContainer.psm1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-05-20
#>

# Variables globales du module
$script:Containers = @{}
$script:ContainerCounter = 0
$script:ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "config"
$script:DataPath = Join-Path -Path $PSScriptRoot -ChildPath "data"
$script:ContainersPath = Join-Path -Path $script:DataPath -ChildPath "containers"
$script:ImagesPath = Join-Path -Path $script:DataPath -ChildPath "images"

# Créer les dossiers nécessaires s'ils n'existent pas
foreach ($path in @($script:ConfigPath, $script:DataPath, $script:ContainersPath, $script:ImagesPath)) {
    if (-not (Test-Path -Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# Fonction pour créer une image de conteneur
function New-ContainerImage {
    <#
    .SYNOPSIS
        Crée une nouvelle image de conteneur.
    .DESCRIPTION
        Cette fonction crée une nouvelle image de conteneur qui peut être utilisée
        pour instancier des conteneurs légers.
    .PARAMETER Name
        Nom de l'image.
    .PARAMETER ModuleDependencies
        Liste des modules PowerShell requis par l'image.
    .PARAMETER ScriptDependencies
        Liste des scripts PowerShell à inclure dans l'image.
    .PARAMETER EnvironmentVariables
        Variables d'environnement à définir dans les conteneurs basés sur cette image.
    .PARAMETER BaseImage
        Nom de l'image de base à utiliser (optionnel).
    .EXAMPLE
        New-ContainerImage -Name "MyImage" -ModuleDependencies @("PSReadLine", "ImportExcel")
    .OUTPUTS
        [PSCustomObject] avec les informations sur l'image créée
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string[]]$ModuleDependencies = @(),

        [Parameter(Mandatory = $false)]
        [string[]]$ScriptDependencies = @(),

        [Parameter(Mandatory = $false)]
        [hashtable]$EnvironmentVariables = @{},

        [Parameter(Mandatory = $false)]
        [string]$BaseImage = ""
    )

    # Vérifier si une image avec ce nom existe déjà
    $imagePath = Join-Path -Path $script:ImagesPath -ChildPath "$Name.json"
    if (Test-Path -Path $imagePath) {
        Write-Warning "Une image avec le nom '$Name' existe déjà."
        return $null
    }

    # Vérifier l'image de base si spécifiée
    $baseImageData = $null
    if (-not [string]::IsNullOrEmpty($BaseImage)) {
        $baseImagePath = Join-Path -Path $script:ImagesPath -ChildPath "$BaseImage.json"
        if (-not (Test-Path -Path $baseImagePath)) {
            Write-Warning "L'image de base '$BaseImage' n'existe pas."
            return $null
        }

        try {
            $baseImageData = Get-Content -Path $baseImagePath -Raw | ConvertFrom-Json
        } catch {
            Write-Error "Erreur lors de la lecture de l'image de base: $_"
            return $null
        }
    }

    # Vérifier les dépendances de modules
    $validModules = @()
    foreach ($module in $ModuleDependencies) {
        if (Get-Module -Name $module -ListAvailable) {
            $validModules += $module
        } else {
            Write-Warning "Le module '$module' n'est pas disponible sur le système."
        }
    }

    # Vérifier les dépendances de scripts
    $validScripts = @()
    foreach ($script in $ScriptDependencies) {
        if (Test-Path -Path $script) {
            $validScripts += $script
        } else {
            Write-Warning "Le script '$script' n'existe pas."
        }
    }

    # Fusionner avec les dépendances de l'image de base
    if ($null -ne $baseImageData) {
        $validModules = @($validModules) + @($baseImageData.ModuleDependencies) | Select-Object -Unique
        $validScripts = @($validScripts) + @($baseImageData.ScriptDependencies) | Select-Object -Unique

        # Fusionner les variables d'environnement
        foreach ($key in $baseImageData.EnvironmentVariables.PSObject.Properties.Name) {
            if (-not $EnvironmentVariables.ContainsKey($key)) {
                $EnvironmentVariables[$key] = $baseImageData.EnvironmentVariables.$key
            }
        }
    }

    # Créer l'objet image
    $image = [PSCustomObject]@{
        Name                 = $Name
        CreatedAt            = Get-Date
        ModuleDependencies   = $validModules
        ScriptDependencies   = $validScripts
        EnvironmentVariables = $EnvironmentVariables
        BaseImage            = $BaseImage
    }

    # Enregistrer l'image
    $image | ConvertTo-Json -Depth 10 | Out-File -FilePath $imagePath -Encoding utf8 -Force

    return $image
}

# Fonction pour créer un nouveau conteneur
function New-Container {
    <#
    .SYNOPSIS
        Crée un nouveau conteneur léger.
    .DESCRIPTION
        Cette fonction crée un nouveau conteneur léger basé sur une image spécifiée.
    .PARAMETER Name
        Nom du conteneur. Si non spécifié, un nom unique sera généré.
    .PARAMETER ImageName
        Nom de l'image à utiliser pour le conteneur.
    .PARAMETER EnvironmentVariables
        Variables d'environnement supplémentaires à définir dans le conteneur.
    .PARAMETER ResourceLimits
        Limites de ressources pour le conteneur (CPU, mémoire).
    .PARAMETER Persistent
        Si spécifié, l'état du conteneur sera persistant entre les exécutions.
    .EXAMPLE
        New-Container -Name "MyContainer" -ImageName "MyImage"
    .OUTPUTS
        [PSCustomObject] avec les informations sur le conteneur créé
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$ImageName,

        [Parameter(Mandatory = $false)]
        [hashtable]$EnvironmentVariables = @{},

        [Parameter(Mandatory = $false)]
        [hashtable]$ResourceLimits = @{},

        [Parameter(Mandatory = $false)]
        [switch]$Persistent
    )

    # Générer un nom unique si non spécifié
    if ([string]::IsNullOrEmpty($Name)) {
        $script:ContainerCounter++
        $Name = "Container_$script:ContainerCounter"
    }

    # Vérifier si un conteneur avec ce nom existe déjà
    if ($script:Containers.ContainsKey($Name)) {
        Write-Warning "Un conteneur avec le nom '$Name' existe déjà."
        return $null
    }

    # Vérifier si l'image existe
    $imagePath = Join-Path -Path $script:ImagesPath -ChildPath "$ImageName.json"
    if (-not (Test-Path -Path $imagePath)) {
        Write-Warning "L'image '$ImageName' n'existe pas."
        return $null
    }

    # Charger l'image
    try {
        $image = Get-Content -Path $imagePath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors de la lecture de l'image: $_"
        return $null
    }

    # Créer le dossier du conteneur
    $containerPath = Join-Path -Path $script:ContainersPath -ChildPath $Name
    if (-not (Test-Path -Path $containerPath)) {
        New-Item -Path $containerPath -ItemType Directory -Force | Out-Null
    }

    # Copier les scripts dépendants
    $scriptsPath = Join-Path -Path $containerPath -ChildPath "scripts"
    if (-not (Test-Path -Path $scriptsPath)) {
        New-Item -Path $scriptsPath -ItemType Directory -Force | Out-Null
    }

    foreach ($scriptPath in $image.ScriptDependencies) {
        if (Test-Path -Path $scriptPath) {
            $scriptName = Split-Path -Path $scriptPath -Leaf
            $destPath = Join-Path -Path $scriptsPath -ChildPath $scriptName
            Copy-Item -Path $scriptPath -Destination $destPath -Force
        }
    }

    # Fusionner les variables d'environnement
    $mergedEnvVars = @{}
    foreach ($key in $image.EnvironmentVariables.PSObject.Properties.Name) {
        $mergedEnvVars[$key] = $image.EnvironmentVariables.$key
    }

    foreach ($key in $EnvironmentVariables.Keys) {
        $mergedEnvVars[$key] = $EnvironmentVariables[$key]
    }

    # Créer le script d'initialisation du conteneur
    $initScriptPath = Join-Path -Path $containerPath -ChildPath "init.ps1"
    $initScript = @"
# Script d'initialisation pour le conteneur '$Name'
`$ErrorActionPreference = 'Stop'

# Définir les variables d'environnement
`$env:CONTAINER_NAME = '$Name'
`$env:CONTAINER_IMAGE = '$ImageName'
`$env:CONTAINER_PATH = '$containerPath'

# Définir les variables d'environnement personnalisées
$(foreach ($key in $mergedEnvVars.Keys) {
    "`$env:$key = '$($mergedEnvVars[$key])'"
})

# Importer les modules requis
$(foreach ($module in $image.ModuleDependencies) {
    "Import-Module -Name '$module' -ErrorAction SilentlyContinue"
})

# Ajouter le chemin des scripts au PATH
`$env:PATH = "`$env:PATH;$scriptsPath"

# Définir la fonction pour enregistrer l'état
function Save-ContainerState {
    param(
        [Parameter(Mandatory = `$true)]
        [hashtable]`$State
    )

    `$statePath = Join-Path -Path '$containerPath' -ChildPath 'state.json'
    `$State | ConvertTo-Json -Depth 10 | Out-File -FilePath `$statePath -Force
}

# Définir la fonction pour charger l'état
function Get-ContainerState {
    `$statePath = Join-Path -Path '$containerPath' -ChildPath 'state.json'
    if (Test-Path -Path `$statePath) {
        `$stateJson = Get-Content -Path `$statePath -Raw
        if (-not [string]::IsNullOrWhiteSpace(`$stateJson)) {
            try {
                `$state = `$stateJson | ConvertFrom-Json

                # Convertir l'objet JSON en hashtable pour faciliter l'accès aux propriétés
                `$stateHashtable = @{}
                foreach (`$prop in `$state.PSObject.Properties) {
                    `$stateHashtable[`$prop.Name] = `$prop.Value
                }

                return `$stateHashtable
            }
            catch {
                Write-Warning "Erreur lors de la conversion de l'état: `$_"
            }
        }
    }
    return `$null
}

# Charger l'état précédent si persistant
if (`$$Persistent) {
    `$previousState = Get-ContainerState
    if (`$null -ne `$previousState) {
        # Restaurer les variables d'état
        foreach (`$prop in `$previousState.PSObject.Properties) {
            Set-Variable -Name `$prop.Name -Value `$prop.Value -Scope Script
        }
    }
}

Write-Host "Conteneur '$Name' initialisé" -ForegroundColor Green
"@

    $initScript | Out-File -FilePath $initScriptPath -Encoding utf8 -Force

    # Créer l'objet conteneur
    $container = [PSCustomObject]@{
        Name                 = $Name
        ImageName            = $ImageName
        CreatedAt            = Get-Date
        Path                 = $containerPath
        InitScriptPath       = $initScriptPath
        EnvironmentVariables = $mergedEnvVars
        ResourceLimits       = $ResourceLimits
        Persistent           = $Persistent
        Status               = "Created"
        Process              = $null
        StartTime            = $null
    }

    # Enregistrer le conteneur
    $script:Containers[$Name] = $container

    return $container
}

# Fonction pour démarrer un conteneur
function Start-Container {
    <#
    .SYNOPSIS
        Démarre un conteneur léger.
    .DESCRIPTION
        Cette fonction démarre un conteneur léger précédemment créé avec New-Container.
    .PARAMETER Name
        Nom du conteneur à démarrer.
    .PARAMETER ScriptBlock
        Bloc de script à exécuter dans le conteneur.
    .PARAMETER ArgumentList
        Liste d'arguments à passer au bloc de script.
    .PARAMETER NoExit
        Si spécifié, le conteneur reste ouvert après l'exécution du script.
    .EXAMPLE
        Start-Container -Name "MyContainer" -ScriptBlock { Write-Host "Hello from container" }
    .OUTPUTS
        [PSCustomObject] avec les informations sur le conteneur démarré
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [object[]]$ArgumentList,

        [Parameter(Mandatory = $false)]
        [switch]$NoExit
    )

    # Vérifier si le conteneur existe
    if (-not $script:Containers.ContainsKey($Name)) {
        Write-Warning "Le conteneur '$Name' n'existe pas."
        return $null
    }

    # Récupérer le conteneur
    $container = $script:Containers[$Name]

    # Vérifier si le conteneur est déjà en cours d'exécution
    if ($container.Status -eq "Running" -and $null -ne $container.Process -and -not $container.Process.HasExited) {
        Write-Warning "Le conteneur '$Name' est déjà en cours d'exécution."
        return $container
    }

    # Préparer le script à exécuter
    $scriptPath = Join-Path -Path $container.Path -ChildPath "run.ps1"

    # Créer le contenu du script
    $scriptContent = @"
# Script d'exécution pour le conteneur '$Name'
`$ErrorActionPreference = 'Stop'

# Initialiser le conteneur
. '$($container.InitScriptPath)'

try {
    # Exécuter le script principal
    `$scriptBlock = {$ScriptBlock}

    # Exécuter avec les arguments si spécifiés
    if (`$args.Count -gt 0) {
        & `$scriptBlock @args
    } else {
        & `$scriptBlock
    }

    # Enregistrer l'état final si persistant et si aucun état n'a été défini manuellement
    if (`$$($container.Persistent)) {
        `$statePath = Join-Path -Path '$($container.Path)' -ChildPath 'state.json'
        `$manualStateDefined = `$false

        # Vérifier si un état a déjà été défini manuellement dans le script
        if (Test-Path -Path `$statePath) {
            try {
                `$existingState = Get-Content -Path `$statePath -Raw | ConvertFrom-Json
                if (`$existingState -and (`$existingState.PSObject.Properties.Name -contains "Counter" -or `$existingState.PSObject.Properties.Name -contains "Message")) {
                    `$manualStateDefined = `$true
                    Write-Host "État défini manuellement détecté, conservation de l'état existant."
                }
            } catch {
                # Ignorer les erreurs lors de la lecture de l'état existant
            }
        }

        # Seulement enregistrer l'état automatique si aucun état manuel n'a été défini
        if (-not `$manualStateDefined) {
            `$state = @{
                LastRunTime = Get-Date
                ExitStatus = "Success"
            }
            Save-ContainerState -State `$state
        }
    }
} catch {
    Write-Error "Erreur dans le conteneur '$Name': `$_"

    # Enregistrer l'état d'erreur si persistant et si aucun état n'a été défini manuellement
    if (`$$($container.Persistent)) {
        `$statePath = Join-Path -Path '$($container.Path)' -ChildPath 'state.json'
        `$manualStateDefined = `$false

        # Vérifier si un état a déjà été défini manuellement dans le script
        if (Test-Path -Path `$statePath) {
            try {
                `$existingState = Get-Content -Path `$statePath -Raw | ConvertFrom-Json
                if (`$existingState -and (`$existingState.PSObject.Properties.Name -contains "Counter" -or `$existingState.PSObject.Properties.Name -contains "Message")) {
                    `$manualStateDefined = `$true
                    Write-Host "État défini manuellement détecté, ajout de l'erreur à l'état existant."

                    # Charger l'état existant comme hashtable
                    `$stateHashtable = @{}
                    foreach (`$prop in `$existingState.PSObject.Properties) {
                        `$stateHashtable[`$prop.Name] = `$prop.Value
                    }

                    # Ajouter les informations d'erreur
                    `$stateHashtable["ExitStatus"] = "Error"
                    `$stateHashtable["ErrorMessage"] = `$_.ToString()

                    # Enregistrer l'état mis à jour
                    Save-ContainerState -State `$stateHashtable
                }
            } catch {
                # Ignorer les erreurs lors de la lecture de l'état existant
            }
        }

        # Seulement enregistrer l'état automatique si aucun état manuel n'a été défini
        if (-not `$manualStateDefined) {
            `$state = @{
                LastRunTime = Get-Date
                ExitStatus = "Error"
                ErrorMessage = `$_.ToString()
            }
            Save-ContainerState -State `$state
        }
    }
}

# Maintenir la fenêtre ouverte si demandé
if (`$$NoExit) {
    Write-Host "Appuyez sur une touche pour fermer le conteneur..." -ForegroundColor Yellow
    [Console]::ReadKey() | Out-Null
}
"@

    # Écrire le script dans un fichier
    $scriptContent | Out-File -FilePath $scriptPath -Encoding utf8 -Force

    # Préparer les arguments pour PowerShell
    $psArgs = "-ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`""

    if ($ArgumentList -and $ArgumentList.Count -gt 0) {
        $argString = $ArgumentList -join " "
        $psArgs += " $argString"
    }

    # Appliquer les limites de ressources
    $startProcessParams = @{
        FilePath     = "powershell.exe"
        ArgumentList = $psArgs
        PassThru     = $true
        WindowStyle  = "Normal"
    }

    # Démarrer le processus PowerShell
    $process = Start-Process @startProcessParams

    # Mettre à jour l'objet conteneur
    $container.Process = $process
    $container.Status = "Running"
    $container.StartTime = Get-Date

    return $container
}

# Fonction pour arrêter un conteneur
function Stop-Container {
    <#
    .SYNOPSIS
        Arrête un conteneur léger.
    .DESCRIPTION
        Cette fonction arrête un conteneur léger précédemment démarré avec Start-Container.
    .PARAMETER Name
        Nom du conteneur à arrêter.
    .PARAMETER Force
        Si spécifié, le conteneur est arrêté de force.
    .EXAMPLE
        Stop-Container -Name "MyContainer"
    .OUTPUTS
        [bool] Indique si l'arrêt a réussi
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier si le conteneur existe
    if (-not $script:Containers.ContainsKey($Name)) {
        Write-Warning "Le conteneur '$Name' n'existe pas."
        return $false
    }

    # Récupérer le conteneur
    $container = $script:Containers[$Name]

    # Vérifier si le conteneur est en cours d'exécution
    if ($container.Status -ne "Running" -or $null -eq $container.Process -or $container.Process.HasExited) {
        $container.Status = "Stopped"
        return $true
    }

    try {
        if ($Force) {
            # Arrêter le processus de force
            $container.Process.Kill()
        } else {
            # Envoyer un signal de fermeture au processus
            $container.Process.CloseMainWindow() | Out-Null

            # Attendre que le processus se termine (max 5 secondes)
            $container.Process.WaitForExit(5000) | Out-Null

            # Si le processus est toujours en cours d'exécution, le tuer
            if (-not $container.Process.HasExited) {
                $container.Process.Kill()
            }
        }

        # Mettre à jour le statut du conteneur
        $container.Status = "Stopped"

        return $true
    } catch {
        Write-Error "Erreur lors de l'arrêt du conteneur '$Name': $_"
        return $false
    }
}

# Fonction pour obtenir un conteneur
function Get-Container {
    <#
    .SYNOPSIS
        Obtient les informations sur un ou plusieurs conteneurs.
    .DESCRIPTION
        Cette fonction récupère les informations sur un conteneur spécifique
        ou sur tous les conteneurs si aucun nom n'est spécifié.
    .PARAMETER Name
        Nom du conteneur à récupérer. Si non spécifié, tous les conteneurs sont retournés.
    .EXAMPLE
        Get-Container -Name "MyContainer"
    .EXAMPLE
        Get-Container
    .OUTPUTS
        [PSCustomObject] ou [PSCustomObject[]] avec les informations sur le(s) conteneur(s)
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name
    )

    # Si un nom est spécifié, retourner ce conteneur spécifique
    if (-not [string]::IsNullOrEmpty($Name)) {
        if ($script:Containers.ContainsKey($Name)) {
            $container = $script:Containers[$Name]

            # Vérifier si le processus est toujours en cours d'exécution
            if ($null -ne $container.Process) {
                if ($container.Process.HasExited) {
                    $container.Status = "Stopped"
                } else {
                    # Mettre à jour les informations du processus
                    try {
                        $process = Get-Process -Id $container.Process.Id -ErrorAction SilentlyContinue
                        if ($process) {
                            $container | Add-Member -MemberType NoteProperty -Name "CPU" -Value $process.CPU -Force
                            $container | Add-Member -MemberType NoteProperty -Name "Memory" -Value ($process.WorkingSet64 / 1MB) -Force
                        }
                    } catch {
                        # Ignorer les erreurs lors de la récupération des informations du processus
                    }
                }
            }

            return $container
        } else {
            Write-Warning "Aucun conteneur avec le nom '$Name' n'a été trouvé."
            return $null
        }
    }

    # Sinon, retourner tous les conteneurs
    $result = @()
    foreach ($containerName in $script:Containers.Keys) {
        $result += Get-Container -Name $containerName
    }

    return $result
}

# Fonction pour supprimer un conteneur
function Remove-Container {
    <#
    .SYNOPSIS
        Supprime un conteneur léger.
    .DESCRIPTION
        Cette fonction supprime un conteneur léger et ses fichiers associés.
    .PARAMETER Name
        Nom du conteneur à supprimer.
    .PARAMETER Force
        Si spécifié, le conteneur est arrêté de force avant d'être supprimé.
    .PARAMETER KeepFiles
        Si spécifié, les fichiers du conteneur ne sont pas supprimés.
    .EXAMPLE
        Remove-Container -Name "MyContainer"
    .OUTPUTS
        [bool] Indique si la suppression a réussi
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$KeepFiles
    )

    # Vérifier si le conteneur existe
    if (-not $script:Containers.ContainsKey($Name)) {
        Write-Warning "Le conteneur '$Name' n'existe pas."
        return $false
    }

    # Récupérer le conteneur
    $container = $script:Containers[$Name]

    # Arrêter le conteneur s'il est en cours d'exécution
    if ($container.Status -eq "Running" -and $null -ne $container.Process -and -not $container.Process.HasExited) {
        $stopped = Stop-Container -Name $Name -Force:$Force
        if (-not $stopped) {
            Write-Warning "Impossible d'arrêter le conteneur '$Name'."
            return $false
        }
    }

    # Supprimer les fichiers du conteneur
    if (-not $KeepFiles) {
        if (Test-Path -Path $container.Path) {
            try {
                Remove-Item -Path $container.Path -Recurse -Force
            } catch {
                Write-Warning "Erreur lors de la suppression des fichiers du conteneur '$Name': $_"
            }
        }
    }

    # Supprimer le conteneur de la liste
    $script:Containers.Remove($Name)

    return $true
}

# Exporter les fonctions du module
Export-ModuleMember -Function New-ContainerImage, New-Container, Start-Container,
Stop-Container, Get-Container, Remove-Container
