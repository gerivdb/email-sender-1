<#
.SYNOPSIS
    Module de sÃ©lection de propriÃ©tÃ©s pour les styles Excel.
.DESCRIPTION
    Ce module fournit des fonctions pour sÃ©lectionner, filtrer et manipuler
    les propriÃ©tÃ©s des styles Excel lors des opÃ©rations de fusion.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
#>

# Importer les modules requis
# ...

# Variables globales pour les alias de types
$script:TypeAliases = @{}

#region Fonctions d'introspection des types

<#
.SYNOPSIS
    CrÃ©e un comparateur de chaÃ®nes personnalisÃ©.
.DESCRIPTION
    Cette fonction crÃ©e un comparateur de chaÃ®nes personnalisÃ© avec des options de sensibilitÃ© Ã  la casse,
    de normalisation et de culture.
.PARAMETER IgnoreCase
    Indique si la comparaison doit Ãªtre insensible Ã  la casse.
.PARAMETER Culture
    La culture Ã  utiliser pour la comparaison. Par dÃ©faut, utilise la culture invariante.
.PARAMETER IgnoreWhiteSpace
    Indique si les espaces blancs doivent Ãªtre ignorÃ©s lors de la comparaison.
.PARAMETER IgnoreNonAlphanumeric
    Indique si les caractÃ¨res non alphanumÃ©riques doivent Ãªtre ignorÃ©s lors de la comparaison.
.EXAMPLE
    $Comparer = New-StringComparer -IgnoreCase -IgnoreWhiteSpace
    $result = $Comparer.Equals("Hello World", "HELLOWORLD")
.OUTPUTS
    System.StringComparer - Un comparateur de chaÃ®nes personnalisÃ©.
#>
function New-StringComparer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$IgnoreCase,

        [Parameter(Mandatory = $false)]
        [System.Globalization.CultureInfo]$Culture,

        [Parameter(Mandatory = $false)]
        [switch]$IgnoreWhiteSpace,

        [Parameter(Mandatory = $false)]
        [switch]$IgnoreNonAlphanumeric
    )

    # DÃ©terminer le comparateur de base
    $baseComparer = if ($null -eq $Culture) {
        if ($IgnoreCase) {
            [StringComparer]::InvariantCultureIgnoreCase
        } else {
            [StringComparer]::InvariantCulture
        }
    } else {
        if ($IgnoreCase) {
            [StringComparer]::Create($Culture, $true)
        } else {
            [StringComparer]::Create($Culture, $false)
        }
    }

    # Si aucune option supplÃ©mentaire n'est spÃ©cifiÃ©e, retourner le comparateur de base
    if (-not $IgnoreWhiteSpace -and -not $IgnoreNonAlphanumeric) {
        return $baseComparer
    }

    # CrÃ©er un comparateur personnalisÃ© avec les options spÃ©cifiÃ©es
    $customComparer = [PSCustomObject]@{
        BaseComparer          = $baseComparer
        IgnoreWhiteSpace      = $IgnoreWhiteSpace
        IgnoreNonAlphanumeric = $IgnoreNonAlphanumeric
    }

    # Ajouter les mÃ©thodes du comparateur
    $customComparer | Add-Member -MemberType ScriptMethod -Name "Equals" -Value {
        param([string]$x, [string]$y)

        # Normaliser les chaÃ®nes selon les options
        if ($this.IgnoreWhiteSpace) {
            $x = $x -replace '\s', ''
            $y = $y -replace '\s', ''
        }

        if ($this.IgnoreNonAlphanumeric) {
            $x = $x -replace '[^a-zA-Z0-9]', ''
            $y = $y -replace '[^a-zA-Z0-9]', ''
        }

        # Comparer les chaÃ®nes normalisÃ©es
        return $this.BaseComparer.Equals($x, $y)
    } -Force

    $customComparer | Add-Member -MemberType ScriptMethod -Name "Compare" -Value {
        param([string]$x, [string]$y)

        # Normaliser les chaÃ®nes selon les options
        if ($this.IgnoreWhiteSpace) {
            $x = $x -replace '\s', ''
            $y = $y -replace '\s', ''
        }

        if ($this.IgnoreNonAlphanumeric) {
            $x = $x -replace '[^a-zA-Z0-9]', ''
            $y = $y -replace '[^a-zA-Z0-9]', ''
        }

        # Comparer les chaÃ®nes normalisÃ©es
        return $this.BaseComparer.Compare($x, $y)
    } -Force

    $customComparer | Add-Member -MemberType ScriptMethod -Name "GetHashCode" -Value {
        param([string]$obj)

        # Normaliser la chaÃ®ne selon les options
        if ($this.IgnoreWhiteSpace) {
            $obj = $obj -replace '\s', ''
        }

        if ($this.IgnoreNonAlphanumeric) {
            $obj = $obj -replace '[^a-zA-Z0-9]', ''
        }

        # Calculer le code de hachage de la chaÃ®ne normalisÃ©e
        return $this.BaseComparer.GetHashCode($obj)
    } -Force

    return $customComparer
}

<#
.SYNOPSIS
    RÃ©cupÃ¨re un type par son nom qualifiÃ© complet.
.DESCRIPTION
    Cette fonction rÃ©cupÃ¨re un type par son nom qualifiÃ© complet, en effectuant
    une recherche dans les assemblies chargÃ©es ou spÃ©cifiÃ©es.
.PARAMETER TypeName
    Le nom qualifiÃ© complet du type Ã  rÃ©cupÃ©rer.
.PARAMETER Assemblies
    Les assemblies dans lesquelles rechercher le type. Si non spÃ©cifiÃ©, recherche dans toutes les assemblies chargÃ©es.
.PARAMETER IgnoreCase
    Indique si la recherche doit Ãªtre insensible Ã  la casse.
.PARAMETER ThrowOnError
    Indique si une exception doit Ãªtre levÃ©e en cas d'erreur de rÃ©solution.
.PARAMETER ResolveCollisions
    Indique comment rÃ©soudre les collisions de noms. Les valeurs possibles sont : FirstMatch, LastMatch, ThrowOnCollision, Interactive.
.PARAMETER AssemblyPriority
    Les assemblies prioritaires lors de la rÃ©solution des collisions. Les types trouvÃ©s dans ces assemblies seront prÃ©fÃ©rÃ©s.
.EXAMPLE
    $Type = Get-TypeByQualifiedName -TypeName "System.String"
.EXAMPLE
    $Type = Get-TypeByQualifiedName -TypeName "MyNamespace.MyClass" -Assemblies $MyAssembly -IgnoreCase
.EXAMPLE
    $Type = Get-TypeByQualifiedName -TypeName "MyNamespace.MyClass" -ResolveCollisions "Interactive"
.OUTPUTS
    System.Type - Le type rÃ©cupÃ©rÃ©, ou $null si le type n'a pas Ã©tÃ© trouvÃ© et ThrowOnError est $false.
#>
function Get-TypeByQualifiedName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$TypeName,

        [Parameter(Mandatory = $false)]
        [System.Reflection.Assembly[]]$Assemblies,

        [Parameter(Mandatory = $false)]
        [switch]$IgnoreCase,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnError,

        [Parameter(Mandatory = $false)]
        [ValidateSet("FirstMatch", "LastMatch", "ThrowOnCollision", "Interactive")]
        [string]$ResolveCollisions = "FirstMatch",

        [Parameter(Mandatory = $false)]
        [System.Reflection.Assembly[]]$AssemblyPriority
    )

    # VÃ©rifier si le nom du type est valide
    if ([string]::IsNullOrWhiteSpace($TypeName)) {
        if ($ThrowOnError) {
            throw "Le nom du type ne peut pas Ãªtre vide."
        }
        return $null
    }

    # RÃ©soudre les alias de types
    $resolvedTypeName = Resolve-TypeAlias -TypeName $TypeName
    if ($resolvedTypeName -ne $TypeName) {
        Write-Verbose "Alias '$TypeName' rÃ©solu en '$resolvedTypeName'."
        $TypeName = $resolvedTypeName
    }

    # Essayer d'abord la mÃ©thode Type.GetType qui est la plus rapide
    try {
        $type = [Type]::GetType($TypeName, $false, $IgnoreCase)
        if ($null -ne $type) {
            Write-Verbose "Type '$TypeName' trouvÃ© avec Type.GetType."
            return $type
        }
    } catch {
        Write-Verbose "Erreur lors de la recherche du type avec Type.GetType: $($_.Exception.Message)"
    }

    # Si aucune assembly n'est spÃ©cifiÃ©e, utiliser toutes les assemblies chargÃ©es
    if ($null -eq $Assemblies -or $Assemblies.Count -eq 0) {
        $Assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
        Write-Verbose "Recherche dans toutes les assemblies chargÃ©es ($($Assemblies.Count) assemblies)."
    } else {
        Write-Verbose "Recherche dans les assemblies spÃ©cifiÃ©es ($($Assemblies.Count) assemblies)."
    }

    # Fonction pour parser le nom du type et extraire l'espace de noms et le nom de type
    $typeInfo = ConvertFrom-TypeName -TypeName $TypeName
    $namespace = $typeInfo.Namespace
    $simpleTypeName = $typeInfo.TypeName

    # Rechercher tous les types correspondants dans les assemblies spÃ©cifiÃ©es
    $matchingTypes = @()

    foreach ($assembly in $Assemblies) {
        try {
            # Essayer d'abord avec le nom qualifiÃ© complet
            $type = $assembly.GetType($TypeName, $false, $IgnoreCase)
            if ($null -ne $type) {
                Write-Verbose "Type '$TypeName' trouvÃ© dans l'assembly '$($assembly.FullName)'."
                $matchingTypes += @{
                    Type      = $type
                    Assembly  = $assembly
                    MatchType = "FullName"
                    Priority  = if ($null -ne $AssemblyPriority -and $AssemblyPriority -contains $assembly) { 1 } else { 0 }
                }
            }

            # Si le type n'est pas trouvÃ©, essayer de rechercher par espace de noms et nom simple
            if (-not [string]::IsNullOrEmpty($namespace) -and -not [string]::IsNullOrEmpty($simpleTypeName)) {
                $types = $assembly.GetTypes() | Where-Object {
                    if ($IgnoreCase) {
                        return $_.Namespace -ieq $namespace -and $_.Name -ieq $simpleTypeName
                    } else {
                        return $_.Namespace -eq $namespace -and $_.Name -eq $simpleTypeName
                    }
                }

                if ($null -ne $types -and $types.Count -gt 0) {
                    foreach ($t in $types) {
                        Write-Verbose "Type '$namespace.$simpleTypeName' trouvÃ© dans l'assembly '$($assembly.FullName)'."
                        $matchingTypes += @{
                            Type      = $t
                            Assembly  = $assembly
                            MatchType = "NamespaceAndName"
                            Priority  = if ($null -ne $AssemblyPriority -and $AssemblyPriority -contains $assembly) { 1 } else { 0 }
                        }
                    }
                }
            }
        } catch {
            Write-Verbose "Erreur lors de la recherche du type dans l'assembly '$($assembly.FullName)': $($_.Exception.Message)"
        }
    }

    # Si aucun type n'est trouvÃ©, retourner null ou lever une exception
    if ($matchingTypes.Count -eq 0) {
        if ($ThrowOnError) {
            throw "Le type '$TypeName' n'a pas Ã©tÃ© trouvÃ© dans les assemblies spÃ©cifiÃ©es."
        }
        return $null
    }

    # Si un seul type est trouvÃ©, le retourner directement
    if ($matchingTypes.Count -eq 1) {
        return $matchingTypes[0].Type
    }

    # GÃ©rer les collisions selon la stratÃ©gie spÃ©cifiÃ©e
    Write-Verbose "$($matchingTypes.Count) types correspondants trouvÃ©s pour '$TypeName'. RÃ©solution selon la stratÃ©gie '$ResolveCollisions'."

    # Trier les types par prioritÃ© (assemblies prioritaires d'abord)
    $sortedTypes = $matchingTypes | Sort-Object -Property Priority -Descending

    switch ($ResolveCollisions) {
        "FirstMatch" {
            return $sortedTypes[0].Type
        }
        "LastMatch" {
            return $sortedTypes[-1].Type
        }
        "ThrowOnCollision" {
            $assemblies = $sortedTypes | ForEach-Object { $_.Assembly.GetName().Name }
            throw "Collision dÃ©tectÃ©e pour le type '$TypeName'. Types trouvÃ©s dans les assemblies: $($assemblies -join ', ')"
        }
        "Interactive" {
            # Afficher les options Ã  l'utilisateur
            Write-Host "Plusieurs types correspondants trouvÃ©s pour '$TypeName':" -ForegroundColor Yellow
            for ($i = 0; $i -lt $sortedTypes.Count; $i++) {
                $t = $sortedTypes[$i]
                $priority = if ($t.Priority -gt 0) { " (prioritaire)" } else { "" }
                Write-Host "  $($i+1). $($t.Type.FullName) dans $($t.Assembly.GetName().Name)$priority" -ForegroundColor Cyan
            }

            # Demander Ã  l'utilisateur de choisir
            $choice = 0
            do {
                $userInput = Read-Host "Choisissez un type (1-$($sortedTypes.Count)) ou 'q' pour annuler"
                if ($userInput -eq 'q') {
                    if ($ThrowOnError) {
                        throw "SÃ©lection annulÃ©e par l'utilisateur."
                    }
                    return $null
                }
            } while (-not [int]::TryParse($userInput, [ref]$choice) -or $choice -lt 1 -or $choice -gt $sortedTypes.Count)

            return $sortedTypes[$choice - 1].Type
        }
    }
}

