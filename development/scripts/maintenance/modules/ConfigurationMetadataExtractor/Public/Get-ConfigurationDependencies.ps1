<#
.SYNOPSIS
    Extrait les dÃ©pendances d'un fichier de configuration.
.DESCRIPTION
    Cette fonction analyse un fichier de configuration et extrait les dÃ©pendances
    entre les diffÃ©rentes options, ainsi que les dÃ©pendances externes.
.PARAMETER Path
    Chemin vers le fichier de configuration Ã  analyser.
.PARAMETER Content
    Contenu du fichier de configuration Ã  analyser. Si spÃ©cifiÃ©, Path est ignorÃ©.
.PARAMETER Format
    Format du fichier de configuration. Si non spÃ©cifiÃ©, il sera dÃ©tectÃ© automatiquement.
.PARAMETER DetectionMode
    Mode de dÃ©tection des dÃ©pendances. Les valeurs possibles sont "Explicit", "Implicit" ou "All".
.PARAMETER ExternalPaths
    Chemins vers des fichiers de configuration externes Ã  analyser pour les dÃ©pendances.
.EXAMPLE
    Get-ConfigurationDependencies -Path "config.json"
    Extrait les dÃ©pendances du fichier config.json.
.EXAMPLE
    Get-ConfigurationDependencies -Content '{"key": "value"}' -Format "JSON" -DetectionMode "All"
    Extrait toutes les dÃ©pendances du contenu JSON fourni.
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
        # Si le chemin est spÃ©cifiÃ©, lire le contenu du fichier
        if ($PSCmdlet.ParameterSetName -eq "Path") {
            if (-not (Test-Path -Path $Path -PathType Leaf)) {
                Write-Error "Le fichier spÃ©cifiÃ© n'existe pas: $Path"
                return $null
            }
            
            $Content = Get-Content -Path $Path -Raw -ErrorAction Stop
        }
        
        # DÃ©terminer le format si nÃ©cessaire
        if ($Format -eq "AUTO") {
            if ($PSCmdlet.ParameterSetName -eq "Path") {
                $Format = Get-ConfigurationFormat -Path $Path
            }
            else {
                $Format = Get-ConfigurationFormat -Content $Content
            }
            
            if ($Format -eq "UNKNOWN") {
                Write-Error "Impossible de dÃ©terminer le format de configuration."
                return $null
            }
        }
        
        # Convertir le contenu en hashtable
        $config = Convert-ConfigToHashtable -Content $Content -Format $Format
        
        if ($null -eq $config) {
            Write-Error "Erreur lors de la conversion du contenu en hashtable."
            return $null
        }
        
        # Initialiser le rÃ©sultat
        $result = @{
            InternalDependencies = @{}
            ExternalDependencies = @{}
            ReferencedPaths = @{}
            CircularDependencies = @()
            ValidationIssues = @()
        }
        
        # Extraire les dÃ©pendances explicites si demandÃ©
        if ($DetectionMode -eq "Explicit" -or $DetectionMode -eq "All") {
            $result = Export-ExplicitDependencies -Config $config -Result $result
        }
        
        # Extraire les dÃ©pendances implicites si demandÃ©
        if ($DetectionMode -eq "Implicit" -or $DetectionMode -eq "All") {
            $result = Export-ImplicitDependencies -Config $config -Result $result
        }
        
        # Analyser les dÃ©pendances externes si spÃ©cifiÃ©es
        if ($ExternalPaths.Count -gt 0) {
            $result = Export-ExternalDependencies -Config $config -ExternalPaths $ExternalPaths -Result $result
        }
        
        # DÃ©tecter les dÃ©pendances circulaires
        $result = Find-CircularDependencies -Dependencies $result.InternalDependencies -Result $result
        
        return $result
    }
    catch {
        Write-Error "Erreur lors de l'extraction des dÃ©pendances de configuration: $_"
        return $null
    }
}

