<#
.SYNOPSIS
    Module de sélection de propriétés pour les styles Excel.
.DESCRIPTION
    Ce module fournit des fonctions pour sélectionner, filtrer et manipuler
    les propriétés des styles Excel lors des opérations de fusion.
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
    Crée un comparateur de chaînes personnalisé.
.DESCRIPTION
    Cette fonction crée un comparateur de chaînes personnalisé avec des options de sensibilité à la casse,
    de normalisation et de culture.
.PARAMETER IgnoreCase
    Indique si la comparaison doit être insensible à la casse.
.PARAMETER Culture
    La culture à utiliser pour la comparaison. Par défaut, utilise la culture invariante.
.PARAMETER IgnoreWhiteSpace
    Indique si les espaces blancs doivent être ignorés lors de la comparaison.
.PARAMETER IgnoreNonAlphanumeric
    Indique si les caractères non alphanumériques doivent être ignorés lors de la comparaison.
.EXAMPLE
    $Comparer = New-StringComparer -IgnoreCase -IgnoreWhiteSpace
    $result = $Comparer.Equals("Hello World", "HELLOWORLD")
.OUTPUTS
    System.StringComparer - Un comparateur de chaînes personnalisé.
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

    # Déterminer le comparateur de base
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

    # Si aucune option supplémentaire n'est spécifiée, retourner le comparateur de base
    if (-not $IgnoreWhiteSpace -and -not $IgnoreNonAlphanumeric) {
        return $baseComparer
    }

    # Créer un comparateur personnalisé avec les options spécifiées
    $customComparer = [PSCustomObject]@{
        BaseComparer          = $baseComparer
        IgnoreWhiteSpace      = $IgnoreWhiteSpace
        IgnoreNonAlphanumeric = $IgnoreNonAlphanumeric
    }

    # Ajouter les méthodes du comparateur
    $customComparer | Add-Member -MemberType ScriptMethod -Name "Equals" -Value {
        param([string]$x, [string]$y)

        # Normaliser les chaînes selon les options
        if ($this.IgnoreWhiteSpace) {
            $x = $x -replace '\s', ''
            $y = $y -replace '\s', ''
        }

        if ($this.IgnoreNonAlphanumeric) {
            $x = $x -replace '[^a-zA-Z0-9]', ''
            $y = $y -replace '[^a-zA-Z0-9]', ''
        }

        # Comparer les chaînes normalisées
        return $this.BaseComparer.Equals($x, $y)
    } -Force

    $customComparer | Add-Member -MemberType ScriptMethod -Name "Compare" -Value {
        param([string]$x, [string]$y)

        # Normaliser les chaînes selon les options
        if ($this.IgnoreWhiteSpace) {
            $x = $x -replace '\s', ''
            $y = $y -replace '\s', ''
        }

        if ($this.IgnoreNonAlphanumeric) {
            $x = $x -replace '[^a-zA-Z0-9]', ''
            $y = $y -replace '[^a-zA-Z0-9]', ''
        }

        # Comparer les chaînes normalisées
        return $this.BaseComparer.Compare($x, $y)
    } -Force

    $customComparer | Add-Member -MemberType ScriptMethod -Name "GetHashCode" -Value {
        param([string]$obj)

        # Normaliser la chaîne selon les options
        if ($this.IgnoreWhiteSpace) {
            $obj = $obj -replace '\s', ''
        }

        if ($this.IgnoreNonAlphanumeric) {
            $obj = $obj -replace '[^a-zA-Z0-9]', ''
        }

        # Calculer le code de hachage de la chaîne normalisée
        return $this.BaseComparer.GetHashCode($obj)
    } -Force

    return $customComparer
}

<#
.SYNOPSIS
    Récupère un type par son nom qualifié complet.
.DESCRIPTION
    Cette fonction récupère un type par son nom qualifié complet, en effectuant
    une recherche dans les assemblies chargées ou spécifiées.
.PARAMETER TypeName
    Le nom qualifié complet du type à récupérer.
.PARAMETER Assemblies
    Les assemblies dans lesquelles rechercher le type. Si non spécifié, recherche dans toutes les assemblies chargées.
.PARAMETER IgnoreCase
    Indique si la recherche doit être insensible à la casse.
.PARAMETER ThrowOnError
    Indique si une exception doit être levée en cas d'erreur de résolution.
.PARAMETER ResolveCollisions
    Indique comment résoudre les collisions de noms. Les valeurs possibles sont : FirstMatch, LastMatch, ThrowOnCollision, Interactive.
.PARAMETER AssemblyPriority
    Les assemblies prioritaires lors de la résolution des collisions. Les types trouvés dans ces assemblies seront préférés.
.EXAMPLE
    $Type = Get-TypeByQualifiedName -TypeName "System.String"
.EXAMPLE
    $Type = Get-TypeByQualifiedName -TypeName "MyNamespace.MyClass" -Assemblies $MyAssembly -IgnoreCase
.EXAMPLE
    $Type = Get-TypeByQualifiedName -TypeName "MyNamespace.MyClass" -ResolveCollisions "Interactive"
