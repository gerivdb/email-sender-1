<#
.SYNOPSIS
    Extrait les dépendances d'un fichier de configuration.
.DESCRIPTION
    Cette fonction analyse un fichier de configuration et extrait les dépendances
    entre les différentes options, ainsi que les dépendances externes.
.PARAMETER Path
    Chemin vers le fichier de configuration à analyser.
.PARAMETER Content
    Contenu du fichier de configuration à analyser. Si spécifié, Path est ignoré.
.PARAMETER Format
    Format du fichier de configuration. Si non spécifié, il sera détecté automatiquement.
.PARAMETER DetectionMode
    Mode de détection des dépendances. Les valeurs possibles sont "Explicit", "Implicit" ou "All".
.PARAMETER ExternalPaths
    Chemins vers des fichiers de configuration externes à analyser pour les dépendances.
.EXAMPLE
    Get-ConfigurationDependencies -Path "config.json"
    Extrait les dépendances du fichier config.json.
.EXAMPLE
    Get-ConfigurationDependencies -Content '{"key": "value"}' -Format "JSON" -DetectionMode "All"
    Extrait toutes les dépendances du contenu JSON fourni.
.OUTPUTS
    System.Collections.Hashtable
#>
function Get-ConfigurationDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Path")]
        [string]$Path,
        
        [Parameter(Mandatory = $true, ParameterSetName = "Content")]
        [string]$Content,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "YAML", "XML", "INI", "PSD1", "AUTO")]
        [string]$Format = "AUTO",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Explicit", "Implicit", "All")]
        [string]$DetectionMode = "All",
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExternalPaths = @()
    )
    
    try {
        # Si le chemin est spécifié, lire le contenu du fichier
        if ($PSCmdlet.ParameterSetName -eq "Path") {
            if (-not (Test-Path -Path $Path -PathType Leaf)) {
                Write-Error "Le fichier spécifié n'existe pas: $Path"
                return $null
            }
            
            $Content = Get-Content -Path $Path -Raw -ErrorAction Stop
        }
        
        # Déterminer le format si nécessaire
        if ($Format -eq "AUTO") {
            if ($PSCmdlet.ParameterSetName -eq "Path") {
                $Format = Get-ConfigurationFormat -Path $Path
            }
            else {
                $Format = Get-ConfigurationFormat -Content $Content
            }
            
            if ($Format -eq "UNKNOWN") {
                Write-Error "Impossible de déterminer le format de configuration."
                return $null
            }
        }
        
        # Convertir le contenu en hashtable
        $config = Convert-ConfigToHashtable -Content $Content -Format $Format
        
        if ($null -eq $config) {
            Write-Error "Erreur lors de la conversion du contenu en hashtable."
            return $null
        }
        
        # Initialiser le résultat
        $result = @{
            InternalDependencies = @{}
            ExternalDependencies = @{}
            ReferencedPaths = @{}
            CircularDependencies = @()
            ValidationIssues = @()
        }
        
        # Extraire les dépendances explicites si demandé
        if ($DetectionMode -eq "Explicit" -or $DetectionMode -eq "All") {
            $result = Extract-ExplicitDependencies -Config $config -Result $result
        }
        
        # Extraire les dépendances implicites si demandé
        if ($DetectionMode -eq "Implicit" -or $DetectionMode -eq "All") {
            $result = Extract-ImplicitDependencies -Config $config -Result $result
        }
        
        # Analyser les dépendances externes si spécifiées
        if ($ExternalPaths.Count -gt 0) {
            $result = Extract-ExternalDependencies -Config $config -ExternalPaths $ExternalPaths -Result $result
        }
        
        # Détecter les dépendances circulaires
        $result = Detect-CircularDependencies -Dependencies $result.InternalDependencies -Result $result
        
        return $result
    }
    catch {
        Write-Error "Erreur lors de l'extraction des dépendances de configuration: $_"
        return $null
    }
}

