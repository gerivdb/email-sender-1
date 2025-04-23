<#
.SYNOPSIS
    Fonctions pour l'identification et l'analyse des propriétés dans les types .NET.
.DESCRIPTION
    Ce module fournit des fonctions pour identifier, analyser et catégoriser les propriétés
    dans les types .NET, y compris la détection des accesseurs, l'analyse des niveaux d'accès,
    l'analyse des attributs et la détection des propriétés auto-implémentées.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
#>

#region Détection des accesseurs

<#
.SYNOPSIS
    Détecte les méthodes get/set associées à une propriété.
.DESCRIPTION
    Cette fonction détecte les méthodes get/set associées à une propriété et retourne des informations détaillées sur ces accesseurs.
.PARAMETER Property
    La propriété à analyser.
.PARAMETER IncludeNonPublic
    Indique si les accesseurs non publics doivent être inclus dans l'analyse.
.EXAMPLE
    $propertyInfo = [System.String].GetProperty("Length")
    $accessors = Get-PropertyAccessors -Property $propertyInfo
.OUTPUTS
    PSObject - Un objet contenant des informations sur les accesseurs de la propriété.
#>
function Get-PropertyAccessors {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Reflection.PropertyInfo]$Property,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNonPublic
    )

    # Récupérer les méthodes get/set
    $getMethod = $Property.GetGetMethod($IncludeNonPublic)
    $setMethod = $Property.GetSetMethod($IncludeNonPublic)

    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Property    = $Property
        GetMethod   = $getMethod
        SetMethod   = $setMethod
        HasGetter   = $null -ne $getMethod
        HasSetter   = $null -ne $setMethod
        IsReadOnly  = $null -ne $getMethod -and $null -eq $setMethod
        IsWriteOnly = $null -eq $getMethod -and $null -ne $setMethod
        IsReadWrite = $null -ne $getMethod -and $null -ne $setMethod
    }

    return $result
}

<#
.SYNOPSIS
    Associe les accesseurs aux propriétés dans un type.
.DESCRIPTION
    Cette fonction analyse un type et associe les méthodes get/set aux propriétés correspondantes.
.PARAMETER Type
    Le type à analyser.
.PARAMETER IncludeNonPublic
    Indique si les accesseurs non publics doivent être inclus dans l'analyse.
.EXAMPLE
    $accessorMap = Get-TypePropertyAccessorMap -Type ([System.String])
.OUTPUTS
    Hashtable - Une table de hachage où les clés sont les noms des propriétés et les valeurs sont les informations sur les accesseurs.
#>
function Get-TypePropertyAccessorMap {
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

    # Créer la table de hachage pour stocker les associations
    $accessorMap = @{}

    # Analyser chaque propriété
    foreach ($property in $properties) {
        $accessors = Get-PropertyAccessors -Property $property -IncludeNonPublic:$IncludeNonPublic
        $accessorMap[$property.Name] = $accessors
    }

    return $accessorMap
}

<#
.SYNOPSIS
    Vérifie la compatibilité des types entre les accesseurs get/set d'une propriété.
.DESCRIPTION
    Cette fonction vérifie que les types de retour et de paramètre des accesseurs get/set d'une propriété sont compatibles.
.PARAMETER Property
    La propriété à analyser.
.PARAMETER IncludeNonPublic
    Indique si les accesseurs non publics doivent être inclus dans l'analyse.
.EXAMPLE
    $propertyInfo = [System.String].GetProperty("Length")
    $isCompatible = Test-PropertyAccessorTypeCompatibility -Property $propertyInfo
.OUTPUTS
    PSObject - Un objet contenant des informations sur la compatibilité des types des accesseurs.
#>
function Test-PropertyAccessorTypeCompatibility {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Reflection.PropertyInfo]$Property,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNonPublic
    )

    # Récupérer les accesseurs
    $accessors = Get-PropertyAccessors -Property $Property -IncludeNonPublic:$IncludeNonPublic

    # Vérifier si les deux accesseurs existent
    if (-not $accessors.HasGetter -or -not $accessors.HasSetter) {
        # Si un seul accesseur existe, il n'y a pas de problème de compatibilité
        return [PSCustomObject]@{
            IsCompatible = $true
            Property     = $Property
            GetterType   = if ($accessors.HasGetter) { $accessors.GetMethod.ReturnType } else { $null }
            SetterType   = if ($accessors.HasSetter) { $accessors.SetMethod.GetParameters()[0].ParameterType } else { $null }
            Reason       = "Un seul accesseur existe"
        }
    }

    # Récupérer les types
    $getterType = $accessors.GetMethod.ReturnType
    $setterType = $accessors.SetMethod.GetParameters()[0].ParameterType

    # Vérifier la compatibilité
    $isCompatible = $getterType -eq $setterType

    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        IsCompatible = $isCompatible
        Property     = $Property
        GetterType   = $getterType
        SetterType   = $setterType
        Reason       = if ($isCompatible) { "Les types sont compatibles" } else { "Les types sont incompatibles" }
    }

    return $result
}

