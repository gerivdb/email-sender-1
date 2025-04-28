<#
.SYNOPSIS
    Fonctions pour la rÃ©cupÃ©ration et l'analyse des propriÃ©tÃ©s hÃ©ritÃ©es dans les types .NET.
.DESCRIPTION
    Ce module fournit des fonctions pour analyser la hiÃ©rarchie d'hÃ©ritage des types, rÃ©soudre les propriÃ©tÃ©s masquÃ©es,
    fusionner les propriÃ©tÃ©s hÃ©ritÃ©es et gÃ©rer les propriÃ©tÃ©s virtuelles.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
#>

#region Analyse de la hiÃ©rarchie

<#
.SYNOPSIS
    Construit l'arbre d'hÃ©ritage d'un type.
.DESCRIPTION
    Cette fonction construit l'arbre d'hÃ©ritage complet d'un type, incluant les classes de base et les interfaces implÃ©mentÃ©es.
.PARAMETER Type
    Le type dont on veut construire l'arbre d'hÃ©ritage.
.PARAMETER IncludeInterfaces
    Indique si les interfaces implÃ©mentÃ©es doivent Ãªtre incluses dans l'arbre d'hÃ©ritage.
.PARAMETER MaxDepth
    La profondeur maximale de l'arbre d'hÃ©ritage. Par dÃ©faut, il n'y a pas de limite.
.EXAMPLE
    $inheritanceTree = Get-TypeInheritanceTree -Type ([System.String])
.OUTPUTS
    PSObject - Un objet reprÃ©sentant l'arbre d'hÃ©ritage du type.
#>
function Get-TypeInheritanceTree {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInterfaces,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = -1  # -1 signifie pas de limite
    )

    # Fonction rÃ©cursive pour construire l'arbre
    function Build-InheritanceTree {
        param (
            [type]$CurrentType,
            [int]$CurrentDepth = 0,
            [System.Collections.Generic.HashSet[type]]$VisitedTypes = (New-Object System.Collections.Generic.HashSet[type])
        )

        # VÃ©rifier si le type a dÃ©jÃ  Ã©tÃ© visitÃ© (pour Ã©viter les cycles)
        if ($VisitedTypes.Contains($CurrentType)) {
            return $null
        }

        # VÃ©rifier si la profondeur maximale est atteinte
        if ($MaxDepth -ne -1 -and $CurrentDepth -gt $MaxDepth) {
            return $null
        }

        # Ajouter le type courant aux types visitÃ©s
        [void]$VisitedTypes.Add($CurrentType)

        # CrÃ©er le nÅ“ud pour le type courant
        $node = [PSCustomObject]@{
            Type       = $CurrentType
            BaseType   = $null
            Interfaces = @()
            Depth      = $CurrentDepth
            Children   = @()
        }

        # Ajouter le type de base s'il existe
        if ($null -ne $CurrentType.BaseType -and $CurrentType.BaseType -ne [object]) {
            $baseNode = Build-InheritanceTree -CurrentType $CurrentType.BaseType -CurrentDepth ($CurrentDepth + 1) -VisitedTypes $VisitedTypes
            if ($null -ne $baseNode) {
                $node.BaseType = $baseNode
                $node.Children += $baseNode
            }
        }

        # Ajouter les interfaces implÃ©mentÃ©es si demandÃ©
        if ($IncludeInterfaces) {
            $interfaces = $CurrentType.GetInterfaces()
            foreach ($interface in $interfaces) {
                # VÃ©rifier si l'interface est directement implÃ©mentÃ©e par ce type
                # (et non par un type de base)
                $isDirectlyImplemented = $true
                if ($null -ne $CurrentType.BaseType) {
                    $baseInterfaces = $CurrentType.BaseType.GetInterfaces()
                    if ($baseInterfaces -contains $interface) {
                        $isDirectlyImplemented = $false
                    }
                }

                if ($isDirectlyImplemented) {
                    $interfaceNode = Build-InheritanceTree -CurrentType $interface -CurrentDepth ($CurrentDepth + 1) -VisitedTypes $VisitedTypes
                    if ($null -ne $interfaceNode) {
                        $node.Interfaces += $interfaceNode
                        $node.Children += $interfaceNode
                    }
                }
            }
        }

        return $node
    }

    # Construire l'arbre d'hÃ©ritage
    $visitedTypes = New-Object System.Collections.Generic.HashSet[type]
    $tree = Build-InheritanceTree -CurrentType $Type -VisitedTypes $visitedTypes

    return $tree
}

<#
.SYNOPSIS
    Parcourt l'arbre d'hÃ©ritage d'un type de maniÃ¨re ascendante.
.DESCRIPTION
    Cette fonction parcourt l'arbre d'hÃ©ritage d'un type de maniÃ¨re ascendante (du type vers ses ancÃªtres).
.PARAMETER Type
    Le type dont on veut parcourir l'arbre d'hÃ©ritage.
.PARAMETER IncludeInterfaces
    Indique si les interfaces implÃ©mentÃ©es doivent Ãªtre incluses dans le parcours.
.PARAMETER MaxDepth
    La profondeur maximale du parcours. Par dÃ©faut, il n'y a pas de limite.
.EXAMPLE
    $ancestors = Get-TypeAncestors -Type ([System.String])
.OUTPUTS
    Type[] - Un tableau des types ancÃªtres du type spÃ©cifiÃ©.