<#
.SYNOPSIS
    Convertit un nom de type en ses composants (espace de noms et nom simple).
.DESCRIPTION
    Cette fonction convertit un nom de type qualifiÃ© en ses composants : l'espace de noms et le nom simple du type.
.PARAMETER TypeName
    Le nom qualifiÃ© du type Ã  convertir.
.PARAMETER NormalizeName
    Indique si le nom du type doit Ãªtre normalisÃ© (suppression des caractÃ¨res spÃ©ciaux, etc.).
.EXAMPLE
    $TypeInfo = ConvertFrom-TypeName -TypeName "System.Collections.Generic.List``1"
.OUTPUTS
    PSObject - Un objet contenant les propriÃ©tÃ©s Namespace et TypeName.
#>
function ConvertFrom-TypeName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$TypeName,

        [Parameter(Mandatory = $false)]
        [switch]$NormalizeName
    )

    # Initialiser les valeurs par dÃ©faut
    $namespace = ""
    $simpleTypeName = $TypeName

    # VÃ©rifier si le nom du type contient un point (sÃ©parateur d'espace de noms)
    if ($TypeName -match '\.') {
        # Trouver le dernier point pour sÃ©parer l'espace de noms du nom de type
        $lastDotIndex = $TypeName.LastIndexOf('.')
        if ($lastDotIndex -gt 0) {
            $namespace = $TypeName.Substring(0, $lastDotIndex)
            $simpleTypeName = $TypeName.Substring($lastDotIndex + 1)
        }
    }

    # GÃ©rer les types gÃ©nÃ©riques (avec des backticks)
    if ($simpleTypeName -match '`') {
        # Extraire le nom de base du type gÃ©nÃ©rique (avant le backtick)
        $genericBaseNameMatch = [regex]::Match($simpleTypeName, '^([^`]+)`')
        if ($genericBaseNameMatch.Success) {
            $genericBaseName = $genericBaseNameMatch.Groups[1].Value

            # Extraire le nombre de paramÃ¨tres de type
            $genericArityMatch = [regex]::Match($simpleTypeName, '`(\d+)')
            if ($genericArityMatch.Success) {
                $genericArity = [int]::Parse($genericArityMatch.Groups[1].Value)

                # Reconstruire le nom simple avec le format correct pour PowerShell
                $simpleTypeName = "$genericBaseName``$genericArity"
            }
        }
    }

    # Normaliser le nom si demandÃ©
    if ($NormalizeName) {
        # Supprimer les caractÃ¨res spÃ©ciaux et les espaces
        $simpleTypeName = $simpleTypeName -replace '[^a-zA-Z0-9_]', ''

        # Normaliser la casse (PascalCase)
        if (-not [string]::IsNullOrEmpty($simpleTypeName)) {
            $simpleTypeName = $simpleTypeName.Substring(0, 1).ToUpper() + $simpleTypeName.Substring(1)
        }

        # Normaliser l'espace de noms (tout en minuscules)
        if (-not [string]::IsNullOrEmpty($namespace)) {
            $namespace = $namespace.ToLower()
        }
    }

    # CrÃ©er et retourner l'objet rÃ©sultat
    return [PSCustomObject]@{
        Namespace = $namespace
        TypeName  = $simpleTypeName
    }
}

<#
.SYNOPSIS
    Recherche un type dans plusieurs assemblies avec gestion des erreurs.
.DESCRIPTION
    Cette fonction recherche un type dans plusieurs assemblies et gÃ¨re les erreurs de rÃ©solution.
.PARAMETER TypeName
    Le nom qualifiÃ© du type Ã  rechercher.
.PARAMETER Assemblies
    Les assemblies dans lesquelles rechercher le type. Si non spÃ©cifiÃ©, recherche dans toutes les assemblies chargÃ©es.
.PARAMETER IgnoreCase
    Indique si la recherche doit Ãªtre insensible Ã  la casse.
.PARAMETER IncludeErrors
    Indique si les erreurs de rÃ©solution doivent Ãªtre incluses dans les rÃ©sultats.
.EXAMPLE
    $SearchResult = Search-TypeInAssemblies -TypeName "System.String"
.OUTPUTS
    PSObject - Un objet contenant les propriÃ©tÃ©s Type, Assembly et Error.
#>
function Search-TypeInAssemblies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$TypeName,

        [Parameter(Mandatory = $false)]
        [System.Reflection.Assembly[]]$Assemblies,

        [Parameter(Mandatory = $false)]
        [switch]$IgnoreCase,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeErrors
    )

    # Si aucune assembly n'est spÃ©cifiÃ©e, utiliser toutes les assemblies chargÃ©es
    if ($null -eq $Assemblies -or $Assemblies.Count -eq 0) {
        $Assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
    }

    # Initialiser les rÃ©sultats comme un tableau vide
    [System.Collections.ArrayList]$results = @()

    # Rechercher le type dans chaque assembly
    foreach ($assembly in $Assemblies) {
        try {
            $type = $assembly.GetType($TypeName, $false, $IgnoreCase)
            if ($null -ne $type) {
                $results += [PSCustomObject]@{
                    Type     = $type
                    Assembly = $assembly
                    Error    = $null
                }
            }
        } catch {
            if ($IncludeErrors) {
                $results += [PSCustomObject]@{
                    Type     = $null
                    Assembly = $assembly
                    Error    = $_.Exception
                }
            }
        }
    }

    # Si aucun rÃ©sultat n'est trouvÃ©, retourner un tableau vide plutÃ´t que null
    if ($null -eq $results -or $results.Count -eq 0) {
        return @()
    }

    return $results
}

<#
.SYNOPSIS
    RÃ©cupÃ¨re des informations dÃ©taillÃ©es sur une erreur de rÃ©solution de type.
.DESCRIPTION
    Cette fonction analyse les erreurs de rÃ©solution de type et fournit des informations dÃ©taillÃ©es sur l'erreur.
.PARAMETER TypeName
    Le nom qualifiÃ© du type qui n'a pas pu Ãªtre rÃ©solu.
.PARAMETER ErrorInfo
    Les informations d'erreur Ã  analyser.
.PARAMETER Assemblies
    Les assemblies dans lesquelles le type a Ã©tÃ© recherchÃ©.
.EXAMPLE
    $ErrorDetails = Get-TypeResolutionError -TypeName "MyNamespace.MyClass" -ErrorInfo $Error[0]
.OUTPUTS
    PSObject - Un objet contenant des informations dÃ©taillÃ©es sur l'erreur.
#>

<#
.SYNOPSIS
    DÃ©finit un alias de type.
.DESCRIPTION
    Cette fonction dÃ©finit un alias pour un type, permettant d'utiliser un nom court ou alternatif
    pour rÃ©fÃ©rencer un type avec un nom qualifiÃ© complet.
.PARAMETER Alias
    L'alias Ã  dÃ©finir pour le type.
.PARAMETER TypeName
    Le nom qualifiÃ© complet du type.
.PARAMETER Force
    Indique si l'alias doit Ãªtre remplacÃ© s'il existe dÃ©jÃ .
.EXAMPLE
    Set-TypeAlias -Alias "str" -TypeName "System.String"
.OUTPUTS
    System.Boolean - True si l'alias a Ã©tÃ© dÃ©fini avec succÃ¨s, False sinon.
#>
function Set-TypeAlias {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Alias,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$TypeName,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # VÃ©rifier si l'alias existe dÃ©jÃ 
    if ($script:TypeAliases.ContainsKey($Alias) -and -not $Force) {
        Write-Warning "L'alias '$Alias' existe dÃ©jÃ  pour le type '$($script:TypeAliases[$Alias])'. Utilisez -Force pour remplacer."
        return $false
    }

    # DÃ©finir l'alias
    $script:TypeAliases[$Alias] = $TypeName
    Write-Verbose "Alias '$Alias' dÃ©fini pour le type '$TypeName'."

    return $true
}

<#
.SYNOPSIS
    Supprime un alias de type.
.DESCRIPTION
    Cette fonction supprime un alias de type prÃ©cÃ©demment dÃ©fini.
.PARAMETER Alias
    L'alias Ã  supprimer.
.EXAMPLE
    Remove-TypeAlias -Alias "str"
.OUTPUTS
    System.Boolean - True si l'alias a Ã©tÃ© supprimÃ© avec succÃ¨s, False sinon.
#>
function Remove-TypeAlias {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Alias
    )

    # VÃ©rifier si l'alias existe
    if (-not $script:TypeAliases.ContainsKey($Alias)) {
        Write-Warning "L'alias '$Alias' n'existe pas."
        return $false
    }

    # Supprimer l'alias
    $script:TypeAliases.Remove($Alias) | Out-Null
    Write-Verbose "Alias '$Alias' supprimÃ©."

    return $true
}

<#
.SYNOPSIS
    Obtient un alias de type ou tous les alias dÃ©finis.
.DESCRIPTION
    Cette fonction retourne un alias de type spÃ©cifique ou tous les alias dÃ©finis.
.PARAMETER Alias
    L'alias Ã  obtenir. Si non spÃ©cifiÃ©, retourne tous les alias.
.EXAMPLE
    $TypeName = Get-TypeAlias -Alias "str"
.EXAMPLE
    $AllAliases = Get-TypeAlias
.OUTPUTS
    System.String - Le nom qualifiÃ© complet du type associÃ© Ã  l'alias, ou $null si l'alias n'existe pas.
    System.Collections.Hashtable - Tous les alias dÃ©finis si aucun alias n'est spÃ©cifiÃ©.
#>
function Get-TypeAlias {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Alias
    )

    # Si aucun alias n'est spÃ©cifiÃ©, retourner tous les alias
    if ([string]::IsNullOrEmpty($Alias)) {
        return $script:TypeAliases.Clone()
    }

    # VÃ©rifier si l'alias existe
    if (-not $script:TypeAliases.ContainsKey($Alias)) {
        Write-Warning "L'alias '$Alias' n'existe pas."
        return $null
    }

    # Retourner le nom qualifiÃ© complet du type associÃ© Ã  l'alias
    return $script:TypeAliases[$Alias]
}

<#
.SYNOPSIS
    RÃ©sout un nom de type en utilisant les alias dÃ©finis.
.DESCRIPTION
    Cette fonction rÃ©sout un nom de type en utilisant les alias dÃ©finis, retournant le nom qualifiÃ© complet du type.
.PARAMETER TypeName
    Le nom du type Ã  rÃ©soudre, qui peut Ãªtre un alias ou un nom qualifiÃ© complet.
.EXAMPLE
    $ResolvedTypeName = Resolve-TypeAlias -TypeName "str"
.OUTPUTS
    System.String - Le nom qualifiÃ© complet du type rÃ©solu, ou le nom d'origine si aucun alias ne correspond.
#>
function Resolve-TypeAlias {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$TypeName
    )

    # VÃ©rifier si le nom est un alias
    if ($script:TypeAliases.ContainsKey($TypeName)) {
        Write-Verbose "Alias '$TypeName' rÃ©solu en '$($script:TypeAliases[$TypeName])'."
        return $script:TypeAliases[$TypeName]
    }

    # Si ce n'est pas un alias, retourner le nom d'origine
    return $TypeName
}

<#
.SYNOPSIS
    Importe des alias de types depuis un fichier JSON.
.DESCRIPTION
    Cette fonction importe des alias de types depuis un fichier JSON.
.PARAMETER Path
    Le chemin du fichier JSON contenant les alias Ã  importer.
.PARAMETER Force
    Indique si les alias existants doivent Ãªtre remplacÃ©s.
.EXAMPLE
    Import-TypeAliases -Path "C:\Aliases\TypeAliases.json"
.OUTPUTS
    System.Int32 - Le nombre d'alias importÃ©s.
#>
function Import-TypeAliases {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le fichier '$Path' n'existe pas."
        return 0
    }

    # Lire le contenu du fichier
    try {
        $content = Get-Content -Path $Path -Raw
        $aliases = ConvertFrom-Json -InputObject $content
    } catch {
        Write-Error "Erreur lors de la lecture du fichier: $($_.Exception.Message)"
        return 0
    }

    # Importer les alias
    $importedCount = 0

    foreach ($property in $aliases.PSObject.Properties) {
        $alias = $property.Name
        $typeName = $property.Value

        if (Set-TypeAlias -Alias $alias -TypeName $typeName -Force:$Force) {
            $importedCount++
        }
    }

    Write-Verbose "$importedCount alias importÃ©s depuis '$Path'."
    return $importedCount
}

<#
.SYNOPSIS
    Exporte des alias de types vers un fichier JSON.
