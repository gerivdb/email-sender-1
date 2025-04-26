# Documentation des exceptions du namespace System

## Introduction

Le namespace `System` contient les exceptions fondamentales du framework .NET. Ces exceptions représentent les erreurs les plus courantes et les plus génériques qui peuvent survenir dans une application .NET. Comprendre ces exceptions, leurs cas d'utilisation et leurs caractéristiques est essentiel pour développer des applications robustes et pour diagnostiquer efficacement les problèmes.

Cette documentation présente en détail les exceptions principales du namespace `System`, leurs hiérarchies, leurs cas d'utilisation typiques, et fournit des exemples concrets en PowerShell pour illustrer leur comportement.

## ArgumentException et ses dérivées

### Vue d'ensemble

La classe `ArgumentException` et ses dérivées sont utilisées pour signaler des problèmes liés aux arguments passés à une méthode ou une fonction. Ces exceptions sont parmi les plus couramment utilisées dans le développement .NET, car elles permettent de valider les entrées et de signaler clairement les problèmes liés aux paramètres.

### Hiérarchie

```
System.Exception
└── System.ArgumentException
    ├── System.ArgumentNullException
    ├── System.ArgumentOutOfRangeException
    ├── System.DuplicateWaitObjectException
    └── System.ArgumentException (autres spécialisations)
```

### ArgumentException

#### Description

`ArgumentException` est l'exception de base pour tous les problèmes liés aux arguments. Elle est utilisée lorsqu'un argument fourni à une méthode n'est pas valide pour une raison quelconque, mais qu'aucune exception plus spécifique n'est appropriée.

#### Propriétés spécifiques

| Propriété | Type | Description |
|-----------|------|-------------|
| ParamName | string | Nom du paramètre qui a causé l'exception |

#### Constructeurs principaux

```csharp
ArgumentException()
ArgumentException(string message)
ArgumentException(string message, Exception innerException)
ArgumentException(string message, string paramName)
ArgumentException(string message, string paramName, Exception innerException)
```

#### Cas d'utilisation typiques

- Un argument a un format incorrect
- Un argument contient une valeur invalide
- Un argument ne respecte pas une contrainte métier
- Une combinaison d'arguments est invalide

#### Exemples en PowerShell

```powershell
# Exemple 1: Lancer une ArgumentException basique
function Test-Argument {
    param (
        [string]$Name
    )
    
    if ($Name -match '\d') {
        throw [System.ArgumentException]::new("Le nom ne doit pas contenir de chiffres", "Name")
    }
    
    return "Nom valide: $Name"
}

try {
    Test-Argument -Name "John123"
} catch {
    Write-Host "Erreur: $($_.Exception.Message)"
    Write-Host "Paramètre: $($_.Exception.ParamName)"
}

# Sortie:
# Erreur: Le nom ne doit pas contenir de chiffres
# Paramètre: Name

# Exemple 2: Validation de plusieurs arguments
function Add-Numbers {
    param (
        [int]$A,
        [int]$B
    )
    
    if ($A -lt 0 -or $B -lt 0) {
        throw [System.ArgumentException]::new("Les nombres doivent être positifs", 
            if ($A -lt 0) { "A" } else { "B" })
    }
    
    return $A + $B
}

try {
    Add-Numbers -A -5 -B 10
} catch {
    Write-Host "Erreur: $($_.Exception.Message)"
    Write-Host "Paramètre: $($_.Exception.ParamName)"
}

# Sortie:
# Erreur: Les nombres doivent être positifs
# Paramètre: A
```

### ArgumentNullException

#### Description

`ArgumentNullException` est une exception spécialisée qui est levée lorsqu'un argument fourni à une méthode est `null` (ou `$null` en PowerShell) alors qu'une valeur non nulle est requise.

#### Propriétés spécifiques

Hérite des propriétés de `ArgumentException`, notamment `ParamName`.

#### Constructeurs principaux

```csharp
ArgumentNullException()
ArgumentNullException(string paramName)
ArgumentNullException(string paramName, string message)
ArgumentNullException(string message, Exception innerException)
```

#### Cas d'utilisation typiques

- Un argument obligatoire est `null`
- Une référence d'objet requise est `null`
- Un élément d'une collection est `null` alors qu'il ne devrait pas l'être

#### Exemples en PowerShell