#>
function Get-TypeAncestors {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInterfaces,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = -1  # -1 signifie pas de limite
    )

    # CrÃ©er un tableau pour stocker les ancÃªtres
    $ancestors = @()

    # Parcourir la hiÃ©rarchie des classes de base
    $currentType = $Type.BaseType
    $currentDepth = 1

    while ($null -ne $currentType -and $currentType -ne [object]) {
        # VÃ©rifier si la profondeur maximale est atteinte
        if ($MaxDepth -ne -1 -and $currentDepth -gt $MaxDepth) {
            break
        }

        $ancestors += $currentType
        $currentType = $currentType.BaseType
        $currentDepth++
    }

    # Ajouter les interfaces si demandÃ©
    if ($IncludeInterfaces) {
        $interfaces = $Type.GetInterfaces()
        $ancestors += $interfaces
    }

    return $ancestors
}

<#
.SYNOPSIS
    Parcourt l'arbre d'hÃ©ritage d'un type de maniÃ¨re descendante.
.DESCRIPTION
    Cette fonction parcourt l'arbre d'hÃ©ritage d'un type de maniÃ¨re descendante (du type vers ses descendants).
.PARAMETER Type
    Le type dont on veut parcourir l'arbre d'hÃ©ritage.
.PARAMETER Assembly
    L'assembly dans lequel rechercher les types descendants. Par dÃ©faut, tous les assemblies chargÃ©s sont analysÃ©s.
.PARAMETER IncludeInterfaces
    Indique si les interfaces implÃ©mentÃ©es doivent Ãªtre incluses dans le parcours.
.PARAMETER MaxDepth
    La profondeur maximale du parcours. Par dÃ©faut, il n'y a pas de limite.
.EXAMPLE
    $descendants = Get-TypeDescendants -Type ([System.Exception])
.OUTPUTS
    Type[] - Un tableau des types descendants du type spÃ©cifiÃ©.
#>
function Get-TypeDescendants {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [System.Reflection.Assembly]$Assembly,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInterfaces,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = -1  # -1 signifie pas de limite
    )

    # Fonction rÃ©cursive pour trouver les descendants
    function Find-Descendants {
        param (
            [type]$CurrentType,
            [int]$CurrentDepth = 0,
            [System.Collections.Generic.HashSet[type]]$VisitedTypes = (New-Object System.Collections.Generic.HashSet[type])
        )

        # VÃ©rifier si le type a dÃ©jÃ  Ã©tÃ© visitÃ© (pour Ã©viter les cycles)
        if ($VisitedTypes.Contains($CurrentType)) {
            return @()
        }

        # VÃ©rifier si la profondeur maximale est atteinte
        if ($MaxDepth -ne -1 -and $CurrentDepth -gt $MaxDepth) {
            return @()
        }

        # Ajouter le type courant aux types visitÃ©s
        [void]$VisitedTypes.Add($CurrentType)

        # RÃ©cupÃ©rer tous les types Ã  analyser
        $typesToAnalyze = if ($null -ne $Assembly) {
            $Assembly.GetTypes()
        } else {
            [AppDomain]::CurrentDomain.GetAssemblies() | ForEach-Object { $_.GetTypes() }
        }

        # Trouver les descendants directs
        $directDescendants = $typesToAnalyze | Where-Object {
            $_.BaseType -eq $CurrentType -or
            ($IncludeInterfaces -and $CurrentType.IsInterface -and $_.GetInterfaces() -contains $CurrentType)
        }

        # RÃ©cupÃ©rer les descendants indirects (rÃ©cursivement)
        $allDescendants = $directDescendants
        foreach ($descendant in $directDescendants) {
            $indirectDescendants = Find-Descendants -CurrentType $descendant -CurrentDepth ($CurrentDepth + 1) -VisitedTypes $VisitedTypes
            $allDescendants += $indirectDescendants
        }

        return $allDescendants
    }

    # Trouver tous les descendants
    $visitedTypes = New-Object System.Collections.Generic.HashSet[type]

    # Limiter la recherche Ã  l'assembly courant pour Ã©viter les performances mÃ©diocres
    $assembly = if ($null -ne $Assembly) { $Assembly } else { $Type.Assembly }

    try {
        $descendants = Find-Descendants -CurrentType $Type -VisitedTypes $visitedTypes
        return $descendants
    } catch {
        Write-Warning "Erreur lors de la recherche des descendants: $_"
        return @()
    }
}

<#
.SYNOPSIS
    DÃ©tecte les cycles d'hÃ©ritage dans un type.
.DESCRIPTION
    Cette fonction dÃ©tecte les cycles d'hÃ©ritage dans un type, ce qui peut se produire avec des interfaces gÃ©nÃ©riques.
.PARAMETER Type
    Le type Ã  analyser pour dÃ©tecter les cycles d'hÃ©ritage.
.PARAMETER IncludeInterfaces
    Indique si les interfaces implÃ©mentÃ©es doivent Ãªtre incluses dans l'analyse.