.DESCRIPTION
    Cette fonction exporte des alias de types vers un fichier JSON.
.PARAMETER Path
    Le chemin du fichier JSON oÃ¹ exporter les alias.
.PARAMETER Force
    Indique si le fichier doit Ãªtre remplacÃ© s'il existe dÃ©jÃ .
.EXAMPLE
    Export-TypeAliases -Path "C:\Aliases\TypeAliases.json"
.OUTPUTS
    System.Int32 - Le nombre d'alias exportÃ©s.
#>
function Export-TypeAliases {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # VÃ©rifier si le fichier existe dÃ©jÃ 
    if (Test-Path -Path $Path) {
        if (-not $Force) {
            Write-Error "Le fichier '$Path' existe dÃ©jÃ . Utilisez -Force pour remplacer."
            return 0
        }
    }

    # Exporter les alias
    try {
        $aliases = $script:TypeAliases.Clone()
        $json = ConvertTo-Json -InputObject $aliases -Depth 1
        Set-Content -Path $Path -Value $json -Force:$Force
    } catch {
        Write-Error "Erreur lors de l'exportation des alias: $($_.Exception.Message)"
        return 0
    }

    Write-Verbose "$($aliases.Count) alias exportÃ©s vers '$Path'."
    return $aliases.Count
}

<#
.SYNOPSIS
    RÃ©cupÃ¨re un type non-public par son nom qualifiÃ©.
.DESCRIPTION
    Cette fonction rÃ©cupÃ¨re un type non-public (interne, privÃ©, etc.) par son nom qualifiÃ©,
    en utilisant la rÃ©flexion avancÃ©e pour accÃ©der aux types non-publics.
.PARAMETER TypeName
    Le nom qualifiÃ© du type non-public Ã  rÃ©cupÃ©rer.
.PARAMETER Assembly
    L'assembly dans laquelle rechercher le type. Si non spÃ©cifiÃ©, recherche dans toutes les assemblies chargÃ©es.
.PARAMETER IncludeNestedTypes
    Indique si les types imbriquÃ©s doivent Ãªtre inclus dans la recherche.
.PARAMETER ThrowOnError
    Indique si une exception doit Ãªtre levÃ©e en cas d'erreur de rÃ©solution.
.EXAMPLE
    $Type = Get-NonPublicType -TypeName "System.RuntimeType+RuntimeTypeCache"
.OUTPUTS
    System.Type - Le type non-public rÃ©cupÃ©rÃ©, ou $null si le type n'a pas Ã©tÃ© trouvÃ© et ThrowOnError est $false.
#>
function Get-NonPublicType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$TypeName,

        [Parameter(Mandatory = $false)]
        [System.Reflection.Assembly]$Assembly,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNestedTypes,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnError
    )

    # DÃ©terminer les assemblies Ã  rechercher
    $assemblies = @()
    if ($null -ne $Assembly) {
        $assemblies += $Assembly
    } else {
        $assemblies += [AppDomain]::CurrentDomain.GetAssemblies()
    }

    # Analyser le nom du type pour dÃ©tecter les types imbriquÃ©s
    $isNestedType = $TypeName -match '\+'
    $parentTypeName = $null
    $nestedTypeName = $null

    if ($isNestedType) {
        $typeParts = $TypeName -split '\+', 2
        $parentTypeName = $typeParts[0]
        $nestedTypeName = $typeParts[1]
    }

    # Rechercher le type dans les assemblies spÃ©cifiÃ©es
    foreach ($asm in $assemblies) {
        try {
            # Si c'est un type imbriquÃ©, rechercher d'abord le type parent
            if ($isNestedType) {
                $parentType = $asm.GetType($parentTypeName, $false, $true)
                if ($null -ne $parentType) {
                    # Rechercher le type imbriquÃ© dans le type parent
                    $bindingFlags = [System.Reflection.BindingFlags]::NonPublic -bor
                    [System.Reflection.BindingFlags]::Public -bor
                    [System.Reflection.BindingFlags]::Instance -bor
                    [System.Reflection.BindingFlags]::Static

                    $nestedType = $parentType.GetNestedType($nestedTypeName, $bindingFlags)
                    if ($null -ne $nestedType) {
                        Write-Verbose "Type imbriquÃ© non-public '$TypeName' trouvÃ© dans l'assembly '$($asm.FullName)'."
                        return $nestedType
                    }
                }
            } else {
                # Essayer de rÃ©cupÃ©rer tous les types de l'assembly, y compris les types non-publics
                $types = $asm.GetTypes() | Where-Object { $_.FullName -eq $TypeName -or $_.Name -eq $TypeName }

                if ($null -ne $types -and $types.Count -gt 0) {
                    Write-Verbose "Type non-public '$TypeName' trouvÃ© dans l'assembly '$($asm.FullName)'."
                    return $types[0]
                }

                # Si IncludeNestedTypes est spÃ©cifiÃ©, rechercher dans les types imbriquÃ©s
                if ($IncludeNestedTypes) {
                    $allTypes = $asm.GetTypes()
                    foreach ($type in $allTypes) {
                        $bindingFlags = [System.Reflection.BindingFlags]::NonPublic -bor
                        [System.Reflection.BindingFlags]::Public -bor
                        [System.Reflection.BindingFlags]::Instance -bor
                        [System.Reflection.BindingFlags]::Static

                        $nestedTypes = $type.GetNestedTypes($bindingFlags)
                        $matchingNestedType = $nestedTypes | Where-Object { $_.Name -eq $TypeName -or $_.FullName -eq $TypeName }

                        if ($null -ne $matchingNestedType -and $matchingNestedType.Count -gt 0) {
                            Write-Verbose "Type imbriquÃ© non-public '$TypeName' trouvÃ© dans l'assembly '$($asm.FullName)'."
                            return $matchingNestedType[0]
                        }
                    }
                }
            }
        } catch {
            Write-Verbose "Erreur lors de la recherche du type non-public dans l'assembly '$($asm.FullName)': $($_.Exception.Message)"
        }
    }

    # Si le type n'est pas trouvÃ© et ThrowOnError est spÃ©cifiÃ©, lever une exception
    if ($ThrowOnError) {
        throw "Le type non-public '$TypeName' n'a pas Ã©tÃ© trouvÃ© dans les assemblies spÃ©cifiÃ©es."
    }

    # Sinon, retourner null
    Write-Verbose "Le type non-public '$TypeName' n'a pas Ã©tÃ© trouvÃ©."
    return $null
}

function Get-TypeResolutionError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$TypeName,

        [Parameter(Mandatory = $true, Position = 1)]
        [System.Management.Automation.ErrorRecord]$ErrorInfo,

        [Parameter(Mandatory = $false)]
        [System.Reflection.Assembly[]]$Assemblies
    )

    # Analyser l'erreur
    $errorMessage = $ErrorInfo.Exception.Message
    $errorType = $ErrorInfo.Exception.GetType().Name

    # DÃ©terminer le type d'erreur
    $errorCategory = "Unknown"
    $suggestion = ""

    if ($errorMessage -match "Could not load file or assembly") {
        $errorCategory = "AssemblyLoadError"
        $suggestion = "VÃ©rifiez que l'assembly est accessible et que toutes ses dÃ©pendances sont satisfaites."
    } elseif ($errorMessage -match "The type or namespace name .* could not be found") {
        $errorCategory = "TypeNotFoundError"
        $suggestion = "VÃ©rifiez l'orthographe du nom de type et assurez-vous que l'assembly contenant ce type est chargÃ©."
    } elseif ($errorMessage -match "Ambiguous match found") {
        $errorCategory = "AmbiguousMatchError"
        $suggestion = "Utilisez le nom qualifiÃ© complet du type pour Ã©viter les ambiguÃ¯tÃ©s."
    }

    # CrÃ©er l'objet de dÃ©tails d'erreur
    $errorDetails = [PSCustomObject]@{
        TypeName           = $TypeName
        ErrorMessage       = $errorMessage
        ErrorType          = $errorType
        ErrorCategory      = $errorCategory
        Suggestion         = $suggestion
        AssembliesSearched = $Assemblies
        Timestamp          = Get-Date
    }

    return $errorDetails
}

<#
.SYNOPSIS
    Recherche des types par expression rÃ©guliÃ¨re.
.DESCRIPTION
    Cette fonction recherche des types dont le nom correspond Ã  une expression rÃ©guliÃ¨re spÃ©cifiÃ©e.
.PARAMETER Pattern
    L'expression rÃ©guliÃ¨re Ã  utiliser pour la recherche.
.PARAMETER Assemblies
    Les assemblies dans lesquelles rechercher les types. Si non spÃ©cifiÃ©, recherche dans toutes les assemblies chargÃ©es.
.PARAMETER SearchFullName
    Indique si la recherche doit porter sur le nom qualifiÃ© complet du type (espace de noms + nom).
.PARAMETER IgnoreCase
    Indique si la recherche doit Ãªtre insensible Ã  la casse.
.PARAMETER MaxResults
    Le nombre maximum de rÃ©sultats Ã  retourner. Si non spÃ©cifiÃ©, retourne tous les rÃ©sultats.
.EXAMPLE
    $Types = Find-TypesByRegex -Pattern "^System\.Collections\.Generic\..*Dictionary.*$"
.OUTPUTS
    System.Type[] - Les types correspondant Ã  l'expression rÃ©guliÃ¨re spÃ©cifiÃ©e.
#>
function Find-TypesByRegex {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Pattern,

        [Parameter(Mandatory = $false)]
        [System.Reflection.Assembly[]]$Assemblies,

        [Parameter(Mandatory = $false)]
        [switch]$SearchFullName,

        [Parameter(Mandatory = $false)]
        [switch]$IgnoreCase,

        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 0
    )

    # Si aucune assembly n'est spÃ©cifiÃ©e, utiliser toutes les assemblies chargÃ©es
    if ($null -eq $Assemblies -or $Assemblies.Count -eq 0) {
        $Assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
    }

    # CrÃ©er l'expression rÃ©guliÃ¨re
    $regexOptions = [System.Text.RegularExpressions.RegexOptions]::Compiled
    if ($IgnoreCase) {
        $regexOptions = $regexOptions -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    }

    try {
        $regex = New-Object System.Text.RegularExpressions.Regex($Pattern, $regexOptions)
    } catch {
        Write-Error "Erreur lors de la crÃ©ation de l'expression rÃ©guliÃ¨re: $($_.Exception.Message)"
        return @()
    }

    # Rechercher les types correspondants
    $result = @()
    $count = 0

    foreach ($assembly in $Assemblies) {
        try {
            $types = $assembly.GetTypes()

            foreach ($type in $types) {
                # DÃ©terminer la chaÃ®ne Ã  rechercher
                $searchString = if ($SearchFullName) { $type.FullName } else { $type.Name }

                # VÃ©rifier si le type correspond Ã  l'expression rÃ©guliÃ¨re
                if ($regex.IsMatch($searchString)) {
                    $result += $type
                    $count++

                    # VÃ©rifier si le nombre maximum de rÃ©sultats est atteint
                    if ($MaxResults -gt 0 -and $count -ge $MaxResults) {
                        Write-Verbose "Nombre maximum de rÃ©sultats atteint ($MaxResults)."
                        return $result
                    }
                }
            }
        } catch {
            Write-Verbose "Erreur lors de la recherche des types dans l'assembly '$($assembly.FullName)': $($_.Exception.Message)"
        }
    }

    Write-Verbose "$count types correspondant Ã  l'expression rÃ©guliÃ¨re '$Pattern' trouvÃ©s."
    return $result
}

<#
.SYNOPSIS
    Charge une assembly depuis un chemin de fichier.
.DESCRIPTION
    Cette fonction charge une assembly depuis un chemin de fichier, avec des options pour la rÃ©solution des dÃ©pendances
    et le chargement en contexte isolÃ©.
.PARAMETER Path
    Le chemin du fichier d'assembly Ã  charger.
.PARAMETER ResolveReferences
    Indique si les rÃ©fÃ©rences de l'assembly doivent Ãªtre rÃ©solues automatiquement.
.PARAMETER IsolatedContext
    Indique si l'assembly doit Ãªtre chargÃ©e dans un contexte isolÃ©.
.PARAMETER ReferencePaths
    Les chemins oÃ¹ rechercher les assemblies rÃ©fÃ©rencÃ©es.
.EXAMPLE
    $Assembly = Import-Assembly -Path "C:\MyAssemblies\MyLibrary.dll"
.EXAMPLE
    $Assembly = Import-Assembly -Path "C:\MyAssemblies\MyLibrary.dll" -ResolveReferences -ReferencePaths "C:\References"
.OUTPUTS
    System.Reflection.Assembly - L'assembly chargÃ©e.