.OUTPUTS
    System.Type - Le type récupéré, ou $null si le type n'a pas été trouvé et ThrowOnError est $false.
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

    # Vérifier si le nom du type est valide
    if ([string]::IsNullOrWhiteSpace($TypeName)) {
        if ($ThrowOnError) {
            throw "Le nom du type ne peut pas être vide."
        }
        return $null
    }

    # Résoudre les alias de types
    $resolvedTypeName = Resolve-TypeAlias -TypeName $TypeName
    if ($resolvedTypeName -ne $TypeName) {
        Write-Verbose "Alias '$TypeName' résolu en '$resolvedTypeName'."
        $TypeName = $resolvedTypeName
    }

    # Essayer d'abord la méthode Type.GetType qui est la plus rapide
    try {
        $type = [Type]::GetType($TypeName, $false, $IgnoreCase)
        if ($null -ne $type) {
            Write-Verbose "Type '$TypeName' trouvé avec Type.GetType."
            return $type
        }
    } catch {
        Write-Verbose "Erreur lors de la recherche du type avec Type.GetType: $($_.Exception.Message)"
    }

    # Si aucune assembly n'est spécifiée, utiliser toutes les assemblies chargées
    if ($null -eq $Assemblies -or $Assemblies.Count -eq 0) {
        $Assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
        Write-Verbose "Recherche dans toutes les assemblies chargées ($($Assemblies.Count) assemblies)."
    } else {
        Write-Verbose "Recherche dans les assemblies spécifiées ($($Assemblies.Count) assemblies)."
    }

    # Fonction pour parser le nom du type et extraire l'espace de noms et le nom de type
    $typeInfo = ConvertFrom-TypeName -TypeName $TypeName
    $namespace = $typeInfo.Namespace
    $simpleTypeName = $typeInfo.TypeName

    # Rechercher tous les types correspondants dans les assemblies spécifiées
    $matchingTypes = @()

    foreach ($assembly in $Assemblies) {
        try {
            # Essayer d'abord avec le nom qualifié complet
            $type = $assembly.GetType($TypeName, $false, $IgnoreCase)
            if ($null -ne $type) {
                Write-Verbose "Type '$TypeName' trouvé dans l'assembly '$($assembly.FullName)'."
                $matchingTypes += @{
                    Type      = $type
                    Assembly  = $assembly
                    MatchType = "FullName"
                    Priority  = if ($null -ne $AssemblyPriority -and $AssemblyPriority -contains $assembly) { 1 } else { 0 }
                }
            }

            # Si le type n'est pas trouvé, essayer de rechercher par espace de noms et nom simple
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
                        Write-Verbose "Type '$namespace.$simpleTypeName' trouvé dans l'assembly '$($assembly.FullName)'."
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

    # Si aucun type n'est trouvé, retourner null ou lever une exception
    if ($matchingTypes.Count -eq 0) {
        if ($ThrowOnError) {
            throw "Le type '$TypeName' n'a pas été trouvé dans les assemblies spécifiées."
        }
        return $null
    }

    # Si un seul type est trouvé, le retourner directement
    if ($matchingTypes.Count -eq 1) {
        return $matchingTypes[0].Type
    }

    # Gérer les collisions selon la stratégie spécifiée
    Write-Verbose "$($matchingTypes.Count) types correspondants trouvés pour '$TypeName'. Résolution selon la stratégie '$ResolveCollisions'."

    # Trier les types par priorité (assemblies prioritaires d'abord)
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
            throw "Collision détectée pour le type '$TypeName'. Types trouvés dans les assemblies: $($assemblies -join ', ')"
        }
        "Interactive" {
            # Afficher les options à l'utilisateur
            Write-Host "Plusieurs types correspondants trouvés pour '$TypeName':" -ForegroundColor Yellow
            for ($i = 0; $i -lt $sortedTypes.Count; $i++) {
                $t = $sortedTypes[$i]
                $priority = if ($t.Priority -gt 0) { " (prioritaire)" } else { "" }
                Write-Host "  $($i+1). $($t.Type.FullName) dans $($t.Assembly.GetName().Name)$priority" -ForegroundColor Cyan
            }

            # Demander à l'utilisateur de choisir
            $choice = 0
            do {
                $userInput = Read-Host "Choisissez un type (1-$($sortedTypes.Count)) ou 'q' pour annuler"
                if ($userInput -eq 'q') {
                    if ($ThrowOnError) {
                        throw "Sélection annulée par l'utilisateur."
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
    Cette fonction convertit un nom de type qualifié en ses composants : l'espace de noms et le nom simple du type.
.PARAMETER TypeName
    Le nom qualifié du type à convertir.
.PARAMETER NormalizeName
    Indique si le nom du type doit être normalisé (suppression des caractères spéciaux, etc.).
.EXAMPLE
    $TypeInfo = ConvertFrom-TypeName -TypeName "System.Collections.Generic.List``1"
.OUTPUTS
    PSObject - Un objet contenant les propriétés Namespace et TypeName.
#>
function ConvertFrom-TypeName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$TypeName,

        [Parameter(Mandatory = $false)]
        [switch]$NormalizeName
    )

    # Initialiser les valeurs par défaut
    $namespace = ""
    $simpleTypeName = $TypeName

    # Vérifier si le nom du type contient un point (séparateur d'espace de noms)
    if ($TypeName -match '\.') {
        # Trouver le dernier point pour séparer l'espace de noms du nom de type
        $lastDotIndex = $TypeName.LastIndexOf('.')
        if ($lastDotIndex -gt 0) {
            $namespace = $TypeName.Substring(0, $lastDotIndex)
            $simpleTypeName = $TypeName.Substring($lastDotIndex + 1)
        }
    }

    # Gérer les types génériques (avec des backticks)
    if ($simpleTypeName -match '`') {
        # Extraire le nom de base du type générique (avant le backtick)
        $genericBaseNameMatch = [regex]::Match($simpleTypeName, '^([^`]+)`')
        if ($genericBaseNameMatch.Success) {
            $genericBaseName = $genericBaseNameMatch.Groups[1].Value

            # Extraire le nombre de paramètres de type
            $genericArityMatch = [regex]::Match($simpleTypeName, '`(\d+)')
            if ($genericArityMatch.Success) {
                $genericArity = [int]::Parse($genericArityMatch.Groups[1].Value)

                # Reconstruire le nom simple avec le format correct pour PowerShell
                $simpleTypeName = "$genericBaseName``$genericArity"
            }
        }
    }

    # Normaliser le nom si demandé
    if ($NormalizeName) {
        # Supprimer les caractères spéciaux et les espaces
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

    # Créer et retourner l'objet résultat
    return [PSCustomObject]@{
        Namespace = $namespace
        TypeName  = $simpleTypeName
    }
}

<#
.SYNOPSIS
    Recherche un type dans plusieurs assemblies avec gestion des erreurs.
.DESCRIPTION
    Cette fonction recherche un type dans plusieurs assemblies et gère les erreurs de résolution.
.PARAMETER TypeName
    Le nom qualifié du type à rechercher.
.PARAMETER Assemblies
    Les assemblies dans lesquelles rechercher le type. Si non spécifié, recherche dans toutes les assemblies chargées.
.PARAMETER IgnoreCase
    Indique si la recherche doit être insensible à la casse.
.PARAMETER IncludeErrors
    Indique si les erreurs de résolution doivent être incluses dans les résultats.
.EXAMPLE
    $SearchResult = Search-TypeInAssemblies -TypeName "System.String"
.OUTPUTS
    PSObject - Un objet contenant les propriétés Type, Assembly et Error.
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

    # Si aucune assembly n'est spécifiée, utiliser toutes les assemblies chargées
    if ($null -eq $Assemblies -or $Assemblies.Count -eq 0) {
        $Assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
    }

    # Initialiser les résultats comme un tableau vide
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

    # Si aucun résultat n'est trouvé, retourner un tableau vide plutôt que null
    if ($null -eq $results -or $results.Count -eq 0) {
        return @()
    }

    return $results
}

<#
.SYNOPSIS
    Récupère des informations détaillées sur une erreur de résolution de type.
.DESCRIPTION
    Cette fonction analyse les erreurs de résolution de type et fournit des informations détaillées sur l'erreur.
.PARAMETER TypeName
    Le nom qualifié du type qui n'a pas pu être résolu.
.PARAMETER ErrorInfo
    Les informations d'erreur à analyser.
.PARAMETER Assemblies
    Les assemblies dans lesquelles le type a été recherché.
.EXAMPLE
    $ErrorDetails = Get-TypeResolutionError -TypeName "MyNamespace.MyClass" -ErrorInfo $Error[0]
.OUTPUTS
    PSObject - Un objet contenant des informations détaillées sur l'erreur.
#>

<#
.SYNOPSIS
    Définit un alias de type.
.DESCRIPTION
    Cette fonction définit un alias pour un type, permettant d'utiliser un nom court ou alternatif
    pour référencer un type avec un nom qualifié complet.
.PARAMETER Alias
    L'alias à définir pour le type.
.PARAMETER TypeName
    Le nom qualifié complet du type.
.PARAMETER Force
    Indique si l'alias doit être remplacé s'il existe déjà.
.EXAMPLE
    Set-TypeAlias -Alias "str" -TypeName "System.String"
.OUTPUTS
    System.Boolean - True si l'alias a été défini avec succès, False sinon.
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

    # Vérifier si l'alias existe déjà
    if ($script:TypeAliases.ContainsKey($Alias) -and -not $Force) {
        Write-Warning "L'alias '$Alias' existe déjà pour le type '$($script:TypeAliases[$Alias])'. Utilisez -Force pour remplacer."
        return $false
    }

    # Définir l'alias
    $script:TypeAliases[$Alias] = $TypeName
    Write-Verbose "Alias '$Alias' défini pour le type '$TypeName'."

    return $true
}

<#
.SYNOPSIS
    Supprime un alias de type.
.DESCRIPTION
    Cette fonction supprime un alias de type précédemment défini.
.PARAMETER Alias
    L'alias à supprimer.
.EXAMPLE
    Remove-TypeAlias -Alias "str"
.OUTPUTS
    System.Boolean - True si l'alias a été supprimé avec succès, False sinon.
#>
function Remove-TypeAlias {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Alias
    )

    # Vérifier si l'alias existe
    if (-not $script:TypeAliases.ContainsKey($Alias)) {
        Write-Warning "L'alias '$Alias' n'existe pas."
        return $false
    }

    # Supprimer l'alias
    $script:TypeAliases.Remove($Alias) | Out-Null
    Write-Verbose "Alias '$Alias' supprimé."

    return $true
}

<#
.SYNOPSIS
    Obtient un alias de type ou tous les alias définis.
.DESCRIPTION
    Cette fonction retourne un alias de type spécifique ou tous les alias définis.
.PARAMETER Alias
    L'alias à obtenir. Si non spécifié, retourne tous les alias.
.EXAMPLE
    $TypeName = Get-TypeAlias -Alias "str"
.EXAMPLE
    $AllAliases = Get-TypeAlias
.OUTPUTS
    System.String - Le nom qualifié complet du type associé à l'alias, ou $null si l'alias n'existe pas.
    System.Collections.Hashtable - Tous les alias définis si aucun alias n'est spécifié.
#>
function Get-TypeAlias {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Alias
    )

    # Si aucun alias n'est spécifié, retourner tous les alias
    if ([string]::IsNullOrEmpty($Alias)) {
        return $script:TypeAliases.Clone()
    }

    # Vérifier si l'alias existe
    if (-not $script:TypeAliases.ContainsKey($Alias)) {
        Write-Warning "L'alias '$Alias' n'existe pas."
        return $null
    }

    # Retourner le nom qualifié complet du type associé à l'alias
    return $script:TypeAliases[$Alias]
}

<#
.SYNOPSIS
    Résout un nom de type en utilisant les alias définis.
.DESCRIPTION
    Cette fonction résout un nom de type en utilisant les alias définis, retournant le nom qualifié complet du type.
.PARAMETER TypeName
    Le nom du type à résoudre, qui peut être un alias ou un nom qualifié complet.
.EXAMPLE
    $ResolvedTypeName = Resolve-TypeAlias -TypeName "str"
.OUTPUTS
    System.String - Le nom qualifié complet du type résolu, ou le nom d'origine si aucun alias ne correspond.