.EXAMPLE
    $cycles = Test-TypeInheritanceCycles -Type ([System.Collections.Generic.IEnumerable`1[System.String]])
.OUTPUTS
    PSObject - Un objet contenant des informations sur les cycles d'hÃ©ritage dÃ©tectÃ©s.
#>
function Test-TypeInheritanceCycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInterfaces
    )

    # Fonction rÃ©cursive pour dÃ©tecter les cycles
    function Find-InheritanceCycles {
        param (
            [type]$CurrentType,
            [int]$Depth = 0,
            [System.Collections.Generic.List[type]]$Path = (New-Object System.Collections.Generic.List[type])
        )

        # VÃ©rifier si le type a dÃ©jÃ  Ã©tÃ© visitÃ©
        if ($Path.Contains($CurrentType)) {
            # Cycle dÃ©tectÃ©
            $cycleStart = $Path.IndexOf($CurrentType)
            $cycle = $Path.GetRange($cycleStart, $Path.Count - $cycleStart)
            $cycle.Add($CurrentType)

            return @{
                HasCycle   = $true
                Cycle      = $cycle
                CycleStart = $CurrentType
            }
        }

        # Ajouter le type courant au chemin
        $Path.Add($CurrentType)

        # VÃ©rifier le type de base
        if ($null -ne $CurrentType.BaseType -and $CurrentType.BaseType -ne [object]) {
            $result = Detect-Cycles -CurrentType $CurrentType.BaseType -Depth ($Depth + 1) -Path $Path
            if ($result.HasCycle) {
                return $result
            }
        }

        # VÃ©rifier les interfaces si demandÃ©
        if ($IncludeInterfaces) {
            $interfaces = $CurrentType.GetInterfaces()
            foreach ($interface in $interfaces) {
                $result = Detect-Cycles -CurrentType $interface -Depth ($Depth + 1) -Path $Path
                if ($result.HasCycle) {
                    return $result
                }
            }
        }

        # Retirer le type courant du chemin
        $Path.RemoveAt($Path.Count - 1)

        # Aucun cycle dÃ©tectÃ©
        return @{
            HasCycle   = $false
            Cycle      = $null
            CycleStart = $null
        }
    }

    # DÃ©tecter les cycles
    $path = New-Object System.Collections.Generic.List[type]
    $result = Find-InheritanceCycles -CurrentType $Type -Path $path

    # CrÃ©er l'objet rÃ©sultat
    $cycleInfo = [PSCustomObject]@{
        Type       = $Type
        HasCycles  = $result.HasCycle
        Cycles     = if ($result.HasCycle) { $result.Cycle } else { @() }
        CycleStart = $result.CycleStart
    }

    return $cycleInfo
}

<#
.SYNOPSIS
    Visualise la hiÃ©rarchie d'hÃ©ritage d'un type.
.DESCRIPTION
    Cette fonction gÃ©nÃ¨re une reprÃ©sentation visuelle de la hiÃ©rarchie d'hÃ©ritage d'un type.
.PARAMETER Type
    Le type dont on veut visualiser la hiÃ©rarchie d'hÃ©ritage.
.PARAMETER IncludeInterfaces
    Indique si les interfaces implÃ©mentÃ©es doivent Ãªtre incluses dans la visualisation.
.PARAMETER MaxDepth
    La profondeur maximale de la hiÃ©rarchie Ã  visualiser. Par dÃ©faut, il n'y a pas de limite.
.PARAMETER Format
    Le format de la visualisation. Les valeurs possibles sont : "Text", "ASCII", "Markdown".
.EXAMPLE
    $visualization = Get-TypeInheritanceVisualization -Type ([System.String]) -Format "ASCII"
.OUTPUTS
    String - Une reprÃ©sentation visuelle de la hiÃ©rarchie d'hÃ©ritage du type.
#>
function Get-TypeInheritanceVisualization {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInterfaces,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = -1, # -1 signifie pas de limite

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "ASCII", "Markdown")]
        [string]$Format = "ASCII"
    )

    # RÃ©cupÃ©rer l'arbre d'hÃ©ritage
    $tree = Get-TypeInheritanceTree -Type $Type -IncludeInterfaces:$IncludeInterfaces -MaxDepth $MaxDepth

    # Fonction rÃ©cursive pour gÃ©nÃ©rer la visualisation
    function Format-InheritanceTree {
        param (
            [PSObject]$Node,
            [string]$Indent = "",
            [bool]$IsLast = $true,
            [string]$Format = "ASCII"
        )

        # DÃ©finir les caractÃ¨res de formatage en fonction du format
        $connector = ""
        $childConnector = ""
        $lastChildConnector = ""
        $indent = ""

        switch ($Format) {
            "Text" {
                $connector = "+-"
                $childConnector = "| "
                $lastChildConnector = "  "
                $indent = "  "
            }
            "ASCII" {
                $connector = "+--"
                $childConnector = "|  "
                $lastChildConnector = "   "
                $indent = "   "
            }
            "Markdown" {
                $connector = "* "
                $childConnector = "  "
                $lastChildConnector = "  "
                $indent = "  "
            }
        }

        # GÃ©nÃ©rer la ligne pour le nÅ“ud courant
        $line = ""
        if ($Node.Depth -eq 0) {
            $line = $Node.Type.FullName
        } else {
            $line = "$Indent$connector$($Node.Type.FullName)"
        }

        # Ajouter la ligne Ã  la sortie
        $output = $line + "`n"

        # GÃ©nÃ©rer les lignes pour les enfants
        $childCount = $Node.Children.Count
        for ($i = 0; $i -lt $childCount; $i++) {
            $child = $Node.Children[$i]
            $isLastChild = ($i -eq $childCount - 1)

            $newIndent = if ($Node.Depth -eq 0) {
                ""
            } elseif ($IsLast) {
                $Indent + $lastChildConnector
            } else {
                $Indent + $childConnector
            }

            $output += Format-InheritanceTree -Node $child -Indent $newIndent -IsLast $isLastChild -Format $Format
        }

        return $output
    }

    # GÃ©nÃ©rer la visualisation
    $visualization = Format-InheritanceTree -Node $tree -Format $Format

    return $visualization
}

#endregion

#region RÃ©solution des propriÃ©tÃ©s masquÃ©es

<#
.SYNOPSIS
    DÃ©tecte les mots-clÃ©s new et override dans les propriÃ©tÃ©s.
.DESCRIPTION
    Cette fonction dÃ©tecte les propriÃ©tÃ©s qui utilisent les mots-clÃ©s new et override pour masquer ou remplacer des propriÃ©tÃ©s hÃ©ritÃ©es.