#>
function Import-Assembly {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveReferences,

        [Parameter(Mandatory = $false)]
        [switch]$IsolatedContext,

        [Parameter(Mandatory = $false)]
        [string[]]$ReferencePaths
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le fichier d'assembly '$Path' n'existe pas."
        return $null
    }

    try {
        # Obtenir le chemin absolu
        $absolutePath = (Resolve-Path -Path $Path).Path

        # CrÃ©er un gestionnaire de rÃ©solution des dÃ©pendances si nÃ©cessaire
        if ($ResolveReferences) {
            # CrÃ©er un gestionnaire d'Ã©vÃ©nements pour la rÃ©solution des assemblies
            $resolveEventHandler = {
                param($senderObj, $resolveArgs)

                $assemblyName = $resolveArgs.Name
                Write-Verbose "Tentative de rÃ©solution de l'assembly: $assemblyName"

                # Rechercher dans les chemins de rÃ©fÃ©rence spÃ©cifiÃ©s
                if ($null -ne $ReferencePaths -and $ReferencePaths.Count -gt 0) {
                    foreach ($refPath in $ReferencePaths) {
                        if (-not (Test-Path -Path $refPath -PathType Container)) {
                            continue
                        }

                        # Extraire le nom simple de l'assembly
                        $simpleName = $assemblyName
                        if ($assemblyName -match '^([^,]+)') {
                            $simpleName = $matches[1]
                        }

                        # Rechercher le fichier DLL
                        $dllPath = Join-Path -Path $refPath -ChildPath "$simpleName.dll"
                        if (Test-Path -Path $dllPath) {
                            Write-Verbose "Assembly '$assemblyName' rÃ©solue Ã  '$dllPath'."
                            return [System.Reflection.Assembly]::LoadFrom($dllPath)
                        }
                    }
                }

                # Essayer de rÃ©soudre l'assembly par son nom
                try {
                    return [System.Reflection.Assembly]::Load($assemblyName)
                } catch {
                    Write-Verbose "Impossible de rÃ©soudre l'assembly '$assemblyName': $($_.Exception.Message)"
                    return $null
                }
            }

            # Ajouter le gestionnaire d'Ã©vÃ©nements
            [System.AppDomain]::CurrentDomain.add_AssemblyResolve($resolveEventHandler)
        }

        # Charger l'assembly
        $assembly = if ($IsolatedContext) {
            # CrÃ©er un contexte de chargement isolÃ©
            $context = [System.Reflection.Assembly]::LoadFile($absolutePath)
            $context
        } else {
            # Charger l'assembly dans le contexte actuel
            [System.Reflection.Assembly]::LoadFrom($absolutePath)
        }

        Write-Verbose "Assembly '$Path' chargÃ©e avec succÃ¨s."
        return $assembly
    } catch {
        Write-Error "Erreur lors du chargement de l'assembly '$Path': $($_.Exception.Message)"
        return $null
    } finally {
        # Supprimer le gestionnaire d'Ã©vÃ©nements si nÃ©cessaire
        if ($ResolveReferences) {
            [System.AppDomain]::CurrentDomain.remove_AssemblyResolve($resolveEventHandler)
        }
    }
}

<#
.SYNOPSIS
    Charge une assembly depuis un flux de donnÃ©es.
.DESCRIPTION
    Cette fonction charge une assembly depuis un flux de donnÃ©es, avec des options pour la rÃ©solution des dÃ©pendances
    et le chargement en contexte isolÃ©.
.PARAMETER Stream
    Le flux de donnÃ©es contenant l'assembly Ã  charger.
.PARAMETER SymbolStream
    Le flux de donnÃ©es contenant les symboles de dÃ©bogage (PDB) de l'assembly.
.PARAMETER ResolveReferences
    Indique si les rÃ©fÃ©rences de l'assembly doivent Ãªtre rÃ©solues automatiquement.
.PARAMETER IsolatedContext
    Indique si l'assembly doit Ãªtre chargÃ©e dans un contexte isolÃ©.
.PARAMETER ReferencePaths
    Les chemins oÃ¹ rechercher les assemblies rÃ©fÃ©rencÃ©es.
.EXAMPLE
    $Assembly = Import-AssemblyFromStream -Stream $stream
.EXAMPLE
    $Assembly = Import-AssemblyFromStream -Stream $stream -SymbolStream $symbolStream -ResolveReferences
.OUTPUTS
    System.Reflection.Assembly - L'assembly chargÃ©e.
#>
function Import-AssemblyFromStream {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.IO.Stream]$Stream,

        [Parameter(Mandatory = $false)]
        [System.IO.Stream]$SymbolStream,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveReferences,

        [Parameter(Mandatory = $false)]
        [switch]$IsolatedContext,

        [Parameter(Mandatory = $false)]
        [string[]]$ReferencePaths
    )

    try {
        # Lire les donnÃ©es du flux
        $assemblyData = New-Object byte[] $Stream.Length
        $Stream.Read($assemblyData, 0, $Stream.Length) | Out-Null
        $Stream.Position = 0

        # Lire les donnÃ©es des symboles si spÃ©cifiÃ©
        $symbolData = $null
        if ($null -ne $SymbolStream) {
            $symbolData = New-Object byte[] $SymbolStream.Length
            $SymbolStream.Read($symbolData, 0, $SymbolStream.Length) | Out-Null
            $SymbolStream.Position = 0
        }

        # CrÃ©er un gestionnaire de rÃ©solution des dÃ©pendances si nÃ©cessaire
        if ($ResolveReferences) {
            # CrÃ©er un gestionnaire d'Ã©vÃ©nements pour la rÃ©solution des assemblies
            $resolveEventHandler = {
                param($senderObj, $resolveArgs)

                $assemblyName = $resolveArgs.Name
                Write-Verbose "Tentative de rÃ©solution de l'assembly: $assemblyName"

                # Rechercher dans les chemins de rÃ©fÃ©rence spÃ©cifiÃ©s
                if ($null -ne $ReferencePaths -and $ReferencePaths.Count -gt 0) {
                    foreach ($refPath in $ReferencePaths) {
                        if (-not (Test-Path -Path $refPath -PathType Container)) {
                            continue
                        }

                        # Extraire le nom simple de l'assembly
                        $simpleName = $assemblyName
                        if ($assemblyName -match '^([^,]+)') {
                            $simpleName = $matches[1]
                        }

                        # Rechercher le fichier DLL
                        $dllPath = Join-Path -Path $refPath -ChildPath "$simpleName.dll"
                        if (Test-Path -Path $dllPath) {
                            Write-Verbose "Assembly '$assemblyName' rÃ©solue Ã  '$dllPath'."
                            return [System.Reflection.Assembly]::LoadFrom($dllPath)
                        }
                    }
                }

                # Essayer de rÃ©soudre l'assembly par son nom
                try {
                    return [System.Reflection.Assembly]::Load($assemblyName)
                } catch {
                    Write-Verbose "Impossible de rÃ©soudre l'assembly '$assemblyName': $($_.Exception.Message)"
                    return $null
                }
            }

            # Ajouter le gestionnaire d'Ã©vÃ©nements
            [System.AppDomain]::CurrentDomain.add_AssemblyResolve($resolveEventHandler)
        }

        # Charger l'assembly
        $assembly = if ($null -ne $symbolData) {
            # Charger l'assembly avec les symboles
            [System.Reflection.Assembly]::Load($assemblyData, $symbolData)
        } else {
            # Charger l'assembly sans les symboles
            [System.Reflection.Assembly]::Load($assemblyData)
        }

        Write-Verbose "Assembly chargÃ©e avec succÃ¨s depuis le flux."
        return $assembly
    } catch {
        Write-Error "Erreur lors du chargement de l'assembly depuis le flux: $($_.Exception.Message)"
        return $null
    } finally {
        # Supprimer le gestionnaire d'Ã©vÃ©nements si nÃ©cessaire
        if ($ResolveReferences) {
            [System.AppDomain]::CurrentDomain.remove_AssemblyResolve($resolveEventHandler)
        }
    }
}

<#
.SYNOPSIS
    Recherche des types par espace de noms.
.DESCRIPTION
    Cette fonction recherche des types dans un espace de noms spÃ©cifiÃ©, avec des options de filtrage et de recherche hiÃ©rarchique.
.PARAMETER Namespace
    L'espace de noms dans lequel rechercher les types.
.PARAMETER Assemblies
    Les assemblies dans lesquelles rechercher les types. Si non spÃ©cifiÃ©, recherche dans toutes les assemblies chargÃ©es.
.PARAMETER IncludeSubNamespaces
    Indique si les sous-espaces de noms doivent Ãªtre inclus dans la recherche.
.PARAMETER Filter
    Un filtre pour limiter les types retournÃ©s (ex: "*Controller", "I*Repository").
.PARAMETER IgnoreCase
    Indique si la recherche doit Ãªtre insensible Ã  la casse.
.EXAMPLE
    $Types = Find-TypesByNamespace -Namespace "System.Collections.Generic" -Filter "*Dictionary*"
.OUTPUTS
    System.Type[] - Les types trouvÃ©s dans l'espace de noms spÃ©cifiÃ©.
#>
function Find-TypesByNamespace {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Namespace,

        [Parameter(Mandatory = $false)]
        [System.Reflection.Assembly[]]$Assemblies,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSubNamespaces,

        [Parameter(Mandatory = $false)]
        [string]$Filter,

        [Parameter(Mandatory = $false)]
        [switch]$IgnoreCase
    )

    # Si aucune assembly n'est spÃ©cifiÃ©e, utiliser toutes les assemblies chargÃ©es
    if ($null -eq $Assemblies -or $Assemblies.Count -eq 0) {
        $Assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
    }

    # CrÃ©er un index des types par espace de noms
    $namespaceIndex = @{}

    foreach ($assembly in $Assemblies) {
        try {
            $types = $assembly.GetTypes()

            foreach ($type in $types) {
                # Ignorer les types sans espace de noms
                if ([string]::IsNullOrEmpty($type.Namespace)) {
                    continue
                }

                # Ajouter le type Ã  l'index
                if (-not $namespaceIndex.ContainsKey($type.Namespace)) {
                    $namespaceIndex[$type.Namespace] = @()
                }

                $namespaceIndex[$type.Namespace] += $type
            }
        } catch {
            Write-Verbose "Erreur lors de l'indexation des types dans l'assembly '$($assembly.FullName)': $($_.Exception.Message)"
        }
    }

    # Rechercher les types dans l'espace de noms spÃ©cifiÃ©
    $result = @()

    # DÃ©terminer les espaces de noms Ã  inclure
    $namespacesToSearch = @()

    if ($IncludeSubNamespaces) {
        # Inclure l'espace de noms spÃ©cifiÃ© et tous ses sous-espaces de noms
        $namespacesToSearch = $namespaceIndex.Keys | Where-Object {
            if ($IgnoreCase) {
                $_ -eq $Namespace -or $_.StartsWith("$Namespace.", [StringComparison]::OrdinalIgnoreCase)
            } else {
                $_ -eq $Namespace -or $_.StartsWith("$Namespace.")
            }
        }
    } else {
        # Inclure uniquement l'espace de noms spÃ©cifiÃ©
        $namespacesToSearch = $namespaceIndex.Keys | Where-Object {
            if ($IgnoreCase) {
                $_ -eq $Namespace
            } else {
                $_ -eq $Namespace
            }
        }
    }

    # Ajouter les types des espaces de noms sÃ©lectionnÃ©s
    foreach ($ns in $namespacesToSearch) {
        $typesInNamespace = $namespaceIndex[$ns]

        # Appliquer le filtre si spÃ©cifiÃ©
        if (-not [string]::IsNullOrEmpty($Filter)) {
            if ($Filter -match '\*') {
                # Utiliser un filtre de type wildcard
                $wildcardFilter = $Filter -replace '\*', '*'

                if ($IgnoreCase) {
                    $typesInNamespace = $typesInNamespace | Where-Object { $_.Name -like $wildcardFilter -or $_.FullName -like $wildcardFilter }
                } else {
                    $typesInNamespace = $typesInNamespace | Where-Object {
                        $name = $_.Name
                        $fullName = $_.FullName
                        $wildcardFilter | ForEach-Object {
                            $name -like $_ -or $fullName -like $_
                        }
                    }
                }
            } else {
                # Utiliser une correspondance exacte
                if ($IgnoreCase) {
                    $typesInNamespace = $typesInNamespace | Where-Object { $_.Name -ieq $Filter -or $_.FullName -ieq $Filter }
                } else {
                    $typesInNamespace = $typesInNamespace | Where-Object { $_.Name -eq $Filter -or $_.FullName -eq $Filter }
                }
            }
        }

        $result += $typesInNamespace
    }

    return $result
}

<#
.SYNOPSIS
    CrÃ©e un type gÃ©nÃ©rique avec les arguments de type spÃ©cifiÃ©s.
.DESCRIPTION
    Cette fonction crÃ©e un type gÃ©nÃ©rique avec les arguments de type spÃ©cifiÃ©s, en rÃ©solvant
    automatiquement les types gÃ©nÃ©riques et leurs arguments.
.PARAMETER GenericTypeName
    Le nom qualifiÃ© complet du type gÃ©nÃ©rique (sans les arguments de type).
.PARAMETER TypeArguments
    Les arguments de type Ã  utiliser pour construire le type gÃ©nÃ©rique.
.PARAMETER Assemblies
    Les assemblies dans lesquelles rechercher le type gÃ©nÃ©rique. Si non spÃ©cifiÃ©, recherche dans toutes les assemblies chargÃ©es.
