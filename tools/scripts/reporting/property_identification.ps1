<#
.SYNOPSIS
    Fonctions pour l'identification et l'analyse des propriÃ©tÃ©s dans les types .NET.
.DESCRIPTION
    Ce module fournit des fonctions pour identifier, analyser et catÃ©goriser les propriÃ©tÃ©s
    dans les types .NET, y compris la dÃ©tection des accesseurs, l'analyse des niveaux d'accÃ¨s,
    l'analyse des attributs et la dÃ©tection des propriÃ©tÃ©s auto-implÃ©mentÃ©es.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
#>

#region DÃ©tection des accesseurs

<#
.SYNOPSIS
    DÃ©tecte les mÃ©thodes get/set associÃ©es Ã  une propriÃ©tÃ©.
.DESCRIPTION
    Cette fonction dÃ©tecte les mÃ©thodes get/set associÃ©es Ã  une propriÃ©tÃ© et retourne des informations dÃ©taillÃ©es sur ces accesseurs.
.PARAMETER Property
    La propriÃ©tÃ© Ã  analyser.
.PARAMETER IncludeNonPublic
    Indique si les accesseurs non publics doivent Ãªtre inclus dans l'analyse.
.EXAMPLE
    $propertyInfo = [System.String].GetProperty("Length")
    $accessors = Get-PropertyAccessors -Property $propertyInfo
.OUTPUTS
    PSObject - Un objet contenant des informations sur les accesseurs de la propriÃ©tÃ©.
#>
function Get-PropertyAccessors {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Reflection.PropertyInfo]$Property,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNonPublic
    )

    # RÃ©cupÃ©rer les mÃ©thodes get/set
    $getMethod = $Property.GetGetMethod($IncludeNonPublic)
    $setMethod = $Property.GetSetMethod($IncludeNonPublic)

    # CrÃ©er l'objet rÃ©sultat
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
    Associe les accesseurs aux propriÃ©tÃ©s dans un type.
.DESCRIPTION
    Cette fonction analyse un type et associe les mÃ©thodes get/set aux propriÃ©tÃ©s correspondantes.
.PARAMETER Type
    Le type Ã  analyser.
.PARAMETER IncludeNonPublic
    Indique si les accesseurs non publics doivent Ãªtre inclus dans l'analyse.
.EXAMPLE
    $accessorMap = Get-TypePropertyAccessorMap -Type ([System.String])
.OUTPUTS
    Hashtable - Une table de hachage oÃ¹ les clÃ©s sont les noms des propriÃ©tÃ©s et les valeurs sont les informations sur les accesseurs.
#>
function Get-TypePropertyAccessorMap {
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

    # CrÃ©er la table de hachage pour stocker les associations
    $accessorMap = @{}

    # Analyser chaque propriÃ©tÃ©
    foreach ($property in $properties) {
        $accessors = Get-PropertyAccessors -Property $property -IncludeNonPublic:$IncludeNonPublic
        $accessorMap[$property.Name] = $accessors
    }

    return $accessorMap
}

<#
.SYNOPSIS
    VÃ©rifie la compatibilitÃ© des types entre les accesseurs get/set d'une propriÃ©tÃ©.
.DESCRIPTION
    Cette fonction vÃ©rifie que les types de retour et de paramÃ¨tre des accesseurs get/set d'une propriÃ©tÃ© sont compatibles.
.PARAMETER Property
    La propriÃ©tÃ© Ã  analyser.
.PARAMETER IncludeNonPublic
    Indique si les accesseurs non publics doivent Ãªtre inclus dans l'analyse.
.EXAMPLE
    $propertyInfo = [System.String].GetProperty("Length")
    $isCompatible = Test-PropertyAccessorTypeCompatibility -Property $propertyInfo
.OUTPUTS
    PSObject - Un objet contenant des informations sur la compatibilitÃ© des types des accesseurs.
