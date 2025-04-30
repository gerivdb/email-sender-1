<#
.SYNOPSIS
    Module de résolution de dépendances pour le Process Manager.

.DESCRIPTION
    Ce module fournit des fonctionnalités pour analyser, valider et résoudre
    les dépendances entre gestionnaires dans le Process Manager.

.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1
#>

#region Variables globales

# Chemin du fichier de configuration par défaut
$script:DefaultConfigPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "config\process-manager.config.json"

#endregion

#region Fonctions privées

<#
.SYNOPSIS
    Écrit un message dans le journal.

.DESCRIPTION
    Cette fonction écrit un message dans le journal avec un niveau de gravité spécifié.

.PARAMETER Message
    Le message à écrire dans le journal.

.PARAMETER Level
    Le niveau de gravité du message (Debug, Info, Warning, Error).

.EXAMPLE
    Write-DependencyLog -Message "Analyse des dépendances du gestionnaire 'ModeManager'" -Level Info
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

    # Définir les niveaux de journalisation
    $logLevels = @{
        Debug = 0
        Info = 1
        Warning = 2
        Error = 3
    }

    # Définir la couleur en fonction du niveau
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
    Cette fonction charge la configuration du Process Manager à partir du fichier de configuration.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spécifié, utilise le chemin par défaut.

.EXAMPLE
    $config = Get-ProcessManagerConfig
#>
function Get-ProcessManagerConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $script:DefaultConfigPath
    )

    # Vérifier si le fichier de configuration existe
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
    Compare deux versions sémantiques.

.DESCRIPTION
    Cette fonction compare deux versions sémantiques et retourne un résultat en fonction de l'opérateur spécifié.

.PARAMETER Version1
    La première version à comparer.

.PARAMETER Version2
    La deuxième version à comparer.

.PARAMETER Operator
    L'opérateur de comparaison (Equal, NotEqual, GreaterThan, GreaterOrEqual, LessThan, LessOrEqual).

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
        Write-DependencyLog -Message "Version1 n'est pas au format sémantique (X.Y.Z) : $Version1" -Level Error
        return $false
    }
    
    if (-not ($Version2 -match '^\d+\.\d+\.\d+$')) {
        Write-DependencyLog -Message "Version2 n'est pas au format sémantique (X.Y.Z) : $Version2" -Level Error
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
    Détecte les cycles dans un graphe de dépendances.

.DESCRIPTION
    Cette fonction détecte les cycles dans un graphe de dépendances en utilisant l'algorithme de détection de cycles de Tarjan.

.PARAMETER DependencyGraph
    Le graphe de dépendances sous forme de hashtable.

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
    
    # Fonction récursive pour l'algorithme de Tarjan
    function StrongConnect {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Node
        )
        
        # Initialiser le nœud
        $indices[$Node] = $index
        $lowLinks[$Node] = $index
        $index++
        $stack += $Node
        $onStack[$Node] = $true
        
        # Parcourir les dépendances du nœud
        if ($DependencyGraph.ContainsKey($Node)) {
            foreach ($dependency in $DependencyGraph[$Node]) {
                if (-not $indices.ContainsKey($dependency)) {
                    # Nœud non visité
                    StrongConnect -Node $dependency
                    $lowLinks[$Node] = [Math]::Min($lowLinks[$Node], $lowLinks[$dependency])
                }
                elseif ($onStack[$dependency]) {
                    # Nœud déjà sur la pile (cycle potentiel)
                    $lowLinks[$Node] = [Math]::Min($lowLinks[$Node], $indices[$dependency])
                }
            }
        }
        
        # Vérifier si le nœud est la racine d'une composante fortement connexe
        if ($lowLinks[$Node] -eq $indices[$Node]) {
            $component = @()
            $w = ""
            
            do {
                $w = $stack[-1]
                $stack = $stack[0..($stack.Count - 2)]
                $onStack[$w] = $false
                $component += $w
            } while ($w -ne $Node)
            
            # Ajouter la composante si elle contient plus d'un nœud (cycle)
            if ($component.Count -gt 1) {
                $stronglyConnectedComponents += ,$component
            }
        }
    }
    
    # Appliquer l'algorithme de Tarjan à tous les nœuds
    foreach ($node in $DependencyGraph.Keys) {
        if (-not $indices.ContainsKey($node)) {
            StrongConnect -Node $node
        }
    }
    
    return $stronglyConnectedComponents
}

<#
.SYNOPSIS
    Trie les gestionnaires selon leurs dépendances.

.DESCRIPTION
    Cette fonction trie les gestionnaires selon leurs dépendances en utilisant l'algorithme de tri topologique.

.PARAMETER DependencyGraph
    Le graphe de dépendances sous forme de hashtable.