.PARAMETER ThrowOnError
    Indique si une exception doit Ãªtre levÃ©e en cas d'erreur de rÃ©solution.
.EXAMPLE
    $ListOfString = New-GenericType -GenericTypeName "System.Collections.Generic.List" -TypeArguments ([string])
.EXAMPLE
    $DictionaryOfStringInt = New-GenericType -GenericTypeName "System.Collections.Generic.Dictionary" -TypeArguments @([string], [int])
.OUTPUTS
    System.Type - Le type gÃ©nÃ©rique construit, ou $null si le type n'a pas pu Ãªtre construit et ThrowOnError est $false.
#>
function New-GenericType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$GenericTypeName,

        [Parameter(Mandatory = $true, Position = 1)]
        [type[]]$TypeArguments,

        [Parameter(Mandatory = $false)]
        [System.Reflection.Assembly[]]$Assemblies,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnError
    )

    try {
        # RÃ©soudre le type gÃ©nÃ©rique non construit
        $genericTypeDefinition = Get-TypeByQualifiedName -TypeName $GenericTypeName -Assemblies $Assemblies -ThrowOnError:$ThrowOnError
        if ($null -eq $genericTypeDefinition) {
            return $null
        }

        # VÃ©rifier si le type est gÃ©nÃ©rique
        if (-not $genericTypeDefinition.IsGenericTypeDefinition) {
            $errorMessage = "Le type '$GenericTypeName' n'est pas un type gÃ©nÃ©rique."
            if ($ThrowOnError) {
                throw $errorMessage
            }
            Write-Warning $errorMessage
            return $null
        }

        # VÃ©rifier si le nombre d'arguments de type est correct
        $genericArguments = $genericTypeDefinition.GetGenericArguments()
        if ($genericArguments.Length -ne $TypeArguments.Length) {
            $errorMessage = "Le type gÃ©nÃ©rique '$GenericTypeName' attend $($genericArguments.Length) arguments de type, mais $($TypeArguments.Length) ont Ã©tÃ© fournis."
            if ($ThrowOnError) {
                throw $errorMessage
            }
            Write-Warning $errorMessage
            return $null
        }

        # Construire le type gÃ©nÃ©rique
        $constructedType = $genericTypeDefinition.MakeGenericType($TypeArguments)
        Write-Verbose "Type gÃ©nÃ©rique '$GenericTypeName' construit avec succÃ¨s: $($constructedType.FullName)"

        return $constructedType
    } catch {
        $errorMessage = "Erreur lors de la construction du type gÃ©nÃ©rique '$GenericTypeName': $($_.Exception.Message)"
        if ($ThrowOnError) {
            throw $errorMessage
        }
        Write-Warning $errorMessage
        return $null
    }
}

<#
.SYNOPSIS
    RÃ©cupÃ¨re les arguments de type d'un type gÃ©nÃ©rique construit.
.DESCRIPTION
    Cette fonction rÃ©cupÃ¨re les arguments de type d'un type gÃ©nÃ©rique construit.
.PARAMETER Type
    Le type gÃ©nÃ©rique construit dont on veut rÃ©cupÃ©rer les arguments de type.
.PARAMETER ThrowOnError
    Indique si une exception doit Ãªtre levÃ©e en cas d'erreur.
.EXAMPLE
    $TypeArguments = Get-GenericTypeArguments -Type ([System.Collections.Generic.List[string]])
.OUTPUTS
    System.Type[] - Les arguments de type du type gÃ©nÃ©rique construit, ou $null si le type n'est pas gÃ©nÃ©rique et ThrowOnError est $false.
#>
function Get-GenericTypeArguments {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [switch]$ThrowOnError
    )

    try {
        # VÃ©rifier si le type est gÃ©nÃ©rique
        if (-not $Type.IsGenericType) {
            $errorMessage = "Le type '$($Type.FullName)' n'est pas un type gÃ©nÃ©rique."
            if ($ThrowOnError) {
                throw $errorMessage
            }
            Write-Warning $errorMessage
            return $null
        }

        # RÃ©cupÃ©rer les arguments de type
        $typeArguments = $Type.GetGenericArguments()
        Write-Verbose "Arguments de type rÃ©cupÃ©rÃ©s pour le type '$($Type.FullName)': $($typeArguments.Length) arguments."

        return $typeArguments
    } catch {
        $errorMessage = "Erreur lors de la rÃ©cupÃ©ration des arguments de type pour le type '$($Type.FullName)': $($_.Exception.Message)"
        if ($ThrowOnError) {
            throw $errorMessage
        }
        Write-Warning $errorMessage
        return $null
    }
}

<#
.SYNOPSIS
    VÃ©rifie si un type est un type gÃ©nÃ©rique ou un type gÃ©nÃ©rique construit.
.DESCRIPTION
    Cette fonction vÃ©rifie si un type est un type gÃ©nÃ©rique ou un type gÃ©nÃ©rique construit.
.PARAMETER Type
    Le type Ã  vÃ©rifier.
.PARAMETER ConstructedOnly
    Indique si seuls les types gÃ©nÃ©riques construits doivent Ãªtre considÃ©rÃ©s comme gÃ©nÃ©riques.
.PARAMETER DefinitionOnly
    Indique si seuls les dÃ©finitions de types gÃ©nÃ©riques doivent Ãªtre considÃ©rÃ©es comme gÃ©nÃ©riques.
.EXAMPLE
    $IsGeneric = Test-GenericType -Type ([System.Collections.Generic.List[string]])
.OUTPUTS
    System.Boolean - True si le type est gÃ©nÃ©rique, False sinon.
#>
function Test-GenericType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [switch]$ConstructedOnly,

        [Parameter(Mandatory = $false)]
        [switch]$DefinitionOnly
    )

    # VÃ©rifier si le type est gÃ©nÃ©rique
    $isGeneric = $Type.IsGenericType

    # Si le type n'est pas gÃ©nÃ©rique, retourner False
    if (-not $isGeneric) {
        return $false
    }

    # VÃ©rifier si le type est une dÃ©finition de type gÃ©nÃ©rique
    $isGenericTypeDefinition = $Type.IsGenericTypeDefinition

    # Appliquer les filtres spÃ©cifiÃ©s
    if ($ConstructedOnly) {
        return $isGeneric -and -not $isGenericTypeDefinition
    } elseif ($DefinitionOnly) {
        return $isGenericTypeDefinition
    } else {
        return $isGeneric
    }
}

#endregion

<#
.SYNOPSIS
    CrÃ©e un type anonyme avec les propriÃ©tÃ©s spÃ©cifiÃ©es.
.DESCRIPTION
    Cette fonction crÃ©e un type anonyme avec les propriÃ©tÃ©s spÃ©cifiÃ©es, similaire aux types anonymes en C#.
.PARAMETER Properties
    Les propriÃ©tÃ©s Ã  inclure dans le type anonyme, sous forme de table de hachage.
.EXAMPLE
    $AnonymousType = New-AnonymousType -Properties @{ Name = "John"; Age = 30 }
.OUTPUTS
    PSObject - Un objet avec les propriÃ©tÃ©s spÃ©cifiÃ©es.
#>
function New-AnonymousType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Properties
    )

    # CrÃ©er un objet PSObject
    $anonymousType = New-Object PSObject

    # Ajouter les propriÃ©tÃ©s spÃ©cifiÃ©es
    foreach ($key in $Properties.Keys) {
        $value = $Properties[$key]
        $anonymousType | Add-Member -MemberType NoteProperty -Name $key -Value $value
    }

    # Ajouter une mÃ©thode ToString personnalisÃ©e
    $anonymousType | Add-Member -MemberType ScriptMethod -Name "ToString" -Value {
        $properties = @()
        foreach ($property in $this.PSObject.Properties) {
            if ($property.Name -ne "ToString" -and $property.Name -ne "Equals" -and $property.Name -ne "GetHashCode") {
                $value = if ($null -eq $this.$($property.Name)) { "null" } else { $this.$($property.Name).ToString() }
                $properties += "$($property.Name) = $value"
            }
        }
        return "{ $($properties -join ", ") }"
    } -Force

    # Ajouter une mÃ©thode Equals personnalisÃ©e
    $anonymousType | Add-Member -MemberType ScriptMethod -Name "Equals" -Value {
        param([object]$obj)

        if ($null -eq $obj) {
            return $false
        }

        if ($this -eq $obj) {
            return $true
        }

        # VÃ©rifier si l'objet a les mÃªmes propriÃ©tÃ©s
        foreach ($property in $this.PSObject.Properties) {
            if ($property.Name -ne "ToString" -and $property.Name -ne "Equals" -and $property.Name -ne "GetHashCode") {
                if (-not $obj.PSObject.Properties.Match($property.Name).Count -or
                    $null -eq $obj.$($property.Name) -xor $null -eq $this.$($property.Name) -or
                    ($null -ne $obj.$($property.Name) -and $null -ne $this.$($property.Name) -and
                    $obj.$($property.Name) -ne $this.$($property.Name))) {
                    return $false
                }
            }
        }

        return $true
    } -Force

    # Ajouter une mÃ©thode GetHashCode personnalisÃ©e
    $anonymousType | Add-Member -MemberType ScriptMethod -Name "GetHashCode" -Value {
        $hash = 17

        foreach ($property in $this.PSObject.Properties) {
            if ($property.Name -ne "ToString" -and $property.Name -ne "Equals" -and $property.Name -ne "GetHashCode") {
                $value = $this.$($property.Name)
                if ($null -ne $value) {
                    $hash = $hash * 23 + $value.GetHashCode()
                }
            }
        }

        return $hash
    } -Force

    return $anonymousType
}

<#
.SYNOPSIS
    CrÃ©e un type dynamique avec les propriÃ©tÃ©s et mÃ©thodes spÃ©cifiÃ©es.
.DESCRIPTION
    Cette fonction crÃ©e un type dynamique avec les propriÃ©tÃ©s et mÃ©thodes spÃ©cifiÃ©es, en utilisant System.Reflection.Emit.
.PARAMETER TypeName
    Le nom du type dynamique Ã  crÃ©er.
.PARAMETER Properties
    Les propriÃ©tÃ©s Ã  inclure dans le type dynamique, sous forme de table de hachage oÃ¹ les clÃ©s sont les noms des propriÃ©tÃ©s et les valeurs sont les types des propriÃ©tÃ©s.
.PARAMETER Methods
    Les mÃ©thodes Ã  inclure dans le type dynamique, sous forme de table de hachage oÃ¹ les clÃ©s sont les noms des mÃ©thodes et les valeurs sont des objets dÃ©crivant les mÃ©thodes.
.PARAMETER Interfaces
    Les interfaces que le type dynamique doit implÃ©menter.
.PARAMETER BaseType
    Le type de base du type dynamique. Par dÃ©faut, System.Object.
.EXAMPLE
    $DynamicType = New-DynamicType -TypeName "MyDynamicType" -Properties @{ Name = [string]; Age = [int] }
.OUTPUTS
    System.Type - Le type dynamique crÃ©Ã©.
