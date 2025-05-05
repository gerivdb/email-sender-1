<#
.SYNOPSIS
    Module de rÃ©solution de dÃ©pendances pour le Process Manager.

.DESCRIPTION
    Ce module fournit des fonctionnalitÃ©s pour analyser, valider et rÃ©soudre
    les dÃ©pendances entre gestionnaires dans le Process Manager.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
#>

#region Variables globales

# Chemin du fichier de configuration par dÃ©faut
$script:DefaultConfigPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "config\process-manager.config.json"

#endregion

#region Fonctions privÃ©es

<#
.SYNOPSIS
    Ã‰crit un message dans le journal.

.DESCRIPTION
    Cette fonction Ã©crit un message dans le journal avec un niveau de gravitÃ© spÃ©cifiÃ©.

.PARAMETER Message
    Le message Ã  Ã©crire dans le journal.

.PARAMETER Level
    Le niveau de gravitÃ© du message (Debug, Info, Warning, Error).

.EXAMPLE
    Write-DependencyLog -Message "Analyse des dÃ©pendances du gestionnaire 'ModeManager'" -Level Info
#>
function Write-DependencyLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Debug", "Info", "Warning", "Error")]
        [string]$Level = "Info"
    )

    # DÃ©finir les niveaux de journalisation
    $logLevels = @{
        Debug = 0
        Info = 1
        Warning = 2
        Error = 3
    }

    # DÃ©finir la couleur en fonction du niveau
    $color = switch ($Level) {
        "Debug" { "Gray" }
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        default { "White" }
    }
    
    # Afficher le message dans la console
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] [DependencyResolver] $Message"
    Write-Host $logMessage -ForegroundColor $color
}

<#
.SYNOPSIS
    Obtient la configuration du Process Manager.

.DESCRIPTION
    Cette fonction charge la configuration du Process Manager Ã  partir du fichier de configuration.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spÃ©cifiÃ©, utilise le chemin par dÃ©faut.

.EXAMPLE
    $config = Get-ProcessManagerConfig
#>
function Get-ProcessManagerConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath
    )

    # VÃ©rifier si le fichier de configuration existe
    if (-not (Test-Path -Path $ConfigPath -PathType Leaf)) {
        Write-DependencyLog -Message "Le fichier de configuration n'existe pas : $ConfigPath" -Level Error
        return $null
    }
    
    # Charger la configuration
    try {
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        return $config
    }
    catch {
        Write-DependencyLog -Message "Erreur lors du chargement de la configuration : $_" -Level Error
        return $null
    }
}

<#
.SYNOPSIS
    Compare deux versions sÃ©mantiques.

.DESCRIPTION
    Cette fonction compare deux versions sÃ©mantiques et retourne un rÃ©sultat en fonction de l'opÃ©rateur spÃ©cifiÃ©.

.PARAMETER Version1
    La premiÃ¨re version Ã  comparer.

.PARAMETER Version2
    La deuxiÃ¨me version Ã  comparer.

.PARAMETER Operator
    L'opÃ©rateur de comparaison (Equal, NotEqual, GreaterThan, GreaterOrEqual, LessThan, LessOrEqual).

.EXAMPLE
    $result = Compare-SemanticVersion -Version1 "1.0.0" -Version2 "1.1.0" -Operator "LessThan"
#>
function Compare-SemanticVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Version1,

        [Parameter(Mandatory = $true)]
        [string]$Version2,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Equal", "NotEqual", "GreaterThan", "GreaterOrEqual", "LessThan", "LessOrEqual")]
        [string]$Operator = "Equal"
    )

    # Valider les versions
    if (-not ($Version1 -match '^\d+\.\d+\.\d+$')) {
        Write-DependencyLog -Message "Version1 n'est pas au format sÃ©mantique (X.Y.Z) : $Version1" -Level Error
        return $false
    }
    
    if (-not ($Version2 -match '^\d+\.\d+\.\d+$')) {
        Write-DependencyLog -Message "Version2 n'est pas au format sÃ©mantique (X.Y.Z) : $Version2" -Level Error
        return $false
    }
    
    # Convertir les versions en tableaux d'entiers
    $v1Parts = $Version1.Split('.') | ForEach-Object { [int]$_ }
    $v2Parts = $Version2.Split('.') | ForEach-Object { [int]$_ }
    
    # Comparer les versions
    for ($i = 0; $i -lt 3; $i++) {
        if ($v1Parts[$i] -gt $v2Parts[$i]) {
            # Version1 > Version2
            return $Operator -in @("GreaterThan", "GreaterOrEqual", "NotEqual")
        }
        elseif ($v1Parts[$i] -lt $v2Parts[$i]) {
            # Version1 < Version2
            return $Operator -in @("LessThan", "LessOrEqual", "NotEqual")
        }
    }
    
    # Version1 == Version2
    return $Operator -in @("Equal", "GreaterOrEqual", "LessOrEqual")
}