#>
function Test-PropertyAccessorTypeCompatibility {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Reflection.PropertyInfo]$Property,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNonPublic
    )

    # RÃ©cupÃ©rer les accesseurs
    $accessors = Get-PropertyAccessors -Property $Property -IncludeNonPublic:$IncludeNonPublic

    # VÃ©rifier si les deux accesseurs existent
    if (-not $accessors.HasGetter -or -not $accessors.HasSetter) {
        # Si un seul accesseur existe, il n'y a pas de problÃ¨me de compatibilitÃ©
        return [PSCustomObject]@{
            IsCompatible = $true
            Property     = $Property
            GetterType   = if ($accessors.HasGetter) { $accessors.GetMethod.ReturnType } else { $null }
            SetterType   = if ($accessors.HasSetter) { $accessors.SetMethod.GetParameters()[0].ParameterType } else { $null }
            Reason       = "Un seul accesseur existe"
        }
    }

    # RÃ©cupÃ©rer les types
    $getterType = $accessors.GetMethod.ReturnType
    $setterType = $accessors.SetMethod.GetParameters()[0].ParameterType

    # VÃ©rifier la compatibilitÃ©
    $isCompatible = $getterType -eq $setterType

    # CrÃ©er l'objet rÃ©sultat
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
    DÃ©tecte les accesseurs explicites d'interface dans un type.
.DESCRIPTION
    Cette fonction dÃ©tecte les accesseurs explicites d'interface dans un type et les associe aux propriÃ©tÃ©s correspondantes.
.PARAMETER Type
    Le type Ã  analyser.
