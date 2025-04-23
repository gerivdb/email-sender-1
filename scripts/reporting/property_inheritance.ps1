<#
.SYNOPSIS
    Fonctions pour la récupération et l'analyse des propriétés héritées dans les types .NET.
.DESCRIPTION
    Ce module fournit des fonctions pour analyser la hiérarchie d'héritage des types, résoudre les propriétés masquées,
    fusionner les propriétés héritées et gérer les propriétés virtuelles.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
#>

#region Analyse de la hiérarchie

<#
.SYNOPSIS
    Construit l'arbre d'héritage d'un type.
.DESCRIPTION
    Cette fonction construit l'arbre d'héritage complet d'un type, incluant les classes de base et les interfaces implémentées.
.PARAMETER Type
    Le type dont on veut construire l'arbre d'héritage.
.PARAMETER IncludeInterfaces
    Indique si les interfaces implémentées doivent être incluses dans l'arbre d'héritage.
.PARAMETER MaxDepth
    La profondeur maximale de l'arbre d'héritage. Par défaut, il n'y a pas de limite.
.EXAMPLE
    $inheritanceTree = Get-TypeInheritanceTree -Type ([System.String])
.OUTPUTS
    PSObject - Un objet représentant l'arbre d'héritage du type.
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

    # Fonction récursive pour construire l'arbre
    function Build-InheritanceTree {
        param (
            [type]$CurrentType,
            [int]$CurrentDepth = 0,
            [System.Collections.Generic.HashSet[type]]$VisitedTypes = (New-Object System.Collections.Generic.HashSet[type])
        )

        # Vérifier si le type a déjà été visité (pour éviter les cycles)
        if ($VisitedTypes.Contains($CurrentType)) {
            return $null
        }

        # Vérifier si la profondeur maximale est atteinte
        if ($MaxDepth -ne -1 -and $CurrentDepth -gt $MaxDepth) {
            return $null
        }

        # Ajouter le type courant aux types visités
        [void]$VisitedTypes.Add($CurrentType)

        # Créer le nœud pour le type courant
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

        # Ajouter les interfaces implémentées si demandé
        if ($IncludeInterfaces) {
            $interfaces = $CurrentType.GetInterfaces()
            foreach ($interface in $interfaces) {
                # Vérifier si l'interface est directement implémentée par ce type
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

    # Construire l'arbre d'héritage
    $visitedTypes = New-Object System.Collections.Generic.HashSet[type]
    $tree = Build-InheritanceTree -CurrentType $Type -VisitedTypes $visitedTypes

    return $tree
}

<#
.SYNOPSIS
    Parcourt l'arbre d'héritage d'un type de manière ascendante.
.DESCRIPTION
    Cette fonction parcourt l'arbre d'héritage d'un type de manière ascendante (du type vers ses ancêtres).
.PARAMETER Type
    Le type dont on veut parcourir l'arbre d'héritage.
.PARAMETER IncludeInterfaces
    Indique si les interfaces implémentées doivent être incluses dans le parcours.
.PARAMETER MaxDepth
    La profondeur maximale du parcours. Par défaut, il n'y a pas de limite.
.EXAMPLE
    $ancestors = Get-TypeAncestors -Type ([System.String])
.OUTPUTS
    Type[] - Un tableau des types ancêtres du type spécifié.
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

    # Créer un tableau pour stocker les ancêtres
    $ancestors = @()

    # Parcourir la hiérarchie des classes de base
    $currentType = $Type.BaseType
    $currentDepth = 1

    while ($null -ne $currentType -and $currentType -ne [object]) {
        # Vérifier si la profondeur maximale est atteinte
        if ($MaxDepth -ne -1 -and $currentDepth -gt $MaxDepth) {
            break
        }

        $ancestors += $currentType
        $currentType = $currentType.BaseType
        $currentDepth++
    }

    # Ajouter les interfaces si demandé
    if ($IncludeInterfaces) {
        $interfaces = $Type.GetInterfaces()
        $ancestors += $interfaces
    }

    return $ancestors
}

<#
.SYNOPSIS
    Parcourt l'arbre d'héritage d'un type de manière descendante.
.DESCRIPTION
    Cette fonction parcourt l'arbre d'héritage d'un type de manière descendante (du type vers ses descendants).
.PARAMETER Type
    Le type dont on veut parcourir l'arbre d'héritage.
.PARAMETER Assembly
    L'assembly dans lequel rechercher les types descendants. Par défaut, tous les assemblies chargés sont analysés.
.PARAMETER IncludeInterfaces
    Indique si les interfaces implémentées doivent être incluses dans le parcours.
.PARAMETER MaxDepth
    La profondeur maximale du parcours. Par défaut, il n'y a pas de limite.
.EXAMPLE
    $descendants = Get-TypeDescendants -Type ([System.Exception])
.OUTPUTS
    Type[] - Un tableau des types descendants du type spécifié.
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

    # Fonction récursive pour trouver les descendants
    function Find-Descendants {
        param (
            [type]$CurrentType,
            [int]$CurrentDepth = 0,
            [System.Collections.Generic.HashSet[type]]$VisitedTypes = (New-Object System.Collections.Generic.HashSet[type])
        )

        # Vérifier si le type a déjà été visité (pour éviter les cycles)
        if ($VisitedTypes.Contains($CurrentType)) {
            return @()
        }

        # Vérifier si la profondeur maximale est atteinte
        if ($MaxDepth -ne -1 -and $CurrentDepth -gt $MaxDepth) {
            return @()
        }

        # Ajouter le type courant aux types visités
        [void]$VisitedTypes.Add($CurrentType)

        # Récupérer tous les types à analyser
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

        # Récupérer les descendants indirects (récursivement)
        $allDescendants = $directDescendants
        foreach ($descendant in $directDescendants) {
            $indirectDescendants = Find-Descendants -CurrentType $descendant -CurrentDepth ($CurrentDepth + 1) -VisitedTypes $VisitedTypes
            $allDescendants += $indirectDescendants
        }

        return $allDescendants
    }

    # Trouver tous les descendants
    $visitedTypes = New-Object System.Collections.Generic.HashSet[type]

    # Limiter la recherche à l'assembly courant pour éviter les performances médiocres
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
    Détecte les cycles d'héritage dans un type.
.DESCRIPTION
    Cette fonction détecte les cycles d'héritage dans un type, ce qui peut se produire avec des interfaces génériques.
.PARAMETER Type
    Le type à analyser pour détecter les cycles d'héritage.
.PARAMETER IncludeInterfaces
    Indique si les interfaces implémentées doivent être incluses dans l'analyse.
.EXAMPLE
    $cycles = Test-TypeInheritanceCycles -Type ([System.Collections.Generic.IEnumerable`1[System.String]])
.OUTPUTS
    PSObject - Un objet contenant des informations sur les cycles d'héritage détectés.
#>
function Test-TypeInheritanceCycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInterfaces
    )

    # Fonction récursive pour détecter les cycles
    function Find-InheritanceCycles {
        param (
            [type]$CurrentType,
            [int]$Depth = 0,
            [System.Collections.Generic.List[type]]$Path = (New-Object System.Collections.Generic.List[type])
        )

        # Vérifier si le type a déjà été visité
        if ($Path.Contains($CurrentType)) {
            # Cycle détecté
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

        # Vérifier le type de base
        if ($null -ne $CurrentType.BaseType -and $CurrentType.BaseType -ne [object]) {
            $result = Detect-Cycles -CurrentType $CurrentType.BaseType -Depth ($Depth + 1) -Path $Path
            if ($result.HasCycle) {
                return $result
            }
        }

        # Vérifier les interfaces si demandé
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

        # Aucun cycle détecté
        return @{
            HasCycle   = $false
            Cycle      = $null
            CycleStart = $null
        }
    }

    # Détecter les cycles
    $path = New-Object System.Collections.Generic.List[type]
    $result = Find-InheritanceCycles -CurrentType $Type -Path $path

    # Créer l'objet résultat
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
    Visualise la hiérarchie d'héritage d'un type.
.DESCRIPTION
    Cette fonction génère une représentation visuelle de la hiérarchie d'héritage d'un type.
.PARAMETER Type
    Le type dont on veut visualiser la hiérarchie d'héritage.
.PARAMETER IncludeInterfaces
    Indique si les interfaces implémentées doivent être incluses dans la visualisation.
.PARAMETER MaxDepth
    La profondeur maximale de la hiérarchie à visualiser. Par défaut, il n'y a pas de limite.
.PARAMETER Format
    Le format de la visualisation. Les valeurs possibles sont : "Text", "ASCII", "Markdown".
.EXAMPLE
    $visualization = Get-TypeInheritanceVisualization -Type ([System.String]) -Format "ASCII"
.OUTPUTS
    String - Une représentation visuelle de la hiérarchie d'héritage du type.
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

    # Récupérer l'arbre d'héritage
    $tree = Get-TypeInheritanceTree -Type $Type -IncludeInterfaces:$IncludeInterfaces -MaxDepth $MaxDepth

    # Fonction récursive pour générer la visualisation
    function Format-InheritanceTree {
        param (
            [PSObject]$Node,
            [string]$Indent = "",
            [bool]$IsLast = $true,
            [string]$Format = "ASCII"
        )

        # Définir les caractères de formatage en fonction du format
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

        # Générer la ligne pour le nœud courant
        $line = ""
        if ($Node.Depth -eq 0) {
            $line = $Node.Type.FullName
        } else {
            $line = "$Indent$connector$($Node.Type.FullName)"
        }

        # Ajouter la ligne à la sortie
        $output = $line + "`n"

        # Générer les lignes pour les enfants
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

    # Générer la visualisation
    $visualization = Format-InheritanceTree -Node $tree -Format $Format

    return $visualization
}

#endregion

#region Résolution des propriétés masquées

<#
.SYNOPSIS
    Détecte les mots-clés new et override dans les propriétés.
.DESCRIPTION
    Cette fonction détecte les propriétés qui utilisent les mots-clés new et override pour masquer ou remplacer des propriétés héritées.
.PARAMETER Type
    Le type à analyser.
.PARAMETER IncludeNonPublic
    Indique si les propriétés non publiques doivent être incluses dans l'analyse.
.EXAMPLE
    $newOverrideProperties = Get-TypeNewOverrideProperties -Type ([System.Exception])
.OUTPUTS
    PSObject[] - Un tableau d'objets contenant des informations sur les propriétés qui utilisent new ou override.
#>
function Get-TypeNewOverrideProperties {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNonPublic
    )

    # Récupérer toutes les propriétés du type
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance
    if ($IncludeNonPublic) {
        $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::NonPublic
    }

    $properties = $Type.GetProperties($bindingFlags)

    # Récupérer les propriétés des types de base
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

    # Créer un tableau pour stocker les résultats
    $results = @()

    # Analyser chaque propriété
    foreach ($property in $properties) {
        # Vérifier si la propriété masque ou remplace une propriété héritée
        $isNew = $false
        $isOverride = $false
        $baseProperty = $null

        if ($baseProperties.ContainsKey($property.Name)) {
            $baseProperty = $baseProperties[$property.Name]

            # Vérifier si la propriété utilise new (masquage)
            if ($null -ne $property.GetMethod -and $null -ne $baseProperty.GetMethod) {
                $isNew = -not $property.GetMethod.IsVirtual -and -not $baseProperty.GetMethod.IsFinal
            }

            # Vérifier si la propriété utilise override (remplacement)
            if ($null -ne $property.GetMethod -and $null -ne $baseProperty.GetMethod) {
                $isOverride = $property.GetMethod.IsVirtual -and $property.GetMethod.GetBaseDefinition() -ne $property.GetMethod
            }
        }

        # Créer l'objet résultat si la propriété utilise new ou override
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
    Résout les conflits de noms entre les propriétés.
.DESCRIPTION
    Cette fonction résout les conflits de noms entre les propriétés d'un type et de ses types de base ou interfaces.
.PARAMETER Type
    Le type à analyser.
.PARAMETER IncludeInterfaces
    Indique si les interfaces implémentées doivent être incluses dans l'analyse.
.PARAMETER IncludeNonPublic
    Indique si les propriétés non publiques doivent être incluses dans l'analyse.
.EXAMPLE
    $nameConflicts = Resolve-TypePropertyNameConflicts -Type ([System.Exception])
.OUTPUTS
    PSObject[] - Un tableau d'objets contenant des informations sur les conflits de noms résolus.
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

    # Récupérer toutes les propriétés du type
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance
    if ($IncludeNonPublic) {
        $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::NonPublic
    }

    $properties = $Type.GetProperties($bindingFlags)

    # Créer un dictionnaire pour stocker les propriétés par nom
    $propertyMap = @{}
    foreach ($property in $properties) {
        if (-not $propertyMap.ContainsKey($property.Name)) {
            $propertyMap[$property.Name] = @()
        }
        $propertyMap[$property.Name] += @{ Property = $property; Type = $Type }
    }

    # Récupérer les propriétés des types de base
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

    # Récupérer les propriétés des interfaces si demandé
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
            # Déterminer la propriété qui a préséance
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
    Cette fonction analyse les patterns de shadowing (masquage) dans un type, comme les propriétés qui masquent des propriétés héritées.
.PARAMETER Type
    Le type à analyser.
.PARAMETER IncludeNonPublic
    Indique si les propriétés non publiques doivent être incluses dans l'analyse.
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

    # Récupérer les propriétés qui utilisent new ou override
    $newOverrideProperties = Get-TypeNewOverrideProperties -Type $Type -IncludeNonPublic:$IncludeNonPublic

    # Récupérer les conflits de noms
    $nameConflicts = Resolve-TypePropertyNameConflicts -Type $Type -IncludeInterfaces -IncludeNonPublic:$IncludeNonPublic

    # Identifier les différents patterns de shadowing
    $newProperties = $newOverrideProperties | Where-Object { $_.IsNew }
    $overrideProperties = $newOverrideProperties | Where-Object { $_.IsOverride }
    $interfaceConflicts = $nameConflicts | Where-Object { $_.ResolutionMethod -eq "Interface" }
    $inheritedConflicts = $nameConflicts | Where-Object { $_.ResolutionMethod -eq "Inherited" }

    # Créer l'objet résultat
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
    Accède aux versions masquées des propriétés.
.DESCRIPTION
    Cette fonction permet d'accéder aux versions masquées des propriétés dans un type.
.PARAMETER Type
    Le type à analyser.
.PARAMETER PropertyName
    Le nom de la propriété dont on veut accéder aux versions masquées.
.PARAMETER IncludeNonPublic
    Indique si les propriétés non publiques doivent être incluses dans l'analyse.
.EXAMPLE
    $shadowedVersions = Get-PropertyShadowedVersions -Type ([System.Exception]) -PropertyName "Message"
.OUTPUTS
    PSObject[] - Un tableau d'objets contenant des informations sur les versions masquées de la propriété.
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

    # Récupérer les flags de liaison
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance
    if ($IncludeNonPublic) {
        $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::NonPublic
    }

    # Récupérer la propriété dans le type courant
    $property = $Type.GetProperty($PropertyName, $bindingFlags)

    # Créer un tableau pour stocker les versions masquées
    $shadowedVersions = @()

    # Ajouter la propriété courante si elle existe
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

    # Récupérer les versions masquées dans les types de base
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

    # Récupérer les versions masquées dans les interfaces
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
                Level       = 0  # Les interfaces sont au même niveau
            }
        }
    }

    return $shadowedVersions
}