#>
function Resolve-TypeAlias {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$TypeName
    )

    # Vérifier si le nom est un alias
    if ($script:TypeAliases.ContainsKey($TypeName)) {
        Write-Verbose "Alias '$TypeName' résolu en '$($script:TypeAliases[$TypeName])'."
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
    Le chemin du fichier JSON contenant les alias à importer.
.PARAMETER Force
    Indique si les alias existants doivent être remplacés.
.EXAMPLE
    Import-TypeAliases -Path "C:\Aliases\TypeAliases.json"
.OUTPUTS
    System.Int32 - Le nombre d'alias importés.
#>
function Import-TypeAliases {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier si le fichier existe
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

    Write-Verbose "$importedCount alias importés depuis '$Path'."
    return $importedCount
}

<#
.SYNOPSIS
    Exporte des alias de types vers un fichier JSON.
.DESCRIPTION
    Cette fonction exporte des alias de types vers un fichier JSON.
.PARAMETER Path
    Le chemin du fichier JSON où exporter les alias.
.PARAMETER Force
    Indique si le fichier doit être remplacé s'il existe déjà.
.EXAMPLE
    Export-TypeAliases -Path "C:\Aliases\TypeAliases.json"
.OUTPUTS
    System.Int32 - Le nombre d'alias exportés.
#>
function Export-TypeAliases {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier si le fichier existe déjà
    if (Test-Path -Path $Path) {
        if (-not $Force) {
            Write-Error "Le fichier '$Path' existe déjà. Utilisez -Force pour remplacer."
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

    Write-Verbose "$($aliases.Count) alias exportés vers '$Path'."
    return $aliases.Count
}

<#
.SYNOPSIS
    Récupère un type non-public par son nom qualifié.
.DESCRIPTION
    Cette fonction récupère un type non-public (interne, privé, etc.) par son nom qualifié,
    en utilisant la réflexion avancée pour accéder aux types non-publics.
.PARAMETER TypeName
    Le nom qualifié du type non-public à récupérer.
.PARAMETER Assembly
    L'assembly dans laquelle rechercher le type. Si non spécifié, recherche dans toutes les assemblies chargées.
.PARAMETER IncludeNestedTypes
    Indique si les types imbriqués doivent être inclus dans la recherche.
.PARAMETER ThrowOnError
    Indique si une exception doit être levée en cas d'erreur de résolution.
.EXAMPLE
    $Type = Get-NonPublicType -TypeName "System.RuntimeType+RuntimeTypeCache"
.OUTPUTS
    System.Type - Le type non-public récupéré, ou $null si le type n'a pas été trouvé et ThrowOnError est $false.
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

    # Déterminer les assemblies à rechercher
    $assemblies = @()
    if ($null -ne $Assembly) {
        $assemblies += $Assembly
    } else {
        $assemblies += [AppDomain]::CurrentDomain.GetAssemblies()
    }

    # Analyser le nom du type pour détecter les types imbriqués
    $isNestedType = $TypeName -match '\+'
    $parentTypeName = $null
    $nestedTypeName = $null

    if ($isNestedType) {
        $typeParts = $TypeName -split '\+', 2
        $parentTypeName = $typeParts[0]
        $nestedTypeName = $typeParts[1]
    }

    # Rechercher le type dans les assemblies spécifiées
    foreach ($asm in $assemblies) {
        try {
            # Si c'est un type imbriqué, rechercher d'abord le type parent
            if ($isNestedType) {
                $parentType = $asm.GetType($parentTypeName, $false, $true)
                if ($null -ne $parentType) {
                    # Rechercher le type imbriqué dans le type parent
                    $bindingFlags = [System.Reflection.BindingFlags]::NonPublic -bor
                    [System.Reflection.BindingFlags]::Public -bor
                    [System.Reflection.BindingFlags]::Instance -bor
                    [System.Reflection.BindingFlags]::Static

                    $nestedType = $parentType.GetNestedType($nestedTypeName, $bindingFlags)
                    if ($null -ne $nestedType) {
                        Write-Verbose "Type imbriqué non-public '$TypeName' trouvé dans l'assembly '$($asm.FullName)'."
                        return $nestedType
                    }
                }
            } else {
                # Essayer de récupérer tous les types de l'assembly, y compris les types non-publics
                $types = $asm.GetTypes() | Where-Object { $_.FullName -eq $TypeName -or $_.Name -eq $TypeName }

                if ($null -ne $types -and $types.Count -gt 0) {
                    Write-Verbose "Type non-public '$TypeName' trouvé dans l'assembly '$($asm.FullName)'."
                    return $types[0]
                }

                # Si IncludeNestedTypes est spécifié, rechercher dans les types imbriqués
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
                            Write-Verbose "Type imbriqué non-public '$TypeName' trouvé dans l'assembly '$($asm.FullName)'."
                            return $matchingNestedType[0]
                        }
                    }
                }
            }
        } catch {
            Write-Verbose "Erreur lors de la recherche du type non-public dans l'assembly '$($asm.FullName)': $($_.Exception.Message)"
        }
    }

    # Si le type n'est pas trouvé et ThrowOnError est spécifié, lever une exception
    if ($ThrowOnError) {
        throw "Le type non-public '$TypeName' n'a pas été trouvé dans les assemblies spécifiées."
    }

    # Sinon, retourner null
    Write-Verbose "Le type non-public '$TypeName' n'a pas été trouvé."
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

    # Déterminer le type d'erreur
    $errorCategory = "Unknown"
    $suggestion = ""

    if ($errorMessage -match "Could not load file or assembly") {
        $errorCategory = "AssemblyLoadError"
        $suggestion = "Vérifiez que l'assembly est accessible et que toutes ses dépendances sont satisfaites."
    } elseif ($errorMessage -match "The type or namespace name .* could not be found") {
        $errorCategory = "TypeNotFoundError"
        $suggestion = "Vérifiez l'orthographe du nom de type et assurez-vous que l'assembly contenant ce type est chargé."
    } elseif ($errorMessage -match "Ambiguous match found") {
        $errorCategory = "AmbiguousMatchError"
        $suggestion = "Utilisez le nom qualifié complet du type pour éviter les ambiguïtés."
    }

    # Créer l'objet de détails d'erreur
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
    Recherche des types par expression régulière.
.DESCRIPTION
    Cette fonction recherche des types dont le nom correspond à une expression régulière spécifiée.
.PARAMETER Pattern
    L'expression régulière à utiliser pour la recherche.
.PARAMETER Assemblies
    Les assemblies dans lesquelles rechercher les types. Si non spécifié, recherche dans toutes les assemblies chargées.
.PARAMETER SearchFullName
    Indique si la recherche doit porter sur le nom qualifié complet du type (espace de noms + nom).
.PARAMETER IgnoreCase
    Indique si la recherche doit être insensible à la casse.
.PARAMETER MaxResults
    Le nombre maximum de résultats à retourner. Si non spécifié, retourne tous les résultats.
.EXAMPLE
    $Types = Find-TypesByRegex -Pattern "^System\.Collections\.Generic\..*Dictionary.*$"
.OUTPUTS
    System.Type[] - Les types correspondant à l'expression régulière spécifiée.
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

    # Si aucune assembly n'est spécifiée, utiliser toutes les assemblies chargées
    if ($null -eq $Assemblies -or $Assemblies.Count -eq 0) {
        $Assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
    }

    # Créer l'expression régulière
    $regexOptions = [System.Text.RegularExpressions.RegexOptions]::Compiled
    if ($IgnoreCase) {
        $regexOptions = $regexOptions -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    }

    try {
        $regex = New-Object System.Text.RegularExpressions.Regex($Pattern, $regexOptions)
    } catch {
        Write-Error "Erreur lors de la création de l'expression régulière: $($_.Exception.Message)"
        return @()
    }

    # Rechercher les types correspondants
    $result = @()
    $count = 0

    foreach ($assembly in $Assemblies) {
        try {
            $types = $assembly.GetTypes()

            foreach ($type in $types) {
                # Déterminer la chaîne à rechercher
                $searchString = if ($SearchFullName) { $type.FullName } else { $type.Name }

                # Vérifier si le type correspond à l'expression régulière
                if ($regex.IsMatch($searchString)) {
                    $result += $type
                    $count++

                    # Vérifier si le nombre maximum de résultats est atteint
                    if ($MaxResults -gt 0 -and $count -ge $MaxResults) {
                        Write-Verbose "Nombre maximum de résultats atteint ($MaxResults)."
                        return $result
                    }
                }
            }
        } catch {
            Write-Verbose "Erreur lors de la recherche des types dans l'assembly '$($assembly.FullName)': $($_.Exception.Message)"
        }
    }

    Write-Verbose "$count types correspondant à l'expression régulière '$Pattern' trouvés."
    return $result
}