.PARAMETER InterfaceType
    Le type d'interface Ã  rechercher. Si non spÃ©cifiÃ©, toutes les interfaces implÃ©mentÃ©es par le type sont analysÃ©es.
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

    # RÃ©cupÃ©rer toutes les interfaces implÃ©mentÃ©es par le type
    $interfaces = if ($null -ne $InterfaceType) {
        @($InterfaceType)
    } else {
        $Type.GetInterfaces()
    }

    # CrÃ©er un tableau pour stocker les rÃ©sultats
    $results = @()

    # Analyser chaque interface
    foreach ($interface in $interfaces) {
        # RÃ©cupÃ©rer la carte d'implÃ©mentation d'interface
        $interfaceMap = $Type.GetInterfaceMap($interface)

        # Parcourir les mÃ©thodes de l'interface
        for ($i = 0; $i -lt $interfaceMap.InterfaceMethods.Length; $i++) {
            $interfaceMethod = $interfaceMap.InterfaceMethods[$i]
            $implementationMethod = $interfaceMap.TargetMethods[$i]

            # VÃ©rifier si la mÃ©thode est un accesseur
            if ($interfaceMethod.Name -match '^get_|^set_') {
                # Extraire le nom de la propriÃ©tÃ©
                $propertyName = $interfaceMethod.Name -replace '^get_|^set_', ''

                # DÃ©terminer s'il s'agit d'un getter ou d'un setter
                $isGetter = $interfaceMethod.Name -match '^get_'

                # CrÃ©er l'objet rÃ©sultat
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

#region VÃ©rification des niveaux d'accÃ¨s

<#
.SYNOPSIS
    Analyse les modificateurs d'accÃ¨s d'une propriÃ©tÃ©.
.DESCRIPTION
    Cette fonction analyse les modificateurs d'accÃ¨s (public, private, etc.) d'une propriÃ©tÃ© et de ses accesseurs.
.PARAMETER Property
    La propriÃ©tÃ© Ã  analyser.
.PARAMETER IncludeNonPublic
    Indique si les accesseurs non publics doivent Ãªtre inclus dans l'analyse.
.EXAMPLE
    $propertyInfo = [System.String].GetProperty("Length")
    $accessLevels = Get-PropertyAccessLevels -Property $propertyInfo
.OUTPUTS
    PSObject - Un objet contenant des informations sur les niveaux d'accÃ¨s de la propriÃ©tÃ©.
#>
function Get-PropertyAccessLevels {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Reflection.PropertyInfo]$Property,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeNonPublic
    )

    # RÃ©cupÃ©rer les accesseurs
    $accessors = Get-PropertyAccessors -Property $Property -IncludeNonPublic:$IncludeNonPublic

    # DÃ©terminer les niveaux d'accÃ¨s
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

    # DÃ©terminer le niveau d'accÃ¨s global de la propriÃ©tÃ©
    $propertyAccess = if ($getterAccess -eq $setterAccess) {
        $getterAccess
    } elseif ($null -eq $getterAccess) {
        $setterAccess
    } elseif ($null -eq $setterAccess) {
        $getterAccess
    } else {
        "Mixed"
    }

    # CrÃ©er l'objet rÃ©sultat
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
    DÃ©tecte les accesseurs asymÃ©triques dans un type.
.DESCRIPTION
    Cette fonction dÃ©tecte les propriÃ©tÃ©s d'un type qui ont des accesseurs avec des niveaux d'accÃ¨s diffÃ©rents.
.PARAMETER Type
    Le type Ã  analyser.
.PARAMETER IncludeNonPublic
    Indique si les accesseurs non publics doivent Ãªtre inclus dans l'analyse.
.EXAMPLE
    $asymmetricProperties = Get-TypeAsymmetricAccessors -Type ([System.String])
.OUTPUTS
    PSObject[] - Un tableau d'objets contenant des informations sur les propriÃ©tÃ©s avec des accesseurs asymÃ©triques.
#>
function Get-TypeAsymmetricAccessors {
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

    # CrÃ©er un tableau pour stocker les rÃ©sultats
    $results = @()

    # Analyser chaque propriÃ©tÃ©
    foreach ($property in $properties) {
        $accessLevels = Get-PropertyAccessLevels -Property $property -IncludeNonPublic:$IncludeNonPublic

        # VÃ©rifier si les accesseurs sont asymÃ©triques
        if ($accessLevels.HasAsymmetricAccessors) {
            $results += $accessLevels
        }
    }

    return $results
}

<#
.SYNOPSIS
    VÃ©rifie les restrictions d'accÃ¨s sur une propriÃ©tÃ©.
.DESCRIPTION
    Cette fonction vÃ©rifie les restrictions d'accÃ¨s sur une propriÃ©tÃ©, comme les attributs de sÃ©curitÃ© ou les restrictions d'hÃ©ritage.
.PARAMETER Property
    La propriÃ©tÃ© Ã  analyser.
.EXAMPLE
    $propertyInfo = [System.String].GetProperty("Length")
    $restrictions = Test-PropertyAccessRestrictions -Property $propertyInfo
.OUTPUTS
    PSObject - Un objet contenant des informations sur les restrictions d'accÃ¨s de la propriÃ©tÃ©.
#>
function Test-PropertyAccessRestrictions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Reflection.PropertyInfo]$Property
    )

    # RÃ©cupÃ©rer les accesseurs
    $accessors = Get-PropertyAccessors -Property $Property -IncludeNonPublic

    # VÃ©rifier les restrictions d'accÃ¨s
    $hasSecurityRestrictions = $false
    $hasInheritanceRestrictions = $false
    $hasAccessModifiers = $false
    $restrictions = @()

    # VÃ©rifier les attributs de sÃ©curitÃ©
    $securityAttributes = $Property.GetCustomAttributes([System.Security.Permissions.SecurityAttribute], $true)
    if ($securityAttributes.Length -gt 0) {
        $hasSecurityRestrictions = $true
        $restrictions += "SecurityAttribute"
    }

    # VÃ©rifier les restrictions d'hÃ©ritage
    if ($accessors.HasGetter -and $accessors.GetMethod.IsFinal) {
        $hasInheritanceRestrictions = $true
        $restrictions += "FinalGetter"
    }

    if ($accessors.HasSetter -and $accessors.SetMethod.IsFinal) {
        $hasInheritanceRestrictions = $true
        $restrictions += "FinalSetter"
    }

    # VÃ©rifier les modificateurs d'accÃ¨s
    $accessLevels = Get-PropertyAccessLevels -Property $Property -IncludeNonPublic
    if ($accessLevels.HasAsymmetricAccessors) {
        $hasAccessModifiers = $true
        $restrictions += "AsymmetricAccessors"
    }

    # CrÃ©er l'objet rÃ©sultat
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
    Analyse les propriÃ©tÃ©s avec accÃ¨s mixte dans un type.