<#
.SYNOPSIS
    DÃ©tecte les cycles dans un graphe de dÃ©pendances.

.DESCRIPTION
    Cette fonction dÃ©tecte les cycles dans un graphe de dÃ©pendances en utilisant l'algorithme de dÃ©tection de cycles de Tarjan.

.PARAMETER DependencyGraph
    Le graphe de dÃ©pendances sous forme de hashtable.

.EXAMPLE
    $cycles = Detect-DependencyCycles -DependencyGraph $dependencyGraph
#>
function Detect-DependencyCycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$DependencyGraph
    )

    # Variables pour l'algorithme de Tarjan
    $index = 0
    $stack = @()
    $indices = @{}
    $lowLinks = @{}
    $onStack = @{}
    $stronglyConnectedComponents = @()
    
    # Fonction rÃ©cursive pour l'algorithme de Tarjan
    function StrongConnect {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Node
        )
        
        # Initialiser le nÅ“ud
        $indices[$Node] = $index
        $lowLinks[$Node] = $index
        $index++
        $stack += $Node
        $onStack[$Node] = $true
        
        # Parcourir les dÃ©pendances du nÅ“ud
        if ($DependencyGraph.ContainsKey($Node)) {
            foreach ($dependency in $DependencyGraph[$Node]) {
                if (-not $indices.ContainsKey($dependency)) {
                    # NÅ“ud non visitÃ©
                    StrongConnect -Node $dependency
                    $lowLinks[$Node] = [Math]::Min($lowLinks[$Node], $lowLinks[$dependency])
                }
                elseif ($onStack[$dependency]) {
                    # NÅ“ud dÃ©jÃ  sur la pile (cycle potentiel)
                    $lowLinks[$Node] = [Math]::Min($lowLinks[$Node], $indices[$dependency])
                }
            }
        }
        
        # VÃ©rifier si le nÅ“ud est la racine d'une composante fortement connexe
        if ($lowLinks[$Node] -eq $indices[$Node]) {
            $component = @()
            $w = ""
            
            do {
                $w = $stack[-1]
                $stack = $stack[0..($stack.Count - 2)]
                $onStack[$w] = $false
                $component += $w
            } while ($w -ne $Node)
            
            # Ajouter la composante si elle contient plus d'un nÅ“ud (cycle)
            if ($component.Count -gt 1) {
                $stronglyConnectedComponents += ,$component
            }
        }
    }
    
    # Appliquer l'algorithme de Tarjan Ã  tous les nÅ“uds
    foreach ($node in $DependencyGraph.Keys) {
        if (-not $indices.ContainsKey($node)) {
            StrongConnect -Node $node
        }
    }
    
    return $stronglyConnectedComponents
}

<#
.SYNOPSIS
    Trie les gestionnaires selon leurs dÃ©pendances.

.DESCRIPTION
    Cette fonction trie les gestionnaires selon leurs dÃ©pendances en utilisant l'algorithme de tri topologique.

.PARAMETER DependencyGraph
    Le graphe de dÃ©pendances sous forme de hashtable.

.EXAMPLE
    $sortedManagers = Sort-ManagersByDependencies -DependencyGraph $dependencyGraph