.PARAMETER Type
    Le type Ã  analyser.
.PARAMETER IncludeNonPublic
    Indique si les propriÃ©tÃ©s non publiques doivent Ãªtre incluses dans l'analyse.
.EXAMPLE
    $newOverrideProperties = Get-TypeNewOverrideProperties -Type ([System.Exception])
.OUTPUTS
    PSObject[] - Un tableau d'objets contenant des informations sur les propriÃ©tÃ©s qui utilisent new ou override.
#>
function Get-TypeNewOverrideProperties {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNonPublic
    )

    # RÃ©cupÃ©rer toutes les propriÃ©tÃ©s du type
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance
    if ($IncludeNonPublic) {
        $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::NonPublic
    }

    $properties = $Type.GetProperties($bindingFlags)

    # RÃ©cupÃ©rer les propriÃ©tÃ©s des types de base
    $baseProperties = @{}
    $currentType = $Type.BaseType

    while ($null -ne $currentType -and $currentType -ne [object]) {
        $baseProps = $currentType.GetProperties($bindingFlags)
        foreach ($prop in $baseProps) {
            if (-not $baseProperties.ContainsKey($prop.Name)) {
                $baseProperties[$prop.Name] = $prop
            }
        }
        $currentType = $currentType.BaseType
    }

    # CrÃ©er un tableau pour stocker les rÃ©sultats
    $results = @()

    # Analyser chaque propriÃ©tÃ©
    foreach ($property in $properties) {
        # VÃ©rifier si la propriÃ©tÃ© masque ou remplace une propriÃ©tÃ© hÃ©ritÃ©e
        $isNew = $false
        $isOverride = $false
        $baseProperty = $null

        if ($baseProperties.ContainsKey($property.Name)) {
            $baseProperty = $baseProperties[$property.Name]

            # VÃ©rifier si la propriÃ©tÃ© utilise new (masquage)
            if ($null -ne $property.GetMethod -and $null -ne $baseProperty.GetMethod) {
                $isNew = -not $property.GetMethod.IsVirtual -and -not $baseProperty.GetMethod.IsFinal
            }

            # VÃ©rifier si la propriÃ©tÃ© utilise override (remplacement)
            if ($null -ne $property.GetMethod -and $null -ne $baseProperty.GetMethod) {
                $isOverride = $property.GetMethod.IsVirtual -and $property.GetMethod.GetBaseDefinition() -ne $property.GetMethod
            }
        }

        # CrÃ©er l'objet rÃ©sultat si la propriÃ©tÃ© utilise new ou override
        if ($isNew -or $isOverride) {
            $result = [PSCustomObject]@{
                Property     = $property
                BaseProperty = $baseProperty
                IsNew        = $isNew
                IsOverride   = $isOverride
                Type         = $Type
                BaseType     = $baseProperty.DeclaringType
            }

            $results += $result
        }
    }

    return $results
}

<#
.SYNOPSIS
    RÃ©sout les conflits de noms entre les propriÃ©tÃ©s.
.DESCRIPTION
    Cette fonction rÃ©sout les conflits de noms entre les propriÃ©tÃ©s d'un type et de ses types de base ou interfaces.
.PARAMETER Type
    Le type Ã  analyser.
.PARAMETER IncludeInterfaces
    Indique si les interfaces implÃ©mentÃ©es doivent Ãªtre incluses dans l'analyse.
.PARAMETER IncludeNonPublic
    Indique si les propriÃ©tÃ©s non publiques doivent Ãªtre incluses dans l'analyse.
.EXAMPLE
    $nameConflicts = Resolve-TypePropertyNameConflicts -Type ([System.Exception])
.OUTPUTS
    PSObject[] - Un tableau d'objets contenant des informations sur les conflits de noms rÃ©solus.
#>
function Resolve-TypePropertyNameConflicts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInterfaces,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNonPublic
    )

    # RÃ©cupÃ©rer toutes les propriÃ©tÃ©s du type
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance
    if ($IncludeNonPublic) {
        $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::NonPublic
    }

    $properties = $Type.GetProperties($bindingFlags)

    # CrÃ©er un dictionnaire pour stocker les propriÃ©tÃ©s par nom
    $propertyMap = @{}
    foreach ($property in $properties) {
        if (-not $propertyMap.ContainsKey($property.Name)) {
            $propertyMap[$property.Name] = @()
        }
        $propertyMap[$property.Name] += @{ Property = $property; Type = $Type }
    }

    # RÃ©cupÃ©rer les propriÃ©tÃ©s des types de base
    $currentType = $Type.BaseType
    while ($null -ne $currentType -and $currentType -ne [object]) {
        $baseProps = $currentType.GetProperties($bindingFlags)
        foreach ($property in $baseProps) {
            if (-not $propertyMap.ContainsKey($property.Name)) {
                $propertyMap[$property.Name] = @()
            }
            $propertyMap[$property.Name] += @{ Property = $property; Type = $currentType }
        }
        $currentType = $currentType.BaseType
    }

    # RÃ©cupÃ©rer les propriÃ©tÃ©s des interfaces si demandÃ©
    if ($IncludeInterfaces) {
        $interfaces = $Type.GetInterfaces()
        foreach ($interface in $interfaces) {
            $interfaceProps = $interface.GetProperties($bindingFlags)
            foreach ($property in $interfaceProps) {
                if (-not $propertyMap.ContainsKey($property.Name)) {
                    $propertyMap[$property.Name] = @()
                }
                $propertyMap[$property.Name] += @{ Property = $property; Type = $interface }
            }
        }
    }

    # Identifier les conflits de noms
    $conflicts = @()
    foreach ($propertyName in $propertyMap.Keys) {
        $propertiesWithSameName = $propertyMap[$propertyName]

        if ($propertiesWithSameName.Count -gt 1) {
            # DÃ©terminer la propriÃ©tÃ© qui a prÃ©sÃ©ance
            $precedence = $propertiesWithSameName | Sort-Object { $_.Type.IsInterface }, { [array]::IndexOf(($Type.GetInterfaces()), $_.Type) }, { Get-TypeAncestors -Type $Type | ForEach-Object { $_ } | Select-Object -First 1 | ForEach-Object { [array]::IndexOf($_, $_.Type) } }

            $winningProperty = $precedence[0]
            $conflictingProperties = $precedence[1..($precedence.Count - 1)]

            $conflict = [PSCustomObject]@{
                PropertyName          = $propertyName
                WinningProperty       = $winningProperty.Property
                WinningType           = $winningProperty.Type
                ConflictingProperties = $conflictingProperties | ForEach-Object { $_.Property }
                ConflictingTypes      = $conflictingProperties | ForEach-Object { $_.Type }
                ResolutionMethod      = if ($winningProperty.Type -eq $Type) { "Declared" } elseif ($winningProperty.Type.IsInterface) { "Interface" } else { "Inherited" }
            }

            $conflicts += $conflict
        }
    }

    return $conflicts
}