function Export-ExplicitDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Result,
        
        [Parameter(Mandatory = $false)]
        [string]$Prefix = ""
    )
    
    # Si l'objet est un hashtable ou un PSCustomObject, analyser ses propriÃ©tÃ©s
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
            
            # Rechercher les dÃ©pendances explicites dans les propriÃ©tÃ©s spÃ©ciales
            if ($key -match "^depends(On|_on|_On|Requires|_requires|_Requires)$" -and ($value -is [string] -or $value -is [array])) {
                $dependencies = @()
                
                if ($value -is [string]) {
                    $dependencies = @($value)
                }
                else {
                    $dependencies = $value
                }
                
                foreach ($dependency in $dependencies) {
                    # Ajouter la dÃ©pendance au rÃ©sultat
                    if (-not $Result.InternalDependencies.ContainsKey($Prefix)) {
                        $Result.InternalDependencies[$Prefix] = @()
                    }
                    
                    if (-not ($Result.InternalDependencies[$Prefix] -contains $dependency)) {
                        $Result.InternalDependencies[$Prefix] += $dependency
                    }
                }
            }
            # Rechercher les rÃ©fÃ©rences Ã  des fichiers externes
            elseif ($key -match "^(path|file|config|configuration)(Path|File|_path|_file)$" -and $value -is [string]) {
                if (-not $Result.ReferencedPaths.ContainsKey($fullKey)) {
                    $Result.ReferencedPaths[$fullKey] = $value
                }
            }
            
            # Si la valeur est un hashtable ou un PSCustomObject, analyser rÃ©cursivement
            if ($value -is [hashtable] -or $value -is [PSCustomObject]) {
                $Result = Export-ExplicitDependencies -Config $value -Result $Result -Prefix $fullKey
            }
            # Si la valeur est un tableau, analyser chaque Ã©lÃ©ment
            elseif ($value -is [array]) {
                for ($i = 0; $i -lt $value.Count; $i++) {
                    $item = $value[$i]
                    
                    if ($item -is [hashtable] -or $item -is [PSCustomObject]) {
                        $Result = Export-ExplicitDependencies -Config $item -Result $Result -Prefix "$fullKey[$i]"
                    }
                }
            }
        }
    }
    # Si l'objet est un tableau, analyser chaque Ã©lÃ©ment
    elseif ($Config -is [array]) {
        for ($i = 0; $i -lt $Config.Count; $i++) {
            $item = $Config[$i]
            
            if ($item -is [hashtable] -or $item -is [PSCustomObject]) {
                $Result = Export-ExplicitDependencies -Config $item -Result $Result -Prefix "$Prefix[$i]"
            }
        }
    }
    
    return $Result
}

