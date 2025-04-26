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

## InvalidOperationException et ses cas d'usage

### Vue d'ensemble

`InvalidOperationException` est une exception qui indique qu'une méthode a été appelée à un moment où elle ne peut pas être exécutée en raison de l'état actuel de l'objet. Contrairement à `ArgumentException` qui est liée aux paramètres d'entrée, `InvalidOperationException` est liée à l'état interne de l'objet ou du système.

### Hiérarchie

```
System.Exception
└── System.SystemException
    └── System.InvalidOperationException
        ├── System.ObjectDisposedException
        ├── System.InvalidTimeZoneException
        ├── System.NotSupportedException
        └── Autres exceptions spécialisées
```

### Description

`InvalidOperationException` est utilisée lorsqu'une opération ne peut pas être effectuée en raison de l'état actuel de l'objet. C'est une exception très courante dans le framework .NET, car elle permet de signaler des problèmes liés au cycle de vie des objets et à la logique métier.

### Propriétés spécifiques

`InvalidOperationException` n'ajoute pas de propriétés spécifiques à celles héritées de `System.Exception`.

### Constructeurs principaux

```csharp
InvalidOperationException()
InvalidOperationException(string message)
InvalidOperationException(string message, Exception innerException)
```

### Cas d'utilisation typiques

1. **Opération sur un objet dans un état incorrect** : Tentative d'utiliser un objet qui n'est pas dans l'état approprié pour l'opération demandée.

2. **Violation de séquence d'opérations** : Appel d'une méthode dans un ordre incorrect (par exemple, appeler `Read` avant `Open`).

3. **Opération sur un objet disposé** : Tentative d'utiliser un objet après qu'il ait été disposé (bien que `ObjectDisposedException` soit plus spécifique pour ce cas).

4. **Violation de contrat d'état** : L'état interne de l'objet ne permet pas l'opération demandée.

5. **Opération non initialisée** : Tentative d'utiliser un objet qui n'a pas été correctement initialisé.

### Exemples en PowerShell

```powershell
# Exemple 1: État incorrect pour une opération
function Start-Process {
    param (
        [PSCustomObject]$Process
    )

    if ($Process.Status -eq "Running") {
        throw [System.InvalidOperationException]::new("Le processus est déjà en cours d'exécution")
    }

    $Process.Status = "Running"
    return $Process
}

$process = [PSCustomObject]@{
    Id = 1
    Name = "TestProcess"
    Status = "Running"
}

try {
    Start-Process -Process $process
} catch {
    Write-Host "Erreur: $($_.Exception.Message)"
}

# Sortie:
# Erreur: Le processus est déjà en cours d'exécution

# Exemple 2: Violation de séquence d'opérations
class FileProcessor {
    [bool]$IsOpen = $false
    [string]$Content = $null

    [void] Open([string]$filePath) {
        if ($this.IsOpen) {
            throw [System.InvalidOperationException]::new("Le fichier est déjà ouvert")
        }

        $this.Content = Get-Content -Path $filePath -Raw
        $this.IsOpen = $true
    }

    [string] Read() {
        if (-not $this.IsOpen) {
            throw [System.InvalidOperationException]::new("Le fichier doit être ouvert avant de pouvoir être lu")
        }

        return $this.Content
    }

    [void] Close() {
        if (-not $this.IsOpen) {
            throw [System.InvalidOperationException]::new("Le fichier n'est pas ouvert")
        }

        $this.Content = $null
        $this.IsOpen = $false
    }
}

$processor = [FileProcessor]::new()

try {
    # Tentative de lecture avant ouverture
    $content = $processor.Read()
} catch {
    Write-Host "Erreur: $($_.Exception.Message)"
}

# Sortie:
# Erreur: Le fichier doit être ouvert avant de pouvoir être lu

# Exemple 3: Implémentation d'une machine à états
class StateMachine {
    [string]$State = "Initial"
    [hashtable]$AllowedTransitions = @{
        "Initial" = @("Processing")
        "Processing" = @("Completed", "Failed")
        "Completed" = @()
        "Failed" = @("Initial")
    }

    [void] TransitionTo([string]$newState) {
        if (-not $this.AllowedTransitions[$this.State].Contains($newState)) {
            throw [System.InvalidOperationException]::new(
                "Transition non autorisée de '$($this.State)' vers '$newState'")
        }

        $this.State = $newState
    }
}

$machine = [StateMachine]::new()

try {
    # Transition valide
    $machine.TransitionTo("Processing")
    Write-Host "État actuel: $($machine.State)"

    # Transition invalide
    $machine.TransitionTo("Initial")
} catch {
    Write-Host "Erreur: $($_.Exception.Message)"
}

# Sortie:
# État actuel: Processing
# Erreur: Transition non autorisée de 'Processing' vers 'Initial'

# Exemple 4: Opération non supportée dans le contexte actuel
function Invoke-Operation {
    param (
        [string]$OperationType,
        [PSCustomObject]$Context
    )

    switch ($OperationType) {
        "Read" {
            if ($Context.ReadOnly -eq $false) {
                throw [System.InvalidOperationException]::new("L'opération de lecture n'est pas autorisée dans un contexte en écriture")
            }
            return "Lecture effectuée"
        }
        "Write" {
            if ($Context.ReadOnly -eq $true) {
                throw [System.InvalidOperationException]::new("L'opération d'écriture n'est pas autorisée dans un contexte en lecture seule")
            }
            return "Écriture effectuée"
        }
        default {
            throw [System.ArgumentException]::new("Type d'opération non reconnu", "OperationType")
        }
    }
}

$readOnlyContext = [PSCustomObject]@{
    ReadOnly = $true
    Name = "ContextTest"
}

try {
    Invoke-Operation -OperationType "Write" -Context $readOnlyContext
} catch {
    Write-Host "Erreur: $($_.Exception.Message)"
}

# Sortie:
# Erreur: L'opération d'écriture n'est pas autorisée dans un contexte en lecture seule
```

