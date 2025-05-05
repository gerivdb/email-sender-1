<#
.SYNOPSIS
    Génère des données structurées aléatoires pour les tests.

.DESCRIPTION
    Cette fonction génère des données structurées aléatoires qui peuvent être utilisées
    pour les tests de performance et de fonctionnalité du module d'extraction.
    Elle permet de personnaliser la structure, la complexité et d'autres caractéristiques des données.

.PARAMETER ItemCount
    Nombre d'éléments à générer. Par défaut: 10.

.PARAMETER MinProperties
    Nombre minimum de propriétés par élément. Par défaut: 3.

.PARAMETER MaxProperties
    Nombre maximum de propriétés par élément. Par défaut: 10.

.PARAMETER Complexity
    Niveau de complexité des données (1-10). Influence la structure et les types de données.
    1-3: Structure simple (principalement des types primitifs)
    4-7: Structure intermédiaire (inclut des objets imbriqués simples)
    8-10: Structure complexe (objets imbriqués profonds, tableaux, etc.)
    Par défaut: 5.

.PARAMETER Format
    Format des données générées. Options: 'Object', 'JSON', 'XML', 'CSV'.
    Par défaut: 'Object'.

.PARAMETER IncludeNestedObjects
    Si spécifié, inclut des objets imbriqués dans les données générées.

.PARAMETER MaxNestingLevel
    Niveau maximum d'imbrication pour les objets imbriqués. Par défaut: 3.

.PARAMETER IncludeArrays
    Si spécifié, inclut des tableaux dans les données générées.

.PARAMETER RandomSeed
    Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
    des données identiques à chaque exécution avec la même graine.

.EXAMPLE
    $data = New-RandomStructuredData -ItemCount 5 -Complexity 7 -Format 'JSON' -IncludeNestedObjects

.EXAMPLE
    $data = New-RandomStructuredData -ItemCount 20 -Complexity 3 -Format 'CSV' -RandomSeed 12345

.NOTES
    Cette fonction est conçue pour les tests et ne doit pas être utilisée en production.