<#
.SYNOPSIS
    Charge une assembly depuis un chemin de fichier.
.DESCRIPTION
    Cette fonction charge une assembly depuis un chemin de fichier, avec des options pour la résolution des dépendances
    et le chargement en contexte isolé.
.PARAMETER Path
    Le chemin du fichier d'assembly à charger.
.PARAMETER ResolveReferences
    Indique si les références de l'assembly doivent être résolues automatiquement.
.PARAMETER IsolatedContext
    Indique si l'assembly doit être chargée dans un contexte isolé.
.PARAMETER ReferencePaths
    Les chemins où rechercher les assemblies référencées.
.EXAMPLE
    $Assembly = Import-Assembly -Path "C:\MyAssemblies\MyLibrary.dll"
.EXAMPLE
    $Assembly = Import-Assembly -Path "C:\MyAssemblies\MyLibrary.dll" -ResolveReferences -ReferencePaths "C:\References"
.OUTPUTS
    System.Reflection.Assembly - L'assembly chargée.
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

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le fichier d'assembly '$Path' n'existe pas."
        return $null
    }

    try {
        # Obtenir le chemin absolu
        $absolutePath = (Resolve-Path -Path $Path).Path

        # Créer un gestionnaire de résolution des dépendances si nécessaire
        if ($ResolveReferences) {
            # Créer un gestionnaire d'événements pour la résolution des assemblies
            $resolveEventHandler = {
                param($senderObj, $resolveArgs)

                $assemblyName = $resolveArgs.Name
                Write-Verbose "Tentative de résolution de l'assembly: $assemblyName"

                # Rechercher dans les chemins de référence spécifiés
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
                            Write-Verbose "Assembly '$assemblyName' résolue à '$dllPath'."
                            return [System.Reflection.Assembly]::LoadFrom($dllPath)
                        }
                    }
                }

                # Essayer de résoudre l'assembly par son nom
                try {
                    return [System.Reflection.Assembly]::Load($assemblyName)
                } catch {
                    Write-Verbose "Impossible de résoudre l'assembly '$assemblyName': $($_.Exception.Message)"
                    return $null
                }
            }

            # Ajouter le gestionnaire d'événements
            [System.AppDomain]::CurrentDomain.add_AssemblyResolve($resolveEventHandler)
        }

        # Charger l'assembly
        $assembly = if ($IsolatedContext) {
            # Créer un contexte de chargement isolé
            $context = [System.Reflection.Assembly]::LoadFile($absolutePath)
            $context
        } else {
            # Charger l'assembly dans le contexte actuel
            [System.Reflection.Assembly]::LoadFrom($absolutePath)
        }

        Write-Verbose "Assembly '$Path' chargée avec succès."
        return $assembly
    } catch {
        Write-Error "Erreur lors du chargement de l'assembly '$Path': $($_.Exception.Message)"
        return $null
    } finally {
        # Supprimer le gestionnaire d'événements si nécessaire
        if ($ResolveReferences) {
            [System.AppDomain]::CurrentDomain.remove_AssemblyResolve($resolveEventHandler)
        }
    }
}

<#
.SYNOPSIS
    Charge une assembly depuis un flux de données.
.DESCRIPTION
    Cette fonction charge une assembly depuis un flux de données, avec des options pour la résolution des dépendances
    et le chargement en contexte isolé.
.PARAMETER Stream
    Le flux de données contenant l'assembly à charger.
.PARAMETER SymbolStream
    Le flux de données contenant les symboles de débogage (PDB) de l'assembly.
.PARAMETER ResolveReferences
    Indique si les références de l'assembly doivent être résolues automatiquement.
.PARAMETER IsolatedContext
    Indique si l'assembly doit être chargée dans un contexte isolé.
.PARAMETER ReferencePaths
    Les chemins où rechercher les assemblies référencées.
.EXAMPLE
    $Assembly = Import-AssemblyFromStream -Stream $stream
.EXAMPLE
    $Assembly = Import-AssemblyFromStream -Stream $stream -SymbolStream $symbolStream -ResolveReferences
.OUTPUTS
    System.Reflection.Assembly - L'assembly chargée.
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
        # Lire les données du flux
        $assemblyData = New-Object byte[] $Stream.Length
        $Stream.Read($assemblyData, 0, $Stream.Length) | Out-Null
        $Stream.Position = 0

        # Lire les données des symboles si spécifié
        $symbolData = $null
        if ($null -ne $SymbolStream) {
            $symbolData = New-Object byte[] $SymbolStream.Length
            $SymbolStream.Read($symbolData, 0, $SymbolStream.Length) | Out-Null
            $SymbolStream.Position = 0
        }

        # Créer un gestionnaire de résolution des dépendances si nécessaire
        if ($ResolveReferences) {
            # Créer un gestionnaire d'événements pour la résolution des assemblies
            $resolveEventHandler = {
                param($senderObj, $resolveArgs)

                $assemblyName = $resolveArgs.Name
                Write-Verbose "Tentative de résolution de l'assembly: $assemblyName"

                # Rechercher dans les chemins de référence spécifiés
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
                            Write-Verbose "Assembly '$assemblyName' résolue à '$dllPath'."
                            return [System.Reflection.Assembly]::LoadFrom($dllPath)
                        }
                    }
                }

                # Essayer de résoudre l'assembly par son nom
                try {
                    return [System.Reflection.Assembly]::Load($assemblyName)
                } catch {
                    Write-Verbose "Impossible de résoudre l'assembly '$assemblyName': $($_.Exception.Message)"
                    return $null
                }
            }

            # Ajouter le gestionnaire d'événements
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

        Write-Verbose "Assembly chargée avec succès depuis le flux."
        return $assembly
    } catch {
        Write-Error "Erreur lors du chargement de l'assembly depuis le flux: $($_.Exception.Message)"
        return $null
    } finally {
        # Supprimer le gestionnaire d'événements si nécessaire
        if ($ResolveReferences) {
            [System.AppDomain]::CurrentDomain.remove_AssemblyResolve($resolveEventHandler)
        }
    }
}

<#
.SYNOPSIS
    Recherche des types par espace de noms.
.DESCRIPTION
    Cette fonction recherche des types dans un espace de noms spécifié, avec des options de filtrage et de recherche hiérarchique.
.PARAMETER Namespace
    L'espace de noms dans lequel rechercher les types.
.PARAMETER Assemblies
    Les assemblies dans lesquelles rechercher les types. Si non spécifié, recherche dans toutes les assemblies chargées.
.PARAMETER IncludeSubNamespaces
    Indique si les sous-espaces de noms doivent être inclus dans la recherche.
.PARAMETER Filter
    Un filtre pour limiter les types retournés (ex: "*Controller", "I*Repository").
.PARAMETER IgnoreCase
    Indique si la recherche doit être insensible à la casse.
.EXAMPLE
    $Types = Find-TypesByNamespace -Namespace "System.Collections.Generic" -Filter "*Dictionary*"