<#
.SYNOPSIS
    Analyse les patterns de shadowing dans un type.
.DESCRIPTION
    Cette fonction analyse les patterns de shadowing (masquage) dans un type, comme les propriÃ©tÃ©s qui masquent des propriÃ©tÃ©s hÃ©ritÃ©es.
.PARAMETER Type
    Le type Ã  analyser.
.PARAMETER IncludeNonPublic
    Indique si les propriÃ©tÃ©s non publiques doivent Ãªtre incluses dans l'analyse.
.EXAMPLE
    $shadowingPatterns = Get-TypeShadowingPatterns -Type ([System.Exception])
.OUTPUTS
    PSObject - Un objet contenant des informations sur les patterns de shadowing dans le type.
#>
function Get-TypeShadowingPatterns {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNonPublic
    )

    # RÃ©cupÃ©rer les propriÃ©tÃ©s qui utilisent new ou override
    $newOverrideProperties = Get-TypeNewOverrideProperties -Type $Type -IncludeNonPublic:$IncludeNonPublic

    # RÃ©cupÃ©rer les conflits de noms
    $nameConflicts = Resolve-TypePropertyNameConflicts -Type $Type -IncludeInterfaces -IncludeNonPublic:$IncludeNonPublic

    # Identifier les diffÃ©rents patterns de shadowing
    $newProperties = $newOverrideProperties | Where-Object { $_.IsNew }
    $overrideProperties = $newOverrideProperties | Where-Object { $_.IsOverride }
    $interfaceConflicts = $nameConflicts | Where-Object { $_.ResolutionMethod -eq "Interface" }
    $inheritedConflicts = $nameConflicts | Where-Object { $_.ResolutionMethod -eq "Inherited" }

    # CrÃ©er l'objet rÃ©sultat
    $result = [PSCustomObject]@{
        Type               = $Type
        NewProperties      = $newProperties
        OverrideProperties = $overrideProperties
        InterfaceConflicts = $interfaceConflicts
        InheritedConflicts = $inheritedConflicts
        HasShadowing       = ($newProperties.Count -gt 0) -or ($interfaceConflicts.Count -gt 0) -or ($inheritedConflicts.Count -gt 0)
        HasOverrides       = $overrideProperties.Count -gt 0
        ShadowingCount     = $newProperties.Count + $interfaceConflicts.Count + $inheritedConflicts.Count
        OverrideCount      = $overrideProperties.Count
    }

    return $result
}

<#
.SYNOPSIS
    AccÃ¨de aux versions masquÃ©es des propriÃ©tÃ©s.
.DESCRIPTION
    Cette fonction permet d'accÃ©der aux versions masquÃ©es des propriÃ©tÃ©s dans un type.
.PARAMETER Type
    Le type Ã  analyser.
.PARAMETER PropertyName
    Le nom de la propriÃ©tÃ© dont on veut accÃ©der aux versions masquÃ©es.
.PARAMETER IncludeNonPublic
    Indique si les propriÃ©tÃ©s non publiques doivent Ãªtre incluses dans l'analyse.
.EXAMPLE
    $shadowedVersions = Get-PropertyShadowedVersions -Type ([System.Exception]) -PropertyName "Message"
.OUTPUTS
    PSObject[] - Un tableau d'objets contenant des informations sur les versions masquÃ©es de la propriÃ©tÃ©.