#>
function New-DynamicType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$TypeName,

        [Parameter(Mandatory = $false)]
        [hashtable]$Properties = @{},

        [Parameter(Mandatory = $false)]
        [hashtable]$Methods = @{},

        [Parameter(Mandatory = $false)]
        [type[]]$Interfaces = @(),

        [Parameter(Mandatory = $false)]
        [type]$BaseType = [object]
    )

    try {
        # CrÃ©er un nom d'assembly dynamique
        $assemblyName = New-Object System.Reflection.AssemblyName("DynamicAssembly")
        $assemblyBuilder = [System.AppDomain]::CurrentDomain.DefineDynamicAssembly($assemblyName, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
        $moduleBuilder = $assemblyBuilder.DefineDynamicModule("DynamicModule")

        # CrÃ©er le type dynamique
        $typeBuilder = $moduleBuilder.DefineType($TypeName, [System.Reflection.TypeAttributes]::Public -bor [System.Reflection.TypeAttributes]::Class, $BaseType, $Interfaces)

        # Ajouter les propriÃ©tÃ©s
        foreach ($propertyName in $Properties.Keys) {
            $propertyType = $Properties[$propertyName]

            # CrÃ©er le champ privÃ© pour la propriÃ©tÃ©
            $fieldBuilder = $typeBuilder.DefineField("_$propertyName", $propertyType, [System.Reflection.FieldAttributes]::Private)

            # CrÃ©er la propriÃ©tÃ©
            $propertyBuilder = $typeBuilder.DefineProperty($propertyName, [System.Reflection.PropertyAttributes]::HasDefault, $propertyType, $null)

            # CrÃ©er la mÃ©thode getter
            $getMethodBuilder = $typeBuilder.DefineMethod("get_$propertyName", [System.Reflection.MethodAttributes]::Public -bor [System.Reflection.MethodAttributes]::SpecialName -bor [System.Reflection.MethodAttributes]::HideBySig, $propertyType, $null)
            $ilGenerator = $getMethodBuilder.GetILGenerator()
            $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ldarg_0)
            $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ldfld, $fieldBuilder)
            $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ret)

            # CrÃ©er la mÃ©thode setter
            $setMethodBuilder = $typeBuilder.DefineMethod("set_$propertyName", [System.Reflection.MethodAttributes]::Public -bor [System.Reflection.MethodAttributes]::SpecialName -bor [System.Reflection.MethodAttributes]::HideBySig, $null, @($propertyType))
            $ilGenerator = $setMethodBuilder.GetILGenerator()
            $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ldarg_0)
            $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ldarg_1)
            $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Stfld, $fieldBuilder)
            $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ret)

            # Associer les mÃ©thodes getter et setter Ã  la propriÃ©tÃ©
            $propertyBuilder.SetGetMethod($getMethodBuilder)
            $propertyBuilder.SetSetMethod($setMethodBuilder)
        }

        # Ajouter les mÃ©thodes
        foreach ($methodName in $Methods.Keys) {
            $methodInfo = $Methods[$methodName]

            # Extraire les informations de la mÃ©thode
            $returnType = $methodInfo.ReturnType
            $parameterTypes = $methodInfo.ParameterTypes
            $methodAttributes = $methodInfo.Attributes -bor [System.Reflection.MethodAttributes]::Public -bor [System.Reflection.MethodAttributes]::HideBySig

            # CrÃ©er la mÃ©thode
            $methodBuilder = $typeBuilder.DefineMethod($methodName, $methodAttributes, $returnType, $parameterTypes)

            # GÃ©nÃ©rer le code IL pour la mÃ©thode
            $ilGenerator = $methodBuilder.GetILGenerator()

            # Si une implÃ©mentation est fournie, l'utiliser
            if ($methodInfo.Implementation) {
                $methodInfo.Implementation.Invoke($ilGenerator)
            } else {
                # ImplÃ©mentation par dÃ©faut : retourner la valeur par dÃ©faut du type de retour
                if ($returnType -eq [void]) {
                    $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ret)
                } else {
                    $ilGenerator.DeclareLocal($returnType)
                    $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ldloc_0)
                    $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ret)
                }
            }
        }

        # CrÃ©er le type
        $type = $typeBuilder.CreateType()
        Write-Verbose "Type dynamique '$TypeName' crÃ©Ã© avec succÃ¨s."

        return $type
    } catch {
        Write-Error "Erreur lors de la crÃ©ation du type dynamique '$TypeName': $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
    CrÃ©e un type Nullable pour un type de valeur.
.DESCRIPTION
    Cette fonction crÃ©e un type Nullable pour un type de valeur spÃ©cifiÃ©.
.PARAMETER ValueType
    Le type de valeur pour lequel crÃ©er un type Nullable.
.EXAMPLE
    $NullableInt = New-NullableType -ValueType ([int])
.OUTPUTS
    System.Type - Le type Nullable crÃ©Ã©.
#>
function New-NullableType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$ValueType
    )

    # VÃ©rifier si le type est un type de valeur
    if (-not $ValueType.IsValueType) {
        throw "Le type '$($ValueType.FullName)' n'est pas un type de valeur. Seuls les types de valeur peuvent Ãªtre rendus nullables."
    }

    # VÃ©rifier si le type est dÃ©jÃ  un type Nullable
    if ($ValueType.IsGenericType -and $ValueType.GetGenericTypeDefinition() -eq [System.Nullable`1]) {
        Write-Warning "Le type '$($ValueType.FullName)' est dÃ©jÃ  un type Nullable."
        return $ValueType
    }

    # CrÃ©er le type Nullable
    $nullableType = [System.Nullable`1].MakeGenericType($ValueType)
    Write-Verbose "Type Nullable crÃ©Ã© pour le type '$($ValueType.FullName)'."

    return $nullableType
}

<#
.SYNOPSIS
    Parcourt les membres d'un type.
.DESCRIPTION
    Cette fonction parcourt les membres d'un type, avec des options pour filtrer par type de membre,
    flags de liaison, et pour effectuer un parcours rÃ©cursif.
.PARAMETER Type
    Le type dont on veut parcourir les membres.
.PARAMETER MemberTypes
    Les types de membres Ã  inclure dans le parcours. Par dÃ©faut, tous les types de membres sont inclus.
.PARAMETER BindingFlags
    Les flags de liaison Ã  utiliser pour la rÃ©cupÃ©ration des membres. Par dÃ©faut, les membres publics et d'instance sont inclus.
.PARAMETER Recursive
    Indique si le parcours doit Ãªtre rÃ©cursif (inclure les membres des types de base).
.PARAMETER IncludeSpecialNames
    Indique si les membres avec des noms spÃ©ciaux (ex: .ctor, .cctor) doivent Ãªtre inclus.
.PARAMETER Filter
    Un prÃ©dicat pour filtrer les membres retournÃ©s.
.EXAMPLE
    $Members = Get-TypeMembers -Type ([System.String])
.EXAMPLE
    $Properties = Get-TypeMembers -Type ([System.String]) -MemberTypes Property -BindingFlags ([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance)
.OUTPUTS
    System.Reflection.MemberInfo[] - Les membres du type qui correspondent aux critÃ¨res spÃ©cifiÃ©s.
#>
function Get-TypeMembers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [System.Reflection.MemberTypes]$MemberTypes = [System.Reflection.MemberTypes]::All,

        [Parameter(Mandatory = $false)]
        [System.Reflection.BindingFlags]$BindingFlags = ([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance),

        [Parameter(Mandatory = $false)]
        [switch]$Recursive,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSpecialNames,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Filter
    )

    # Ajouter les flags pour les membres statiques et non-publics si nÃ©cessaire
    if (-not ($BindingFlags -band [System.Reflection.BindingFlags]::Static)) {
        Write-Verbose "Flags de liaison ne contiennent pas Static. Seuls les membres d'instance seront retournÃ©s."
    }

    if (-not ($BindingFlags -band [System.Reflection.BindingFlags]::NonPublic)) {
        Write-Verbose "Flags de liaison ne contiennent pas NonPublic. Seuls les membres publics seront retournÃ©s."
    }

    # Ajouter le flag FlattenHierarchy si Recursive est spÃ©cifiÃ©
    if ($Recursive) {
        $BindingFlags = $BindingFlags -bor [System.Reflection.BindingFlags]::FlattenHierarchy
    }

    # RÃ©cupÃ©rer les membres du type
    $members = $Type.GetMembers($BindingFlags)

    # Filtrer par type de membre si spÃ©cifiÃ©
    if ($MemberTypes -ne [System.Reflection.MemberTypes]::All) {
        $members = $members | Where-Object { $_.MemberType -band $MemberTypes }
    }

    # Filtrer les membres avec des noms spÃ©ciaux si nÃ©cessaire
    if (-not $IncludeSpecialNames) {
        $members = $members | Where-Object { -not $_.Name.StartsWith(".") }  # Exclure les noms comme .ctor, .cctor, etc.
    }

    # Appliquer le filtre personnalisÃ© si spÃ©cifiÃ©
    if ($null -ne $Filter) {
        $members = $members | Where-Object $Filter
    }

    return $members
}

<#
.SYNOPSIS
    Parcourt les membres d'un type de maniÃ¨re rÃ©cursive.
.DESCRIPTION
    Cette fonction parcourt les membres d'un type de maniÃ¨re rÃ©cursive, en incluant les membres des types de base.
.PARAMETER Type
    Le type dont on veut parcourir les membres.
.PARAMETER MemberTypes
    Les types de membres Ã  inclure dans le parcours. Par dÃ©faut, tous les types de membres sont inclus.
.PARAMETER BindingFlags
    Les flags de liaison Ã  utiliser pour la rÃ©cupÃ©ration des membres. Par dÃ©faut, les membres publics et d'instance sont inclus.
.PARAMETER MaxDepth
    La profondeur maximale de rÃ©cursion. Par dÃ©faut, il n'y a pas de limite.
.PARAMETER IncludeSpecialNames
    Indique si les membres avec des noms spÃ©ciaux (ex: .ctor, .cctor) doivent Ãªtre inclus.
.PARAMETER Filter
    Un prÃ©dicat pour filtrer les membres retournÃ©s.
.EXAMPLE
    $AllMembers = Get-TypeMembersRecursive -Type ([System.String])
.EXAMPLE
    $AllProperties = Get-TypeMembersRecursive -Type ([System.String]) -MemberTypes Property -MaxDepth 2
.OUTPUTS
    System.Reflection.MemberInfo[] - Les membres du type qui correspondent aux critÃ¨res spÃ©cifiÃ©s.
#>
function Get-TypeMembersRecursive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [System.Reflection.MemberTypes]$MemberTypes = [System.Reflection.MemberTypes]::All,

        [Parameter(Mandatory = $false)]
        [System.Reflection.BindingFlags]$BindingFlags = ([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance),

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = -1, # -1 signifie pas de limite

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSpecialNames,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Filter
    )

    # Fonction rÃ©cursive interne
    function Get-MembersRecursive {
        param (
            [type]$CurrentType,
            [int]$CurrentDepth = 0
        )

        # VÃ©rifier si la profondeur maximale est atteinte
        if ($MaxDepth -ne -1 -and $CurrentDepth -gt $MaxDepth) {
            return @()
        }

        # RÃ©cupÃ©rer les membres du type courant
        $currentMembers = Get-TypeMembers -Type $CurrentType -MemberTypes $MemberTypes -BindingFlags $BindingFlags -IncludeSpecialNames:$IncludeSpecialNames -Filter $Filter

        # Si le type a un type de base, rÃ©cupÃ©rer ses membres rÃ©cursivement
        $baseMembers = @()
        if ($null -ne $CurrentType.BaseType -and $CurrentType.BaseType -ne [object]) {
            $baseMembers = Get-MembersRecursive -CurrentType $CurrentType.BaseType -CurrentDepth ($CurrentDepth + 1)
        }

        # Combiner les membres du type courant et des types de base
        return $currentMembers + $baseMembers
    }

    # Appeler la fonction rÃ©cursive
    return Get-MembersRecursive -CurrentType $Type
}

<#
.SYNOPSIS
    Parcourt les membres d'un type par catÃ©gorie.
.DESCRIPTION
    Cette fonction parcourt les membres d'un type et les regroupe par catÃ©gorie (propriÃ©tÃ©s, mÃ©thodes, Ã©vÃ©nements, etc.).
.PARAMETER Type
    Le type dont on veut parcourir les membres.
.PARAMETER BindingFlags
    Les flags de liaison Ã  utiliser pour la rÃ©cupÃ©ration des membres. Par dÃ©faut, les membres publics et d'instance sont inclus.
.PARAMETER Recursive
    Indique si le parcours doit Ãªtre rÃ©cursif (inclure les membres des types de base).
.PARAMETER IncludeSpecialNames
    Indique si les membres avec des noms spÃ©ciaux (ex: .ctor, .cctor) doivent Ãªtre inclus.
.PARAMETER Categories
    Les catÃ©gories de membres Ã  inclure. Par dÃ©faut, toutes les catÃ©gories sont incluses.
.EXAMPLE
    $MembersByCategory = Get-TypeMembersByCategory -Type ([System.String])
.EXAMPLE
    $MembersByCategory = Get-TypeMembersByCategory -Type ([System.String]) -Categories Property, Method -Recursive
.OUTPUTS
    System.Collections.Hashtable - Une table de hachage oÃ¹ les clÃ©s sont les catÃ©gories de membres et les valeurs sont les membres correspondants.
#>
function Get-TypeMembersByCategory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [System.Reflection.BindingFlags]$BindingFlags = ([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance),

        [Parameter(Mandatory = $false)]
        [switch]$Recursive,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSpecialNames,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Property", "Method", "Constructor", "Event", "Field", "NestedType", "Custom")]
        [string[]]$Categories = @("Property", "Method", "Constructor", "Event", "Field", "NestedType", "Custom")
    )

    # CrÃ©er une table de hachage pour stocker les membres par catÃ©gorie
    $membersByCategory = @{}

    # Initialiser les catÃ©gories sÃ©lectionnÃ©es
    foreach ($category in $Categories) {
        $membersByCategory[$category] = @()
    }

    # DÃ©finir les types de membres pour chaque catÃ©gorie
    $categoryMemberTypes = @{
        "Property"    = [System.Reflection.MemberTypes]::Property
        "Method"      = [System.Reflection.MemberTypes]::Method
        "Constructor" = [System.Reflection.MemberTypes]::Constructor
        "Event"       = [System.Reflection.MemberTypes]::Event
        "Field"       = [System.Reflection.MemberTypes]::Field
        "NestedType"  = [System.Reflection.MemberTypes]::NestedType
        "Custom"      = [System.Reflection.MemberTypes]::Custom
    }

    # RÃ©cupÃ©rer tous les membres
    $getMembersParams = @{
        Type                = $Type
        BindingFlags        = $BindingFlags
        IncludeSpecialNames = $IncludeSpecialNames
    }

    if ($Recursive) {
        $allMembers = Get-TypeMembersRecursive @getMembersParams
    } else {
        $allMembers = Get-TypeMembers @getMembersParams
    }

    # Regrouper les membres par catÃ©gorie
    foreach ($member in $allMembers) {
        foreach ($category in $Categories) {
            if ($member.MemberType -band $categoryMemberTypes[$category]) {
                $membersByCategory[$category] += $member
            }
        }
    }

    return $membersByCategory
}