.OUTPUTS
    System.Type[] - Les types trouvés dans l'espace de noms spécifié.
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

    # Si aucune assembly n'est spécifiée, utiliser toutes les assemblies chargées
    if ($null -eq $Assemblies -or $Assemblies.Count -eq 0) {
        $Assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
    }

    # Créer un index des types par espace de noms
    $namespaceIndex = @{}

    foreach ($assembly in $Assemblies) {
        try {
            $types = $assembly.GetTypes()

            foreach ($type in $types) {
                # Ignorer les types sans espace de noms
                if ([string]::IsNullOrEmpty($type.Namespace)) {
                    continue
                }

                # Ajouter le type à l'index
                if (-not $namespaceIndex.ContainsKey($type.Namespace)) {
                    $namespaceIndex[$type.Namespace] = @()
                }

                $namespaceIndex[$type.Namespace] += $type
            }
        } catch {
            Write-Verbose "Erreur lors de l'indexation des types dans l'assembly '$($assembly.FullName)': $($_.Exception.Message)"
        }
    }

    # Rechercher les types dans l'espace de noms spécifié
    $result = @()

    # Déterminer les espaces de noms à inclure
    $namespacesToSearch = @()

    if ($IncludeSubNamespaces) {
        # Inclure l'espace de noms spécifié et tous ses sous-espaces de noms
        $namespacesToSearch = $namespaceIndex.Keys | Where-Object {
            if ($IgnoreCase) {
                $_ -eq $Namespace -or $_.StartsWith("$Namespace.", [StringComparison]::OrdinalIgnoreCase)
            } else {
                $_ -eq $Namespace -or $_.StartsWith("$Namespace.")
            }
        }
    } else {
        # Inclure uniquement l'espace de noms spécifié
        $namespacesToSearch = $namespaceIndex.Keys | Where-Object {
            if ($IgnoreCase) {
                $_ -eq $Namespace
            } else {
                $_ -eq $Namespace
            }
        }
    }

    # Ajouter les types des espaces de noms sélectionnés
    foreach ($ns in $namespacesToSearch) {
        $typesInNamespace = $namespaceIndex[$ns]

        # Appliquer le filtre si spécifié
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
    Crée un type générique avec les arguments de type spécifiés.
.DESCRIPTION
    Cette fonction crée un type générique avec les arguments de type spécifiés, en résolvant
    automatiquement les types génériques et leurs arguments.
.PARAMETER GenericTypeName
    Le nom qualifié complet du type générique (sans les arguments de type).
.PARAMETER TypeArguments
    Les arguments de type à utiliser pour construire le type générique.
.PARAMETER Assemblies
    Les assemblies dans lesquelles rechercher le type générique. Si non spécifié, recherche dans toutes les assemblies chargées.
.PARAMETER ThrowOnError
    Indique si une exception doit être levée en cas d'erreur de résolution.
.EXAMPLE
    $ListOfString = New-GenericType -GenericTypeName "System.Collections.Generic.List" -TypeArguments ([string])
.EXAMPLE
    $DictionaryOfStringInt = New-GenericType -GenericTypeName "System.Collections.Generic.Dictionary" -TypeArguments @([string], [int])
.OUTPUTS
    System.Type - Le type générique construit, ou $null si le type n'a pas pu être construit et ThrowOnError est $false.
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
        # Résoudre le type générique non construit
        $genericTypeDefinition = Get-TypeByQualifiedName -TypeName $GenericTypeName -Assemblies $Assemblies -ThrowOnError:$ThrowOnError
        if ($null -eq $genericTypeDefinition) {
            return $null
        }

        # Vérifier si le type est générique
        if (-not $genericTypeDefinition.IsGenericTypeDefinition) {
            $errorMessage = "Le type '$GenericTypeName' n'est pas un type générique."
            if ($ThrowOnError) {
                throw $errorMessage
            }
            Write-Warning $errorMessage
            return $null
        }

        # Vérifier si le nombre d'arguments de type est correct
        $genericArguments = $genericTypeDefinition.GetGenericArguments()
        if ($genericArguments.Length -ne $TypeArguments.Length) {
            $errorMessage = "Le type générique '$GenericTypeName' attend $($genericArguments.Length) arguments de type, mais $($TypeArguments.Length) ont été fournis."
            if ($ThrowOnError) {
                throw $errorMessage
            }
            Write-Warning $errorMessage
            return $null
        }

        # Construire le type générique
        $constructedType = $genericTypeDefinition.MakeGenericType($TypeArguments)
        Write-Verbose "Type générique '$GenericTypeName' construit avec succès: $($constructedType.FullName)"

        return $constructedType
    } catch {
        $errorMessage = "Erreur lors de la construction du type générique '$GenericTypeName': $($_.Exception.Message)"
        if ($ThrowOnError) {
            throw $errorMessage
        }
        Write-Warning $errorMessage
        return $null
    }
}

<#
.SYNOPSIS
    Récupère les arguments de type d'un type générique construit.
.DESCRIPTION
    Cette fonction récupère les arguments de type d'un type générique construit.
.PARAMETER Type
    Le type générique construit dont on veut récupérer les arguments de type.
.PARAMETER ThrowOnError
    Indique si une exception doit être levée en cas d'erreur.
.EXAMPLE
    $TypeArguments = Get-GenericTypeArguments -Type ([System.Collections.Generic.List[string]])
.OUTPUTS
    System.Type[] - Les arguments de type du type générique construit, ou $null si le type n'est pas générique et ThrowOnError est $false.
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
        # Vérifier si le type est générique
        if (-not $Type.IsGenericType) {
            $errorMessage = "Le type '$($Type.FullName)' n'est pas un type générique."
            if ($ThrowOnError) {
                throw $errorMessage
            }
            Write-Warning $errorMessage
            return $null
        }

        # Récupérer les arguments de type
        $typeArguments = $Type.GetGenericArguments()
        Write-Verbose "Arguments de type récupérés pour le type '$($Type.FullName)': $($typeArguments.Length) arguments."

        return $typeArguments
    } catch {
        $errorMessage = "Erreur lors de la récupération des arguments de type pour le type '$($Type.FullName)': $($_.Exception.Message)"
        if ($ThrowOnError) {
            throw $errorMessage
        }
        Write-Warning $errorMessage
        return $null
    }
}

<#
.SYNOPSIS
    Vérifie si un type est un type générique ou un type générique construit.
.DESCRIPTION
    Cette fonction vérifie si un type est un type générique ou un type générique construit.
.PARAMETER Type
    Le type à vérifier.
.PARAMETER ConstructedOnly
    Indique si seuls les types génériques construits doivent être considérés comme génériques.
.PARAMETER DefinitionOnly
    Indique si seuls les définitions de types génériques doivent être considérées comme génériques.
.EXAMPLE
    $IsGeneric = Test-GenericType -Type ([System.Collections.Generic.List[string]])
.OUTPUTS
    System.Boolean - True si le type est générique, False sinon.
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

    # Vérifier si le type est générique
    $isGeneric = $Type.IsGenericType

    # Si le type n'est pas générique, retourner False
    if (-not $isGeneric) {
        return $false
    }

    # Vérifier si le type est une définition de type générique
    $isGenericTypeDefinition = $Type.IsGenericTypeDefinition

    # Appliquer les filtres spécifiés
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
    Crée un type anonyme avec les propriétés spécifiées.
.DESCRIPTION
    Cette fonction crée un type anonyme avec les propriétés spécifiées, similaire aux types anonymes en C#.
.PARAMETER Properties
    Les propriétés à inclure dans le type anonyme, sous forme de table de hachage.
.EXAMPLE
    $AnonymousType = New-AnonymousType -Properties @{ Name = "John"; Age = 30 }
.OUTPUTS
    PSObject - Un objet avec les propriétés spécifiées.