#>
function Sort-ManagersByDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$DependencyGraph
    )

    # VÃ©rifier s'il y a des cycles
    $cycles = Detect-DependencyCycles -DependencyGraph $DependencyGraph
    if ($cycles.Count -gt 0) {
        Write-DependencyLog -Message "Des cycles de dÃ©pendances ont Ã©tÃ© dÃ©tectÃ©s : $($cycles | ForEach-Object { $_ -join ' -> ' } | Join-String -Separator ', ')" -Level Error
        return $null
    }
    
    # Variables pour l'algorithme de tri topologique
    $visited = @{}
    $sorted = @()
    
    # Fonction rÃ©cursive pour l'algorithme de tri topologique
    function Visit {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Node
        )
        
        # VÃ©rifier si le nÅ“ud a dÃ©jÃ  Ã©tÃ© visitÃ©
        if ($visited.ContainsKey($Node)) {
            return
        }
        
        # Marquer le nÅ“ud comme visitÃ©
        $visited[$Node] = $true
        
        # Visiter les dÃ©pendances du nÅ“ud
        if ($DependencyGraph.ContainsKey($Node)) {
            foreach ($dependency in $DependencyGraph[$Node]) {
                Visit -Node $dependency
            }
        }
        
        # Ajouter le nÅ“ud Ã  la liste triÃ©e
        $sorted += $Node
    }
    
    # Appliquer l'algorithme de tri topologique Ã  tous les nÅ“uds
    foreach ($node in $DependencyGraph.Keys) {
        Visit -Node $node
    }
    
    # Ajouter les nÅ“uds qui n'ont pas de dÃ©pendances
    foreach ($node in $DependencyGraph.Keys) {
        if (-not $visited.ContainsKey($node)) {
            $sorted += $node
        }
    }
    
    return $sorted
}

#endregion

#region Fonctions publiques

<#
.SYNOPSIS
    Obtient les dÃ©pendances d'un gestionnaire.

.DESCRIPTION
    Cette fonction extrait les dÃ©pendances d'un gestionnaire Ã  partir de son manifeste.

.PARAMETER Path
    Le chemin vers le fichier du gestionnaire.

.PARAMETER ManifestPath
    Le chemin vers le fichier de manifeste. Si non spÃ©cifiÃ©, tente de le dÃ©duire Ã  partir du chemin du gestionnaire.

.EXAMPLE
    $dependencies = Get-ManagerDependencies -Path "development\managers\mode-manager\scripts\mode-manager.ps1"

.EXAMPLE
    $dependencies = Get-ManagerDependencies -Path "development\managers\mode-manager\scripts\mode-manager.ps1" -ManifestPath "development\managers\mode-manager\mode-manager.manifest.json"
#>
function Get-ManagerDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$ManifestPath
    )

    # VÃ©rifier que le fichier du gestionnaire existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-DependencyLog -Message "Le fichier du gestionnaire n'existe pas : $Path" -Level Error
        return $null
    }

    # Extraire le nom du gestionnaire
    $managerName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    Write-DependencyLog -Message "Extraction des dÃ©pendances du gestionnaire '$managerName'..." -Level Info

    # Essayer d'extraire le manifeste
    try {
        # VÃ©rifier si le module ManifestParser est disponible
        if (Get-Module -ListAvailable -Name "ManifestParser") {
            # Importer le module ManifestParser
            Import-Module -Name "ManifestParser" -ErrorAction Stop
            
            # Extraire le manifeste
            $manifest = Get-ManagerManifest -Path $Path -ManifestPath $ManifestPath -ErrorAction Stop
            
            # Extraire les dÃ©pendances du manifeste
            if ($manifest -and $manifest.Dependencies) {
                Write-DependencyLog -Message "DÃ©pendances trouvÃ©es dans le manifeste : $($manifest.Dependencies.Count)" -Level Info
                return $manifest.Dependencies
            }
        }
        else {
            Write-DependencyLog -Message "Le module ManifestParser n'est pas disponible. Analyse manuelle des dÃ©pendances..." -Level Warning
        }
    }
    catch {
        Write-DependencyLog -Message "Erreur lors de l'extraction du manifeste : $_" -Level Warning
    }

    # Analyse manuelle des dÃ©pendances si le manifeste n'est pas disponible
    Write-DependencyLog -Message "Analyse manuelle des dÃ©pendances..." -Level Info
    
    # Charger le contenu du fichier
    $content = Get-Content -Path $Path -Raw
    
    # Rechercher les imports de modules
    $dependencies = @()
    $importPattern = 'Import-Module\s+([''"])(.*?)\1'
    $importMatches = [regex]::Matches($content, $importPattern)
    
    foreach ($match in $importMatches) {
        $moduleName = $match.Groups[2].Value
        $dependencies += @{
            Name = $moduleName
            Required = $true
        }
    }
    
    # Rechercher les appels Ã  d'autres gestionnaires
    $managerPattern = '(Start|Stop|Get)-(\w+)(Manager|Service)'
    $managerMatches = [regex]::Matches($content, $managerPattern)
    
    foreach ($match in $managerMatches) {
        $calledManagerName = $match.Groups[2].Value + $match.Groups[3].Value
        
        # Ã‰viter les auto-rÃ©fÃ©rences
        if ($calledManagerName -ne $managerName) {
            # VÃ©rifier si la dÃ©pendance existe dÃ©jÃ 
            $existingDependency = $dependencies | Where-Object { $_.Name -eq $calledManagerName } | Select-Object -First 1
            
            if (-not $existingDependency) {
                $dependencies += @{
                    Name = $calledManagerName
                    Required = $true
                }
            }
        }
    }
    
    Write-DependencyLog -Message "DÃ©pendances trouvÃ©es par analyse manuelle : $($dependencies.Count)" -Level Info
    return $dependencies
}