```powershell
# Exemple 1: Vérification de paramètre null
function Process-Data {
    param (
        [object]$Data
    )
    
    if ($null -eq $Data) {
        throw [System.ArgumentNullException]::new("Data", "Les données ne peuvent pas être nulles")
    }
    
    return "Traitement de $($Data.GetType().Name) réussi"
}

try {
    Process-Data -Data $null
} catch {
    Write-Host "Erreur: $($_.Exception.Message)"
    Write-Host "Paramètre: $($_.Exception.ParamName)"
}

# Sortie:
# Erreur: Les données ne peuvent pas être nulles
# Paramètre: Data

# Exemple 2: Vérification de propriété null
function Process-User {
    param (
        [PSCustomObject]$User
    )
    
    if ($null -eq $User) {
        throw [System.ArgumentNullException]::new("User")
    }
    
    if ($null -eq $User.Name) {
        throw [System.ArgumentNullException]::new("User.Name", "Le nom de l'utilisateur ne peut pas être null")
    }
    
    return "Utilisateur traité: $($User.Name)"
}

try {
    $user = [PSCustomObject]@{
        Id = 1
        Name = $null
        Email = "user@example.com"
    }
    
    Process-User -User $user
} catch {
    Write-Host "Erreur: $($_.Exception.Message)"
    Write-Host "Paramètre: $($_.Exception.ParamName)"
}

# Sortie:
# Erreur: Le nom de l'utilisateur ne peut pas être null
# Paramètre: User.Name
```

### ArgumentOutOfRangeException

#### Description

`ArgumentOutOfRangeException` est une exception spécialisée qui est levée lorsqu'un argument est en dehors de la plage de valeurs valides pour ce paramètre.

#### Propriétés spécifiques

| Propriété | Type | Description |
|-----------|------|-------------|
| ParamName | string | Nom du paramètre qui a causé l'exception |
| ActualValue | object | Valeur réelle de l'argument qui a causé l'exception |

#### Constructeurs principaux

```csharp
ArgumentOutOfRangeException()
ArgumentOutOfRangeException(string paramName)
ArgumentOutOfRangeException(string paramName, string message)
ArgumentOutOfRangeException(string paramName, object actualValue, string message)
ArgumentOutOfRangeException(string message, Exception innerException)
```

#### Cas d'utilisation typiques

- Un index est en dehors des limites d'un tableau ou d'une collection
- Une valeur numérique est en dehors d'une plage acceptable
- Une date est en dehors d'une période valide
- Un énumérateur a une valeur non définie

#### Exemples en PowerShell

```powershell
# Exemple 1: Vérification de plage numérique
function Set-Age {
    param (
        [int]$Age
    )
    
    if ($Age -lt 0 -or $Age -gt 120) {
        throw [System.ArgumentOutOfRangeException]::new("Age", $Age, "L'âge doit être compris entre 0 et 120")
    }
    
    return "Âge défini à $Age"
}

try {
    Set-Age -Age 150
} catch {
    Write-Host "Erreur: $($_.Exception.Message)"
    Write-Host "Paramètre: $($_.Exception.ParamName)"
    Write-Host "Valeur: $($_.Exception.ActualValue)"
}

# Sortie:
# Erreur: L'âge doit être compris entre 0 et 120
# Paramètre: Age
# Valeur: 150

# Exemple 2: Vérification d'index
function Get-Element {
    param (
        [array]$Array,
        [int]$Index
    )
    
    if ($Index -lt 0 -or $Index -ge $Array.Length) {
        throw [System.ArgumentOutOfRangeException]::new("Index", $Index, 
            "L'index doit être compris entre 0 et $($Array.Length - 1)")
    }
    
    return $Array[$Index]
}

try {
    $array = @(1, 2, 3, 4, 5)
    Get-Element -Array $array -Index 10
} catch {
    Write-Host "Erreur: $($_.Exception.Message)"
    Write-Host "Paramètre: $($_.Exception.ParamName)"
    Write-Host "Valeur: $($_.Exception.ActualValue)"
}

# Sortie:
# Erreur: L'index doit être compris entre 0 et 4
# Paramètre: Index
# Valeur: 10
```

### Autres dérivées d'ArgumentException

#### DuplicateWaitObjectException

Cette exception est levée lorsqu'un objet d'attente apparaît plusieurs fois dans un tableau d'objets d'attente.

```powershell
# Exemple: DuplicateWaitObjectException
try {
    $event1 = [System.Threading.AutoResetEvent]::new($false)
    $event2 = [System.Threading.AutoResetEvent]::new($false)
    
    # Créer un tableau avec un objet en double
    $waitHandles = @($event1, $event2, $event1)
    
    # Cela va générer une DuplicateWaitObjectException
    [System.Threading.WaitHandle]::WaitAll($waitHandles)
} catch {
    Write-Host "Erreur: $($_.Exception.GetType().FullName)"
    Write-Host "Message: $($_.Exception.Message)"
}

# Sortie:
# Erreur: System.ArgumentException
# Message: Duplicate handles are not allowed in the wait list.
```