#>
function New-AnonymousType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [hashtable]$Properties
    )

    # Créer un objet PSObject
    $anonymousType = New-Object PSObject

    # Ajouter les propriétés spécifiées
    foreach ($key in $Properties.Keys) {
        $value = $Properties[$key]
        $anonymousType | Add-Member -MemberType NoteProperty -Name $key -Value $value
    }

    # Ajouter une méthode ToString personnalisée
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

    # Ajouter une méthode Equals personnalisée
    $anonymousType | Add-Member -MemberType ScriptMethod -Name "Equals" -Value {
        param([object]$obj)

        if ($null -eq $obj) {
            return $false
        }

        if ($this -eq $obj) {
            return $true
        }

        # Vérifier si l'objet a les mêmes propriétés
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

    # Ajouter une méthode GetHashCode personnalisée
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
    Crée un type dynamique avec les propriétés et méthodes spécifiées.
.DESCRIPTION
    Cette fonction crée un type dynamique avec les propriétés et méthodes spécifiées, en utilisant System.Reflection.Emit.
.PARAMETER TypeName
    Le nom du type dynamique à créer.
.PARAMETER Properties
    Les propriétés à inclure dans le type dynamique, sous forme de table de hachage où les clés sont les noms des propriétés et les valeurs sont les types des propriétés.
.PARAMETER Methods
    Les méthodes à inclure dans le type dynamique, sous forme de table de hachage où les clés sont les noms des méthodes et les valeurs sont des objets décrivant les méthodes.
.PARAMETER Interfaces
    Les interfaces que le type dynamique doit implémenter.
.PARAMETER BaseType
    Le type de base du type dynamique. Par défaut, System.Object.
.EXAMPLE
    $DynamicType = New-DynamicType -TypeName "MyDynamicType" -Properties @{ Name = [string]; Age = [int] }
.OUTPUTS
    System.Type - Le type dynamique créé.
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
        # Créer un nom d'assembly dynamique
        $assemblyName = New-Object System.Reflection.AssemblyName("DynamicAssembly")
        $assemblyBuilder = [System.AppDomain]::CurrentDomain.DefineDynamicAssembly($assemblyName, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
        $moduleBuilder = $assemblyBuilder.DefineDynamicModule("DynamicModule")

        # Créer le type dynamique
        $typeBuilder = $moduleBuilder.DefineType($TypeName, [System.Reflection.TypeAttributes]::Public -bor [System.Reflection.TypeAttributes]::Class, $BaseType, $Interfaces)

        # Ajouter les propriétés
        foreach ($propertyName in $Properties.Keys) {
            $propertyType = $Properties[$propertyName]

            # Créer le champ privé pour la propriété
            $fieldBuilder = $typeBuilder.DefineField("_$propertyName", $propertyType, [System.Reflection.FieldAttributes]::Private)

            # Créer la propriété
            $propertyBuilder = $typeBuilder.DefineProperty($propertyName, [System.Reflection.PropertyAttributes]::HasDefault, $propertyType, $null)

            # Créer la méthode getter
            $getMethodBuilder = $typeBuilder.DefineMethod("get_$propertyName", [System.Reflection.MethodAttributes]::Public -bor [System.Reflection.MethodAttributes]::SpecialName -bor [System.Reflection.MethodAttributes]::HideBySig, $propertyType, $null)
            $ilGenerator = $getMethodBuilder.GetILGenerator()
            $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ldarg_0)
            $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ldfld, $fieldBuilder)
            $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ret)

            # Créer la méthode setter
            $setMethodBuilder = $typeBuilder.DefineMethod("set_$propertyName", [System.Reflection.MethodAttributes]::Public -bor [System.Reflection.MethodAttributes]::SpecialName -bor [System.Reflection.MethodAttributes]::HideBySig, $null, @($propertyType))
            $ilGenerator = $setMethodBuilder.GetILGenerator()
            $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ldarg_0)
            $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ldarg_1)
            $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Stfld, $fieldBuilder)
            $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ret)

            # Associer les méthodes getter et setter à la propriété
            $propertyBuilder.SetGetMethod($getMethodBuilder)
            $propertyBuilder.SetSetMethod($setMethodBuilder)
        }

        # Ajouter les méthodes
        foreach ($methodName in $Methods.Keys) {
            $methodInfo = $Methods[$methodName]

            # Extraire les informations de la méthode
            $returnType = $methodInfo.ReturnType
            $parameterTypes = $methodInfo.ParameterTypes
            $methodAttributes = $methodInfo.Attributes -bor [System.Reflection.MethodAttributes]::Public -bor [System.Reflection.MethodAttributes]::HideBySig

            # Créer la méthode
            $methodBuilder = $typeBuilder.DefineMethod($methodName, $methodAttributes, $returnType, $parameterTypes)

            # Générer le code IL pour la méthode
            $ilGenerator = $methodBuilder.GetILGenerator()

            # Si une implémentation est fournie, l'utiliser
            if ($methodInfo.Implementation) {
                $methodInfo.Implementation.Invoke($ilGenerator)
            } else {
                # Implémentation par défaut : retourner la valeur par défaut du type de retour
                if ($returnType -eq [void]) {
                    $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ret)
                } else {
                    $ilGenerator.DeclareLocal($returnType)
                    $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ldloc_0)
                    $ilGenerator.Emit([System.Reflection.Emit.OpCodes]::Ret)
                }
            }
        }

        # Créer le type
        $type = $typeBuilder.CreateType()
        Write-Verbose "Type dynamique '$TypeName' créé avec succès."

        return $type
    } catch {
        Write-Error "Erreur lors de la création du type dynamique '$TypeName': $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
    Crée un type Nullable pour un type de valeur.
.DESCRIPTION
    Cette fonction crée un type Nullable pour un type de valeur spécifié.
.PARAMETER ValueType
    Le type de valeur pour lequel créer un type Nullable.
.EXAMPLE
    $NullableInt = New-NullableType -ValueType ([int])
.OUTPUTS
    System.Type - Le type Nullable créé.
#>
function New-NullableType {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$ValueType
    )

    # Vérifier si le type est un type de valeur
    if (-not $ValueType.IsValueType) {
        throw "Le type '$($ValueType.FullName)' n'est pas un type de valeur. Seuls les types de valeur peuvent être rendus nullables."
    }

    # Vérifier si le type est déjà un type Nullable
    if ($ValueType.IsGenericType -and $ValueType.GetGenericTypeDefinition() -eq [System.Nullable`1]) {
        Write-Warning "Le type '$($ValueType.FullName)' est déjà un type Nullable."
        return $ValueType
    }

    # Créer le type Nullable
    $nullableType = [System.Nullable`1].MakeGenericType($ValueType)
    Write-Verbose "Type Nullable créé pour le type '$($ValueType.FullName)'."

    return $nullableType
}

<#
.SYNOPSIS
    Parcourt les membres d'un type.
.DESCRIPTION
    Cette fonction parcourt les membres d'un type, avec des options pour filtrer par type de membre,
    flags de liaison, et pour effectuer un parcours récursif.
.PARAMETER Type
    Le type dont on veut parcourir les membres.
.PARAMETER MemberTypes
    Les types de membres à inclure dans le parcours. Par défaut, tous les types de membres sont inclus.
.PARAMETER BindingFlags
    Les flags de liaison à utiliser pour la récupération des membres. Par défaut, les membres publics et d'instance sont inclus.
.PARAMETER Recursive
    Indique si le parcours doit être récursif (inclure les membres des types de base).
.PARAMETER IncludeSpecialNames
    Indique si les membres avec des noms spéciaux (ex: .ctor, .cctor) doivent être inclus.
.PARAMETER Filter
    Un prédicat pour filtrer les membres retournés.
.EXAMPLE
    $Members = Get-TypeMembers -Type ([System.String])
.EXAMPLE
    $Properties = Get-TypeMembers -Type ([System.String]) -MemberTypes Property -BindingFlags ([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance)
.OUTPUTS
    System.Reflection.MemberInfo[] - Les membres du type qui correspondent aux critères spécifiés.
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

    # Ajouter les flags pour les membres statiques et non-publics si nécessaire
    if (-not ($BindingFlags -band [System.Reflection.BindingFlags]::Static)) {
        Write-Verbose "Flags de liaison ne contiennent pas Static. Seuls les membres d'instance seront retournés."
    }

    if (-not ($BindingFlags -band [System.Reflection.BindingFlags]::NonPublic)) {
        Write-Verbose "Flags de liaison ne contiennent pas NonPublic. Seuls les membres publics seront retournés."
    }

    # Ajouter le flag FlattenHierarchy si Recursive est spécifié
    if ($Recursive) {
        $BindingFlags = $BindingFlags -bor [System.Reflection.BindingFlags]::FlattenHierarchy
    }

    # Récupérer les membres du type
    $members = $Type.GetMembers($BindingFlags)

    # Filtrer par type de membre si spécifié
    if ($MemberTypes -ne [System.Reflection.MemberTypes]::All) {
        $members = $members | Where-Object { $_.MemberType -band $MemberTypes }
    }

    # Filtrer les membres avec des noms spéciaux si nécessaire
    if (-not $IncludeSpecialNames) {
        $members = $members | Where-Object { -not $_.Name.StartsWith(".") }  # Exclure les noms comme .ctor, .cctor, etc.
    }

    # Appliquer le filtre personnalisé si spécifié
    if ($null -ne $Filter) {
        $members = $members | Where-Object $Filter
    }

    return $members
}

<#
.SYNOPSIS
    Parcourt les membres d'un type de manière récursive.
.DESCRIPTION
    Cette fonction parcourt les membres d'un type de manière récursive, en incluant les membres des types de base.
.PARAMETER Type
    Le type dont on veut parcourir les membres.
.PARAMETER MemberTypes
    Les types de membres à inclure dans le parcours. Par défaut, tous les types de membres sont inclus.
.PARAMETER BindingFlags
    Les flags de liaison à utiliser pour la récupération des membres. Par défaut, les membres publics et d'instance sont inclus.
.PARAMETER MaxDepth
    La profondeur maximale de récursion. Par défaut, il n'y a pas de limite.
.PARAMETER IncludeSpecialNames
    Indique si les membres avec des noms spéciaux (ex: .ctor, .cctor) doivent être inclus.
.PARAMETER Filter
    Un prédicat pour filtrer les membres retournés.
.EXAMPLE
    $AllMembers = Get-TypeMembersRecursive -Type ([System.String])
.EXAMPLE
    $AllProperties = Get-TypeMembersRecursive -Type ([System.String]) -MemberTypes Property -MaxDepth 2
.OUTPUTS
    System.Reflection.MemberInfo[] - Les membres du type qui correspondent aux critères spécifiés.
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

    # Fonction récursive interne
    function Get-MembersRecursive {
        param (
            [type]$CurrentType,
            [int]$CurrentDepth = 0
        )

        # Vérifier si la profondeur maximale est atteinte
        if ($MaxDepth -ne -1 -and $CurrentDepth -gt $MaxDepth) {
            return @()
        }

        # Récupérer les membres du type courant
        $currentMembers = Get-TypeMembers -Type $CurrentType -MemberTypes $MemberTypes -BindingFlags $BindingFlags -IncludeSpecialNames:$IncludeSpecialNames -Filter $Filter

        # Si le type a un type de base, récupérer ses membres récursivement
        $baseMembers = @()
        if ($null -ne $CurrentType.BaseType -and $CurrentType.BaseType -ne [object]) {
            $baseMembers = Get-MembersRecursive -CurrentType $CurrentType.BaseType -CurrentDepth ($CurrentDepth + 1)
        }

        # Combiner les membres du type courant et des types de base
        return $currentMembers + $baseMembers
    }

    # Appeler la fonction récursive
    return Get-MembersRecursive -CurrentType $Type
}