### Sous-classes importantes

#### ObjectDisposedException

`ObjectDisposedException` est une sous-classe spécialisée de `InvalidOperationException` qui est levée lorsqu'une opération est tentée sur un objet qui a été disposé.

```powershell
# Exemple: ObjectDisposedException
class DisposableResource : System.IDisposable {
    [bool]$IsDisposed = $false

    [void] DoWork() {
        if ($this.IsDisposed) {
            throw [System.ObjectDisposedException]::new("DisposableResource")
        }

        Write-Host "Travail effectué"
    }

    [void] Dispose() {
        if (-not $this.IsDisposed) {
            # Nettoyage des ressources
            $this.IsDisposed = $true
        }
    }
}

$resource = [DisposableResource]::new()
$resource.DoWork()  # Fonctionne

# Disposer la ressource
$resource.Dispose()

try {
    $resource.DoWork()  # Génère une exception
} catch {
    Write-Host "Erreur: $($_.Exception.GetType().FullName)"
    Write-Host "Message: $($_.Exception.Message)"
}

# Sortie:
# Travail effectué
# Erreur: System.ObjectDisposedException
# Message: Cannot access a disposed object.
# Object name: 'DisposableResource'.
```

#### NotSupportedException

`NotSupportedException` est une sous-classe de `InvalidOperationException` qui est levée lorsqu'une opération n'est pas supportée par l'implémentation actuelle.

```powershell
# Exemple: NotSupportedException
class ReadOnlyCollection {
    [array]$Items

    ReadOnlyCollection([array]$items) {
        $this.Items = $items
    }

    [object] GetItem([int]$index) {
        return $this.Items[$index]
    }

    [void] AddItem([object]$item) {
        throw [System.NotSupportedException]::new("Cette collection est en lecture seule")
    }
}

$collection = [ReadOnlyCollection]::new(@(1, 2, 3))
Write-Host "Item à l'index 1: $($collection.GetItem(1))"

try {
    $collection.AddItem(4)
} catch {
    Write-Host "Erreur: $($_.Exception.GetType().FullName)"
    Write-Host "Message: $($_.Exception.Message)"
}

# Sortie:
# Item à l'index 1: 2
# Erreur: System.NotSupportedException
# Message: Cette collection est en lecture seule
```

### Bonnes pratiques pour InvalidOperationException

1. **Messages clairs** : Fournir des messages d'erreur qui expliquent clairement pourquoi l'opération n'est pas valide dans l'état actuel.

2. **Vérifications précoces** : Vérifier l'état de l'objet au début de la méthode pour éviter des traitements inutiles.

3. **Documentation** : Documenter clairement les conditions dans lesquelles une méthode peut lever `InvalidOperationException`.

4. **Utilisation appropriée** : Utiliser `InvalidOperationException` pour les problèmes d'état, et non pour les problèmes d'arguments (utiliser `ArgumentException` pour cela).

5. **Sous-classes spécifiques** : Utiliser des sous-classes plus spécifiques lorsqu'elles existent (`ObjectDisposedException`, `NotSupportedException`).

### Comparaison avec d'autres exceptions

| Exception | Quand l'utiliser | Au lieu de |
|-----------|-----------------|------------|
| InvalidOperationException | L'opération n'est pas valide dans l'état actuel | ArgumentException (quand ce n'est pas lié à un argument) |
| ObjectDisposedException | L'objet a été disposé | InvalidOperationException générique |
| NotSupportedException | L'opération n'est pas supportée par l'implémentation | InvalidOperationException générique |
| MethodAccessException | L'accès à la méthode est refusé | InvalidOperationException (quand c'est lié à la sécurité) |
| MissingMethodException | La méthode n'existe pas | InvalidOperationException (quand c'est lié à la réflexion) |

### Interception et gestion en PowerShell

En PowerShell, vous pouvez intercepter spécifiquement les exceptions liées aux opérations invalides :

```powershell
function Test-OperationHandling {
    try {
        $stream = [System.IO.MemoryStream]::new()
        $stream.Dispose()

        # Tentative d'utilisation après disposition
        $stream.Write(@(1, 2, 3), 0, 3)
    }
    catch [System.ObjectDisposedException] {
        Write-Host "Erreur d'objet disposé: $($_.Exception.Message)"
        return "Objet disposé"
    }
    catch [System.InvalidOperationException] {
        Write-Host "Erreur d'opération invalide: $($_.Exception.Message)"
        return "Opération invalide"
    }
    catch {
        Write-Host "Erreur générique: $($_.Exception.Message)"
        return "Erreur générique"
    }
}

Test-OperationHandling
```

### Résumé

`InvalidOperationException` est une exception fondamentale dans le framework .NET qui permet de signaler des problèmes liés à l'état des objets et à la séquence des opérations. Elle est particulièrement utile pour implémenter des machines à états, des cycles de vie d'objets, et pour garantir que les méthodes sont appelées dans le bon ordre et dans le bon contexte.

En utilisant cette exception de manière appropriée, vous pouvez créer des APIs plus robustes et plus faciles à utiliser, car les erreurs liées à une utilisation incorrecte sont clairement identifiées et expliquées.