<#
.SYNOPSIS
    VÃ©rifie la disponibilitÃ© des dÃ©pendances d'un gestionnaire.

.DESCRIPTION
    Cette fonction vÃ©rifie si les dÃ©pendances d'un gestionnaire sont disponibles et compatibles.

.PARAMETER Dependencies
    Les dÃ©pendances Ã  vÃ©rifier.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spÃ©cifiÃ©, utilise le chemin par dÃ©faut.

.EXAMPLE
    $result = Test-DependenciesAvailability -Dependencies $dependencies

.EXAMPLE
    $result = Test-DependenciesAvailability -Dependencies $dependencies -ConfigPath "path/to/config.json"
#>
function Test-DependenciesAvailability {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Dependencies,

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath
    )

    # VÃ©rifier si des dÃ©pendances sont spÃ©cifiÃ©es
    if ($Dependencies.Count -eq 0) {
        Write-DependencyLog -Message "Aucune dÃ©pendance Ã  vÃ©rifier." -Level Info
        return $true
    }

    # Obtenir la configuration du Process Manager
    $config = Get-ProcessManagerConfig -ConfigPath $ConfigPath
    if (-not $config) {
        Write-DependencyLog -Message "Impossible de charger la configuration du Process Manager." -Level Error
        return $false
    }

    # VÃ©rifier chaque dÃ©pendance
    $missingDependencies = @()
    $incompatibleDependencies = @()
    
    foreach ($dependency in $Dependencies) {
        $dependencyName = $dependency.Name
        $required = $dependency.Required -eq $true
        
        # VÃ©rifier si la dÃ©pendance est enregistrÃ©e
        if (-not $config.Managers.PSObject.Properties.Name -contains $dependencyName) {
            if ($required) {
                Write-DependencyLog -Message "DÃ©pendance requise non enregistrÃ©e : $dependencyName" -Level Error
                $missingDependencies += $dependencyName
            } else {
                Write-DependencyLog -Message "DÃ©pendance optionnelle non enregistrÃ©e : $dependencyName" -Level Warning
            }
            continue
        }
        
        # VÃ©rifier la version si spÃ©cifiÃ©e
        if ($dependency.MinimumVersion -or $dependency.MaximumVersion) {
            $dependencyVersion = $config.Managers.$dependencyName.Version
            
            if (-not $dependencyVersion) {
                Write-DependencyLog -Message "Version non spÃ©cifiÃ©e pour la dÃ©pendance : $dependencyName" -Level Warning
                continue
            }
            
            # VÃ©rifier la version minimale
            if ($dependency.MinimumVersion) {
                $versionCompatible = Compare-SemanticVersion -Version1 $dependencyVersion -Version2 $dependency.MinimumVersion -Operator "GreaterOrEqual"
                
                if (-not $versionCompatible) {
                    Write-DependencyLog -Message "Version incompatible pour la dÃ©pendance $dependencyName : $dependencyVersion < $($dependency.MinimumVersion) (minimum requis)" -Level Error
                    $incompatibleDependencies += "$dependencyName (version $dependencyVersion < $($dependency.MinimumVersion))"
                    continue
                }
            }
            
            # VÃ©rifier la version maximale
            if ($dependency.MaximumVersion) {
                $versionCompatible = Compare-SemanticVersion -Version1 $dependencyVersion -Version2 $dependency.MaximumVersion -Operator "LessOrEqual"
                
                if (-not $versionCompatible) {
                    Write-DependencyLog -Message "Version incompatible pour la dÃ©pendance $dependencyName : $dependencyVersion > $($dependency.MaximumVersion) (maximum autorisÃ©)" -Level Error
                    $incompatibleDependencies += "$dependencyName (version $dependencyVersion > $($dependency.MaximumVersion))"
                    continue
                }
            }
        }
        
        Write-DependencyLog -Message "DÃ©pendance disponible et compatible : $dependencyName" -Level Debug
    }
    
    # VÃ©rifier s'il y a des dÃ©pendances manquantes ou incompatibles
    if ($missingDependencies.Count -gt 0 -or $incompatibleDependencies.Count -gt 0) {
        if ($missingDependencies.Count -gt 0) {
            Write-DependencyLog -Message "DÃ©pendances requises manquantes : $($missingDependencies -join ', ')" -Level Error
        }
        
        if ($incompatibleDependencies.Count -gt 0) {
            Write-DependencyLog -Message "DÃ©pendances incompatibles : $($incompatibleDependencies -join ', ')" -Level Error
        }
        
        return $false
    }
    
    Write-DependencyLog -Message "Toutes les dÃ©pendances sont disponibles et compatibles." -Level Info
    return $true
}