### Bonnes pratiques pour ArgumentException

1. **Spécificité** : Utilisez la classe d'exception la plus spécifique possible (`ArgumentNullException` pour les valeurs nulles, `ArgumentOutOfRangeException` pour les valeurs hors limites).

2. **Nommage des paramètres** : Toujours spécifier le nom du paramètre qui a causé l'exception pour faciliter le débogage.

3. **Messages clairs** : Fournir des messages d'erreur clairs qui expliquent pourquoi l'argument est invalide et quelles sont les valeurs acceptables.

4. **Validation précoce** : Valider les arguments au début de la méthode pour éviter des traitements inutiles.

5. **Documentation** : Documenter les contraintes sur les paramètres dans la documentation de la fonction.

### Validation des arguments en PowerShell

PowerShell offre plusieurs mécanismes intégrés pour la validation des arguments, qui peuvent aider à éviter de devoir lever manuellement des exceptions `ArgumentException` :

```powershell
function Test-ValidationAttributes {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$NotNullParam,
        
        [ValidateRange(1, 100)]
        [int]$RangeParam = 50,
        
        [ValidateSet("Option1", "Option2", "Option3")]
        [string]$OptionParam,
        
        [ValidatePattern("^[a-zA-Z0-9]+$")]
        [string]$PatternParam
    )
    
    return "Tous les paramètres sont valides"
}

# Ces appels vont générer des erreurs de validation
try { Test-ValidationAttributes -NotNullParam $null } catch { Write-Host "Erreur 1: $($_.Exception.Message)" }
try { Test-ValidationAttributes -NotNullParam "Valid" -RangeParam 101 } catch { Write-Host "Erreur 2: $($_.Exception.Message)" }
try { Test-ValidationAttributes -NotNullParam "Valid" -OptionParam "Option4" } catch { Write-Host "Erreur 3: $($_.Exception.Message)" }
try { Test-ValidationAttributes -NotNullParam "Valid" -PatternParam "Invalid!" } catch { Write-Host "Erreur 4: $($_.Exception.Message)" }

# Cet appel est valide
Test-ValidationAttributes -NotNullParam "Valid" -RangeParam 50 -OptionParam "Option1" -PatternParam "Valid123"
```

### Comparaison avec d'autres exceptions

| Exception | Quand l'utiliser | Au lieu de |
|-----------|-----------------|------------|
| ArgumentException | Argument invalide pour une raison générale | Exception générique |
| ArgumentNullException | Argument null non autorisé | Vérification null manuelle |
| ArgumentOutOfRangeException | Valeur en dehors des limites acceptables | IndexOutOfRangeException (pour les collections) |
| InvalidOperationException | L'opération n'est pas valide dans l'état actuel | ArgumentException (quand ce n'est pas lié à un argument) |
| FormatException | Format de données incorrect | ArgumentException (quand spécifiquement lié au format) |

### Interception et gestion en PowerShell

En PowerShell, vous pouvez intercepter spécifiquement les exceptions liées aux arguments :

```powershell
function Test-ExceptionHandling {
    try {
        $array = @(1, 2, 3)
        $index = 5
        
        if ($index -lt 0 -or $index -ge $array.Length) {
            throw [System.ArgumentOutOfRangeException]::new("index", $index, "Index hors limites")
        }
        
        return $array[$index]
    }
    catch [System.ArgumentOutOfRangeException] {
        Write-Host "Erreur d'index: $($_.Exception.Message)"
        Write-Host "Valeur: $($_.Exception.ActualValue)"
        return -1
    }
    catch [System.ArgumentException] {
        Write-Host "Erreur d'argument: $($_.Exception.Message)"
        return -2
    }
    catch {
        Write-Host "Erreur générique: $($_.Exception.Message)"
        return -3
    }
}

Test-ExceptionHandling
```

### Résumé

Les exceptions de type `ArgumentException` et ses dérivées sont essentielles pour la validation des entrées dans les applications .NET. Elles permettent de signaler clairement les problèmes liés aux arguments et facilitent le débogage en fournissant des informations précises sur la nature et la localisation de l'erreur.

En utilisant ces exceptions de manière appropriée, vous pouvez améliorer la robustesse de votre code et fournir des messages d'erreur plus utiles aux utilisateurs et aux développeurs.