<#
.SYNOPSIS
    Parcourt les membres d'un type par catégorie.
.DESCRIPTION
    Cette fonction parcourt les membres d'un type et les regroupe par catégorie (propriétés, méthodes, événements, etc.).
.PARAMETER Type
    Le type dont on veut parcourir les membres.
.PARAMETER BindingFlags
    Les flags de liaison à utiliser pour la récupération des membres. Par défaut, les membres publics et d'instance sont inclus.
.PARAMETER Recursive
    Indique si le parcours doit être récursif (inclure les membres des types de base).
.PARAMETER IncludeSpecialNames
    Indique si les membres avec des noms spéciaux (ex: .ctor, .cctor) doivent être inclus.
.PARAMETER Categories
    Les catégories de membres à inclure. Par défaut, toutes les catégories sont incluses.
.EXAMPLE
    $MembersByCategory = Get-TypeMembersByCategory -Type ([System.String])
.EXAMPLE
    $MembersByCategory = Get-TypeMembersByCategory -Type ([System.String]) -Categories Property, Method -Recursive
.OUTPUTS
    System.Collections.Hashtable - Une table de hachage où les clés sont les catégories de membres et les valeurs sont les membres correspondants.
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

    # Créer une table de hachage pour stocker les membres par catégorie
    $membersByCategory = @{}

    # Initialiser les catégories sélectionnées
    foreach ($category in $Categories) {
        $membersByCategory[$category] = @()
    }

    # Définir les types de membres pour chaque catégorie
    $categoryMemberTypes = @{
        "Property"    = [System.Reflection.MemberTypes]::Property
        "Method"      = [System.Reflection.MemberTypes]::Method
        "Constructor" = [System.Reflection.MemberTypes]::Constructor
        "Event"       = [System.Reflection.MemberTypes]::Event
        "Field"       = [System.Reflection.MemberTypes]::Field
        "NestedType"  = [System.Reflection.MemberTypes]::NestedType
        "Custom"      = [System.Reflection.MemberTypes]::Custom
    }

    # Récupérer tous les membres
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

    # Regrouper les membres par catégorie
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
    Crée un itérateur pour parcourir les membres d'un type.
.DESCRIPTION
    Cette fonction crée un itérateur pour parcourir les membres d'un type, avec des options pour filtrer par type de membre,
    flags de liaison, et pour effectuer un parcours récursif.
.PARAMETER Type
    Le type dont on veut parcourir les membres.
.PARAMETER MemberTypes
    Les types de membres à inclure dans le parcours. Par défaut, tous les types de membres sont inclus.
.PARAMETER BindingFlags
    Les flags de liaison à utiliser pour la récupération des membres. Par défaut, les membres publics et d'instance sont inclus.
.PARAMETER Recursive
    Indique si le parcours doit être récursif (inclure les membres des types de base).
.PARAMETER IncludeSpecialNames
    Indique si les membres avec des noms spéciaux (ex: .ctor, .cctor) doivent être inclus.
.PARAMETER Filter
    Un prédicat pour filtrer les membres retournés.
.EXAMPLE
    $Iterator = New-TypeMemberIterator -Type ([System.String])
    foreach ($member in $Iterator) { $member.Name }
.OUTPUTS
    System.Collections.IEnumerable - Un itérateur pour parcourir les membres du type.
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

    # Créer un script block qui retourne un énumérateur
    $iteratorScriptBlock = {
        param (
            [type]$Type,
            [System.Reflection.MemberTypes]$MemberTypes,
            [System.Reflection.BindingFlags]$BindingFlags,
            [bool]$Recursive,
            [bool]$IncludeSpecialNames,
            [scriptblock]$Filter
        )

        # Fonction récursive pour parcourir les membres
        function Get-MembersRecursive {
            param (
                [type]$CurrentType
            )

            # Récupérer les membres du type courant
            $members = $CurrentType.GetMembers($BindingFlags)

            # Filtrer par type de membre si spécifié
            if ($MemberTypes -ne [System.Reflection.MemberTypes]::All) {
                $members = $members | Where-Object { $_.MemberType -band $MemberTypes }
            }

            # Filtrer les membres avec des noms spéciaux si nécessaire
            if (-not $IncludeSpecialNames) {
                $members = $members | Where-Object { -not $_.Name.StartsWith(".") }  # Exclure les noms comme .ctor, .cctor, etc.
            }

            # Appliquer le filtre personnalisé si spécifié
            if ($null -ne $Filter) {
                $members = $members | Where-Object $Filter
            }

            # Retourner les membres du type courant
            foreach ($member in $members) {
                yield $member
            }

            # Si récursif et le type a un type de base, parcourir ses membres
            if ($Recursive -and $null -ne $CurrentType.BaseType -and $CurrentType.BaseType -ne [object]) {
                Get-MembersRecursive -CurrentType $CurrentType.BaseType
            }
        }

        # Commencer le parcours
        Get-MembersRecursive -CurrentType $Type
    }

    # Créer et retourner l'énumérateur
    return & $iteratorScriptBlock -Type $Type -MemberTypes $MemberTypes -BindingFlags $BindingFlags -Recursive $Recursive -IncludeSpecialNames $IncludeSpecialNames -Filter $Filter
}

<#
.SYNOPSIS
    Filtre les membres d'un type par attribut.
.DESCRIPTION
    Cette fonction filtre les membres d'un type en fonction des attributs qu'ils possèdent.
.PARAMETER Type
    Le type dont on veut filtrer les membres.
.PARAMETER AttributeType
    Le type d'attribut à rechercher.
.PARAMETER BindingFlags
    Les flags de liaison à utiliser pour la récupération des membres. Par défaut, les membres publics et d'instance sont inclus.
.PARAMETER Recursive
    Indique si le parcours doit être récursif (inclure les membres des types de base).
.PARAMETER IncludeInherited
    Indique si les attributs hérités doivent être inclus.
.PARAMETER Filter
    Un prédicat pour filtrer les membres retournés.
.EXAMPLE
    $SerializableMembers = Get-TypeMembersByAttribute -Type ([System.String]) -AttributeType ([System.SerializableAttribute])
.OUTPUTS
    System.Reflection.MemberInfo[] - Les membres du type qui possèdent l'attribut spécifié.
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

    # Récupérer les membres du type
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

        # Appliquer le filtre personnalisé si spécifié
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
    Cette fonction filtre les membres d'un type en fonction de leur type de retour (pour les propriétés et méthodes).
.PARAMETER Type
    Le type dont on veut filtrer les membres.
.PARAMETER ReturnType
    Le type de retour à rechercher.
.PARAMETER BindingFlags
    Les flags de liaison à utiliser pour la récupération des membres. Par défaut, les membres publics et d'instance sont inclus.
.PARAMETER Recursive
    Indique si le parcours doit être récursif (inclure les membres des types de base).
.PARAMETER ExactMatch
    Indique si le type de retour doit correspondre exactement au type spécifié.
.PARAMETER Filter
    Un prédicat pour filtrer les membres retournés.
.EXAMPLE
    $StringMembers = Get-TypeMembersByReturnType -Type ([System.Object]) -ReturnType ([System.String])
.OUTPUTS
    System.Reflection.MemberInfo[] - Les membres du type qui ont le type de retour spécifié.
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

    # Récupérer les membres du type
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

        # Déterminer le type de retour en fonction du type de membre
        if ($member.MemberType -eq [System.Reflection.MemberTypes]::Property) {
            $memberReturnType = $member.PropertyType
        } elseif ($member.MemberType -eq [System.Reflection.MemberTypes]::Method) {
            $memberReturnType = $member.ReturnType
        } else {
            return $false  # Ignorer les autres types de membres
        }

        # Vérifier si le type de retour correspond
        $typeMatches = if ($ExactMatch) {
            $memberReturnType -eq $ReturnType
        } else {
            $ReturnType.IsAssignableFrom($memberReturnType)
        }

        # Appliquer le filtre personnalisé si spécifié
        if ($typeMatches -and $null -ne $Filter) {
            return $member | Where-Object $Filter
        }

        return $typeMatches
    }

    return $filteredMembers
}

