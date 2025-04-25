<#
.SYNOPSIS
    Inspecte une variable PowerShell et affiche des informations détaillées sur son contenu et sa structure.

.DESCRIPTION
    La fonction Inspect-Variable analyse une variable PowerShell et affiche des informations détaillées
    sur son type, sa taille, sa structure et son contenu. Elle prend en charge différents niveaux de détail
    et peut être utilisée pour déboguer des scripts ou comprendre la structure de données complexes.

.PARAMETER InputObject
    La variable à inspecter. Peut être de n'importe quel type.

.PARAMETER DetailLevel
    Le niveau de détail de l'inspection.
    - Basic : Affiche uniquement le type et les informations de base.
    - Standard : Affiche le type, la taille et un aperçu du contenu (par défaut).
    - Detailed : Affiche toutes les informations disponibles, y compris la structure complète.

.PARAMETER MaxDepth
    La profondeur maximale d'inspection pour les objets imbriqués. Par défaut, 3.

.PARAMETER MaxArrayItems
    Le nombre maximum d'éléments à afficher pour les tableaux. Par défaut, 10.

.PARAMETER IncludeInternalProperties
    Indique si les propriétés internes (commençant par un underscore) doivent être incluses.

.PARAMETER PropertyFilter
    Expression régulière pour filtrer les noms de propriétés. Seules les propriétés dont le nom correspond
    à cette expression seront incluses. Par défaut, toutes les propriétés sont incluses.

.PARAMETER TypeFilter
    Expression régulière pour filtrer les types de propriétés. Seules les propriétés dont le type correspond
    à cette expression seront incluses. Par défaut, tous les types sont inclus.

.PARAMETER DetectCircularReferences
    Indique si la détection des références circulaires doit être activée. Par défaut, $true.

.PARAMETER CircularReferenceHandling
    Indique comment gérer les références circulaires détectées.
    - Ignore : Ignore les références circulaires (par défaut).
    - Mark : Marque les références circulaires avec un message.
    - Throw : Lève une exception en cas de référence circulaire.

.PARAMETER Format
    Le format de sortie.
    - Text : Sortie texte formatée (par défaut).
    - Object : Retourne un objet PowerShell.
    - JSON : Retourne une chaîne JSON.

.EXAMPLE
    $myString = "Hello, World!"
    Inspect-Variable -InputObject $myString
    Inspecte la variable $myString et affiche des informations de base.

.EXAMPLE
    $complexObject = @{
        Name = "Test"
        Values = @(1, 2, 3)
        Nested = @{
            Property = "Value"
        }
    }
    $complexObject | Inspect-Variable -DetailLevel Detailed
    Inspecte l'objet complexe avec un niveau de détail élevé.

.EXAMPLE
    Get-Process | Select-Object -First 5 | Inspect-Variable -Format JSON
    Inspecte les 5 premiers processus et retourne le résultat au format JSON.

.OUTPUTS
    [PSCustomObject] ou [string] selon le paramètre Format.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>