.EXAMPLE
    $sortedManagers = Sort-ManagersByDependencies -DependencyGraph $dependencyGraph
#>
function Sort-ManagersByDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$DependencyGraph
    )

    # Vérifier s'il y a des cycles
    $cycles = Detect-DependencyCycles -DependencyGraph $DependencyGraph
    if ($cycles.Count -gt 0) {
        Write-DependencyLog -Message "Des cycles de dépendances ont été détectés : $($cycles | ForEach-Object { $_ -join ' -> ' } | Join-String -Separator ', ')" -Level Error
        return $null
    }
    
    # Variables pour l'algorithme de tri topologique
    $visited = @{}
    $sorted = @()
    
    # Fonction récursive pour l'algorithme de tri topologique
    function Visit {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Node
        )
        
        # Vérifier si le nœud a déjà été visité
        if ($visited.ContainsKey($Node)) {
            return
        }
        
        # Marquer le nœud comme visité
        $visited[$Node] = $true
        
        # Visiter les dépendances du nœud
        if ($DependencyGraph.ContainsKey($Node)) {
            foreach ($dependency in $DependencyGraph[$Node]) {
                Visit -Node $dependency
            }
        }
        
        # Ajouter le nœud à la liste triée
        $sorted += $Node
    }
    
    # Appliquer l'algorithme de tri topologique à tous les nœuds
    foreach ($node in $DependencyGraph.Keys) {
        Visit -Node $node
    }
    
    # Ajouter les nœuds qui n'ont pas de dépendances
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
    Obtient les dépendances d'un gestionnaire.

.DESCRIPTION
    Cette fonction extrait les dépendances d'un gestionnaire à partir de son manifeste.

.PARAMETER Path
    Le chemin vers le fichier du gestionnaire.

.PARAMETER ManifestPath
    Le chemin vers le fichier de manifeste. Si non spécifié, tente de le déduire à partir du chemin du gestionnaire.

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

    # Vérifier que le fichier du gestionnaire existe
    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        Write-DependencyLog -Message "Le fichier du gestionnaire n'existe pas : $Path" -Level Error
        return $null
    }

    # Extraire le nom du gestionnaire
    $managerName = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    Write-DependencyLog -Message "Extraction des dépendances du gestionnaire '$managerName'..." -Level Info

    # Essayer d'extraire le manifeste
    try {
        # Vérifier si le module ManifestParser est disponible
        if (Get-Module -ListAvailable -Name "ManifestParser") {
            # Importer le module ManifestParser
            Import-Module -Name "ManifestParser" -ErrorAction Stop
            
            # Extraire le manifeste
            $manifest = Get-ManagerManifest -Path $Path -ManifestPath $ManifestPath -ErrorAction Stop
            
            # Extraire les dépendances du manifeste
            if ($manifest -and $manifest.Dependencies) {
                Write-DependencyLog -Message "Dépendances trouvées dans le manifeste : $($manifest.Dependencies.Count)" -Level Info
                return $manifest.Dependencies
            }
        }
        else {
            Write-DependencyLog -Message "Le module ManifestParser n'est pas disponible. Analyse manuelle des dépendances..." -Level Warning
        }
    }
    catch {
        Write-DependencyLog -Message "Erreur lors de l'extraction du manifeste : $_" -Level Warning
    }

    # Analyse manuelle des dépendances si le manifeste n'est pas disponible
    Write-DependencyLog -Message "Analyse manuelle des dépendances..." -Level Info
    
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
    
    # Rechercher les appels à d'autres gestionnaires
    $managerPattern = '(Start|Stop|Get)-(\w+)(Manager|Service)'
    $managerMatches = [regex]::Matches($content, $managerPattern)
    
    foreach ($match in $managerMatches) {
        $calledManagerName = $match.Groups[2].Value + $match.Groups[3].Value
        
        # Éviter les auto-références
        if ($calledManagerName -ne $managerName) {
            # Vérifier si la dépendance existe déjà
            $existingDependency = $dependencies | Where-Object { $_.Name -eq $calledManagerName } | Select-Object -First 1
            
            if (-not $existingDependency) {
                $dependencies += @{
                    Name = $calledManagerName
                    Required = $true
                }
            }
        }
    }
    
    Write-DependencyLog -Message "Dépendances trouvées par analyse manuelle : $($dependencies.Count)" -Level Info
    return $dependencies
}

<#
.SYNOPSIS
    Vérifie la disponibilité des dépendances d'un gestionnaire.

.DESCRIPTION
    Cette fonction vérifie si les dépendances d'un gestionnaire sont disponibles et compatibles.