.DESCRIPTION
    Cette fonction analyse les propriÃ©tÃ©s d'un type qui ont des niveaux d'accÃ¨s mixtes (par exemple, getter public et setter privÃ©).
.PARAMETER Type
    Le type Ã  analyser.
.PARAMETER IncludeNonPublic
    Indique si les accesseurs non publics doivent Ãªtre inclus dans l'analyse.
.EXAMPLE
    $mixedAccessProperties = Get-TypeMixedAccessProperties -Type ([System.String])
.OUTPUTS
    PSObject[] - Un tableau d'objets contenant des informations sur les propriÃ©tÃ©s avec accÃ¨s mixte.
#>
function Get-TypeMixedAccessProperties {
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

    # CrÃ©er un tableau pour stocker les rÃ©sultats
    $results = @()

    # Analyser chaque propriÃ©tÃ©
    foreach ($property in $properties) {
        $accessLevels = Get-PropertyAccessLevels -Property $property -IncludeNonPublic:$IncludeNonPublic

        # VÃ©rifier si la propriÃ©tÃ© a un accÃ¨s mixte
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
    DÃ©tecte les attributs de sÃ©rialisation sur une propriÃ©tÃ©.
.DESCRIPTION
    Cette fonction dÃ©tecte les attributs de sÃ©rialisation (XmlElement, JsonProperty, etc.) sur une propriÃ©tÃ©.
.PARAMETER Property
    La propriÃ©tÃ© Ã  analyser.
.PARAMETER IncludeInherited
    Indique si les attributs hÃ©ritÃ©s doivent Ãªtre inclus dans l'analyse.
.EXAMPLE
    $propertyInfo = [System.String].GetProperty("Length")
    $serializationAttributes = Get-PropertySerializationAttributes -Property $propertyInfo
.OUTPUTS
    PSObject - Un objet contenant des informations sur les attributs de sÃ©rialisation de la propriÃ©tÃ©.
#>
function Get-PropertySerializationAttributes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Reflection.PropertyInfo]$Property,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInherited
    )

    # DÃ©finir les types d'attributs de sÃ©rialisation courants
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

    # RÃ©cupÃ©rer tous les attributs de la propriÃ©tÃ©
    $attributes = $Property.GetCustomAttributes($IncludeInherited)

    # Filtrer les attributs de sÃ©rialisation
    $serializationAttributes = @()
    foreach ($attribute in $attributes) {
        $attributeType = $attribute.GetType().FullName
        if ($serializationAttributeTypes -contains $attributeType) {
            $serializationAttributes += $attribute
        }
    }

    # CrÃ©er l'objet rÃ©sultat
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
    Analyse les attributs de validation sur une propriÃ©tÃ©.
.DESCRIPTION
    Cette fonction analyse les attributs de validation (Required, Range, StringLength, etc.) sur une propriÃ©tÃ©.
.PARAMETER Property
    La propriÃ©tÃ© Ã  analyser.
.PARAMETER IncludeInherited
    Indique si les attributs hÃ©ritÃ©s doivent Ãªtre inclus dans l'analyse.
.EXAMPLE
    $propertyInfo = [System.String].GetProperty("Length")
    $validationAttributes = Get-PropertyValidationAttributes -Property $propertyInfo
.OUTPUTS
    PSObject - Un objet contenant des informations sur les attributs de validation de la propriÃ©tÃ©.
#>
function Get-PropertyValidationAttributes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Reflection.PropertyInfo]$Property,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeInherited
    )

    # DÃ©finir les types d'attributs de validation courants
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

    # RÃ©cupÃ©rer tous les attributs de la propriÃ©tÃ©
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

    # CrÃ©er l'objet rÃ©sultat
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
    Traite les attributs personnalisÃ©s sur une propriÃ©tÃ©.