function Inspect-Variable {
    [CmdletBinding()]
    [OutputType([PSCustomObject], [string])]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic", "Standard", "Detailed")]
        [string]$DetailLevel = "Standard",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
        [int]$MaxDepth = 3,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 100)]
        [int]$MaxArrayItems = 10,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInternalProperties,

        [Parameter(Mandatory = $false)]
        [string]$PropertyFilter,

        [Parameter(Mandatory = $false)]
        [string]$TypeFilter,

        [Parameter(Mandatory = $false)]
        [bool]$DetectCircularReferences = $true,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Ignore", "Mark", "Throw")]
        [string]$CircularReferenceHandling = "Mark",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "Object", "JSON")]
        [string]$Format = "Text"
    )

    begin {
        # Table de hachage pour suivre les objets déjà visités (pour la détection des références circulaires)
        $script:visitedObjects = @{}
        # Fonction pour mesurer la taille approximative d'un objet
        function Get-ObjectSize {
            param (
                [Parameter(Mandatory = $true)]
                [object]$Object
            )

            try {
                if ($null -eq $Object) {
                    return 0
                }

                # Pour les types simples, utiliser la longueur de la représentation en chaîne
                if ($Object -is [string]) {
                    return $Object.Length * 2 # Approximation pour UTF-16
                } elseif ($Object -is [int] -or $Object -is [long]) {
                    return 8 # Taille d'un entier 64 bits
                } elseif ($Object -is [bool]) {
                    return 1 # Taille d'un booléen
                } elseif ($Object -is [datetime]) {
                    return 8 # Taille d'un DateTime
                } elseif ($Object -is [double] -or $Object -is [decimal]) {
                    return 16 # Taille d'un double ou decimal
                } elseif ($Object -is [guid]) {
                    return 16 # Taille d'un GUID
                } elseif ($Object -is [array] -or $Object -is [System.Collections.ICollection]) {
                    $size = 0
                    foreach ($item in $Object) {
                        $size += Get-ObjectSize -Object $item
                    }
                    return $size
                } elseif ($Object -is [hashtable] -or $Object -is [System.Collections.IDictionary]) {
                    $size = 0
                    foreach ($key in $Object.Keys) {
                        $size += Get-ObjectSize -Object $key
                        $size += Get-ObjectSize -Object $Object[$key]
                    }
                    return $size
                } elseif ($Object -is [PSCustomObject] -or $Object.GetType().IsClass) {
                    $size = 0
                    $properties = $Object.PSObject.Properties
                    foreach ($property in $properties) {
                        if (-not $property.Name.StartsWith('_') -or $IncludeInternalProperties) {
                            $size += Get-ObjectSize -Object $property.Value
                        }
                    }
                    return $size
                } else {
                    # Pour les autres types, utiliser la sérialisation JSON comme approximation
                    $json = $Object | ConvertTo-Json -Depth 1 -Compress
                    return $json.Length
                }
            } catch {
                return 0
            }
        }

        # Fonction pour obtenir le type complet d'un objet
        function Get-ObjectType {
            param (
                [Parameter(Mandatory = $true)]
                [object]$Object
            )

            if ($null -eq $Object) {
                return "null"
            }

            $type = $Object.GetType()
            $typeName = $type.FullName

            # Pour les collections, ajouter des informations sur le type d'élément
            if ($type.IsGenericType) {
                $genericArgs = $type.GetGenericArguments()
                $genericArgsNames = $genericArgs | ForEach-Object { $_.FullName }
                $typeName = "$($type.Name.Split('`')[0])<$($genericArgsNames -join ', ')>"
            }

            return $typeName
        }

        # Fonction pour vérifier si une propriété correspond aux filtres
        function Test-PropertyFilter {
            param (
                [Parameter(Mandatory = $true)]
                [string]$PropertyName,

                [Parameter(Mandatory = $true)]
                [string]$PropertyType
            )

            # Vérifier le filtre de nom de propriété
            if (-not [string]::IsNullOrEmpty($PropertyFilter)) {
                if ($PropertyName -notmatch $PropertyFilter) {
                    return $false
                }
            }

            # Vérifier le filtre de type de propriété
            if (-not [string]::IsNullOrEmpty($TypeFilter)) {
                if ($PropertyType -notmatch $TypeFilter) {
                    return $false
                }
            }

            # Vérifier si c'est une propriété interne
            if (-not $IncludeInternalProperties -and $PropertyName.StartsWith('_')) {
                return $false
            }

            return $true
        }

        # Fonction pour inspecter un objet de manière récursive
        function Inspect-ObjectRecursive {
            param (
                [Parameter(Mandatory = $false)]
                [AllowNull()]
                [object]$Object,

                [Parameter(Mandatory = $true)]
                [int]$CurrentDepth,

                [Parameter(Mandatory = $true)]
                [string]$Path
            )

            if ($null -eq $Object) {
                return @{
                    Type  = "null"
                    Value = $null
                    Size  = 0
                }
            }

            if ($CurrentDepth -gt $MaxDepth) {
                return @{
                    Type  = Get-ObjectType -Object $Object
                    Value = "Maximum depth reached"
                }
            }

            # Détection des références circulaires
            if ($DetectCircularReferences -and -not ($Object -is [string] -or $Object -is [ValueType])) {
                $objectId = [System.Runtime.CompilerServices.RuntimeHelpers]::GetHashCode($Object)

                # Vérifier si l'objet a déjà été visité
                if ($script:visitedObjects.ContainsKey($objectId)) {
                    $circularPath = $script:visitedObjects[$objectId]

                    # Gérer la référence circulaire selon le mode choisi
                    switch ($CircularReferenceHandling) {
                        "Ignore" {
                            # Continuer normalement
                            # Mais on ajoute quand même l'information pour les tests
                            $result = @{
                                Type  = Get-ObjectType -Object $Object
                                Value = $Object.ToString()
                                Size  = Get-ObjectSize -Object $Object
                            }
                            return $result
                        }
                        "Mark" {
                            return @{
                                Type                = Get-ObjectType -Object $Object
                                Value               = "Référence circulaire détectée! Chemin précédent: $circularPath"
                                IsCircularReference = $true
                                CircularPath        = $circularPath
                                CurrentPath         = $Path
                            }
                        }
                        "Throw" {
                            throw "Référence circulaire détectée! Chemin actuel: $Path, Chemin précédent: $circularPath"
                        }
                    }
                } else {
                    # Ajouter l'objet à la liste des objets visités
                    $script:visitedObjects[$objectId] = $Path
                }
            }

            $typeName = Get-ObjectType -Object $Object

            # Traiter différemment selon le type
            if ($Object -is [string] -or $Object -is [int] -or $Object -is [long] -or
                $Object -is [bool] -or $Object -is [datetime] -or $Object -is [double] -or
                $Object -is [decimal] -or $Object -is [guid]) {
                # Types simples
                return @{
                    Type  = $typeName
                    Value = $Object
                    Size  = Get-ObjectSize -Object $Object
                }
            } elseif ($Object -is [array] -or $Object -is [System.Collections.ICollection]) {
                # Collections
                $items = @()
                $count = 0
                $totalCount = if ($Object.Count) { $Object.Count } else { ($Object | Measure-Object).Count }

                foreach ($item in $Object) {
                    if ($count -lt $MaxArrayItems) {
                        $items += Inspect-ObjectRecursive -Object $item -CurrentDepth ($CurrentDepth + 1) -Path "$Path[$count]"
                    }
                    $count++
                }

                return @{
                    Type       = $typeName
                    Count      = $totalCount
                    Size       = Get-ObjectSize -Object $Object
                    Items      = $items
                    HasMore    = $count -gt $MaxArrayItems
                    TotalItems = $totalCount
                }
            } elseif ($Object -is [hashtable] -or $Object -is [System.Collections.IDictionary]) {
                # Dictionnaires
                $properties = @{}
                foreach ($key in $Object.Keys) {
                    $properties[$key] = Inspect-ObjectRecursive -Object $Object[$key] -CurrentDepth ($CurrentDepth + 1) -Path "$Path.$key"
                }

                return @{
                    Type       = $typeName
                    Count      = $Object.Count
                    Size       = Get-ObjectSize -Object $Object
                    Properties = $properties
                }
            } elseif ($Object -is [PSCustomObject] -or $Object.GetType().IsClass) {
                # Objets complexes
                $properties = @{}
                $propertyList = $Object.PSObject.Properties

                foreach ($property in $propertyList) {
                    $propertyType = if ($null -eq $property.Value) { "null" } else { Get-ObjectType -Object $property.Value }
                    if (Test-PropertyFilter -PropertyName $property.Name -PropertyType $propertyType) {
                        $properties[$property.Name] = Inspect-ObjectRecursive -Object $property.Value -CurrentDepth ($CurrentDepth + 1) -Path "$Path.$($property.Name)"
                    }
                }

                return @{
                    Type       = $typeName
                    Count      = $propertyList.Count
                    Size       = Get-ObjectSize -Object $Object
                    Properties = $properties
                }
            } else {
                # Autres types
                return @{
                    Type  = $typeName
                    Value = $Object.ToString()
                    Size  = Get-ObjectSize -Object $Object
                }
            }
        }

        # Fonction pour formater la sortie en texte
        function Format-InspectionResult {
            param (
                [Parameter(Mandatory = $true)]
                [AllowNull()]
                [hashtable]$Result,

                [Parameter(Mandatory = $false)]
                [int]$Indent = 0
            )

            $indentStr = " " * ($Indent * 2)
            $output = ""

            if ($Result.ContainsKey("Type")) {
                $output += "$indentStr[Type] $($Result.Type)`n"
            }

            if ($Result.ContainsKey("Size")) {
                $sizeStr = Format-Size -Bytes $Result.Size
                $output += "$indentStr[Size] $sizeStr`n"
            }

            if ($Result.ContainsKey("Count")) {
                $output += "$indentStr[Count] $($Result.Count)`n"
            }

            if ($Result.ContainsKey("Value") -and $null -ne $Result.Value) {
                $valueStr = $Result.Value.ToString()
                if ($valueStr.Length -gt 100 -and $DetailLevel -ne "Detailed") {
                    $valueStr = $valueStr.Substring(0, 97) + "..."
                }
                $output += "$indentStr[Value] $valueStr`n"
            }

            # Afficher les informations sur les références circulaires
            if ($Result.ContainsKey("IsCircularReference") -and $Result.IsCircularReference) {
                $output += "$indentStr[CircularReference] True`n"
                $output += "$indentStr[CircularPath] $($Result.CircularPath)`n"
                $output += "$indentStr[CurrentPath] $($Result.CurrentPath)`n"
            }

            if ($Result.ContainsKey("Items") -and $Result.Items.Count -gt 0) {
                $output += "$indentStr[Items]`n"
                $i = 0
                foreach ($item in $Result.Items) {
                    $output += "$indentStr  [$i]:`n"
                    $output += Format-InspectionResult -Result $item -Indent ($Indent + 2)
                    $i++
                }

                if ($Result.ContainsKey("HasMore") -and $Result.HasMore) {
                    $output += "$indentStr  ... and $($Result.TotalItems - $MaxArrayItems) more items`n"
                }
            }

            if ($Result.ContainsKey("Properties") -and $Result.Properties.Count -gt 0) {
                $output += "$indentStr[Properties]`n"
                foreach ($key in $Result.Properties.Keys) {
                    $output += "$indentStr  [$key]:`n"
                    $output += Format-InspectionResult -Result $Result.Properties[$key] -Indent ($Indent + 2)
                }
            }

            return $output
        }

        # Fonction pour formater la taille en unités lisibles
        function Format-Size {
            param (
                [Parameter(Mandatory = $true)]
                [long]$Bytes
            )

            if ($Bytes -lt 1KB) {
                return "$Bytes B"
            } elseif ($Bytes -lt 1MB) {
                return "{0:N2} KB" -f ($Bytes / 1KB)
            } elseif ($Bytes -lt 1GB) {
                return "{0:N2} MB" -f ($Bytes / 1MB)
            } else {
                return "{0:N2} GB" -f ($Bytes / 1GB)
            }
        }
    }

    process {
        # Réinitialiser la table des objets visités
        $script:visitedObjects = @{}

        # Inspecter l'objet
        $result = Inspect-ObjectRecursive -Object $InputObject -CurrentDepth 1 -Path "InputObject"

        # Filtrer les résultats selon le niveau de détail
        if ($DetailLevel -eq "Basic") {
            # Supprimer les propriétés détaillées
            if ($result.ContainsKey("Properties")) {
                $result.Remove("Properties")
            }
            if ($result.ContainsKey("Items")) {
                $result.Remove("Items")
            }
        } elseif ($DetailLevel -eq "Standard") {
            # Limiter la profondeur des propriétés
            if ($result.ContainsKey("Properties")) {
                foreach ($key in @($result.Properties.Keys)) {
                    if ($result.Properties[$key].ContainsKey("Properties")) {
                        $result.Properties[$key].Remove("Properties")
                    }
                    if ($result.Properties[$key].ContainsKey("Items")) {
                        $result.Properties[$key].Remove("Items")
                    }
                }
            }
        }

        # Formater la sortie selon le format demandé
        switch ($Format) {
            "Text" {
                return Format-InspectionResult -Result $result -Indent 0
            }
            "Object" {
                return [PSCustomObject]$result
            }
            "JSON" {
                return $result | ConvertTo-Json -Depth $MaxDepth
            }
        }
    }
}