<#
.SYNOPSIS
    CrÃ©e un itÃ©rateur pour parcourir les membres d'un type.
.DESCRIPTION
    Cette fonction crÃ©e un itÃ©rateur pour parcourir les membres d'un type, avec des options pour filtrer par type de membre,
    flags de liaison, et pour effectuer un parcours rÃ©cursif.
.PARAMETER Type
    Le type dont on veut parcourir les membres.
.PARAMETER MemberTypes
    Les types de membres Ã  inclure dans le parcours. Par dÃ©faut, tous les types de membres sont inclus.
.PARAMETER BindingFlags
    Les flags de liaison Ã  utiliser pour la rÃ©cupÃ©ration des membres. Par dÃ©faut, les membres publics et d'instance sont inclus.
.PARAMETER Recursive
    Indique si le parcours doit Ãªtre rÃ©cursif (inclure les membres des types de base).
.PARAMETER IncludeSpecialNames
    Indique si les membres avec des noms spÃ©ciaux (ex: .ctor, .cctor) doivent Ãªtre inclus.
.PARAMETER Filter
    Un prÃ©dicat pour filtrer les membres retournÃ©s.
.EXAMPLE
    $Iterator = New-TypeMemberIterator -Type ([System.String])
    foreach ($member in $Iterator) { $member.Name }
.OUTPUTS
    System.Collections.IEnumerable - Un itÃ©rateur pour parcourir les membres du type.
#>
function New-TypeMemberIterator {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [System.Reflection.MemberTypes]$MemberTypes = [System.Reflection.MemberTypes]::All,

        [Parameter(Mandatory = $false)]
        [System.Reflection.BindingFlags]$BindingFlags = ([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance),

        [Parameter(Mandatory = $false)]
        [switch]$Recursive,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSpecialNames,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Filter
    )

    # CrÃ©er un script block qui retourne un Ã©numÃ©rateur
    $iteratorScriptBlock = {
        param (
            [type]$Type,
            [System.Reflection.MemberTypes]$MemberTypes,
            [System.Reflection.BindingFlags]$BindingFlags,
            [bool]$Recursive,
            [bool]$IncludeSpecialNames,
            [scriptblock]$Filter
        )

        # Fonction rÃ©cursive pour parcourir les membres
        function Get-MembersRecursive {
            param (
                [type]$CurrentType
            )

            # RÃ©cupÃ©rer les membres du type courant
            $members = $CurrentType.GetMembers($BindingFlags)

            # Filtrer par type de membre si spÃ©cifiÃ©
            if ($MemberTypes -ne [System.Reflection.MemberTypes]::All) {
                $members = $members | Where-Object { $_.MemberType -band $MemberTypes }
            }

            # Filtrer les membres avec des noms spÃ©ciaux si nÃ©cessaire
            if (-not $IncludeSpecialNames) {
                $members = $members | Where-Object { -not $_.Name.StartsWith(".") }  # Exclure les noms comme .ctor, .cctor, etc.
            }

            # Appliquer le filtre personnalisÃ© si spÃ©cifiÃ©
            if ($null -ne $Filter) {
                $members = $members | Where-Object $Filter
            }

            # Retourner les membres du type courant
            foreach ($member in $members) {
                yield $member
            }

            # Si rÃ©cursif et le type a un type de base, parcourir ses membres
            if ($Recursive -and $null -ne $CurrentType.BaseType -and $CurrentType.BaseType -ne [object]) {
                Get-MembersRecursive -CurrentType $CurrentType.BaseType
            }
        }

        # Commencer le parcours
        Get-MembersRecursive -CurrentType $Type
    }

    # CrÃ©er et retourner l'Ã©numÃ©rateur
    return & $iteratorScriptBlock -Type $Type -MemberTypes $MemberTypes -BindingFlags $BindingFlags -Recursive $Recursive -IncludeSpecialNames $IncludeSpecialNames -Filter $Filter
}

<#
.SYNOPSIS
    Filtre les membres d'un type par attribut.
.DESCRIPTION
    Cette fonction filtre les membres d'un type en fonction des attributs qu'ils possÃ¨dent.
.PARAMETER Type
    Le type dont on veut filtrer les membres.
.PARAMETER AttributeType
    Le type d'attribut Ã  rechercher.
.PARAMETER BindingFlags
    Les flags de liaison Ã  utiliser pour la rÃ©cupÃ©ration des membres. Par dÃ©faut, les membres publics et d'instance sont inclus.
.PARAMETER Recursive
    Indique si le parcours doit Ãªtre rÃ©cursif (inclure les membres des types de base).
.PARAMETER IncludeInherited
    Indique si les attributs hÃ©ritÃ©s doivent Ãªtre inclus.
.PARAMETER Filter
    Un prÃ©dicat pour filtrer les membres retournÃ©s.
.EXAMPLE
    $SerializableMembers = Get-TypeMembersByAttribute -Type ([System.String]) -AttributeType ([System.SerializableAttribute])
.OUTPUTS
    System.Reflection.MemberInfo[] - Les membres du type qui possÃ¨dent l'attribut spÃ©cifiÃ©.
#>
function Get-TypeMembersByAttribute {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $true, Position = 1)]
        [type]$AttributeType,

        [Parameter(Mandatory = $false)]
        [System.Reflection.BindingFlags]$BindingFlags = ([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance),

        [Parameter(Mandatory = $false)]
        [switch]$Recursive,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInherited,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Filter
    )

    # RÃ©cupÃ©rer les membres du type
    $getMembersParams = @{
        Type         = $Type
        BindingFlags = $BindingFlags
    }

    if ($Recursive) {
        $members = Get-TypeMembersRecursive @getMembersParams
    } else {
        $members = Get-TypeMembers @getMembersParams
    }

    # Filtrer les membres par attribut
    $filteredMembers = $members | Where-Object {
        $member = $_
        $attributes = if ($IncludeInherited) {
            $member.GetCustomAttributes($AttributeType, $true)
        } else {
            $member.GetCustomAttributes($AttributeType, $false)
        }

        $hasAttribute = $attributes.Count -gt 0

        # Appliquer le filtre personnalisÃ© si spÃ©cifiÃ©
        if ($hasAttribute -and $null -ne $Filter) {
            return $member | Where-Object $Filter
        }

        return $hasAttribute
    }

    return $filteredMembers
}

<#
.SYNOPSIS
    Filtre les membres d'un type par type de retour.
.DESCRIPTION
    Cette fonction filtre les membres d'un type en fonction de leur type de retour (pour les propriÃ©tÃ©s et mÃ©thodes).
.PARAMETER Type
    Le type dont on veut filtrer les membres.
.PARAMETER ReturnType
    Le type de retour Ã  rechercher.
.PARAMETER BindingFlags
    Les flags de liaison Ã  utiliser pour la rÃ©cupÃ©ration des membres. Par dÃ©faut, les membres publics et d'instance sont inclus.
.PARAMETER Recursive
    Indique si le parcours doit Ãªtre rÃ©cursif (inclure les membres des types de base).
.PARAMETER ExactMatch
    Indique si le type de retour doit correspondre exactement au type spÃ©cifiÃ©.
.PARAMETER Filter
    Un prÃ©dicat pour filtrer les membres retournÃ©s.
.EXAMPLE
    $StringMembers = Get-TypeMembersByReturnType -Type ([System.Object]) -ReturnType ([System.String])
.OUTPUTS
    System.Reflection.MemberInfo[] - Les membres du type qui ont le type de retour spÃ©cifiÃ©.
#>
function Get-TypeMembersByReturnType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $true, Position = 1)]
        [type]$ReturnType,

        [Parameter(Mandatory = $false)]
        [System.Reflection.BindingFlags]$BindingFlags = ([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance),

        [Parameter(Mandatory = $false)]
        [switch]$Recursive,

        [Parameter(Mandatory = $false)]
        [switch]$ExactMatch,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Filter
    )

    # RÃ©cupÃ©rer les membres du type
    $getMembersParams = @{
        Type         = $Type
        BindingFlags = $BindingFlags
        MemberTypes  = [System.Reflection.MemberTypes]::Property -bor [System.Reflection.MemberTypes]::Method
    }

    if ($Recursive) {
        $members = Get-TypeMembersRecursive @getMembersParams
    } else {
        $members = Get-TypeMembers @getMembersParams
    }

    # Filtrer les membres par type de retour
    $filteredMembers = $members | Where-Object {
        $member = $_
        $memberReturnType = $null

        # DÃ©terminer le type de retour en fonction du type de membre
        if ($member.MemberType -eq [System.Reflection.MemberTypes]::Property) {
            $memberReturnType = $member.PropertyType
        } elseif ($member.MemberType -eq [System.Reflection.MemberTypes]::Method) {
            $memberReturnType = $member.ReturnType
        } else {
            return $false  # Ignorer les autres types de membres
        }

        # VÃ©rifier si le type de retour correspond
        $typeMatches = if ($ExactMatch) {
            $memberReturnType -eq $ReturnType
        } else {
            $ReturnType.IsAssignableFrom($memberReturnType)
        }

        # Appliquer le filtre personnalisÃ© si spÃ©cifiÃ©
        if ($typeMatches -and $null -ne $Filter) {
            return $member | Where-Object $Filter
        }

        return $typeMatches
    }

    return $filteredMembers
}

<#
.SYNOPSIS
    Filtre les membres d'un type par accessibilitÃ©.
.DESCRIPTION
    Cette fonction filtre les membres d'un type en fonction de leur accessibilitÃ© (public, privÃ©, protÃ©gÃ©, etc.).
.PARAMETER Type
    Le type dont on veut filtrer les membres.
.PARAMETER Accessibility
    L'accessibilitÃ© des membres Ã  inclure. Les valeurs possibles sont : Public, Private, Protected, Internal, ProtectedInternal, PrivateProtected.
.PARAMETER BindingFlags
    Les flags de liaison Ã  utiliser pour la rÃ©cupÃ©ration des membres. Par dÃ©faut, tous les membres sont inclus.
.PARAMETER Recursive
    Indique si le parcours doit Ãªtre rÃ©cursif (inclure les membres des types de base).
.PARAMETER Filter
    Un prÃ©dicat pour filtrer les membres retournÃ©s.
.EXAMPLE
    $PublicMembers = Get-TypeMembersByAccessibility -Type ([System.String]) -Accessibility Public
.OUTPUTS
    System.Reflection.MemberInfo[] - Les membres du type qui ont l'accessibilitÃ© spÃ©cifiÃ©e.