.PARAMETER Dependencies
    Les dépendances à vérifier.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spécifié, utilise le chemin par défaut.

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

    # Vérifier si des dépendances sont spécifiées
    if ($Dependencies.Count -eq 0) {
        Write-DependencyLog -Message "Aucune dépendance à vérifier." -Level Info
        return $true
    }

    # Obtenir la configuration du Process Manager
    $config = Get-ProcessManagerConfig -ConfigPath $ConfigPath
    if (-not $config) {
        Write-DependencyLog -Message "Impossible de charger la configuration du Process Manager." -Level Error
        return $false
    }

    # Vérifier chaque dépendance
    $missingDependencies = @()
    $incompatibleDependencies = @()
    
    foreach ($dependency in $Dependencies) {
        $dependencyName = $dependency.Name
        $required = $dependency.Required -eq $true
        
        # Vérifier si la dépendance est enregistrée
        if (-not $config.Managers.PSObject.Properties.Name -contains $dependencyName) {
            if ($required) {
                Write-DependencyLog -Message "Dépendance requise non enregistrée : $dependencyName" -Level Error
                $missingDependencies += $dependencyName
            } else {
                Write-DependencyLog -Message "Dépendance optionnelle non enregistrée : $dependencyName" -Level Warning
            }
            continue
        }
        
        # Vérifier la version si spécifiée
        if ($dependency.MinimumVersion -or $dependency.MaximumVersion) {
            $dependencyVersion = $config.Managers.$dependencyName.Version
            
            if (-not $dependencyVersion) {
                Write-DependencyLog -Message "Version non spécifiée pour la dépendance : $dependencyName" -Level Warning
                continue
            }
            
            # Vérifier la version minimale
            if ($dependency.MinimumVersion) {
                $versionCompatible = Compare-SemanticVersion -Version1 $dependencyVersion -Version2 $dependency.MinimumVersion -Operator "GreaterOrEqual"
                
                if (-not $versionCompatible) {
                    Write-DependencyLog -Message "Version incompatible pour la dépendance $dependencyName : $dependencyVersion < $($dependency.MinimumVersion) (minimum requis)" -Level Error
                    $incompatibleDependencies += "$dependencyName (version $dependencyVersion < $($dependency.MinimumVersion))"
                    continue
                }
            }
            
            # Vérifier la version maximale
            if ($dependency.MaximumVersion) {
                $versionCompatible = Compare-SemanticVersion -Version1 $dependencyVersion -Version2 $dependency.MaximumVersion -Operator "LessOrEqual"
                
                if (-not $versionCompatible) {
                    Write-DependencyLog -Message "Version incompatible pour la dépendance $dependencyName : $dependencyVersion > $($dependency.MaximumVersion) (maximum autorisé)" -Level Error
                    $incompatibleDependencies += "$dependencyName (version $dependencyVersion > $($dependency.MaximumVersion))"
                    continue
                }
            }
        }
        
        Write-DependencyLog -Message "Dépendance disponible et compatible : $dependencyName" -Level Debug
    }
    
    # Vérifier s'il y a des dépendances manquantes ou incompatibles
    if ($missingDependencies.Count -gt 0 -or $incompatibleDependencies.Count -gt 0) {
        if ($missingDependencies.Count -gt 0) {
            Write-DependencyLog -Message "Dépendances requises manquantes : $($missingDependencies -join ', ')" -Level Error
        }
        
        if ($incompatibleDependencies.Count -gt 0) {
            Write-DependencyLog -Message "Dépendances incompatibles : $($incompatibleDependencies -join ', ')" -Level Error
        }
        
        return $false
    }
    
    Write-DependencyLog -Message "Toutes les dépendances sont disponibles et compatibles." -Level Info
    return $true
}

<#
.SYNOPSIS
    Résout les conflits de dépendances.

.DESCRIPTION
    Cette fonction détecte et résout les conflits de dépendances entre gestionnaires.