#>
function Get-PropertyShadowedVersions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$PropertyName,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNonPublic
    )

    # RÃ©cupÃ©rer les flags de liaison
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance
    if ($IncludeNonPublic) {
        $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::NonPublic
    }

    # RÃ©cupÃ©rer la propriÃ©tÃ© dans le type courant
    $property = $Type.GetProperty($PropertyName, $bindingFlags)

    # CrÃ©er un tableau pour stocker les versions masquÃ©es
    $shadowedVersions = @()

    # Ajouter la propriÃ©tÃ© courante si elle existe
    if ($null -ne $property) {
        $shadowedVersions += [PSCustomObject]@{
            Property    = $property
            Type        = $Type
            IsCurrent   = $true
            IsBase      = $false
            IsInterface = $false
            Level       = 0
        }
    }

    # RÃ©cupÃ©rer les versions masquÃ©es dans les types de base
    $currentType = $Type.BaseType
    $level = 1

    while ($null -ne $currentType -and $currentType -ne [object]) {
        $baseProperty = $currentType.GetProperty($PropertyName, $bindingFlags)

        if ($null -ne $baseProperty) {
            $shadowedVersions += [PSCustomObject]@{
                Property    = $baseProperty
                Type        = $currentType
                IsCurrent   = $false
                IsBase      = $true
                IsInterface = $false
                Level       = $level
            }
        }

        $currentType = $currentType.BaseType
        $level++
    }

    # RÃ©cupÃ©rer les versions masquÃ©es dans les interfaces
    $interfaces = $Type.GetInterfaces()
    foreach ($interface in $interfaces) {
        $interfaceProperty = $interface.GetProperty($PropertyName, $bindingFlags)

        if ($null -ne $interfaceProperty) {
            $shadowedVersions += [PSCustomObject]@{
                Property    = $interfaceProperty
                Type        = $interface
                IsCurrent   = $false
                IsBase      = $false
                IsInterface = $true
                Level       = 0  # Les interfaces sont au mÃªme niveau
            }
        }
    }

    return $shadowedVersions
}

#endregion

#region Fusion des propriÃ©tÃ©s

<#
.SYNOPSIS
    ImplÃ©mente les stratÃ©gies de fusion pour les propriÃ©tÃ©s.
.DESCRIPTION
    Cette fonction implÃ©mente diffÃ©rentes stratÃ©gies de fusion (union, intersection, etc.) pour les propriÃ©tÃ©s de plusieurs types.
.PARAMETER Types
    Les types dont on veut fusionner les propriÃ©tÃ©s.
.PARAMETER Strategy
    La stratÃ©gie de fusion Ã  utiliser. Les valeurs possibles sont : "Union", "Intersection", "Difference", "SymmetricDifference".
.PARAMETER IncludeNonPublic
    Indique si les propriÃ©tÃ©s non publiques doivent Ãªtre incluses dans la fusion.
.EXAMPLE
    $mergedProperties = Merge-TypeProperties -Types @([System.String], [System.Object]) -Strategy "Union"
.OUTPUTS
    PSObject - Un objet contenant les propriÃ©tÃ©s fusionnÃ©es selon la stratÃ©gie spÃ©cifiÃ©e.
#>
function Merge-TypeProperties {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type[]]$Types,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Union", "Intersection", "Difference", "SymmetricDifference")]
        [string]$Strategy = "Union",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNonPublic
    )

    # VÃ©rifier qu'il y a au moins un type
    if ($Types.Count -eq 0) {
        throw "Au moins un type doit Ãªtre spÃ©cifiÃ©."
    }

    # RÃ©cupÃ©rer les flags de liaison
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance
    if ($IncludeNonPublic) {
        $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::NonPublic
    }

    # RÃ©cupÃ©rer les propriÃ©tÃ©s de chaque type
    $propertiesByType = @{}
    foreach ($type in $Types) {
        $properties = $type.GetProperties($bindingFlags)
        $propertiesByType[$type.FullName] = $properties
    }

    # CrÃ©er des ensembles de noms de propriÃ©tÃ©s pour chaque type
    $propertyNameSets = @{}
    foreach ($typeName in $propertiesByType.Keys) {
        $propertyNames = $propertiesByType[$typeName] | ForEach-Object { $_.Name }
        $propertyNameSets[$typeName] = [System.Collections.Generic.HashSet[string]]::new($propertyNames)
    }

    # Appliquer la stratÃ©gie de fusion
    $resultPropertyNames = $null

    switch ($Strategy) {
        "Union" {
            # Union de toutes les propriÃ©tÃ©s
            $resultPropertyNames = [System.Collections.Generic.HashSet[string]]::new()
            foreach ($set in $propertyNameSets.Values) {
                $resultPropertyNames.UnionWith($set)
            }
        }
        "Intersection" {
            # Intersection de toutes les propriÃ©tÃ©s
            $resultPropertyNames = $propertyNameSets[$propertyNameSets.Keys[0]].Clone()
            for ($i = 1; $i -lt $propertyNameSets.Count; $i++) {
                $resultPropertyNames.IntersectWith($propertyNameSets[$propertyNameSets.Keys[$i]])
            }
        }
        "Difference" {
            # DiffÃ©rence entre le premier type et tous les autres
            $resultPropertyNames = $propertyNameSets[$propertyNameSets.Keys[0]].Clone()
            for ($i = 1; $i -lt $propertyNameSets.Count; $i++) {
                $resultPropertyNames.ExceptWith($propertyNameSets[$propertyNameSets.Keys[$i]])
            }
        }
        "SymmetricDifference" {
            # DiffÃ©rence symÃ©trique entre tous les types
            $resultPropertyNames = [System.Collections.Generic.HashSet[string]]::new()
            foreach ($set in $propertyNameSets.Values) {
                $resultPropertyNames.SymmetricExceptWith($set)
            }
        }
    }

    # CrÃ©er un dictionnaire pour stocker les propriÃ©tÃ©s fusionnÃ©es
    $mergedProperties = @{}

    # Pour chaque nom de propriÃ©tÃ© dans le rÃ©sultat, rÃ©cupÃ©rer les propriÃ©tÃ©s correspondantes
    foreach ($propertyName in $resultPropertyNames) {
        $propertiesWithName = @()

        foreach ($typeName in $propertiesByType.Keys) {
            $propertiesWithName += $propertiesByType[$typeName] | Where-Object { $_.Name -eq $propertyName }
        }

        $mergedProperties[$propertyName] = $propertiesWithName
    }

    # CrÃ©er l'objet rÃ©sultat
    $result = [PSCustomObject]@{
        Types            = $Types
        Strategy         = $Strategy
        PropertyNames    = $resultPropertyNames
        MergedProperties = $mergedProperties
        Count            = $resultPropertyNames.Count
    }

    return $result
}