function Extract-ExplicitDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Result,
        
        [Parameter(Mandatory = $false)]
        [string]$Prefix = ""
    )
    
    # Si l'objet est un hashtable ou un PSCustomObject, analyser ses propriétés
    if ($Config -is [hashtable] -or $Config -is [PSCustomObject]) {
        $properties = @()
        
        if ($Config -is [hashtable]) {
            $properties = $Config.Keys
        }
        else {
            $properties = $Config.PSObject.Properties.Name
        }
        
        foreach ($key in $properties) {
            $value = if ($Config -is [hashtable]) { $Config[$key] } else { $Config.$key }
            $fullKey = if ($Prefix -eq "") { $key } else { "$Prefix.$key" }
            
            # Rechercher les dépendances explicites dans les propriétés spéciales
            if ($key -match "^depends(On|_on|_On|Requires|_requires|_Requires)$" -and ($value -is [string] -or $value -is [array])) {
                $dependencies = @()
                
                if ($value -is [string]) {
                    $dependencies = @($value)
                }
                else {
                    $dependencies = $value
                }
                
                foreach ($dependency in $dependencies) {
                    # Ajouter la dépendance au résultat
                    if (-not $Result.InternalDependencies.ContainsKey($Prefix)) {
                        $Result.InternalDependencies[$Prefix] = @()
                    }
                    
                    if (-not ($Result.InternalDependencies[$Prefix] -contains $dependency)) {
                        $Result.InternalDependencies[$Prefix] += $dependency
                    }
                }
            }
            # Rechercher les références à des fichiers externes
            elseif ($key -match "^(path|file|config|configuration)(Path|File|_path|_file)$" -and $value -is [string]) {
                if (-not $Result.ReferencedPaths.ContainsKey($fullKey)) {
                    $Result.ReferencedPaths[$fullKey] = $value
                }
            }
            
            # Si la valeur est un hashtable ou un PSCustomObject, analyser récursivement
            if ($value -is [hashtable] -or $value -is [PSCustomObject]) {
                $Result = Extract-ExplicitDependencies -Config $value -Result $Result -Prefix $fullKey
            }
            # Si la valeur est un tableau, analyser chaque élément
            elseif ($value -is [array]) {
                for ($i = 0; $i -lt $value.Count; $i++) {
                    $item = $value[$i]
                    
                    if ($item -is [hashtable] -or $item -is [PSCustomObject]) {
                        $Result = Extract-ExplicitDependencies -Config $item -Result $Result -Prefix "$fullKey[$i]"
                    }
                }
            }
        }
    }
    # Si l'objet est un tableau, analyser chaque élément
    elseif ($Config -is [array]) {
        for ($i = 0; $i -lt $Config.Count; $i++) {
            $item = $Config[$i]
            
            if ($item -is [hashtable] -or $item -is [PSCustomObject]) {
                $Result = Extract-ExplicitDependencies -Config $item -Result $Result -Prefix "$Prefix[$i]"
            }
        }
    }
    
    return $Result
}

function Extract-ImplicitDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Result,
        
        [Parameter(Mandatory = $false)]
        [string]$Prefix = ""
    )
    
    # Obtenir toutes les clés plates
    $flatOptions = Extract-FlatOptions -Config $Config -IncludeValues
    
    # Rechercher les références dans les valeurs de chaîne
    foreach ($key in $flatOptions.Keys) {
        $option = $flatOptions[$key]
        
        if ($option.Type -eq "String" -and $option.Value -is [string]) {
            $value = $option.Value
            
            # Rechercher les références à d'autres clés (format ${key} ou $(key) ou %key%)
            $matches = [regex]::Matches($value, '\$\{([^}]+)\}|\$\(([^)]+)\)|%([^%]+)%')
            
            foreach ($match in $matches) {
                $referencedKey = if ($match.Groups[1].Success) { $match.Groups[1].Value } 
                                elseif ($match.Groups[2].Success) { $match.Groups[2].Value }
                                else { $match.Groups[3].Value }
                
                # Ajouter la dépendance au résultat
                if (-not $Result.InternalDependencies.ContainsKey($key)) {
                    $Result.InternalDependencies[$key] = @()
                }
                
                if (-not ($Result.InternalDependencies[$key] -contains $referencedKey)) {
                    $Result.InternalDependencies[$key] += $referencedKey
                }
            }
        }
    }
    
    return $Result
}