.DESCRIPTION
    Cette fonction traite les attributs personnalisÃ©s sur une propriÃ©tÃ© et extrait leurs valeurs.
.PARAMETER Property
    La propriÃ©tÃ© Ã  analyser.
.PARAMETER AttributeType
    Le type d'attribut Ã  rechercher. Si non spÃ©cifiÃ©, tous les attributs personnalisÃ©s sont traitÃ©s.
.PARAMETER IncludeInherited
    Indique si les attributs hÃ©ritÃ©s doivent Ãªtre inclus dans l'analyse.
.EXAMPLE
    $propertyInfo = [System.String].GetProperty("Length")
    $customAttributes = Get-PropertyCustomAttributes -Property $propertyInfo
.OUTPUTS
    PSObject[] - Un tableau d'objets contenant des informations sur les attributs personnalisÃ©s de la propriÃ©tÃ©.
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

    # RÃ©cupÃ©rer les attributs
    $attributes = if ($null -ne $AttributeType) {
        $Property.GetCustomAttributes($AttributeType, $IncludeInherited)
    } else {
        $Property.GetCustomAttributes($IncludeInherited)
    }

    # CrÃ©er un tableau pour stocker les rÃ©sultats
    $results = @()

    # Traiter chaque attribut
    foreach ($attribute in $attributes) {
        # RÃ©cupÃ©rer les propriÃ©tÃ©s de l'attribut
        $attributeProperties = $attribute.GetType().GetProperties() | Where-Object { $_.Name -ne "TypeId" }

        # CrÃ©er un dictionnaire pour stocker les valeurs des propriÃ©tÃ©s
        $propertyValues = @{}
        foreach ($attributeProperty in $attributeProperties) {
            $propertyValues[$attributeProperty.Name] = $attributeProperty.GetValue($attribute)
        }

        # CrÃ©er l'objet rÃ©sultat
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
    CatÃ©gorise les propriÃ©tÃ©s d'un type par attributs.
.DESCRIPTION
    Cette fonction catÃ©gorise les propriÃ©tÃ©s d'un type en fonction des attributs qu'elles possÃ¨dent.
.PARAMETER Type
    Le type Ã  analyser.
.PARAMETER IncludeInherited
    Indique si les attributs hÃ©ritÃ©s doivent Ãªtre inclus dans l'analyse.
.PARAMETER IncludeNonPublic
    Indique si les propriÃ©tÃ©s non publiques doivent Ãªtre incluses dans l'analyse.
.EXAMPLE
    $categorizedProperties = Get-TypePropertiesByAttributes -Type ([System.String])
.OUTPUTS
    PSObject - Un objet contenant les propriÃ©tÃ©s catÃ©gorisÃ©es par attributs.
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

    # RÃ©cupÃ©rer toutes les propriÃ©tÃ©s du type
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance
    if ($IncludeNonPublic) {
        $bindingFlags = $bindingFlags -bor [System.Reflection.BindingFlags]::NonPublic
    }

    $properties = $Type.GetProperties($bindingFlags)

    # CrÃ©er des listes pour chaque catÃ©gorie
    $serializableProperties = @()
    $validatedProperties = @()
    $requiredProperties = @()
    $displayProperties = @()
    $customProperties = @()
    $uncategorizedProperties = @()

    # Analyser chaque propriÃ©tÃ©
    foreach ($property in $properties) {
        $attributes = $property.GetCustomAttributes($IncludeInherited)

        $isSerialized = $false
        $isValidated = $false
        $isRequired = $false
        $hasDisplayAttribute = $false
        $hasCustomAttribute = $false

        foreach ($attribute in $attributes) {
            $attributeType = $attribute.GetType().FullName

            # VÃ©rifier les attributs de sÃ©rialisation
            if ($attributeType -like "System.Xml.Serialization.*" -or
                $attributeType -like "*Json*" -or
                $attributeType -like "System.Runtime.Serialization.*" -or
                $attributeType -eq "System.SerializableAttribute") {
                $isSerialized = $true
                $serializableProperties += $property
            }

            # VÃ©rifier les attributs de validation
            if ($attributeType -like "System.ComponentModel.DataAnnotations.*Attribute" -or
                ($null -ne $attribute.GetType().BaseType -and $attribute.GetType().BaseType.FullName -eq "System.ComponentModel.DataAnnotations.ValidationAttribute")) {
                $isValidated = $true
                $validatedProperties += $property

                # VÃ©rifier si la propriÃ©tÃ© est requise
                if ($attributeType -eq "System.ComponentModel.DataAnnotations.RequiredAttribute") {
                    $isRequired = $true
                    $requiredProperties += $property
                }
            }

            # VÃ©rifier les attributs d'affichage
            if ($attributeType -like "System.ComponentModel.*DisplayAttribute" -or
                $attributeType -eq "System.ComponentModel.DisplayNameAttribute") {
                $hasDisplayAttribute = $true
                $displayProperties += $property
            }

            # VÃ©rifier les attributs personnalisÃ©s (non systÃ¨me)
            if (-not $attributeType.StartsWith("System.")) {
                $hasCustomAttribute = $true
                $customProperties += $property
            }
        }

        # Si la propriÃ©tÃ© n'a pas Ã©tÃ© catÃ©gorisÃ©e, l'ajouter aux propriÃ©tÃ©s non catÃ©gorisÃ©es
        if (-not ($isSerialized -or $isValidated -or $hasDisplayAttribute -or $hasCustomAttribute)) {
            $uncategorizedProperties += $property
        }
    }

    # CrÃ©er l'objet rÃ©sultat
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

#region PropriÃ©tÃ©s auto-implÃ©mentÃ©es

<#
.SYNOPSIS
    DÃ©tecte les champs de backing pour les propriÃ©tÃ©s.
.DESCRIPTION
    Cette fonction dÃ©tecte les champs de backing (champs privÃ©s utilisÃ©s pour stocker les valeurs des propriÃ©tÃ©s) dans un type.
.PARAMETER Type
    Le type Ã  analyser.
.PARAMETER Property
    La propriÃ©tÃ© spÃ©cifique Ã  analyser. Si non spÃ©cifiÃ©, toutes les propriÃ©tÃ©s du type sont analysÃ©es.
.EXAMPLE
    $backingFields = Get-TypePropertyBackingFields -Type ([System.String])
.OUTPUTS
    PSObject[] - Un tableau d'objets contenant des informations sur les champs de backing des propriÃ©tÃ©s.
#>
function Get-TypePropertyBackingFields {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type,

        [Parameter(Mandatory = $false)]
        [System.Reflection.PropertyInfo]$Property
    )

    # RÃ©cupÃ©rer tous les champs privÃ©s du type
    $bindingFlags = [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance
    $fields = $Type.GetFields($bindingFlags)

    # RÃ©cupÃ©rer les propriÃ©tÃ©s Ã  analyser
    $properties = if ($null -ne $Property) {
        @($Property)
    } else {
        $Type.GetProperties([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance)
    }

    # CrÃ©er un tableau pour stocker les rÃ©sultats
    $results = @()

    # Analyser chaque propriÃ©tÃ©
    foreach ($prop in $properties) {
        # Rechercher les champs de backing potentiels
        $backingFields = @()

        # ModÃ¨les de nommage courants pour les champs de backing
        $patterns = @(
            "_$($prop.Name.ToLower())", # _propertyName
            "m_$($prop.Name.ToLower())", # m_propertyName
            "$($prop.Name.ToLower())Field", # propertyNameField
            "$($prop.Name.Substring(0, 1).ToLower())$($prop.Name.Substring(1))", # propertyName (camelCase)
            "<$($prop.Name)>k__BackingField"  # <PropertyName>k__BackingField (auto-implÃ©mentÃ©)
        )

        foreach ($field in $fields) {
            $fieldNameLower = $field.Name.ToLower()

            # VÃ©rifier si le champ correspond Ã  l'un des modÃ¨les
            $isBackingField = $false
            foreach ($pattern in $patterns) {
                if ($fieldNameLower -eq $pattern.ToLower() -or $field.Name -eq "<$($prop.Name)>k__BackingField") {
                    $isBackingField = $true
                    break
                }
            }

            # VÃ©rifier si le type du champ est compatible avec le type de la propriÃ©tÃ©
            if ($isBackingField -and $field.FieldType -eq $prop.PropertyType) {
                $backingFields += $field
            }
        }

        # CrÃ©er l'objet rÃ©sultat
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
    Identifie les propriÃ©tÃ©s synthÃ©tiques dans un type.
.DESCRIPTION
    Cette fonction identifie les propriÃ©tÃ©s synthÃ©tiques (propriÃ©tÃ©s gÃ©nÃ©rÃ©es par le compilateur) dans un type.
.PARAMETER Type
    Le type Ã  analyser.
.EXAMPLE
    $syntheticProperties = Get-TypeSyntheticProperties -Type ([System.String])
.OUTPUTS
    PSObject[] - Un tableau d'objets contenant des informations sur les propriÃ©tÃ©s synthÃ©tiques du type.
#>
function Get-TypeSyntheticProperties {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type
    )

    # RÃ©cupÃ©rer toutes les propriÃ©tÃ©s du type
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance
    $properties = $Type.GetProperties($bindingFlags)

    # CrÃ©er un tableau pour stocker les rÃ©sultats
    $results = @()

    # Analyser chaque propriÃ©tÃ©
    foreach ($property in $properties) {
        # VÃ©rifier si la propriÃ©tÃ© est synthÃ©tique
        $isSynthetic = $false

        # VÃ©rifier les attributs de compilation
        $compilerGeneratedAttribute = $property.GetCustomAttributes([System.Runtime.CompilerServices.CompilerGeneratedAttribute], $false)
        if ($compilerGeneratedAttribute.Length -gt 0) {
            $isSynthetic = $true
        }

        # VÃ©rifier si la propriÃ©tÃ© a un champ de backing gÃ©nÃ©rÃ© par le compilateur
        $backingFields = Get-TypePropertyBackingFields -Type $Type -Property $property
        if ($backingFields.IsAutoImplemented) {
            $isSynthetic = $true
        }

        # VÃ©rifier si le nom de la propriÃ©tÃ© suit un modÃ¨le synthÃ©tique
        if ($property.Name -match "^<.*>.*$") {
            $isSynthetic = $true
        }

        # CrÃ©er l'objet rÃ©sultat si la propriÃ©tÃ© est synthÃ©tique
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
    Distingue les propriÃ©tÃ©s explicites des propriÃ©tÃ©s auto-implÃ©mentÃ©es.
.DESCRIPTION
    Cette fonction distingue les propriÃ©tÃ©s explicites (avec accesseurs personnalisÃ©s) des propriÃ©tÃ©s auto-implÃ©mentÃ©es dans un type.
.PARAMETER Type
    Le type Ã  analyser.
.EXAMPLE
    $propertyTypes = Get-TypePropertyImplementationTypes -Type ([System.String])
.OUTPUTS
    PSObject - Un objet contenant des informations sur les propriÃ©tÃ©s explicites et auto-implÃ©mentÃ©es du type.
#>
function Get-TypePropertyImplementationTypes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type
    )

    # RÃ©cupÃ©rer toutes les propriÃ©tÃ©s du type
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance
    $properties = $Type.GetProperties($bindingFlags)

    # RÃ©cupÃ©rer les champs de backing
    $backingFields = Get-TypePropertyBackingFields -Type $Type

    # CrÃ©er des listes pour chaque catÃ©gorie
    $autoImplementedProperties = @()
    $explicitProperties = @()
    $mixedProperties = @()

    # Analyser chaque propriÃ©tÃ©
    foreach ($property in $properties) {
        # RÃ©cupÃ©rer les accesseurs
        $accessors = Get-PropertyAccessors -Property $property -IncludeNonPublic

        # VÃ©rifier si la propriÃ©tÃ© a un champ de backing auto-implÃ©mentÃ©
        $backingField = $backingFields | Where-Object { $_.Property -eq $property }
        $isAutoImplemented = $null -ne $backingField -and $backingField.IsAutoImplemented

        # VÃ©rifier si les accesseurs sont explicites
        $hasExplicitAccessors = $false

        if ($accessors.HasGetter) {
            # VÃ©rifier si le getter contient du code personnalisÃ©
            $getterIL = $accessors.GetMethod.GetMethodBody()
            if ($null -ne $getterIL -and $getterIL.GetILAsByteArray().Length -gt 10) {
                $hasExplicitAccessors = $true
            }
        }

        if ($accessors.HasSetter) {
            # VÃ©rifier si le setter contient du code personnalisÃ©
            $setterIL = $accessors.SetMethod.GetMethodBody()
            if ($null -ne $setterIL -and $setterIL.GetILAsByteArray().Length -gt 10) {
                $hasExplicitAccessors = $true
            }
        }

        # CatÃ©goriser la propriÃ©tÃ©
        if ($isAutoImplemented -and -not $hasExplicitAccessors) {
            $autoImplementedProperties += $property
        } elseif ($hasExplicitAccessors -and -not $isAutoImplemented) {
            $explicitProperties += $property
        } else {
            $mixedProperties += $property
        }
    }

    # CrÃ©er l'objet rÃ©sultat
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
    Analyse les optimisations du compilateur pour les propriÃ©tÃ©s.
.DESCRIPTION
    Cette fonction analyse les optimisations du compilateur pour les propriÃ©tÃ©s d'un type, comme l'inlining ou les accesseurs synthÃ©tiques.
.PARAMETER Type
    Le type Ã  analyser.
.EXAMPLE
    $optimizations = Get-TypePropertyCompilerOptimizations -Type ([System.String])
.OUTPUTS
    PSObject - Un objet contenant des informations sur les optimisations du compilateur pour les propriÃ©tÃ©s du type.
#>
function Get-TypePropertyCompilerOptimizations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [type]$Type
    )

    # RÃ©cupÃ©rer toutes les propriÃ©tÃ©s du type
    $bindingFlags = [System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance
    $properties = $Type.GetProperties($bindingFlags)

    # CrÃ©er un tableau pour stocker les rÃ©sultats
    $results = @()

    # Analyser chaque propriÃ©tÃ©
    foreach ($property in $properties) {
        # RÃ©cupÃ©rer les accesseurs
        $accessors = Get-PropertyAccessors -Property $property -IncludeNonPublic

        # VÃ©rifier les optimisations
        $isInlined = $false
        $hasAggressiveInlining = $false
        $isReadOnly = $false
        $isConstant = $false

        # VÃ©rifier l'attribut AggressiveInlining
        if ($accessors.HasGetter) {
            $aggressiveInliningAttribute = $accessors.GetMethod.GetCustomAttributes([System.Runtime.CompilerServices.MethodImplAttribute], $false) |
                Where-Object { $_.Value -band [System.Runtime.CompilerServices.MethodImplOptions]::AggressiveInlining }

            if ($null -ne $aggressiveInliningAttribute -and $aggressiveInliningAttribute.Count -gt 0) {
                $hasAggressiveInlining = $true
            }

            # VÃ©rifier si la propriÃ©tÃ© est en lecture seule
            if (-not $accessors.HasSetter) {
                $isReadOnly = $true

                # VÃ©rifier si la propriÃ©tÃ© est une constante (getter simple qui retourne une valeur constante)
                $getterIL = $accessors.GetMethod.GetMethodBody()
                if ($null -ne $getterIL -and $getterIL.GetILAsByteArray().Length -le 5) {
                    $isConstant = $true
                }
            }
        }

        # VÃ©rifier si la propriÃ©tÃ© est susceptible d'Ãªtre inlinÃ©e
        if ($hasAggressiveInlining -or $isConstant) {
            $isInlined = $true
        }

        # CrÃ©er l'objet rÃ©sultat
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