<#
.SYNOPSIS
    RÃ©sout les conflits de dÃ©pendances.

.DESCRIPTION
    Cette fonction dÃ©tecte et rÃ©sout les conflits de dÃ©pendances entre gestionnaires.

.PARAMETER Dependencies
    Les dÃ©pendances Ã  rÃ©soudre.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spÃ©cifiÃ©, utilise le chemin par dÃ©faut.

.EXAMPLE
    $resolvedDependencies = Resolve-DependencyConflicts -Dependencies $dependencies

.EXAMPLE
    $resolvedDependencies = Resolve-DependencyConflicts -Dependencies $dependencies -ConfigPath "path/to/config.json"
#>
function Resolve-DependencyConflicts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Dependencies,

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath
    )

    # VÃ©rifier si des dÃ©pendances sont spÃ©cifiÃ©es
    if ($Dependencies.Count -eq 0) {
        Write-DependencyLog -Message "Aucune dÃ©pendance Ã  rÃ©soudre." -Level Info
        return @()
    }

    # Obtenir la configuration du Process Manager
    $config = Get-ProcessManagerConfig -ConfigPath $ConfigPath
    if (-not $config) {
        Write-DependencyLog -Message "Impossible de charger la configuration du Process Manager." -Level Error
        return $null
    }

    # Regrouper les dÃ©pendances par nom
    $dependenciesByName = @{}
    foreach ($dependency in $Dependencies) {
        $dependencyName = $dependency.Name
        
        if (-not $dependenciesByName.ContainsKey($dependencyName)) {
            $dependenciesByName[$dependencyName] = @()
        }
        
        $dependenciesByName[$dependencyName] += $dependency
    }
    
    # RÃ©soudre les conflits pour chaque dÃ©pendance
    $resolvedDependencies = @()
    
    foreach ($dependencyName in $dependenciesByName.Keys) {
        $dependencyGroup = $dependenciesByName[$dependencyName]
        
        # Si une seule dÃ©pendance, pas de conflit
        if ($dependencyGroup.Count -eq 1) {
            $resolvedDependencies += $dependencyGroup[0]
            continue
        }
        
        Write-DependencyLog -Message "RÃ©solution des conflits pour la dÃ©pendance : $dependencyName" -Level Info
        
        # DÃ©terminer si la dÃ©pendance est requise
        $isRequired = $dependencyGroup | Where-Object { $_.Required -eq $true } | Select-Object -First 1
        
        # Fusionner les versions
        $minVersions = @()
        $maxVersions = @()
        
        foreach ($dependency in $dependencyGroup) {
            if ($dependency.MinimumVersion) {
                $minVersions += $dependency.MinimumVersion
            }
            
            if ($dependency.MaximumVersion) {
                $maxVersions += $dependency.MaximumVersion
            }
        }
        
        # DÃ©terminer la version minimale la plus Ã©levÃ©e
        $minVersion = $null
        if ($minVersions.Count -gt 0) {
            $minVersion = $minVersions | Sort-Object -Descending | Select-Object -First 1
        }
        
        # DÃ©terminer la version maximale la plus basse
        $maxVersion = $null
        if ($maxVersions.Count -gt 0) {
            $maxVersion = $maxVersions | Sort-Object | Select-Object -First 1
        }
        
        # VÃ©rifier si les versions sont compatibles
        if ($minVersion -and $maxVersion) {
            $versionsCompatible = Compare-SemanticVersion -Version1 $minVersion -Version2 $maxVersion -Operator "LessOrEqual"
            
            if (-not $versionsCompatible) {
                Write-DependencyLog -Message "Conflit de versions irrÃ©solvable pour la dÃ©pendance $dependencyName : $minVersion > $maxVersion" -Level Error
                return $null
            }
        }
        
        # CrÃ©er la dÃ©pendance rÃ©solue
        $resolvedDependency = @{
            Name = $dependencyName
            Required = $isRequired -ne $null
        }
        
        if ($minVersion) {
            $resolvedDependency.MinimumVersion = $minVersion
        }
        
        if ($maxVersion) {
            $resolvedDependency.MaximumVersion = $maxVersion
        }
        
        $resolvedDependencies += $resolvedDependency
        Write-DependencyLog -Message "Conflit rÃ©solu pour la dÃ©pendance $dependencyName : Required=$($resolvedDependency.Required), MinVersion=$($resolvedDependency.MinimumVersion), MaxVersion=$($resolvedDependency.MaximumVersion)" -Level Info
    }
    
    return $resolvedDependencies
}