.PARAMETER Dependencies
    Les dépendances à résoudre.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spécifié, utilise le chemin par défaut.

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

    # Vérifier si des dépendances sont spécifiées
    if ($Dependencies.Count -eq 0) {
        Write-DependencyLog -Message "Aucune dépendance à résoudre." -Level Info
        return @()
    }

    # Obtenir la configuration du Process Manager
    $config = Get-ProcessManagerConfig -ConfigPath $ConfigPath
    if (-not $config) {
        Write-DependencyLog -Message "Impossible de charger la configuration du Process Manager." -Level Error
        return $null
    }

    # Regrouper les dépendances par nom
    $dependenciesByName = @{}
    foreach ($dependency in $Dependencies) {
        $dependencyName = $dependency.Name
        
        if (-not $dependenciesByName.ContainsKey($dependencyName)) {
            $dependenciesByName[$dependencyName] = @()
        }
        
        $dependenciesByName[$dependencyName] += $dependency
    }
    
    # Résoudre les conflits pour chaque dépendance
    $resolvedDependencies = @()
    
    foreach ($dependencyName in $dependenciesByName.Keys) {
        $dependencyGroup = $dependenciesByName[$dependencyName]
        
        # Si une seule dépendance, pas de conflit
        if ($dependencyGroup.Count -eq 1) {
            $resolvedDependencies += $dependencyGroup[0]
            continue
        }
        
        Write-DependencyLog -Message "Résolution des conflits pour la dépendance : $dependencyName" -Level Info
        
        # Déterminer si la dépendance est requise
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
        
        # Déterminer la version minimale la plus élevée
        $minVersion = $null
        if ($minVersions.Count -gt 0) {
            $minVersion = $minVersions | Sort-Object -Descending | Select-Object -First 1
        }
        
        # Déterminer la version maximale la plus basse
        $maxVersion = $null
        if ($maxVersions.Count -gt 0) {
            $maxVersion = $maxVersions | Sort-Object | Select-Object -First 1
        }
        
        # Vérifier si les versions sont compatibles
        if ($minVersion -and $maxVersion) {
            $versionsCompatible = Compare-SemanticVersion -Version1 $minVersion -Version2 $maxVersion -Operator "LessOrEqual"
            
            if (-not $versionsCompatible) {
                Write-DependencyLog -Message "Conflit de versions irrésolvable pour la dépendance $dependencyName : $minVersion > $maxVersion" -Level Error
                return $null
            }
        }
        
        # Créer la dépendance résolue
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
        Write-DependencyLog -Message "Conflit résolu pour la dépendance $dependencyName : Required=$($resolvedDependency.Required), MinVersion=$($resolvedDependency.MinimumVersion), MaxVersion=$($resolvedDependency.MaximumVersion)" -Level Info
    }
    
    return $resolvedDependencies
}

<#
.SYNOPSIS
    Détermine l'ordre de chargement des gestionnaires.

.DESCRIPTION
    Cette fonction détermine l'ordre de chargement des gestionnaires en fonction de leurs dépendances.

.PARAMETER ManagerNames
    Les noms des gestionnaires à ordonner.

.PARAMETER ConfigPath
    Le chemin vers le fichier de configuration. Si non spécifié, utilise le chemin par défaut.

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

    # Vérifier si des gestionnaires sont spécifiés
    if ($ManagerNames.Count -eq 0) {
        Write-DependencyLog -Message "Aucun gestionnaire à ordonner." -Level Info
        return @()
    }

    # Obtenir la configuration du Process Manager
    $config = Get-ProcessManagerConfig -ConfigPath $ConfigPath
    if (-not $config) {
        Write-DependencyLog -Message "Impossible de charger la configuration du Process Manager." -Level Error
        return $null
    }

    # Construire le graphe de dépendances
    $dependencyGraph = @{}
    
    foreach ($managerName in $ManagerNames) {
        # Vérifier si le gestionnaire est enregistré
        if (-not $config.Managers.PSObject.Properties.Name -contains $managerName) {
            Write-DependencyLog -Message "Gestionnaire non enregistré : $managerName" -Level Warning
            continue
        }
        
        # Obtenir le chemin du gestionnaire
        $managerPath = $config.Managers.$managerName.Path
        
        # Obtenir les dépendances du gestionnaire
        $dependencies = Get-ManagerDependencies -Path $managerPath
        
        # Ajouter les dépendances au graphe
        $dependencyGraph[$managerName] = @()
        
        if ($dependencies) {
            foreach ($dependency in $dependencies) {
                $dependencyName = $dependency.Name
                
                # Vérifier si la dépendance est dans la liste des gestionnaires à ordonner
                if ($ManagerNames -contains $dependencyName) {
                    $dependencyGraph[$managerName] += $dependencyName
                }
            }
        }
    }
    
    # Trier les gestionnaires selon leurs dépendances
    $sortedManagers = Sort-ManagersByDependencies -DependencyGraph $dependencyGraph
    
    if (-not $sortedManagers) {
        Write-DependencyLog -Message "Impossible de déterminer l'ordre de chargement des gestionnaires." -Level Error
        return $null
    }
    
    Write-DependencyLog -Message "Ordre de chargement des gestionnaires : $($sortedManagers -join ' -> ')" -Level Info
    return $sortedManagers
}

#endregion

# Exporter les fonctions publiques
Export-ModuleMember -Function Get-ManagerDependencies, Test-DependenciesAvailability, Resolve-DependencyConflicts, Get-ManagerLoadOrder