#>
function Get-TypeMembersByAccessibility {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Public", "Private", "Protected", "Internal", "ProtectedInternal", "PrivateProtected")]
        [string[]]$Accessibility,

        [Parameter(Mandatory = $false)]
        [System.Reflection.BindingFlags]$BindingFlags = ([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Static),

        [Parameter(Mandatory = $false)]
        [switch]$Recursive,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Filter
    )

    # RÃ©cupÃ©rer les membres du type
    $getMembersParams = @{
        Type         = $Type
        BindingFlags = $BindingFlags
    }

    if ($Recursive) {
        $members = Get-TypeMembersRecursive @getMembersParams
    } else {
        $members = Get-TypeMembers @getMembersParams
    }

    # Filtrer les membres par accessibilitÃ©
    $filteredMembers = $members | Where-Object {
        $member = $_

        # DÃ©terminer l'accessibilitÃ© du membre
        $isPublic = $false
        $isPrivate = $false
        $isProtected = $false
        $isInternal = $false

        # VÃ©rifier le type de membre et dÃ©terminer son accessibilitÃ©
        if ($member.MemberType -eq [System.Reflection.MemberTypes]::Method) {
            $isPublic = $member.IsPublic
            $isPrivate = $member.IsPrivate
            $isProtected = $member.IsFamily
            $isInternal = $member.IsAssembly
            $isProtectedInternal = $member.IsFamilyOrAssembly
            $isPrivateProtected = $member.IsFamilyAndAssembly
        } elseif ($member.MemberType -eq [System.Reflection.MemberTypes]::Field) {
            $isPublic = $member.IsPublic
            $isPrivate = $member.IsPrivate
            $isProtected = $member.IsFamily
            $isInternal = $member.IsAssembly
            $isProtectedInternal = $member.IsFamilyOrAssembly
            $isPrivateProtected = $member.IsFamilyAndAssembly
        } elseif ($member.MemberType -eq [System.Reflection.MemberTypes]::Property) {
            # Pour les propriÃ©tÃ©s, vÃ©rifier les accesseurs
            $getMethod = $member.GetGetMethod($true)  # Inclure les mÃ©thodes non-publiques
            $setMethod = $member.GetSetMethod($true)  # Inclure les mÃ©thodes non-publiques

            # Utiliser l'accesseur le plus accessible
            if ($null -ne $getMethod) {
                $isPublic = $isPublic -or $getMethod.IsPublic
                $isPrivate = $isPrivate -or $getMethod.IsPrivate
                $isProtected = $isProtected -or $getMethod.IsFamily
                $isInternal = $isInternal -or $getMethod.IsAssembly
                $isProtectedInternal = $isProtectedInternal -or $getMethod.IsFamilyOrAssembly
                $isPrivateProtected = $isPrivateProtected -or $getMethod.IsFamilyAndAssembly
            }

            if ($null -ne $setMethod) {
                $isPublic = $isPublic -or $setMethod.IsPublic
                $isPrivate = $isPrivate -or $setMethod.IsPrivate
                $isProtected = $isProtected -or $setMethod.IsFamily
                $isInternal = $isInternal -or $setMethod.IsAssembly
                $isProtectedInternal = $isProtectedInternal -or $setMethod.IsFamilyOrAssembly
                $isPrivateProtected = $isPrivateProtected -or $setMethod.IsFamilyAndAssembly
            }
        } elseif ($member.MemberType -eq [System.Reflection.MemberTypes]::Event) {
            # Pour les Ã©vÃ©nements, vÃ©rifier les accesseurs
            $addMethod = $member.GetAddMethod($true)  # Inclure les mÃ©thodes non-publiques
            $removeMethod = $member.GetRemoveMethod($true)  # Inclure les mÃ©thodes non-publiques

            # Utiliser l'accesseur le plus accessible
            if ($null -ne $addMethod) {
                $isPublic = $isPublic -or $addMethod.IsPublic
                $isPrivate = $isPrivate -or $addMethod.IsPrivate
                $isProtected = $isProtected -or $addMethod.IsFamily
                $isInternal = $isInternal -or $addMethod.IsAssembly
                $isProtectedInternal = $isProtectedInternal -or $addMethod.IsFamilyOrAssembly
                $isPrivateProtected = $isPrivateProtected -or $addMethod.IsFamilyAndAssembly
            }

            if ($null -ne $removeMethod) {
                $isPublic = $isPublic -or $removeMethod.IsPublic
                $isPrivate = $isPrivate -or $removeMethod.IsPrivate
                $isProtected = $isProtected -or $removeMethod.IsFamily
                $isInternal = $isInternal -or $removeMethod.IsAssembly
                $isProtectedInternal = $isProtectedInternal -or $removeMethod.IsFamilyOrAssembly
                $isPrivateProtected = $isPrivateProtected -or $removeMethod.IsFamilyAndAssembly
            }
        }

        # VÃ©rifier si l'accessibilitÃ© du membre correspond Ã  celle spÃ©cifiÃ©e
        $accessibilityMatches = $false
        foreach ($acc in $Accessibility) {
            switch ($acc) {
                "Public" { $accessibilityMatches = $accessibilityMatches -or $isPublic }
                "Private" { $accessibilityMatches = $accessibilityMatches -or $isPrivate }
                "Protected" { $accessibilityMatches = $accessibilityMatches -or $isProtected }
                "Internal" { $accessibilityMatches = $accessibilityMatches -or $isInternal }
                "ProtectedInternal" { $accessibilityMatches = $accessibilityMatches -or $isProtectedInternal }
                "PrivateProtected" { $accessibilityMatches = $accessibilityMatches -or $isPrivateProtected }
            }
        }

        # Appliquer le filtre personnalisÃ© si spÃ©cifiÃ©
        if ($accessibilityMatches -and $null -ne $Filter) {
            return $member | Where-Object $Filter
        }

        return $accessibilityMatches
    }

    return $filteredMembers
}

<#
.SYNOPSIS
    Analyse une classe d'exception.
.DESCRIPTION
    Cette fonction analyse une classe d'exception et retourne des informations dÃ©taillÃ©es sur ses propriÃ©tÃ©s, constructeurs et mÃ©thodes.
.PARAMETER ExceptionType
    Le type d'exception Ã  analyser.
.PARAMETER IncludeInheritedMembers
    Indique si les membres hÃ©ritÃ©s doivent Ãªtre inclus dans l'analyse.
.PARAMETER IncludePrivateMembers
    Indique si les membres privÃ©s doivent Ãªtre inclus dans l'analyse.
.EXAMPLE
    $ExceptionInfo = Get-ExceptionTypeInfo -ExceptionType ([System.ArgumentException])
.OUTPUTS
    PSObject - Un objet contenant des informations dÃ©taillÃ©es sur la classe d'exception.
#>
function Get-ExceptionTypeInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$ExceptionType,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInheritedMembers,

        [Parameter(Mandatory = $false)]
        [switch]$IncludePrivateMembers
    )

    # VÃ©rifier si le type est une exception
    if (-not [System.Exception].IsAssignableFrom($ExceptionType)) {
        throw "Le type '$($ExceptionType.FullName)' n'est pas une classe d'exception."
    }

    # DÃ©terminer les flags de liaison
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance

    if ($IncludePrivateMembers) {
        $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::NonPublic
    }

    # RÃ©cupÃ©rer les membres
    $getMembersParams = @{
        Type         = $ExceptionType
        BindingFlags = $bindingFlags
        Recursive    = $IncludeInheritedMembers
    }

    $membersByCategory = Get-TypeMembersByCategory @getMembersParams -Categories Property, Method, Constructor, Field

    # CrÃ©er l'objet rÃ©sultat
    $result = [PSCustomObject]@{
        Type                 = $ExceptionType
        FullName             = $ExceptionType.FullName
        BaseType             = $ExceptionType.BaseType
        IsAbstract           = $ExceptionType.IsAbstract
        IsSealed             = $ExceptionType.IsSealed
        Properties           = $membersByCategory["Property"]
        Methods              = $membersByCategory["Method"]
        Constructors         = $membersByCategory["Constructor"]
        Fields               = $membersByCategory["Field"]
        InheritanceHierarchy = @()
    }

    # Construire la hiÃ©rarchie d'hÃ©ritage
    $currentType = $ExceptionType
    while ($null -ne $currentType -and $currentType -ne [object]) {
        $result.InheritanceHierarchy += $currentType
        $currentType = $currentType.BaseType
    }

    return $result
}

<#
.SYNOPSIS
    Analyse une classe d'attribut.
.DESCRIPTION
    Cette fonction analyse une classe d'attribut et retourne des informations dÃ©taillÃ©es sur ses propriÃ©tÃ©s, constructeurs et cibles valides.
.PARAMETER AttributeType
    Le type d'attribut Ã  analyser.
.PARAMETER IncludeInheritedMembers
    Indique si les membres hÃ©ritÃ©s doivent Ãªtre inclus dans l'analyse.
.PARAMETER IncludePrivateMembers
    Indique si les membres privÃ©s doivent Ãªtre inclus dans l'analyse.
.EXAMPLE
    $AttributeInfo = Get-AttributeTypeInfo -AttributeType ([System.SerializableAttribute])
.OUTPUTS
    PSObject - Un objet contenant des informations dÃ©taillÃ©es sur la classe d'attribut.
#>
function Get-AttributeTypeInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$AttributeType,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInheritedMembers,

        [Parameter(Mandatory = $false)]
        [switch]$IncludePrivateMembers
    )

    # VÃ©rifier si le type est un attribut
    if (-not [System.Attribute].IsAssignableFrom($AttributeType)) {
        throw "Le type '$($AttributeType.FullName)' n'est pas une classe d'attribut."
    }

    # DÃ©terminer les flags de liaison
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance

    if ($IncludePrivateMembers) {
        $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::NonPublic
    }

    # RÃ©cupÃ©rer les membres
    $getMembersParams = @{
        Type         = $AttributeType
        BindingFlags = $bindingFlags
        Recursive    = $IncludeInheritedMembers
    }

    $membersByCategory = Get-TypeMembersByCategory @getMembersParams -Categories Property, Constructor

    # RÃ©cupÃ©rer les cibles valides de l'attribut
    $attributeUsageAttribute = $AttributeType.GetCustomAttributes([System.AttributeUsageAttribute], $true) | Select-Object -First 1
    $validTargets = if ($null -ne $attributeUsageAttribute) {
        $attributeUsageAttribute.ValidOn
    } else {
        [System.AttributeTargets]::All  # Valeur par dÃ©faut
    }

    $allowMultiple = if ($null -ne $attributeUsageAttribute) {
        $attributeUsageAttribute.AllowMultiple
    } else {
        $false  # Valeur par dÃ©faut
    }

    $inherited = if ($null -ne $attributeUsageAttribute) {
        $attributeUsageAttribute.Inherited
    } else {
        $true  # Valeur par dÃ©faut
    }

    # CrÃ©er l'objet rÃ©sultat
    $result = [PSCustomObject]@{
        Type                 = $AttributeType
        FullName             = $AttributeType.FullName
        BaseType             = $AttributeType.BaseType
        IsAbstract           = $AttributeType.IsAbstract
        IsSealed             = $AttributeType.IsSealed
        Properties           = $membersByCategory["Property"]
        Constructors         = $membersByCategory["Constructor"]
        ValidTargets         = $validTargets
        AllowMultiple        = $allowMultiple
        Inherited            = $inherited
        InheritanceHierarchy = @()
    }

    # Construire la hiÃ©rarchie d'hÃ©ritage
    $currentType = $AttributeType
    while ($null -ne $currentType -and $currentType -ne [object]) {
        $result.InheritanceHierarchy += $currentType
        $currentType = $currentType.BaseType
    }

    return $result
}

<#
.SYNOPSIS
    Analyse une classe d'Ã©numÃ©ration.
.DESCRIPTION
    Cette fonction analyse une classe d'Ã©numÃ©ration et retourne des informations dÃ©taillÃ©es sur ses valeurs et attributs.
.PARAMETER EnumType
    Le type d'Ã©numÃ©ration Ã  analyser.
.PARAMETER IncludeAttributes
    Indique si les attributs des valeurs d'Ã©numÃ©ration doivent Ãªtre inclus dans l'analyse.
.EXAMPLE
    $EnumInfo = Get-EnumTypeInfo -EnumType ([System.DayOfWeek])
.OUTPUTS
    PSObject - Un objet contenant des informations dÃ©taillÃ©es sur la classe d'Ã©numÃ©ration.
#>
function Get-EnumTypeInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$EnumType,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeAttributes
    )

    # VÃ©rifier si le type est une Ã©numÃ©ration
    if (-not $EnumType.IsEnum) {
        throw "Le type '$($EnumType.FullName)' n'est pas une Ã©numÃ©ration."
    }

    # RÃ©cupÃ©rer les valeurs de l'Ã©numÃ©ration
    $enumValues = [Enum]::GetValues($EnumType)
    $enumNames = [Enum]::GetNames($EnumType)

    # RÃ©cupÃ©rer le type sous-jacent
    $underlyingType = [Enum]::GetUnderlyingType($EnumType)

    # VÃ©rifier si l'Ã©numÃ©ration a l'attribut [Flags]
    $isFlagsEnum = $EnumType.GetCustomAttributes([System.FlagsAttribute], $false).Length -gt 0

    # CrÃ©er un tableau pour stocker les informations sur les valeurs
    $values = @()

    for ($i = 0; $i -lt $enumNames.Length; $i++) {
        $name = $enumNames[$i]
        $value = $enumValues[$i]
        $numericValue = [Convert]::ChangeType($value, $underlyingType)

        $valueInfo = [PSCustomObject]@{
            Name         = $name
            Value        = $value
            NumericValue = $numericValue
        }

        # Ajouter les attributs si demandÃ©
        if ($IncludeAttributes) {
            $field = $EnumType.GetField($name)
            $attributes = $field.GetCustomAttributes($false)
            $valueInfo | Add-Member -MemberType NoteProperty -Name "Attributes" -Value $attributes
        }

        $values += $valueInfo
    }

    # CrÃ©er l'objet rÃ©sultat
    $result = [PSCustomObject]@{
        Type           = $EnumType
        FullName       = $EnumType.FullName
        UnderlyingType = $underlyingType
        IsFlags        = $isFlagsEnum
        Values         = $values
    }

    return $result
}

# Exporter les fonctions
# Note: CommentÃ© pour permettre l'exÃ©cution en mode script
# Export-ModuleMember -Function Get-TypeByQualifiedName, ConvertFrom-TypeName, Search-TypeInAssemblies, Get-TypeResolutionError, Get-NonPublicType, New-StringComparer, Find-TypesByNamespace, Find-TypesByRegex, Set-TypeAlias, Remove-TypeAlias, Get-TypeAlias, Resolve-TypeAlias, Import-TypeAliases, Export-TypeAliases, Import-Assembly, Import-AssemblyFromStream, New-GenericType, Get-GenericTypeArguments, Test-GenericType, New-AnonymousType, New-DynamicType, New-NullableType, Get-TypeMembers, Get-TypeMembersRecursive, Get-TypeMembersByCategory, New-TypeMemberIterator, Get-TypeMembersByAttribute, Get-TypeMembersByReturnType, Get-TypeMembersByAccessibility, Get-ExceptionTypeInfo, Get-AttributeTypeInfo, Get-EnumTypeInfo