#>
function New-RandomStructuredData {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$ItemCount = 10,
        
        [Parameter(Mandatory = $false)]
        [int]$MinProperties = 3,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxProperties = 10,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
        [int]$Complexity = 5,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Object', 'JSON', 'XML', 'CSV')]
        [string]$Format = 'Object',
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeNestedObjects,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxNestingLevel = 3,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeArrays,
        
        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null
    )
    
    # Initialiser le générateur de nombres aléatoires
    if ($null -ne $RandomSeed) {
        $random = New-Object System.Random($RandomSeed)
    }
    else {
        $random = New-Object System.Random
    }
    
    # Ajuster les paramètres en fonction de la complexité
    if ($Complexity -le 3) {
        $IncludeNestedObjects = $false
        $IncludeArrays = $false
        $MaxProperties = [Math]::Min($MaxProperties, 5)
    }
    elseif ($Complexity -le 7) {
        if (-not $PSBoundParameters.ContainsKey('IncludeNestedObjects')) {
            $IncludeNestedObjects = $true
        }
        if (-not $PSBoundParameters.ContainsKey('IncludeArrays')) {
            $IncludeArrays = ($random.Next(0, 2) -eq 1)
        }
        $MaxNestingLevel = [Math]::Min($MaxNestingLevel, 2)
    }
    else {
        if (-not $PSBoundParameters.ContainsKey('IncludeNestedObjects')) {
            $IncludeNestedObjects = $true
        }
        if (-not $PSBoundParameters.ContainsKey('IncludeArrays')) {
            $IncludeArrays = $true
        }
    }
    
    # Fonction récursive pour générer un objet aléatoire
    function New-RandomObject {
        param (
            [int]$NestingLevel = 0,
            [int]$MinProps = $MinProperties,
            [int]$MaxProps = $MaxProperties
        )
        
        # Limiter la récursion
        if ($NestingLevel -ge $MaxNestingLevel) {
            $IncludeNestedObjects = $false
            $IncludeArrays = $false
        }
        
        # Déterminer le nombre de propriétés
        $propertyCount = $random.Next($MinProps, $MaxProps + 1)
        
        # Créer l'objet
        $obj = [ordered]@{}
        
        # Types de données possibles
        $dataTypes = @("string", "number", "boolean", "date")
        if ($IncludeNestedObjects -and $NestingLevel -lt $MaxNestingLevel) {
            $dataTypes += "object"
        }
        if ($IncludeArrays) {
            $dataTypes += "array"
        }
        
        # Générer les propriétés
        for ($i = 1; $i -le $propertyCount; $i++) {
            $propertyName = "Property$i"
            
            # Sélectionner un type de données aléatoire
            $typeIndex = $random.Next(0, $dataTypes.Count)
            $dataType = $dataTypes[$typeIndex]
            
            # Générer la valeur en fonction du type
            $value = switch ($dataType) {
                "string" {
                    $stringTypes = @("normal", "email", "url", "id", "name")
                    $stringType = $stringTypes[$random.Next(0, $stringTypes.Count)]
                    
                    switch ($stringType) {
                        "email" { "user$($random.Next(1, 1000))@example.com" }
                        "url" { "https://example.com/resource/$($random.Next(1, 10000))" }
                        "id" { "ID-" + [guid]::NewGuid().ToString().Substring(0, 8) }
                        "name" {
                            $firstNames = @("Jean", "Marie", "Pierre", "Sophie", "Thomas", "Julie", "Nicolas", "Isabelle", "François", "Catherine")
                            $lastNames = @("Dupont", "Martin", "Durand", "Lefebvre", "Bernard", "Robert", "Petit", "Dubois", "Moreau", "Simon")
                            $firstNames[$random.Next(0, $firstNames.Count)] + " " + $lastNames[$random.Next(0, $lastNames.Count)]
                        }
                        default { "Value-$($random.Next(1, 10000))" }
                    }
                }
                "number" {
                    $numberTypes = @("integer", "decimal", "percentage", "currency")
                    $numberType = $numberTypes[$random.Next(0, $numberTypes.Count)]
                    
                    switch ($numberType) {
                        "integer" { $random.Next(1, 10000) }
                        "decimal" { [Math]::Round($random.NextDouble() * 1000, 2) }
                        "percentage" { [Math]::Round($random.NextDouble() * 100, 2) }
                        "currency" { [Math]::Round($random.NextDouble() * 10000, 2) }
                        default { $random.Next(1, 10000) }
                    }
                }
                "boolean" {
                    $random.Next(0, 2) -eq 1
                }
                "date" {
                    $daysAgo = $random.Next(-365, 365)
                    (Get-Date).AddDays($daysAgo).ToString("yyyy-MM-dd")
                }
                "object" {
                    # Réduire le nombre de propriétés pour les objets imbriqués
                    $nestedMinProps = [Math]::Max(1, $MinProps - 1)
                    $nestedMaxProps = [Math]::Max(3, $MaxProps - 2)
                    New-RandomObject -NestingLevel ($NestingLevel + 1) -MinProps $nestedMinProps -MaxProps $nestedMaxProps
                }
                "array" {
                    $arraySize = $random.Next(1, 5)
                    $array = @()
                    
                    # Déterminer le type des éléments du tableau
                    $arrayElementType = $dataTypes | Where-Object { $_ -ne "array" } | Get-Random
                    
                    for ($j = 0; $j -lt $arraySize; $j++) {
                        $arrayElement = switch ($arrayElementType) {
                            "string" { "Item-$($j + 1)" }
                            "number" { $random.Next(1, 1000) }
                            "boolean" { $random.Next(0, 2) -eq 1 }
                            "date" {
                                $daysAgo = $random.Next(-365, 365)
                                (Get-Date).AddDays($daysAgo).ToString("yyyy-MM-dd")
                            }
                            "object" {
                                if ($NestingLevel -lt $MaxNestingLevel - 1) {
                                    $nestedMinProps = [Math]::Max(1, $MinProps - 2)
                                    $nestedMaxProps = [Math]::Max(2, $MaxProps - 3)
                                    New-RandomObject -NestingLevel ($NestingLevel + 2) -MinProps $nestedMinProps -MaxProps $nestedMaxProps
                                }
                                else {
                                    [PSCustomObject]@{ "SimpleProperty" = "SimpleValue-$($j + 1)" }
                                }
                            }
                            default { "Item-$($j + 1)" }
                        }
                        
                        $array += $arrayElement
                    }
                    
                    $array
                }
                default {
                    "Value-$($random.Next(1, 10000))"
                }
            }
            
            $obj[$propertyName] = $value
        }
        
        # Ajouter un ID unique à chaque objet racine
        if ($NestingLevel -eq 0) {
            $obj["Id"] = [guid]::NewGuid().ToString()
        }
        
        return [PSCustomObject]$obj
    }
    
    # Générer les éléments
    $items = @()
    for ($i = 0; $i -lt $ItemCount; $i++) {
        $items += New-RandomObject
    }
    
    # Formater la sortie selon le format demandé
    switch ($Format) {
        "JSON" {
            $items | ConvertTo-Json -Depth 10
        }
        "XML" {
            # Créer un document XML
            $xmlDoc = New-Object System.Xml.XmlDocument
            $root = $xmlDoc.CreateElement("Items")
            $xmlDoc.AppendChild($root) | Out-Null
            
            foreach ($item in $items) {
                $itemElement = $xmlDoc.CreateElement("Item")
                
                # Fonction récursive pour ajouter des propriétés XML
                function Add-XmlProperties {
                    param (
                        [System.Xml.XmlElement]$Parent,
                        [PSCustomObject]$Object
                    )
                    
                    foreach ($prop in $Object.PSObject.Properties) {
                        if ($null -eq $prop.Value) {
                            continue
                        }
                        
                        if ($prop.Value -is [PSCustomObject]) {
                            $childElement = $xmlDoc.CreateElement($prop.Name)
                            Add-XmlProperties -Parent $childElement -Object $prop.Value
                            $Parent.AppendChild($childElement) | Out-Null
                        }
                        elseif ($prop.Value -is [array]) {
                            $arrayElement = $xmlDoc.CreateElement($prop.Name)
                            
                            foreach ($item in $prop.Value) {
                                $itemElement = $xmlDoc.CreateElement("Item")
                                
                                if ($item -is [PSCustomObject]) {
                                    Add-XmlProperties -Parent $itemElement -Object $item
                                }
                                else {
                                    $itemElement.InnerText = $item.ToString()
                                }
                                
                                $arrayElement.AppendChild($itemElement) | Out-Null
                            }
                            
                            $Parent.AppendChild($arrayElement) | Out-Null
                        }
                        else {
                            $element = $xmlDoc.CreateElement($prop.Name)
                            $element.InnerText = $prop.Value.ToString()
                            $Parent.AppendChild($element) | Out-Null
                        }
                    }
                }
                
                Add-XmlProperties -Parent $itemElement -Object $item
                $root.AppendChild($itemElement) | Out-Null
            }
            
            # Convertir le document XML en chaîne
            $stringWriter = New-Object System.IO.StringWriter
            $xmlWriter = New-Object System.Xml.XmlTextWriter($stringWriter)
            $xmlWriter.Formatting = [System.Xml.Formatting]::Indented
            $xmlDoc.WriteTo($xmlWriter)
            $xmlWriter.Flush()
            $stringWriter.ToString()
        }
        "CSV" {
            # Pour CSV, nous devons aplatir les objets
            $flatItems = @()
            
            foreach ($item in $items) {
                $flatItem = [ordered]@{}
                
                # Fonction récursive pour aplatir un objet
                function Get-FlatProperties {
                    param (
                        [hashtable]$Result,
                        [PSCustomObject]$Object,
                        [string]$Prefix = ""
                    )
                    
                    foreach ($prop in $Object.PSObject.Properties) {
                        $key = if ($Prefix -eq "") { $prop.Name } else { "$Prefix.$($prop.Name)" }
                        
                        if ($null -eq $prop.Value) {
                            $Result[$key] = ""
                        }
                        elseif ($prop.Value -is [PSCustomObject]) {
                            Get-FlatProperties -Result $Result -Object $prop.Value -Prefix $key
                        }
                        elseif ($prop.Value -is [array]) {
                            $Result[$key] = ($prop.Value | ForEach-Object { $_.ToString() }) -join "; "
                        }
                        else {
                            $Result[$key] = $prop.Value.ToString()
                        }
                    }
                }
                
                Get-FlatProperties -Result $flatItem -Object $item
                $flatItems += [PSCustomObject]$flatItem
            }
            
            $flatItems | ConvertTo-Csv -NoTypeInformation
        }
        default {
            $items
        }
    }
}

# Exporter la fonction
Export-ModuleMember -Function New-RandomStructuredData