#endregion

#region Fusion des propriétés

<#
.SYNOPSIS
    Implémente les stratégies de fusion pour les propriétés.
.DESCRIPTION
    Cette fonction implémente différentes stratégies de fusion (union, intersection, etc.) pour les propriétés de plusieurs types.
.PARAMETER Types
    Les types dont on veut fusionner les propriétés.
.PARAMETER Strategy
    La stratégie de fusion à utiliser. Les valeurs possibles sont : "Union", "Intersection", "Difference", "SymmetricDifference".
.PARAMETER IncludeNonPublic
    Indique si les propriétés non publiques doivent être incluses dans la fusion.
.EXAMPLE
    $mergedProperties = Merge-TypeProperties -Types @([System.String], [System.Object]) -Strategy "Union"
.OUTPUTS
    PSObject - Un objet contenant les propriétés fusionnées selon la stratégie spécifiée.
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

    # Vérifier qu'il y a au moins un type
    if ($Types.Count -eq 0) {
        throw "Au moins un type doit être spécifié."
    }

    # Récupérer les flags de liaison
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance
    if ($IncludeNonPublic) {
        $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::NonPublic
    }

    # Récupérer les propriétés de chaque type
    $propertiesByType = @{}
    foreach ($type in $Types) {
        $properties = $type.GetProperties($bindingFlags)
        $propertiesByType[$type.FullName] = $properties
    }

    # Créer des ensembles de noms de propriétés pour chaque type
    $propertyNameSets = @{}
    foreach ($typeName in $propertiesByType.Keys) {
        $propertyNames = $propertiesByType[$typeName] | ForEach-Object { $_.Name }
        $propertyNameSets[$typeName] = [System.Collections.Generic.HashSet[string]]::new($propertyNames)
    }

    # Appliquer la stratégie de fusion
    $resultPropertyNames = $null

    switch ($Strategy) {
        "Union" {
            # Union de toutes les propriétés
            $resultPropertyNames = [System.Collections.Generic.HashSet[string]]::new()
            foreach ($set in $propertyNameSets.Values) {
                $resultPropertyNames.UnionWith($set)
            }
        }
        "Intersection" {
            # Intersection de toutes les propriétés
            $resultPropertyNames = $propertyNameSets[$propertyNameSets.Keys[0]].Clone()
            for ($i = 1; $i -lt $propertyNameSets.Count; $i++) {
                $resultPropertyNames.IntersectWith($propertyNameSets[$propertyNameSets.Keys[$i]])
            }
        }
        "Difference" {
            # Différence entre le premier type et tous les autres
            $resultPropertyNames = $propertyNameSets[$propertyNameSets.Keys[0]].Clone()
            for ($i = 1; $i -lt $propertyNameSets.Count; $i++) {
                $resultPropertyNames.ExceptWith($propertyNameSets[$propertyNameSets.Keys[$i]])
            }
        }
        "SymmetricDifference" {
            # Différence symétrique entre tous les types
            $resultPropertyNames = [System.Collections.Generic.HashSet[string]]::new()
            foreach ($set in $propertyNameSets.Values) {
                $resultPropertyNames.SymmetricExceptWith($set)
            }
        }
    }

    # Créer un dictionnaire pour stocker les propriétés fusionnées
    $mergedProperties = @{}

    # Pour chaque nom de propriété dans le résultat, récupérer les propriétés correspondantes
    foreach ($propertyName in $resultPropertyNames) {
        $propertiesWithName = @()

        foreach ($typeName in $propertiesByType.Keys) {
            $propertiesWithName += $propertiesByType[$typeName] | Where-Object { $_.Name -eq $propertyName }
        }

        $mergedProperties[$propertyName] = $propertiesWithName
    }

    # Créer l'objet résultat
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
    Résout les conflits de fusion entre les propriétés.