<#
.SYNOPSIS
    Détecte les accesseurs explicites d'interface dans un type.
.DESCRIPTION
    Cette fonction détecte les accesseurs explicites d'interface dans un type et les associe aux propriétés correspondantes.
.PARAMETER Type
    Le type à analyser.
.PARAMETER InterfaceType
    Le type d'interface à rechercher. Si non spécifié, toutes les interfaces implémentées par le type sont analysées.
.EXAMPLE
    $explicitAccessors = Get-TypeExplicitInterfaceAccessors -Type ([System.Collections.Generic.List`1[System.String]])
.OUTPUTS
    PSObject[] - Un tableau d'objets contenant des informations sur les accesseurs explicites d'interface.
#>
function Get-TypeExplicitInterfaceAccessors {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [type]$InterfaceType
    )

    # Récupérer toutes les interfaces implémentées par le type
    $interfaces = if ($null -ne $InterfaceType) {
        @($InterfaceType)
    } else {
        $Type.GetInterfaces()
    }

    # Créer un tableau pour stocker les résultats
    $results = @()

    # Analyser chaque interface
    foreach ($interface in $interfaces) {
        # Récupérer la carte d'implémentation d'interface
        $interfaceMap = $Type.GetInterfaceMap($interface)

        # Parcourir les méthodes de l'interface
        for ($i = 0; $i -lt $interfaceMap.InterfaceMethods.Length; $i++) {
            $interfaceMethod = $interfaceMap.InterfaceMethods[$i]
            $implementationMethod = $interfaceMap.TargetMethods[$i]

            # Vérifier si la méthode est un accesseur
            if ($interfaceMethod.Name -match '^get_|^set_') {
                # Extraire le nom de la propriété
                $propertyName = $interfaceMethod.Name -replace '^get_|^set_', ''

                # Déterminer s'il s'agit d'un getter ou d'un setter
                $isGetter = $interfaceMethod.Name -match '^get_'

                # Créer l'objet résultat
                $result = [PSCustomObject]@{
                    Interface            = $interface
                    PropertyName         = $propertyName
                    InterfaceMethod      = $interfaceMethod
                    ImplementationMethod = $implementationMethod
                    IsGetter             = $isGetter
                    IsSetter             = -not $isGetter
                    IsExplicit           = $implementationMethod.Name -ne $interfaceMethod.Name
                }

                $results += $result
            }
        }
    }

    return $results
}

#endregion

#region Vérification des niveaux d'accès

<#
.SYNOPSIS
    Analyse les modificateurs d'accès d'une propriété.
.DESCRIPTION
    Cette fonction analyse les modificateurs d'accès (public, private, etc.) d'une propriété et de ses accesseurs.
.PARAMETER Property
    La propriété à analyser.
.PARAMETER IncludeNonPublic
    Indique si les accesseurs non publics doivent être inclus dans l'analyse.
.EXAMPLE
    $propertyInfo = [System.String].GetProperty("Length")
    $accessLevels = Get-PropertyAccessLevels -Property $propertyInfo
.OUTPUTS
    PSObject - Un objet contenant des informations sur les niveaux d'accès de la propriété.
#>
function Get-PropertyAccessLevels {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Reflection.PropertyInfo]$Property,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNonPublic
    )

    # Récupérer les accesseurs
    $accessors = Get-PropertyAccessors -Property $Property -IncludeNonPublic:$IncludeNonPublic

    # Déterminer les niveaux d'accès
    $getterAccess = if ($accessors.HasGetter) {
        if ($accessors.GetMethod.IsPublic) { "Public" }
        elseif ($accessors.GetMethod.IsPrivate) { "Private" }
        elseif ($accessors.GetMethod.IsFamily) { "Protected" }
        elseif ($accessors.GetMethod.IsAssembly) { "Internal" }
        elseif ($accessors.GetMethod.IsFamilyOrAssembly) { "ProtectedInternal" }
        elseif ($accessors.GetMethod.IsFamilyAndAssembly) { "PrivateProtected" }
        else { "Unknown" }
    } else { $null }

    $setterAccess = if ($accessors.HasSetter) {
        if ($accessors.SetMethod.IsPublic) { "Public" }
        elseif ($accessors.SetMethod.IsPrivate) { "Private" }
        elseif ($accessors.SetMethod.IsFamily) { "Protected" }
        elseif ($accessors.SetMethod.IsAssembly) { "Internal" }
        elseif ($accessors.SetMethod.IsFamilyOrAssembly) { "ProtectedInternal" }
        elseif ($accessors.SetMethod.IsFamilyAndAssembly) { "PrivateProtected" }
        else { "Unknown" }
    } else { $null }

    # Déterminer le niveau d'accès global de la propriété
    $propertyAccess = if ($getterAccess -eq $setterAccess) {
        $getterAccess
    } elseif ($null -eq $getterAccess) {
        $setterAccess
    } elseif ($null -eq $setterAccess) {
        $getterAccess
    } else {
        "Mixed"
    }

    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Property               = $Property
        PropertyAccess         = $propertyAccess
        GetterAccess           = $getterAccess
        SetterAccess           = $setterAccess
        HasAsymmetricAccessors = $getterAccess -ne $setterAccess -and $null -ne $getterAccess -and $null -ne $setterAccess
        IsPublic               = $propertyAccess -eq "Public"
        IsPrivate              = $propertyAccess -eq "Private"
        IsProtected            = $propertyAccess -eq "Protected"
        IsInternal             = $propertyAccess -eq "Internal"
        IsProtectedInternal    = $propertyAccess -eq "ProtectedInternal"
        IsPrivateProtected     = $propertyAccess -eq "PrivateProtected"
        IsMixed                = $propertyAccess -eq "Mixed"
    }

    return $result
}

<#
.SYNOPSIS
    Détecte les accesseurs asymétriques dans un type.
.DESCRIPTION
    Cette fonction détecte les propriétés d'un type qui ont des accesseurs avec des niveaux d'accès différents.
.PARAMETER Type
    Le type à analyser.
.PARAMETER IncludeNonPublic
    Indique si les accesseurs non publics doivent être inclus dans l'analyse.
.EXAMPLE
    $asymmetricProperties = Get-TypeAsymmetricAccessors -Type ([System.String])
.OUTPUTS
    PSObject[] - Un tableau d'objets contenant des informations sur les propriétés avec des accesseurs asymétriques.
#>
function Get-TypeAsymmetricAccessors {
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

    # Créer un tableau pour stocker les résultats
    $results = @()

    # Analyser chaque propriété
    foreach ($property in $properties) {
        $accessLevels = Get-PropertyAccessLevels -Property $property -IncludeNonPublic:$IncludeNonPublic

        # Vérifier si les accesseurs sont asymétriques
        if ($accessLevels.HasAsymmetricAccessors) {
            $results += $accessLevels
        }
    }

    return $results
}

<#
.SYNOPSIS
    Vérifie les restrictions d'accès sur une propriété.
.DESCRIPTION
    Cette fonction vérifie les restrictions d'accès sur une propriété, comme les attributs de sécurité ou les restrictions d'héritage.
.PARAMETER Property
    La propriété à analyser.
.EXAMPLE
    $propertyInfo = [System.String].GetProperty("Length")
    $restrictions = Test-PropertyAccessRestrictions -Property $propertyInfo
.OUTPUTS
    PSObject - Un objet contenant des informations sur les restrictions d'accès de la propriété.
#>
function Test-PropertyAccessRestrictions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Reflection.PropertyInfo]$Property
    )

    # Récupérer les accesseurs
    $accessors = Get-PropertyAccessors -Property $Property -IncludeNonPublic

    # Vérifier les restrictions d'accès
    $hasSecurityRestrictions = $false
    $hasInheritanceRestrictions = $false
    $hasAccessModifiers = $false
    $restrictions = @()

    # Vérifier les attributs de sécurité
    $securityAttributes = $Property.GetCustomAttributes([System.Security.Permissions.SecurityAttribute], $true)
    if ($securityAttributes.Length -gt 0) {
        $hasSecurityRestrictions = $true
        $restrictions += "SecurityAttribute"
    }

    # Vérifier les restrictions d'héritage
    if ($accessors.HasGetter -and $accessors.GetMethod.IsFinal) {
        $hasInheritanceRestrictions = $true
        $restrictions += "FinalGetter"
    }

    if ($accessors.HasSetter -and $accessors.SetMethod.IsFinal) {
        $hasInheritanceRestrictions = $true
        $restrictions += "FinalSetter"
    }

    # Vérifier les modificateurs d'accès
    $accessLevels = Get-PropertyAccessLevels -Property $Property -IncludeNonPublic
    if ($accessLevels.HasAsymmetricAccessors) {
        $hasAccessModifiers = $true
        $restrictions += "AsymmetricAccessors"
    }

    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Property                   = $Property
        HasRestrictions            = $hasSecurityRestrictions -or $hasInheritanceRestrictions -or $hasAccessModifiers
        HasSecurityRestrictions    = $hasSecurityRestrictions
        HasInheritanceRestrictions = $hasInheritanceRestrictions
        HasAccessModifiers         = $hasAccessModifiers
        Restrictions               = $restrictions
    }

    return $result
}

<#
.SYNOPSIS
    Analyse les propriétés avec accès mixte dans un type.
.DESCRIPTION
    Cette fonction analyse les propriétés d'un type qui ont des niveaux d'accès mixtes (par exemple, getter public et setter privé).
.PARAMETER Type
    Le type à analyser.
.PARAMETER IncludeNonPublic
    Indique si les accesseurs non publics doivent être inclus dans l'analyse.
.EXAMPLE
    $mixedAccessProperties = Get-TypeMixedAccessProperties -Type ([System.String])
.OUTPUTS
    PSObject[] - Un tableau d'objets contenant des informations sur les propriétés avec accès mixte.
#>
function Get-TypeMixedAccessProperties {
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

    # Créer un tableau pour stocker les résultats
    $results = @()

    # Analyser chaque propriété
    foreach ($property in $properties) {
        $accessLevels = Get-PropertyAccessLevels -Property $property -IncludeNonPublic:$IncludeNonPublic

        # Vérifier si la propriété a un accès mixte
        if ($accessLevels.IsMixed) {
            $results += $accessLevels
        }
    }

    return $results
}

#endregion

#region Analyse des attributs

<#
.SYNOPSIS
    Détecte les attributs de sérialisation sur une propriété.
.DESCRIPTION
    Cette fonction détecte les attributs de sérialisation (XmlElement, JsonProperty, etc.) sur une propriété.
.PARAMETER Property
    La propriété à analyser.
.PARAMETER IncludeInherited
    Indique si les attributs hérités doivent être inclus dans l'analyse.
.EXAMPLE
    $propertyInfo = [System.String].GetProperty("Length")
    $serializationAttributes = Get-PropertySerializationAttributes -Property $propertyInfo
.OUTPUTS
    PSObject - Un objet contenant des informations sur les attributs de sérialisation de la propriété.
#>
function Get-PropertySerializationAttributes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Reflection.PropertyInfo]$Property,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInherited
    )

    # Définir les types d'attributs de sérialisation courants
    $serializationAttributeTypes = @(
        "System.Xml.Serialization.XmlElementAttribute",
        "System.Xml.Serialization.XmlAttributeAttribute",
        "System.Xml.Serialization.XmlArrayAttribute",
        "System.Xml.Serialization.XmlArrayItemAttribute",
        "System.Xml.Serialization.XmlTextAttribute",
        "System.Xml.Serialization.XmlIgnoreAttribute",
        "System.Runtime.Serialization.DataMemberAttribute",
        "System.Runtime.Serialization.IgnoreDataMemberAttribute",
        "Newtonsoft.Json.JsonPropertyAttribute",
        "Newtonsoft.Json.JsonIgnoreAttribute",
        "System.Text.Json.Serialization.JsonPropertyNameAttribute",
        "System.Text.Json.Serialization.JsonIgnoreAttribute",
        "System.NonSerializedAttribute",
        "System.SerializableAttribute"
    )

    # Récupérer tous les attributs de la propriété
    $attributes = $Property.GetCustomAttributes($IncludeInherited)

    # Filtrer les attributs de sérialisation
    $serializationAttributes = @()
    foreach ($attribute in $attributes) {
        $attributeType = $attribute.GetType().FullName
        if ($serializationAttributeTypes -contains $attributeType) {
            $serializationAttributes += $attribute
        }
    }

    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Property                   = $Property
        HasSerializationAttributes = $serializationAttributes.Count -gt 0
        SerializationAttributes    = $serializationAttributes
        XmlAttributes              = $serializationAttributes | Where-Object { $_.GetType().FullName -like "System.Xml.Serialization.*" }
        JsonAttributes             = $serializationAttributes | Where-Object { $_.GetType().FullName -like "*Json*" }
        DataContractAttributes     = $serializationAttributes | Where-Object { $_.GetType().FullName -like "System.Runtime.Serialization.*" }
        IsSerializable             = $null -ne ($serializationAttributes | Where-Object { $_.GetType().FullName -eq "System.SerializableAttribute" })
        IsNonSerialized            = $null -ne ($serializationAttributes | Where-Object { $_.GetType().FullName -eq "System.NonSerializedAttribute" })
    }

    return $result
}

<#
.SYNOPSIS
    Analyse les attributs de validation sur une propriété.
.DESCRIPTION
    Cette fonction analyse les attributs de validation (Required, Range, StringLength, etc.) sur une propriété.
.PARAMETER Property
    La propriété à analyser.
.PARAMETER IncludeInherited
    Indique si les attributs hérités doivent être inclus dans l'analyse.
.EXAMPLE
    $propertyInfo = [System.String].GetProperty("Length")
    $validationAttributes = Get-PropertyValidationAttributes -Property $propertyInfo
.OUTPUTS
    PSObject - Un objet contenant des informations sur les attributs de validation de la propriété.
#>
function Get-PropertyValidationAttributes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Reflection.PropertyInfo]$Property,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInherited
    )

    # Définir les types d'attributs de validation courants
    $validationAttributeTypes = @(
        "System.ComponentModel.DataAnnotations.RequiredAttribute",
        "System.ComponentModel.DataAnnotations.RangeAttribute",
        "System.ComponentModel.DataAnnotations.StringLengthAttribute",
        "System.ComponentModel.DataAnnotations.RegularExpressionAttribute",
        "System.ComponentModel.DataAnnotations.EmailAddressAttribute",
        "System.ComponentModel.DataAnnotations.CreditCardAttribute",
        "System.ComponentModel.DataAnnotations.PhoneAttribute",
        "System.ComponentModel.DataAnnotations.UrlAttribute",
        "System.ComponentModel.DataAnnotations.CompareAttribute",
        "System.ComponentModel.DataAnnotations.MinLengthAttribute",
        "System.ComponentModel.DataAnnotations.MaxLengthAttribute",
        "System.ComponentModel.DataAnnotations.ValidationAttribute"
    )

    # Récupérer tous les attributs de la propriété
    $attributes = $Property.GetCustomAttributes($IncludeInherited)

    # Filtrer les attributs de validation
    $validationAttributes = @()
    foreach ($attribute in $attributes) {
        $attributeType = $attribute.GetType().FullName
        if ($validationAttributeTypes -contains $attributeType -or
            ($null -ne $attribute.GetType().BaseType -and $attribute.GetType().BaseType.FullName -eq "System.ComponentModel.DataAnnotations.ValidationAttribute")) {
            $validationAttributes += $attribute
        }
    }

    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Property                  = $Property
        HasValidationAttributes   = $validationAttributes.Count -gt 0
        ValidationAttributes      = $validationAttributes
        IsRequired                = $null -ne ($validationAttributes | Where-Object { $_.GetType().FullName -eq "System.ComponentModel.DataAnnotations.RequiredAttribute" })
        HasRangeValidation        = $null -ne ($validationAttributes | Where-Object { $_.GetType().FullName -eq "System.ComponentModel.DataAnnotations.RangeAttribute" })
        HasStringLengthValidation = $null -ne ($validationAttributes | Where-Object { $_.GetType().FullName -like "*LengthAttribute" })
        HasRegexValidation        = $null -ne ($validationAttributes | Where-Object { $_.GetType().FullName -eq "System.ComponentModel.DataAnnotations.RegularExpressionAttribute" })
    }

    return $result
}

<#
.SYNOPSIS
    Traite les attributs personnalisés sur une propriété.
.DESCRIPTION
    Cette fonction traite les attributs personnalisés sur une propriété et extrait leurs valeurs.
.PARAMETER Property
    La propriété à analyser.
.PARAMETER AttributeType
    Le type d'attribut à rechercher. Si non spécifié, tous les attributs personnalisés sont traités.
.PARAMETER IncludeInherited
    Indique si les attributs hérités doivent être inclus dans l'analyse.
.EXAMPLE
    $propertyInfo = [System.String].GetProperty("Length")
    $customAttributes = Get-PropertyCustomAttributes -Property $propertyInfo
.OUTPUTS
    PSObject[] - Un tableau d'objets contenant des informations sur les attributs personnalisés de la propriété.
#>
function Get-PropertyCustomAttributes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Reflection.PropertyInfo]$Property,

        [Parameter(Mandatory = $false)]
        [type]$AttributeType,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInherited
    )

    # Récupérer les attributs
    $attributes = if ($null -ne $AttributeType) {
        $Property.GetCustomAttributes($AttributeType, $IncludeInherited)
    } else {
        $Property.GetCustomAttributes($IncludeInherited)
    }

    # Créer un tableau pour stocker les résultats
    $results = @()

    # Traiter chaque attribut
    foreach ($attribute in $attributes) {
        # Récupérer les propriétés de l'attribut
        $attributeProperties = $attribute.GetType().GetProperties() | Where-Object { $_.Name -ne "TypeId" }

        # Créer un dictionnaire pour stocker les valeurs des propriétés
        $propertyValues = @{}
        foreach ($attributeProperty in $attributeProperties) {
            $propertyValues[$attributeProperty.Name] = $attributeProperty.GetValue($attribute)
        }

        # Créer l'objet résultat
        $result = [PSCustomObject]@{
            Property       = $Property
            Attribute      = $attribute
            AttributeType  = $attribute.GetType()
            PropertyValues = $propertyValues
        }

        $results += $result
    }

    return $results
}

<#
.SYNOPSIS
    Catégorise les propriétés d'un type par attributs.
.DESCRIPTION
    Cette fonction catégorise les propriétés d'un type en fonction des attributs qu'elles possèdent.
.PARAMETER Type
    Le type à analyser.
.PARAMETER IncludeInherited
    Indique si les attributs hérités doivent être inclus dans l'analyse.
.PARAMETER IncludeNonPublic
    Indique si les propriétés non publiques doivent être incluses dans l'analyse.
.EXAMPLE
    $categorizedProperties = Get-TypePropertiesByAttributes -Type ([System.String])
.OUTPUTS
    PSObject - Un objet contenant les propriétés catégorisées par attributs.
#>
function Get-TypePropertiesByAttributes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInherited,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNonPublic
    )

    # Récupérer toutes les propriétés du type
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance
    if ($IncludeNonPublic) {
        $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::NonPublic
    }

    $properties = $Type.GetProperties($bindingFlags)

    # Créer des listes pour chaque catégorie
    $serializableProperties = @()
    $validatedProperties = @()
    $requiredProperties = @()
    $displayProperties = @()
    $customProperties = @()
    $uncategorizedProperties = @()

    # Analyser chaque propriété
    foreach ($property in $properties) {
        $attributes = $property.GetCustomAttributes($IncludeInherited)

        $isSerialized = $false
        $isValidated = $false
        $isRequired = $false
        $hasDisplayAttribute = $false
        $hasCustomAttribute = $false

        foreach ($attribute in $attributes) {
            $attributeType = $attribute.GetType().FullName

            # Vérifier les attributs de sérialisation
            if ($attributeType -like "System.Xml.Serialization.*" -or
                $attributeType -like "*Json*" -or
                $attributeType -like "System.Runtime.Serialization.*" -or
                $attributeType -eq "System.SerializableAttribute") {
                $isSerialized = $true
                $serializableProperties += $property
            }

            # Vérifier les attributs de validation
            if ($attributeType -like "System.ComponentModel.DataAnnotations.*Attribute" -or
                ($null -ne $attribute.GetType().BaseType -and $attribute.GetType().BaseType.FullName -eq "System.ComponentModel.DataAnnotations.ValidationAttribute")) {
                $isValidated = $true
                $validatedProperties += $property

                # Vérifier si la propriété est requise
                if ($attributeType -eq "System.ComponentModel.DataAnnotations.RequiredAttribute") {
                    $isRequired = $true
                    $requiredProperties += $property
                }
            }

            # Vérifier les attributs d'affichage
            if ($attributeType -like "System.ComponentModel.*DisplayAttribute" -or
                $attributeType -eq "System.ComponentModel.DisplayNameAttribute") {
                $hasDisplayAttribute = $true
                $displayProperties += $property
            }

            # Vérifier les attributs personnalisés (non système)
            if (-not $attributeType.StartsWith("System.")) {
                $hasCustomAttribute = $true
                $customProperties += $property
            }
        }

        # Si la propriété n'a pas été catégorisée, l'ajouter aux propriétés non catégorisées
        if (-not ($isSerialized -or $isValidated -or $hasDisplayAttribute -or $hasCustomAttribute)) {
            $uncategorizedProperties += $property
        }
    }

    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Type                    = $Type
        AllProperties           = $properties
        SerializableProperties  = $serializableProperties | Select-Object -Unique
        ValidatedProperties     = $validatedProperties | Select-Object -Unique
        RequiredProperties      = $requiredProperties | Select-Object -Unique
        DisplayProperties       = $displayProperties | Select-Object -Unique
        CustomProperties        = $customProperties | Select-Object -Unique
        UncategorizedProperties = $uncategorizedProperties | Select-Object -Unique
    }

    return $result
}

#endregion

#region Propriétés auto-implémentées

<#
.SYNOPSIS
    Détecte les champs de backing pour les propriétés.
.DESCRIPTION
    Cette fonction détecte les champs de backing (champs privés utilisés pour stocker les valeurs des propriétés) dans un type.
.PARAMETER Type
    Le type à analyser.
.PARAMETER Property
    La propriété spécifique à analyser. Si non spécifié, toutes les propriétés du type sont analysées.
.EXAMPLE
    $backingFields = Get-TypePropertyBackingFields -Type ([System.String])
.OUTPUTS
    PSObject[] - Un tableau d'objets contenant des informations sur les champs de backing des propriétés.
#>
function Get-TypePropertyBackingFields {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [System.Reflection.PropertyInfo]$Property
    )

    # Récupérer tous les champs privés du type
    $bindingFlags = [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance
    $fields = $Type.GetFields($bindingFlags)

    # Récupérer les propriétés à analyser
    $properties = if ($null -ne $Property) {
        @($Property)
    } else {
        $Type.GetProperties([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance)
    }

    # Créer un tableau pour stocker les résultats
    $results = @()

    # Analyser chaque propriété
    foreach ($prop in $properties) {
        # Rechercher les champs de backing potentiels
        $backingFields = @()

        # Modèles de nommage courants pour les champs de backing
        $patterns = @(
            "_$($prop.Name.ToLower())", # _propertyName
            "m_$($prop.Name.ToLower())", # m_propertyName
            "$($prop.Name.ToLower())Field", # propertyNameField
            "$($prop.Name.Substring(0, 1).ToLower())$($prop.Name.Substring(1))", # propertyName (camelCase)
            "<$($prop.Name)>k__BackingField"  # <PropertyName>k__BackingField (auto-implémenté)
        )

        foreach ($field in $fields) {
            $fieldNameLower = $field.Name.ToLower()

            # Vérifier si le champ correspond à l'un des modèles
            $isBackingField = $false
            foreach ($pattern in $patterns) {
                if ($fieldNameLower -eq $pattern.ToLower() -or $field.Name -eq "<$($prop.Name)>k__BackingField") {
                    $isBackingField = $true
                    break
                }
            }

            # Vérifier si le type du champ est compatible avec le type de la propriété
            if ($isBackingField -and $field.FieldType -eq $prop.PropertyType) {
                $backingFields += $field
            }
        }

        # Créer l'objet résultat
        if ($backingFields.Count -gt 0) {
            $result = [PSCustomObject]@{
                Property          = $prop
                BackingFields     = $backingFields
                IsAutoImplemented = $backingFields | Where-Object { $_.Name -eq "<$($prop.Name)>k__BackingField" } | Measure-Object | Select-Object -ExpandProperty Count -gt 0
            }

            $results += $result
        }
    }

    return $results
}

<#
.SYNOPSIS
    Identifie les propriétés synthétiques dans un type.
.DESCRIPTION
    Cette fonction identifie les propriétés synthétiques (propriétés générées par le compilateur) dans un type.
.PARAMETER Type
    Le type à analyser.
.EXAMPLE
    $syntheticProperties = Get-TypeSyntheticProperties -Type ([System.String])
.OUTPUTS
    PSObject[] - Un tableau d'objets contenant des informations sur les propriétés synthétiques du type.
#>
function Get-TypeSyntheticProperties {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type
    )

    # Récupérer toutes les propriétés du type
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance
    $properties = $Type.GetProperties($bindingFlags)

    # Créer un tableau pour stocker les résultats
    $results = @()

    # Analyser chaque propriété
    foreach ($property in $properties) {
        # Vérifier si la propriété est synthétique
        $isSynthetic = $false

        # Vérifier les attributs de compilation
        $compilerGeneratedAttribute = $property.GetCustomAttributes([System.Runtime.CompilerServices.CompilerGeneratedAttribute], $false)
        if ($compilerGeneratedAttribute.Length -gt 0) {
            $isSynthetic = $true
        }

        # Vérifier si la propriété a un champ de backing généré par le compilateur
        $backingFields = Get-TypePropertyBackingFields -Type $Type -Property $property
        if ($backingFields.IsAutoImplemented) {
            $isSynthetic = $true
        }

        # Vérifier si le nom de la propriété suit un modèle synthétique
        if ($property.Name -match "^<.*>.*$") {
            $isSynthetic = $true
        }

        # Créer l'objet résultat si la propriété est synthétique
        if ($isSynthetic) {
            $result = [PSCustomObject]@{
                Property                       = $property
                IsSynthetic                    = $true
                HasCompilerGeneratedAttribute  = $compilerGeneratedAttribute.Length -gt 0
                HasAutoImplementedBackingField = $backingFields.IsAutoImplemented
                HasSyntheticName               = $property.Name -match "^<.*>.*$"
            }

            $results += $result
        }
    }

    return $results
}

<#
.SYNOPSIS
    Distingue les propriétés explicites des propriétés auto-implémentées.
.DESCRIPTION
    Cette fonction distingue les propriétés explicites (avec accesseurs personnalisés) des propriétés auto-implémentées dans un type.
.PARAMETER Type
    Le type à analyser.
.EXAMPLE
    $propertyTypes = Get-TypePropertyImplementationTypes -Type ([System.String])
.OUTPUTS
    PSObject - Un objet contenant des informations sur les propriétés explicites et auto-implémentées du type.
#>
function Get-TypePropertyImplementationTypes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type
    )

    # Récupérer toutes les propriétés du type
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance
    $properties = $Type.GetProperties($bindingFlags)

    # Récupérer les champs de backing
    $backingFields = Get-TypePropertyBackingFields -Type $Type

    # Créer des listes pour chaque catégorie
    $autoImplementedProperties = @()
    $explicitProperties = @()
    $mixedProperties = @()

    # Analyser chaque propriété
    foreach ($property in $properties) {
        # Récupérer les accesseurs
        $accessors = Get-PropertyAccessors -Property $property -IncludeNonPublic

        # Vérifier si la propriété a un champ de backing auto-implémenté
        $backingField = $backingFields | Where-Object { $_.Property -eq $property }
        $isAutoImplemented = $null -ne $backingField -and $backingField.IsAutoImplemented

        # Vérifier si les accesseurs sont explicites
        $hasExplicitAccessors = $false

        if ($accessors.HasGetter) {
            # Vérifier si le getter contient du code personnalisé
            $getterIL = $accessors.GetMethod.GetMethodBody()
            if ($null -ne $getterIL -and $getterIL.GetILAsByteArray().Length -gt 10) {
                $hasExplicitAccessors = $true
            }
        }

        if ($accessors.HasSetter) {
            # Vérifier si le setter contient du code personnalisé
            $setterIL = $accessors.SetMethod.GetMethodBody()
            if ($null -ne $setterIL -and $setterIL.GetILAsByteArray().Length -gt 10) {
                $hasExplicitAccessors = $true
            }
        }

        # Catégoriser la propriété
        if ($isAutoImplemented -and -not $hasExplicitAccessors) {
            $autoImplementedProperties += $property
        } elseif ($hasExplicitAccessors -and -not $isAutoImplemented) {
            $explicitProperties += $property
        } else {
            $mixedProperties += $property
        }
    }

    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Type                      = $Type
        AllProperties             = $properties
        AutoImplementedProperties = $autoImplementedProperties
        ExplicitProperties        = $explicitProperties
        MixedProperties           = $mixedProperties
    }

    return $result
}

<#
.SYNOPSIS
    Analyse les optimisations du compilateur pour les propriétés.
.DESCRIPTION
    Cette fonction analyse les optimisations du compilateur pour les propriétés d'un type, comme l'inlining ou les accesseurs synthétiques.
.PARAMETER Type
    Le type à analyser.
.EXAMPLE
    $optimizations = Get-TypePropertyCompilerOptimizations -Type ([System.String])
.OUTPUTS
    PSObject - Un objet contenant des informations sur les optimisations du compilateur pour les propriétés du type.
#>
function Get-TypePropertyCompilerOptimizations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type
    )

    # Récupérer toutes les propriétés du type
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance
    $properties = $Type.GetProperties($bindingFlags)

    # Créer un tableau pour stocker les résultats
    $results = @()

    # Analyser chaque propriété
    foreach ($property in $properties) {
        # Récupérer les accesseurs
        $accessors = Get-PropertyAccessors -Property $property -IncludeNonPublic

        # Vérifier les optimisations
        $isInlined = $false
        $hasAggressiveInlining = $false
        $isReadOnly = $false
        $isConstant = $false

        # Vérifier l'attribut AggressiveInlining
        if ($accessors.HasGetter) {
            $aggressiveInliningAttribute = $accessors.GetMethod.GetCustomAttributes([System.Runtime.CompilerServices.MethodImplAttribute], $false) |
                Where-Object { $_.Value -band [System.Runtime.CompilerServices.MethodImplOptions]::AggressiveInlining }

            if ($null -ne $aggressiveInliningAttribute -and $aggressiveInliningAttribute.Count -gt 0) {
                $hasAggressiveInlining = $true
            }

            # Vérifier si la propriété est en lecture seule
            if (-not $accessors.HasSetter) {
                $isReadOnly = $true

                # Vérifier si la propriété est une constante (getter simple qui retourne une valeur constante)
                $getterIL = $accessors.GetMethod.GetMethodBody()
                if ($null -ne $getterIL -and $getterIL.GetILAsByteArray().Length -le 5) {
                    $isConstant = $true
                }
            }
        }

        # Vérifier si la propriété est susceptible d'être inlinée
        if ($hasAggressiveInlining -or $isConstant) {
            $isInlined = $true
        }

        # Créer l'objet résultat
        $result = [PSCustomObject]@{
            Property              = $property
            IsInlined             = $isInlined
            HasAggressiveInlining = $hasAggressiveInlining
            IsReadOnly            = $isReadOnly
            IsConstant            = $isConstant
        }

        $results += $result
    }

    return $results
}

#endregion