<#
.SYNOPSIS
    DÃ©termine l'ordre de chargement des gestionnaires.

.DESCRIPTION
    Cette fonction dÃ©termine l'ordre de chargement des gestionnaires en fonction de leurs dÃ©pendances.

.PARAMETER ManagerNames
    Les noms des gestionnaires Ã  ordonner.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spÃ©cifiÃ©, utilise le chemin par dÃ©faut.

.EXAMPLE
    $loadOrder = Get-ManagerLoadOrder -ManagerNames @("ModeManager", "RoadmapManager")

.EXAMPLE
    $loadOrder = Get-ManagerLoadOrder -ManagerNames @("ModeManager", "RoadmapManager") -ConfigPath "path/to/config.json"
#>
function Get-ManagerLoadOrder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ManagerNames,

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath
    )

    # VÃ©rifier si des gestionnaires sont spÃ©cifiÃ©s
    if ($ManagerNames.Count -eq 0) {
        Write-DependencyLog -Message "Aucun gestionnaire Ã  ordonner." -Level Info
        return @()
    }

    # Obtenir la configuration du Process Manager
    $config = Get-ProcessManagerConfig -ConfigPath $ConfigPath
    if (-not $config) {
        Write-DependencyLog -Message "Impossible de charger la configuration du Process Manager." -Level Error
        return $null
    }

    # Construire le graphe de dÃ©pendances
    $dependencyGraph = @{}
    
    foreach ($managerName in $ManagerNames) {
        # VÃ©rifier si le gestionnaire est enregistrÃ©
        if (-not $config.Managers.PSObject.Properties.Name -contains $managerName) {
            Write-DependencyLog -Message "Gestionnaire non enregistrÃ© : $managerName" -Level Warning
            continue
        }
        
        # Obtenir le chemin du gestionnaire
        $managerPath = $config.Managers.$managerName.Path
        
        # Obtenir les dÃ©pendances du gestionnaire
        $dependencies = Get-ManagerDependencies -Path $managerPath
        
        # Ajouter les dÃ©pendances au graphe
        $dependencyGraph[$managerName] = @()
        
        if ($dependencies) {
            foreach ($dependency in $dependencies) {
                $dependencyName = $dependency.Name
                
                # VÃ©rifier si la dÃ©pendance est dans la liste des gestionnaires Ã  ordonner
                if ($ManagerNames -contains $dependencyName) {
                    $dependencyGraph[$managerName] += $dependencyName
                }
            }
        }
    }
    
    # Trier les gestionnaires selon leurs dÃ©pendances
    $sortedManagers = Sort-ManagersByDependencies -DependencyGraph $dependencyGraph
    
    if (-not $sortedManagers) {
        Write-DependencyLog -Message "Impossible de dÃ©terminer l'ordre de chargement des gestionnaires." -Level Error
        return $null
    }
    
    Write-DependencyLog -Message "Ordre de chargement des gestionnaires : $($sortedManagers -join ' -> ')" -Level Info
    return $sortedManagers
}

#endregion

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-ManagerDependencies, Test-DependenciesAvailability, Resolve-DependencyConflicts, Get-ManagerLoadOrder