<#
.SYNOPSIS
    RÃ©sout les conflits de fusion entre les propriÃ©tÃ©s.
.DESCRIPTION
    Cette fonction rÃ©sout les conflits de fusion entre les propriÃ©tÃ©s de plusieurs types, en utilisant diffÃ©rentes stratÃ©gies de rÃ©solution.
.PARAMETER MergedProperties
    Les propriÃ©tÃ©s fusionnÃ©es Ã  rÃ©soudre.
.PARAMETER ResolutionStrategy
    La stratÃ©gie de rÃ©solution Ã  utiliser. Les valeurs possibles sont : "First", "Last", "MostDerived", "LeastDerived", "Custom".
.PARAMETER CustomResolver
    Un script block personnalisÃ© pour rÃ©soudre les conflits. UtilisÃ© uniquement avec la stratÃ©gie "Custom".
.EXAMPLE
    $resolvedProperties = Resolve-PropertyMergeConflicts -MergedProperties $mergedProperties -ResolutionStrategy "MostDerived"
.OUTPUTS
    PSObject - Un objet contenant les propriÃ©tÃ©s rÃ©solues selon la stratÃ©gie spÃ©cifiÃ©e.
#>
function Resolve-PropertyMergeConflicts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSObject]$MergedProperties,

        [Parameter(Mandatory = $false)]
        [ValidateSet("First", "Last", "MostDerived", "LeastDerived", "Custom")]
        [string]$ResolutionStrategy = "MostDerived",

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomResolver
    )

    # VÃ©rifier que le rÃ©solveur personnalisÃ© est spÃ©cifiÃ© si la stratÃ©gie est "Custom"
    if ($ResolutionStrategy -eq "Custom" -and $null -eq $CustomResolver) {
        throw "Un rÃ©solveur personnalisÃ© doit Ãªtre spÃ©cifiÃ© avec la stratÃ©gie 'Custom'."
    }

    # CrÃ©er un dictionnaire pour stocker les propriÃ©tÃ©s rÃ©solues
    $resolvedProperties = @{}

    # Pour chaque nom de propriÃ©tÃ©, rÃ©soudre les conflits
    foreach ($propertyName in $MergedProperties.PropertyNames) {
        $propertiesWithName = $MergedProperties.MergedProperties[$propertyName]

        # S'il n'y a qu'une seule propriÃ©tÃ©, il n'y a pas de conflit
        if ($propertiesWithName.Count -eq 1) {
            $resolvedProperties[$propertyName] = $propertiesWithName[0]
            continue
        }

        # RÃ©soudre le conflit selon la stratÃ©gie spÃ©cifiÃ©e
        $resolvedProperty = $null

        switch ($ResolutionStrategy) {
            "First" {
                # Prendre la premiÃ¨re propriÃ©tÃ©
                $resolvedProperty = $propertiesWithName[0]
            }
            "Last" {
                # Prendre la derniÃ¨re propriÃ©tÃ©
                $resolvedProperty = $propertiesWithName[-1]
            }
            "MostDerived" {
                # Prendre la propriÃ©tÃ© du type le plus dÃ©rivÃ©
                $resolvedProperty = $propertiesWithName | Sort-Object { $_.DeclaringType.IsSubclassOf($_.DeclaringType) } -Descending | Select-Object -First 1
            }
            "LeastDerived" {
                # Prendre la propriÃ©tÃ© du type le moins dÃ©rivÃ©
                $resolvedProperty = $propertiesWithName | Sort-Object { $_.DeclaringType.IsSubclassOf($_.DeclaringType) } | Select-Object -First 1
            }
            "Custom" {
                # Utiliser le rÃ©solveur personnalisÃ©
                $resolvedProperty = & $CustomResolver -Properties $propertiesWithName
            }
        }

        $resolvedProperties[$propertyName] = $resolvedProperty
    }

    # CrÃ©er l'objet rÃ©sultat
    $result = [PSCustomObject]@{
        OriginalProperties = $MergedProperties
        ResolutionStrategy = $ResolutionStrategy
        ResolvedProperties = $resolvedProperties
        Count              = $resolvedProperties.Count
    }

    return $result
}

<#
.SYNOPSIS
    DÃ©veloppe les fonctions de dÃ©duplication des propriÃ©tÃ©s.
.DESCRIPTION
    Cette fonction dÃ©duplique les propriÃ©tÃ©s en fonction de diffÃ©rents critÃ¨res, comme le nom, le type, ou les attributs.
.PARAMETER Properties
    Les propriÃ©tÃ©s Ã  dÃ©dupliquer.
.PARAMETER DeduplicationCriteria
    Les critÃ¨res de dÃ©duplication Ã  utiliser. Les valeurs possibles sont : "Name", "Type", "Attributes", "All".
.EXAMPLE
    $deduplicatedProperties = Get-DeduplicatedProperties -Properties $properties -DeduplicationCriteria "Name"
.OUTPUTS
    System.Reflection.PropertyInfo[] - Un tableau des propriÃ©tÃ©s dÃ©dupliquÃ©es selon les critÃ¨res spÃ©cifiÃ©s.