.DESCRIPTION
    Cette fonction résout les conflits de fusion entre les propriétés de plusieurs types, en utilisant différentes stratégies de résolution.
.PARAMETER MergedProperties
    Les propriétés fusionnées à résoudre.
.PARAMETER ResolutionStrategy
    La stratégie de résolution à utiliser. Les valeurs possibles sont : "First", "Last", "MostDerived", "LeastDerived", "Custom".
.PARAMETER CustomResolver
    Un script block personnalisé pour résoudre les conflits. Utilisé uniquement avec la stratégie "Custom".
.EXAMPLE
    $resolvedProperties = Resolve-PropertyMergeConflicts -MergedProperties $mergedProperties -ResolutionStrategy "MostDerived"
.OUTPUTS
    PSObject - Un objet contenant les propriétés résolues selon la stratégie spécifiée.
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

    # Vérifier que le résolveur personnalisé est spécifié si la stratégie est "Custom"
    if ($ResolutionStrategy -eq "Custom" -and $null -eq $CustomResolver) {
        throw "Un résolveur personnalisé doit être spécifié avec la stratégie 'Custom'."
    }

    # Créer un dictionnaire pour stocker les propriétés résolues
    $resolvedProperties = @{}

    # Pour chaque nom de propriété, résoudre les conflits
    foreach ($propertyName in $MergedProperties.PropertyNames) {
        $propertiesWithName = $MergedProperties.MergedProperties[$propertyName]

        # S'il n'y a qu'une seule propriété, il n'y a pas de conflit
        if ($propertiesWithName.Count -eq 1) {
            $resolvedProperties[$propertyName] = $propertiesWithName[0]
            continue
        }

        # Résoudre le conflit selon la stratégie spécifiée
        $resolvedProperty = $null

        switch ($ResolutionStrategy) {
            "First" {
                # Prendre la première propriété
                $resolvedProperty = $propertiesWithName[0]
            }
            "Last" {
                # Prendre la dernière propriété
                $resolvedProperty = $propertiesWithName[-1]
            }
            "MostDerived" {
                # Prendre la propriété du type le plus dérivé
                $resolvedProperty = $propertiesWithName | Sort-Object { $_.DeclaringType.IsSubclassOf($_.DeclaringType) } -Descending | Select-Object -First 1
            }
            "LeastDerived" {
                # Prendre la propriété du type le moins dérivé
                $resolvedProperty = $propertiesWithName | Sort-Object { $_.DeclaringType.IsSubclassOf($_.DeclaringType) } | Select-Object -First 1
            }
            "Custom" {
                # Utiliser le résolveur personnalisé
                $resolvedProperty = & $CustomResolver -Properties $propertiesWithName
            }
        }

        $resolvedProperties[$propertyName] = $resolvedProperty
    }

    # Créer l'objet résultat
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
    Développe les fonctions de déduplication des propriétés.