function Export-ImplicitDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Result,
        
        [Parameter(Mandatory = $false)]
        [string]$Prefix = ""
    )
    
    # Obtenir toutes les clÃ©s plates
    $flatOptions = Extract-FlatOptions -Config $Config -IncludeValues
    
    # Rechercher les rÃ©fÃ©rences dans les valeurs de chaÃ®ne
    foreach ($key in $flatOptions.Keys) {
        $option = $flatOptions[$key]
        
        if ($option.Type -eq "String" -and $option.Value -is [string]) {
            $value = $option.Value
            
            # Rechercher les rÃ©fÃ©rences Ã  d'autres clÃ©s (format ${key} ou $(key) ou %key%)
            $matches = [regex]::Matches($value, '\$\{([^}]+)\}|\$\(([^)]+)\)|%([^%]+)%')
            
            foreach ($match in $matches) {
                $referencedKey = if ($match.Groups[1].Success) { $match.Groups[1].Value } 
                                elseif ($match.Groups[2].Success) { $match.Groups[2].Value }
                                else { $match.Groups[3].Value }
                
                # Ajouter la dÃ©pendance au rÃ©sultat
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

function Export-ExternalDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config,
        
        [Parameter(Mandatory = $true)]
        [string[]]$ExternalPaths,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Result
    )
    
    # Obtenir toutes les clÃ©s plates avec leurs valeurs
    $flatOptions = Extract-FlatOptions -Config $Config -IncludeValues
    
    # Analyser chaque fichier externe
    foreach ($externalPath in $ExternalPaths) {
        if (-not (Test-Path -Path $externalPath -PathType Leaf)) {
            $Result.ValidationIssues += "Le fichier externe spÃ©cifiÃ© n'existe pas: $externalPath"
            continue
        }
        
        try {
            # DÃ©terminer le format du fichier externe
            $externalFormat = Get-ConfigurationFormat -Path $externalPath
            
            if ($externalFormat -eq "UNKNOWN") {
                $Result.ValidationIssues += "Impossible de dÃ©terminer le format du fichier externe: $externalPath"
                continue
            }
            
            # Lire et convertir le contenu du fichier externe
            $externalContent = Get-Content -Path $externalPath -Raw
            $externalConfig = Convert-ConfigToHashtable -Content $externalContent -Format $externalFormat
            
            if ($null -eq $externalConfig) {
                $Result.ValidationIssues += "Erreur lors de la conversion du contenu du fichier externe: $externalPath"
                continue
            }
            
            # Obtenir toutes les clÃ©s plates du fichier externe
            $externalFlatOptions = Extract-FlatOptions -Config $externalConfig -IncludeValues
            
            # Rechercher les rÃ©fÃ©rences entre les fichiers
            foreach ($key in $flatOptions.Keys) {
                $option = $flatOptions[$key]
                
                if ($option.Type -eq "String" -and $option.Value -is [string]) {
                    $value = $option.Value
                    
                    # Rechercher les rÃ©fÃ©rences Ã  des clÃ©s du fichier externe
                    foreach ($externalKey in $externalFlatOptions.Keys) {
                        if ($value -match [regex]::Escape($externalKey)) {
                            # Ajouter la dÃ©pendance externe au rÃ©sultat
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

function Find-CircularDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Dependencies,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Result
    )
    
    # Construire le graphe de dÃ©pendances
    $graph = @{}
    
    foreach ($key in $Dependencies.Keys) {
        $graph[$key] = $Dependencies[$key]
    }
    
    # DÃ©tecter les cycles en utilisant l'algorithme DFS
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
    
    # Marquer le nÅ“ud comme visitÃ© et l'ajouter Ã  la pile de rÃ©cursion
    $Visited[$Node] = $true
    $RecursionStack[$Node] = $true
    
    # Ajouter le nÅ“ud au chemin
    $Path += $Node
    
    # Parcourir tous les nÅ“uds adjacents
    if ($Graph.ContainsKey($Node)) {
        foreach ($adjacent in $Graph[$Node]) {
            # Si le nÅ“ud adjacent n'a pas Ã©tÃ© visitÃ©, l'explorer
            if (-not $Visited.ContainsKey($adjacent)) {
                $cycle = Find-Cycle -Graph $Graph -Node $adjacent -Visited $Visited -RecursionStack $RecursionStack -Path $Path
                
                if ($cycle.Count -gt 0) {
                    return $cycle
                }
            }
            # Si le nÅ“ud adjacent est dans la pile de rÃ©cursion, un cycle a Ã©tÃ© trouvÃ©
            elseif ($RecursionStack.ContainsKey($adjacent)) {
                # Trouver l'index du nÅ“ud adjacent dans le chemin
                $index = $Path.IndexOf($adjacent)
                
                # Retourner le cycle (sous-chemin du nÅ“ud adjacent au nÅ“ud actuel)
                return $Path[$index..$Path.Count]
            }
        }
    }
    
    # Retirer le nÅ“ud de la pile de rÃ©cursion
    $RecursionStack.Remove($Node)
    
    # Aucun cycle trouvÃ©
    return @()
}