function Extract-ExternalDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config,
        
        [Parameter(Mandatory = $true)]
        [string[]]$ExternalPaths,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Result
    )
    
    # Obtenir toutes les clés plates avec leurs valeurs
    $flatOptions = Extract-FlatOptions -Config $Config -IncludeValues
    
    # Analyser chaque fichier externe
    foreach ($externalPath in $ExternalPaths) {
        if (-not (Test-Path -Path $externalPath -PathType Leaf)) {
            $Result.ValidationIssues += "Le fichier externe spécifié n'existe pas: $externalPath"
            continue
        }
        
        try {
            # Déterminer le format du fichier externe
            $externalFormat = Get-ConfigurationFormat -Path $externalPath
            
            if ($externalFormat -eq "UNKNOWN") {
                $Result.ValidationIssues += "Impossible de déterminer le format du fichier externe: $externalPath"
                continue
            }
            
            # Lire et convertir le contenu du fichier externe
            $externalContent = Get-Content -Path $externalPath -Raw
            $externalConfig = Convert-ConfigToHashtable -Content $externalContent -Format $externalFormat
            
            if ($null -eq $externalConfig) {
                $Result.ValidationIssues += "Erreur lors de la conversion du contenu du fichier externe: $externalPath"
                continue
            }
            
            # Obtenir toutes les clés plates du fichier externe
            $externalFlatOptions = Extract-FlatOptions -Config $externalConfig -IncludeValues
            
            # Rechercher les références entre les fichiers
            foreach ($key in $flatOptions.Keys) {
                $option = $flatOptions[$key]
                
                if ($option.Type -eq "String" -and $option.Value -is [string]) {
                    $value = $option.Value
                    
                    # Rechercher les références à des clés du fichier externe
                    foreach ($externalKey in $externalFlatOptions.Keys) {
                        if ($value -match [regex]::Escape($externalKey)) {
                            # Ajouter la dépendance externe au résultat
                            if (-not $Result.ExternalDependencies.ContainsKey($key)) {
                                $Result.ExternalDependencies[$key] = @{}
                            }
                            
                            if (-not $Result.ExternalDependencies[$key].ContainsKey($externalPath)) {
                                $Result.ExternalDependencies[$key][$externalPath] = @()
                            }
                            
                            if (-not ($Result.ExternalDependencies[$key][$externalPath] -contains $externalKey)) {
                                $Result.ExternalDependencies[$key][$externalPath] += $externalKey
                            }
                        }
                    }
                }
            }
        }
        catch {
            $Result.ValidationIssues += "Erreur lors de l'analyse du fichier externe $externalPath : $_"
        }
    }
    
    return $Result
}

function Detect-CircularDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Dependencies,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Result
    )
    
    # Construire le graphe de dépendances
    $graph = @{}
    
    foreach ($key in $Dependencies.Keys) {
        $graph[$key] = $Dependencies[$key]
    }
    
    # Détecter les cycles en utilisant l'algorithme DFS
    $visited = @{}
    $recursionStack = @{}
    
    foreach ($node in $graph.Keys) {
        if (-not $visited.ContainsKey($node)) {
            $cycle = Find-Cycle -Graph $graph -Node $node -Visited $visited -RecursionStack $recursionStack
            
            if ($cycle.Count -gt 0) {
                $Result.CircularDependencies += ,$cycle
            }
        }
    }
    
    return $Result
}

function Find-Cycle {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory = $true)]
        [string]$Node,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Visited,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$RecursionStack,
        
        [Parameter(Mandatory = $false)]
        [System.Collections.ArrayList]$Path = @()
    )
    
    # Marquer le nœud comme visité et l'ajouter à la pile de récursion
    $Visited[$Node] = $true
    $RecursionStack[$Node] = $true
    
    # Ajouter le nœud au chemin
    $Path += $Node
    
    # Parcourir tous les nœuds adjacents
    if ($Graph.ContainsKey($Node)) {
        foreach ($adjacent in $Graph[$Node]) {
            # Si le nœud adjacent n'a pas été visité, l'explorer
            if (-not $Visited.ContainsKey($adjacent)) {
                $cycle = Find-Cycle -Graph $Graph -Node $adjacent -Visited $Visited -RecursionStack $RecursionStack -Path $Path
                
                if ($cycle.Count -gt 0) {
                    return $cycle
                }
            }
            # Si le nœud adjacent est dans la pile de récursion, un cycle a été trouvé
            elseif ($RecursionStack.ContainsKey($adjacent)) {
                # Trouver l'index du nœud adjacent dans le chemin
                $index = $Path.IndexOf($adjacent)
                
                # Retourner le cycle (sous-chemin du nœud adjacent au nœud actuel)
                return $Path[$index..$Path.Count]
            }
        }
    }
    
    # Retirer le nœud de la pile de récursion
    $RecursionStack.Remove($Node)
    
    # Aucun cycle trouvé
    return @()
}