.DESCRIPTION
    Cette fonction déduplique les propriétés en fonction de différents critères, comme le nom, le type, ou les attributs.
.PARAMETER Properties
    Les propriétés à dédupliquer.
.PARAMETER DeduplicationCriteria
    Les critères de déduplication à utiliser. Les valeurs possibles sont : "Name", "Type", "Attributes", "All".
.EXAMPLE
    $deduplicatedProperties = Get-DeduplicatedProperties -Properties $properties -DeduplicationCriteria "Name"
.OUTPUTS
    System.Reflection.PropertyInfo[] - Un tableau des propriétés dédupliquées selon les critères spécifiés.
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

    # Créer un dictionnaire pour stocker les propriétés dédupliquées
    $deduplicatedProperties = @{}

    # Dédupliquer les propriétés selon les critères spécifiés
    foreach ($property in $Properties) {
        $key = $null

        switch ($DeduplicationCriteria) {
            "Name" {
                # Dédupliquer par nom
                $key = $property.Name
            }
            "Type" {
                # Dédupliquer par type
                $key = "$($property.Name)_$($property.PropertyType.FullName)"
            }
            "Attributes" {
                # Dédupliquer par attributs
                $attributes = $property.GetCustomAttributes($false) | ForEach-Object { $_.GetType().FullName }
                $attributesKey = $attributes -join "_"
                $key = "$($property.Name)_$($property.PropertyType.FullName)_$attributesKey"
            }
            "All" {
                # Dédupliquer par tous les critères
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
    Personnalise les stratégies de fusion des propriétés.
.DESCRIPTION
    Cette fonction permet de personnaliser les stratégies de fusion des propriétés en spécifiant des règles personnalisées.
.PARAMETER Types
    Les types dont on veut fusionner les propriétés.
.PARAMETER Rules
    Les règles de fusion personnalisées. Chaque règle est un hashtable avec les clés "PropertyName", "Strategy", et "Resolver".
.PARAMETER DefaultStrategy
    La stratégie de fusion par défaut à utiliser pour les propriétés qui ne correspondent à aucune règle.
.PARAMETER IncludeNonPublic
    Indique si les propriétés non publiques doivent être incluses dans la fusion.
.EXAMPLE
    $rules = @(
        @{ PropertyName = "Length"; Strategy = "First"; Resolver = $null },
        @{ PropertyName = "*"; Strategy = "MostDerived"; Resolver = $null }
    )
    $customMergedProperties = Merge-TypePropertiesWithRules -Types @([System.String], [System.Object]) -Rules $rules
.OUTPUTS
    PSObject - Un objet contenant les propriétés fusionnées selon les règles spécifiées.
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

    # Fusionner les propriétés avec la stratégie par défaut
    $mergedProperties = Merge-TypeProperties -Types $Types -Strategy $DefaultStrategy -IncludeNonPublic:$IncludeNonPublic

    # Créer un dictionnaire pour stocker les propriétés résolues
    $resolvedProperties = @{}

    # Pour chaque nom de propriété, appliquer les règles correspondantes
    foreach ($propertyName in $mergedProperties.PropertyNames) {
        $propertiesWithName = $mergedProperties.MergedProperties[$propertyName]

        # Trouver la règle correspondante
        $matchingRule = $null

        foreach ($rule in $Rules) {
            if ($rule.PropertyName -eq $propertyName -or $rule.PropertyName -eq "*") {
                $matchingRule = $rule
                break
            }
        }

        # S'il n'y a pas de règle correspondante, utiliser la stratégie par défaut
        if ($null -eq $matchingRule) {
            $resolvedProperty = Resolve-PropertyMergeConflicts -MergedProperties $mergedProperties -ResolutionStrategy "MostDerived"
            $resolvedProperties[$propertyName] = $resolvedProperty.ResolvedProperties[$propertyName]
            continue
        }

        # Appliquer la règle
        $resolutionStrategy = $matchingRule.Strategy
        $resolver = $matchingRule.Resolver

        if ($resolutionStrategy -eq "Custom" -and $null -eq $resolver) {
            throw "Un résolveur personnalisé doit être spécifié avec la stratégie 'Custom'."
        }

        $resolvedProperty = Resolve-PropertyMergeConflicts -MergedProperties $mergedProperties -ResolutionStrategy $resolutionStrategy -CustomResolver $resolver
        $resolvedProperties[$propertyName] = $resolvedProperty.ResolvedProperties[$propertyName]
    }

    # Créer l'objet résultat
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