#>
function Get-DeduplicatedProperties {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Reflection.PropertyInfo[]]$Properties,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Name", "Type", "Attributes", "All")]
        [string]$DeduplicationCriteria = "Name"
    )

    # CrÃ©er un dictionnaire pour stocker les propriÃ©tÃ©s dÃ©dupliquÃ©es
    $deduplicatedProperties = @{}

    # DÃ©dupliquer les propriÃ©tÃ©s selon les critÃ¨res spÃ©cifiÃ©s
    foreach ($property in $Properties) {
        $key = $null

        switch ($DeduplicationCriteria) {
            "Name" {
                # DÃ©dupliquer par nom
                $key = $property.Name
            }
            "Type" {
                # DÃ©dupliquer par type
                $key = "$($property.Name)_$($property.PropertyType.FullName)"
            }
            "Attributes" {
                # DÃ©dupliquer par attributs
                $attributes = $property.GetCustomAttributes($false) | ForEach-Object { $_.GetType().FullName }
                $attributesKey = $attributes -join "_"
                $key = "$($property.Name)_$($property.PropertyType.FullName)_$attributesKey"
            }
            "All" {
                # DÃ©dupliquer par tous les critÃ¨res
                $attributes = $property.GetCustomAttributes($false) | ForEach-Object { $_.GetType().FullName }
                $attributesKey = $attributes -join "_"
                $declaringType = $property.DeclaringType.FullName
                $key = "$($property.Name)_$($property.PropertyType.FullName)_$declaringType_$attributesKey"
            }
        }

        if (-not $deduplicatedProperties.ContainsKey($key)) {
            $deduplicatedProperties[$key] = $property
        }
    }

    return $deduplicatedProperties.Values
}

<#
.SYNOPSIS
    Personnalise les stratÃ©gies de fusion des propriÃ©tÃ©s.
.DESCRIPTION
    Cette fonction permet de personnaliser les stratÃ©gies de fusion des propriÃ©tÃ©s en spÃ©cifiant des rÃ¨gles personnalisÃ©es.
.PARAMETER Types
    Les types dont on veut fusionner les propriÃ©tÃ©s.
.PARAMETER Rules
    Les rÃ¨gles de fusion personnalisÃ©es. Chaque rÃ¨gle est un hashtable avec les clÃ©s "PropertyName", "Strategy", et "Resolver".
.PARAMETER DefaultStrategy
    La stratÃ©gie de fusion par dÃ©faut Ã  utiliser pour les propriÃ©tÃ©s qui ne correspondent Ã  aucune rÃ¨gle.
.PARAMETER IncludeNonPublic
    Indique si les propriÃ©tÃ©s non publiques doivent Ãªtre incluses dans la fusion.
.EXAMPLE
    $rules = @(
        @{ PropertyName = "Length"; Strategy = "First"; Resolver = $null },
        @{ PropertyName = "*"; Strategy = "MostDerived"; Resolver = $null }
    )
    $customMergedProperties = Merge-TypePropertiesWithRules -Types @([System.String], [System.Object]) -Rules $rules
.OUTPUTS
    PSObject - Un objet contenant les propriÃ©tÃ©s fusionnÃ©es selon les rÃ¨gles spÃ©cifiÃ©es.
#>
function Merge-TypePropertiesWithRules {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type[]]$Types,

        [Parameter(Mandatory = $true, Position = 1)]
        [hashtable[]]$Rules,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Union", "Intersection", "Difference", "SymmetricDifference")]
        [string]$DefaultStrategy = "Union",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNonPublic
    )

    # Fusionner les propriÃ©tÃ©s avec la stratÃ©gie par dÃ©faut
    $mergedProperties = Merge-TypeProperties -Types $Types -Strategy $DefaultStrategy -IncludeNonPublic:$IncludeNonPublic

    # CrÃ©er un dictionnaire pour stocker les propriÃ©tÃ©s rÃ©solues
    $resolvedProperties = @{}

    # Pour chaque nom de propriÃ©tÃ©, appliquer les rÃ¨gles correspondantes
    foreach ($propertyName in $mergedProperties.PropertyNames) {
        $propertiesWithName = $mergedProperties.MergedProperties[$propertyName]

        # Trouver la rÃ¨gle correspondante
        $matchingRule = $null

        foreach ($rule in $Rules) {
            if ($rule.PropertyName -eq $propertyName -or $rule.PropertyName -eq "*") {
                $matchingRule = $rule
                break
            }
        }

        # S'il n'y a pas de rÃ¨gle correspondante, utiliser la stratÃ©gie par dÃ©faut
        if ($null -eq $matchingRule) {
            $resolvedProperty = Resolve-PropertyMergeConflicts -MergedProperties $mergedProperties -ResolutionStrategy "MostDerived"
            $resolvedProperties[$propertyName] = $resolvedProperty.ResolvedProperties[$propertyName]
            continue
        }

        # Appliquer la rÃ¨gle
        $resolutionStrategy = $matchingRule.Strategy
        $resolver = $matchingRule.Resolver

        if ($resolutionStrategy -eq "Custom" -and $null -eq $resolver) {
            throw "Un rÃ©solveur personnalisÃ© doit Ãªtre spÃ©cifiÃ© avec la stratÃ©gie 'Custom'."
        }

        $resolvedProperty = Resolve-PropertyMergeConflicts -MergedProperties $mergedProperties -ResolutionStrategy $resolutionStrategy -CustomResolver $resolver
        $resolvedProperties[$propertyName] = $resolvedProperty.ResolvedProperties[$propertyName]
    }

    # CrÃ©er l'objet rÃ©sultat
    $result = [PSCustomObject]@{
        Types              = $Types
        Rules              = $Rules
        DefaultStrategy    = $DefaultStrategy
        MergedProperties   = $mergedProperties
        ResolvedProperties = $resolvedProperties
        Count              = $resolvedProperties.Count
    }

    return $result
}

#endregion