<#
.SYNOPSIS
    Filtre les membres d'un type par accessibilité.
.DESCRIPTION
    Cette fonction filtre les membres d'un type en fonction de leur accessibilité (public, privé, protégé, etc.).
.PARAMETER Type
    Le type dont on veut filtrer les membres.
.PARAMETER Accessibility
    L'accessibilité des membres à inclure. Les valeurs possibles sont : Public, Private, Protected, Internal, ProtectedInternal, PrivateProtected.
.PARAMETER BindingFlags
    Les flags de liaison à utiliser pour la récupération des membres. Par défaut, tous les membres sont inclus.
.PARAMETER Recursive
    Indique si le parcours doit être récursif (inclure les membres des types de base).
.PARAMETER Filter
    Un prédicat pour filtrer les membres retournés.
.EXAMPLE
    $PublicMembers = Get-TypeMembersByAccessibility -Type ([System.String]) -Accessibility Public
.OUTPUTS
    System.Reflection.MemberInfo[] - Les membres du type qui ont l'accessibilité spécifiée.
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

    # Récupérer les membres du type
    $getMembersParams = @{
        Type         = $Type
        BindingFlags = $BindingFlags
    }

    if ($Recursive) {
        $members = Get-TypeMembersRecursive @getMembersParams
    } else {
        $members = Get-TypeMembers @getMembersParams
    }

    # Filtrer les membres par accessibilité
    $filteredMembers = $members | Where-Object {
        $member = $_

        # Déterminer l'accessibilité du membre
        $isPublic = $false
        $isPrivate = $false
        $isProtected = $false
        $isInternal = $false

        # Vérifier le type de membre et déterminer son accessibilité
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
            # Pour les propriétés, vérifier les accesseurs
            $getMethod = $member.GetGetMethod($true)  # Inclure les méthodes non-publiques
            $setMethod = $member.GetSetMethod($true)  # Inclure les méthodes non-publiques

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
            # Pour les événements, vérifier les accesseurs
            $addMethod = $member.GetAddMethod($true)  # Inclure les méthodes non-publiques
            $removeMethod = $member.GetRemoveMethod($true)  # Inclure les méthodes non-publiques

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

        # Vérifier si l'accessibilité du membre correspond à celle spécifiée
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

        # Appliquer le filtre personnalisé si spécifié
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
    Cette fonction analyse une classe d'exception et retourne des informations détaillées sur ses propriétés, constructeurs et méthodes.
.PARAMETER ExceptionType
    Le type d'exception à analyser.
.PARAMETER IncludeInheritedMembers
    Indique si les membres hérités doivent être inclus dans l'analyse.
.PARAMETER IncludePrivateMembers
    Indique si les membres privés doivent être inclus dans l'analyse.
.EXAMPLE
    $ExceptionInfo = Get-ExceptionTypeInfo -ExceptionType ([System.ArgumentException])
.OUTPUTS
    PSObject - Un objet contenant des informations détaillées sur la classe d'exception.
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

    # Vérifier si le type est une exception
    if (-not [System.Exception].IsAssignableFrom($ExceptionType)) {
        throw "Le type '$($ExceptionType.FullName)' n'est pas une classe d'exception."
    }

    # Déterminer les flags de liaison
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance

    if ($IncludePrivateMembers) {
        $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::NonPublic
    }

    # Récupérer les membres
    $getMembersParams = @{
        Type         = $ExceptionType
        BindingFlags = $bindingFlags
        Recursive    = $IncludeInheritedMembers
    }

    $membersByCategory = Get-TypeMembersByCategory @getMembersParams -Categories Property, Method, Constructor, Field

    # Créer l'objet résultat
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

    # Construire la hiérarchie d'héritage
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
    Cette fonction analyse une classe d'attribut et retourne des informations détaillées sur ses propriétés, constructeurs et cibles valides.
.PARAMETER AttributeType
    Le type d'attribut à analyser.
.PARAMETER IncludeInheritedMembers
    Indique si les membres hérités doivent être inclus dans l'analyse.
.PARAMETER IncludePrivateMembers
    Indique si les membres privés doivent être inclus dans l'analyse.
.EXAMPLE
    $AttributeInfo = Get-AttributeTypeInfo -AttributeType ([System.SerializableAttribute])
.OUTPUTS
    PSObject - Un objet contenant des informations détaillées sur la classe d'attribut.
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

    # Vérifier si le type est un attribut
    if (-not [System.Attribute].IsAssignableFrom($AttributeType)) {
        throw "Le type '$($AttributeType.FullName)' n'est pas une classe d'attribut."
    }

    # Déterminer les flags de liaison
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance

    if ($IncludePrivateMembers) {
        $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::NonPublic
    }

    # Récupérer les membres
    $getMembersParams = @{
        Type         = $AttributeType
        BindingFlags = $bindingFlags
        Recursive    = $IncludeInheritedMembers
    }

    $membersByCategory = Get-TypeMembersByCategory @getMembersParams -Categories Property, Constructor

    # Récupérer les cibles valides de l'attribut
    $attributeUsageAttribute = $AttributeType.GetCustomAttributes([System.AttributeUsageAttribute], $true) | Select-Object -First 1
    $validTargets = if ($null -ne $attributeUsageAttribute) {
        $attributeUsageAttribute.ValidOn
    } else {
        [System.AttributeTargets]::All  # Valeur par défaut
    }

    $allowMultiple = if ($null -ne $attributeUsageAttribute) {
        $attributeUsageAttribute.AllowMultiple
    } else {
        $false  # Valeur par défaut
    }

    $inherited = if ($null -ne $attributeUsageAttribute) {
        $attributeUsageAttribute.Inherited
    } else {
        $true  # Valeur par défaut
    }

    # Créer l'objet résultat
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

    # Construire la hiérarchie d'héritage
    $currentType = $AttributeType
    while ($null -ne $currentType -and $currentType -ne [object]) {
        $result.InheritanceHierarchy += $currentType
        $currentType = $currentType.BaseType
    }

    return $result
}

<#
.SYNOPSIS
    Analyse une classe d'énumération.
.DESCRIPTION
    Cette fonction analyse une classe d'énumération et retourne des informations détaillées sur ses valeurs et attributs.
.PARAMETER EnumType
    Le type d'énumération à analyser.
.PARAMETER IncludeAttributes
    Indique si les attributs des valeurs d'énumération doivent être inclus dans l'analyse.
.EXAMPLE
    $EnumInfo = Get-EnumTypeInfo -EnumType ([System.DayOfWeek])
.OUTPUTS
    PSObject - Un objet contenant des informations détaillées sur la classe d'énumération.
#>
function Get-EnumTypeInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$EnumType,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeAttributes
    )

    # Vérifier si le type est une énumération
    if (-not $EnumType.IsEnum) {
        throw "Le type '$($EnumType.FullName)' n'est pas une énumération."
    }

    # Récupérer les valeurs de l'énumération
    $enumValues = [Enum]::GetValues($EnumType)
    $enumNames = [Enum]::GetNames($EnumType)

    # Récupérer le type sous-jacent
    $underlyingType = [Enum]::GetUnderlyingType($EnumType)

    # Vérifier si l'énumération a l'attribut [Flags]
    $isFlagsEnum = $EnumType.GetCustomAttributes([System.FlagsAttribute], $false).Length -gt 0

    # Créer un tableau pour stocker les informations sur les valeurs
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

        # Ajouter les attributs si demandé
        if ($IncludeAttributes) {
            $field = $EnumType.GetField($name)
            $attributes = $field.GetCustomAttributes($false)
            $valueInfo | Add-Member -MemberType NoteProperty -Name "Attributes" -Value $attributes
        }

        $values += $valueInfo
    }

    # Créer l'objet résultat
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
# Note: Commenté pour permettre l'exécution en mode script
# Export-ModuleMember -Function Get-TypeByQualifiedName, ConvertFrom-TypeName, Search-TypeInAssemblies, Get-TypeResolutionError, Get-NonPublicType, New-StringComparer, Find-TypesByNamespace, Find-TypesByRegex, Set-TypeAlias, Remove-TypeAlias, Get-TypeAlias, Resolve-TypeAlias, Import-TypeAliases, Export-TypeAliases, Import-Assembly, Import-AssemblyFromStream, New-GenericType, Get-GenericTypeArguments, Test-GenericType, New-AnonymousType, New-DynamicType, New-NullableType, Get-TypeMembers, Get-TypeMembersRecursive, Get-TypeMembersByCategory, New-TypeMemberIterator, Get-TypeMembersByAttribute, Get-TypeMembersByReturnType, Get-TypeMembersByAccessibility, Get-ExceptionTypeInfo, Get-AttributeTypeInfo, Get-EnumTypeInfo
