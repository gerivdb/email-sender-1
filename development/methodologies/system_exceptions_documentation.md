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

## NullReferenceException et ses causes

### Vue d'ensemble

`NullReferenceException` est l'une des exceptions les plus courantes dans le développement .NET. Elle se produit lorsque vous tentez d'accéder à un membre (propriété, méthode, champ) d'une référence d'objet qui est `null`. Cette exception est souvent le signe d'un bug dans le code, car elle indique généralement un oubli de vérification de nullité.

### Hiérarchie

```
System.Exception
└── System.SystemException
    └── System.NullReferenceException
```

### Description

`NullReferenceException` est levée automatiquement par le runtime .NET lorsqu'une tentative est faite pour déréférencer une référence nulle. Contrairement à d'autres exceptions comme `ArgumentNullException` ou `InvalidOperationException`, elle n'est généralement pas levée explicitement par le code, mais plutôt par le runtime lui-même.

### Propriétés spécifiques

`NullReferenceException` n'ajoute pas de propriétés spécifiques à celles héritées de `System.Exception`.

### Constructeurs principaux

```csharp
NullReferenceException()
NullReferenceException(string message)
NullReferenceException(string message, Exception innerException)
```

### Causes courantes

1. **Référence non initialisée** : Utilisation d'une variable qui n'a jamais été initialisée.

2. **Valeur nulle inattendue** : Une méthode ou une propriété retourne `null` de manière inattendue.

3. **Chaînage d'appels sans vérification** : Appel en chaîne de méthodes ou propriétés sans vérifier les valeurs intermédiaires (`obj.Property1.Property2.Method()`).

4. **Tableau ou collection avec éléments nuls** : Accès à un élément nul dans un tableau ou une collection.

5. **Erreur de logique** : Erreurs de logique qui conduisent à des références nulles dans certaines conditions.

### Exemples en PowerShell

```powershell
# Exemple 1: Référence non initialisée
function Test-NullReference1 {
    [PSCustomObject]$user = $null

    # Ceci va générer une NullReferenceException
    return $user.Name
}

try {
    Test-NullReference1
} catch {
    Write-Host "Erreur: $($_.Exception.GetType().FullName)"
    Write-Host "Message: $($_.Exception.Message)"
}

# Sortie:
# Erreur: System.NullReferenceException
# Message: Object reference not set to an instance of an object.

# Exemple 2: Chaînage d'appels sans vérification
function Test-NullReference2 {
    param (
        [PSCustomObject]$user
    )

    # Ceci va générer une NullReferenceException si $user.Address est null
    return $user.Address.City
}

$user = [PSCustomObject]@{
    Name = "John Doe"
    Address = $null
}

try {
    Test-NullReference2 -User $user
} catch {
    Write-Host "Erreur: $($_.Exception.GetType().FullName)"
    Write-Host "Message: $($_.Exception.Message)"
}

# Sortie:
# Erreur: System.NullReferenceException
# Message: Object reference not set to an instance of an object.

# Exemple 3: Tableau avec éléments nuls
function Test-NullReference3 {
    $array = @("Item1", $null, "Item3")

    # Ceci va générer une NullReferenceException
    return $array[1].Length
}

try {
    Test-NullReference3
} catch {
    Write-Host "Erreur: $($_.Exception.GetType().FullName)"
    Write-Host "Message: $($_.Exception.Message)"
}

# Sortie:
# Erreur: System.NullReferenceException
# Message: Object reference not set to an instance of an object.

# Exemple 4: Erreur de logique conditionnelle
function Test-NullReference4 {
    param (
        [int]$id
    )

    $user = if ($id -eq 1) {
        [PSCustomObject]@{
            Id = 1
            Name = "John Doe"
        }
    } else {
        $null  # Retourne null pour les autres IDs
    }

    # Oubli de vérifier si $user est null
    return $user.Name
}

try {
    Test-NullReference4 -Id 2  # ID qui retourne null
} catch {
    Write-Host "Erreur: $($_.Exception.GetType().FullName)"
    Write-Host "Message: $($_.Exception.Message)"
}

# Sortie:
# Erreur: System.NullReferenceException
# Message: Object reference not set to an instance of an object.
```

### Prévention des NullReferenceException

La meilleure façon de gérer les `NullReferenceException` est de les prévenir. Voici plusieurs techniques pour éviter ces exceptions :

#### 1. Vérification de nullité explicite

```powershell
function Get-UserCity {
    param (
        [PSCustomObject]$User
    )

    if ($null -eq $User) {
        return $null
    }

    if ($null -eq $User.Address) {
        return $null
    }

    return $User.Address.City
}
```

#### 2. Opérateur de coalescence nulle (en C#, simulé en PowerShell)

```powershell
function Get-UserCity {
    param (
        [PSCustomObject]$User
    )

    $address = if ($null -ne $User) { $User.Address } else { $null }
    $city = if ($null -ne $address) { $address.City } else { "Inconnu" }

    return $city
}
```

#### 3. Utilisation de Try-Catch pour la gestion des erreurs

```powershell
function Get-UserCity {
    param (
        [PSCustomObject]$User
    )

    try {
        return $User.Address.City
    } catch [System.NullReferenceException] {
        return "Inconnu"
    }
}
```

#### 4. Initialisation par défaut

```powershell
function Initialize-User {
    param (
        [string]$Name
    )

    return [PSCustomObject]@{
        Name = $Name
        Address = [PSCustomObject]@{
            Street = ""
            City = ""
            ZipCode = ""
        }
    }
}

$user = Initialize-User -Name "John Doe"
# Maintenant $user.Address ne sera jamais null
```

#### 5. Utilisation de l'opérateur d'accès sécurisé (en PowerShell 7+)

```powershell
function Get-UserCity {
    param (
        [PSCustomObject]$User
    )

    # L'opérateur ?. retourne null si l'objet est null au lieu de générer une exception
    return $User?.Address?.City
}
```

### Débogage des NullReferenceException

Lorsque vous rencontrez une `NullReferenceException`, voici quelques étapes pour la déboguer efficacement :

1. **Examiner la stack trace** : La stack trace indique où l'exception s'est produite.

2. **Inspecter les variables** : Vérifiez l'état des variables au moment de l'exception.

3. **Ajouter des points d'arrêt** : Placez des points d'arrêt avant la ligne qui génère l'exception.

4. **Ajouter des assertions** : Ajoutez des assertions pour vérifier les hypothèses sur l'état des variables.

5. **Journalisation** : Ajoutez des instructions de journalisation pour suivre le flux d'exécution.

```powershell
function Debug-NullReference {
    param (
        [PSCustomObject]$User
    )

    Write-Host "User: $($null -eq $User ? 'null' : 'not null')"

    if ($null -ne $User) {
        Write-Host "User.Address: $($null -eq $User.Address ? 'null' : 'not null')"
    }

    try {
        $city = $User.Address.City
        Write-Host "City: $city"
        return $city
    } catch {
        Write-Host "Exception: $($_.Exception.GetType().FullName)"
        Write-Host "Message: $($_.Exception.Message)"
        Write-Host "Stack Trace: $($_.Exception.StackTrace)"
        throw
    }
}
```

### Différence entre NullReferenceException et ArgumentNullException

Il est important de comprendre la différence entre `NullReferenceException` et `ArgumentNullException` :

- **NullReferenceException** : Levée par le runtime lorsqu'une référence nulle est déréférencée. Indique généralement un bug dans le code.

- **ArgumentNullException** : Levée explicitement par le code lorsqu'un argument null est passé à une méthode qui ne l'accepte pas. Fait partie de la validation des entrées.

```powershell
function Compare-NullExceptions {
    # Ceci génère une ArgumentNullException (validation explicite)
    function Process-Data {
        param (
            [object]$Data
        )

        if ($null -eq $Data) {
            throw [System.ArgumentNullException]::new("Data")
        }

        return $Data.ToString()
    }

    # Ceci génère une NullReferenceException (erreur de runtime)
    function Process-DataUnsafe {
        param (
            [object]$Data
        )

        # Pas de vérification de nullité
        return $Data.ToString()
    }

    try {
        Process-Data -Data $null
    } catch {
        Write-Host "Exception 1: $($_.Exception.GetType().FullName)"
        Write-Host "Message 1: $($_.Exception.Message)"
    }

    try {
        Process-DataUnsafe -Data $null
    } catch {
        Write-Host "Exception 2: $($_.Exception.GetType().FullName)"
        Write-Host "Message 2: $($_.Exception.Message)"
    }
}

Compare-NullExceptions

# Sortie:
# Exception 1: System.ArgumentNullException
# Message 1: Value cannot be null. Parameter name: Data
# Exception 2: System.NullReferenceException
# Message 2: Object reference not set to an instance of an object.
```

### Bonnes pratiques pour éviter les NullReferenceException

1. **Validation des entrées** : Validez toujours les paramètres d'entrée au début des méthodes.

2. **Initialisation par défaut** : Initialisez les objets avec des valeurs par défaut plutôt que null.

3. **Conception défensive** : Concevez vos APIs pour minimiser les possibilités de références nulles.

4. **Documentation** : Documentez clairement quelles méthodes peuvent retourner null et dans quelles conditions.

5. **Tests unitaires** : Écrivez des tests qui vérifient le comportement avec des entrées nulles.

6. **Analyse statique** : Utilisez des outils d'analyse statique pour détecter les déréférencements potentiels de null.

7. **Utilisation de types non nullables** : En C#, utilisez les types de référence non nullables (C# 8.0+).

### Résumé

`NullReferenceException` est l'une des exceptions les plus courantes et les plus frustrantes dans le développement .NET. Elle indique généralement un bug dans le code plutôt qu'une condition d'erreur attendue. La meilleure approche est de prévenir ces exceptions par une validation appropriée des entrées, une initialisation par défaut et une conception défensive.

En comprenant les causes courantes de `NullReferenceException` et en appliquant les bonnes pratiques pour les éviter, vous pouvez écrire un code plus robuste et plus fiable.

## FormatException et ses scénarios

### Vue d'ensemble

`FormatException` est une exception qui est levée lorsqu'une opération de formatage ou de conversion échoue en raison d'un format incorrect dans les données d'entrée. Cette exception est couramment rencontrée lors de la conversion de chaînes de caractères en types numériques, dates, ou autres types structurés.

### Hiérarchie

```
System.Exception
└── System.SystemException
    └── System.FormatException
```

### Description

`FormatException` est levée lorsqu'une méthode de conversion ou de formatage ne peut pas interpréter correctement les données d'entrée selon le format attendu. Elle est souvent générée par les méthodes de conversion comme `Int32.Parse()`, `DateTime.Parse()`, ou les méthodes `Convert.To*()`.

### Propriétés spécifiques

`FormatException` n'ajoute pas de propriétés spécifiques à celles héritées de `System.Exception`.

### Constructeurs principaux

```csharp
FormatException()
FormatException(string message)
FormatException(string message, Exception innerException)
```

### Scénarios courants

1. **Conversion de chaîne en nombre** : Tentative de convertir une chaîne qui ne représente pas un nombre valide en type numérique.

2. **Conversion de chaîne en date** : Tentative de convertir une chaîne qui ne représente pas une date valide en type DateTime.

3. **Conversion de chaîne en GUID** : Tentative de convertir une chaîne qui ne respecte pas le format GUID.

4. **Formatage de chaîne avec placeholders** : Utilisation incorrecte des placeholders dans une opération de formatage de chaîne.

5. **Conversion de base64** : Tentative de décoder une chaîne base64 mal formée.

### Exemples en PowerShell

```powershell
# Exemple 1: Conversion de chaîne en nombre
function Convert-ToNumber {
    param (
        [string]$InputString
    )

    try {
        return [int]::Parse($InputString)
    } catch [System.FormatException] {
        Write-Host "Erreur de format: '$InputString' n'est pas un nombre valide"
        return $null
    }
}

Convert-ToNumber -InputString "123"    # Fonctionne
Convert-ToNumber -InputString "abc"    # Génère FormatException
Convert-ToNumber -InputString "123.45" # Génère FormatException (pour Int32)

# Sortie:
# 123
# Erreur de format: 'abc' n'est pas un nombre valide
# Erreur de format: '123.45' n'est pas un nombre valide

# Exemple 2: Conversion de chaîne en date
function Convert-ToDate {
    param (
        [string]$DateString
    )

    try {
        return [DateTime]::Parse($DateString)
    } catch [System.FormatException] {
        Write-Host "Erreur de format: '$DateString' n'est pas une date valide"
        return $null
    }
}

Convert-ToDate -DateString "2023-06-17"          # Fonctionne
Convert-ToDate -DateString "17/06/2023"          # Fonctionne (selon la culture)
Convert-ToDate -DateString "Pas une date"        # Génère FormatException
Convert-ToDate -DateString "2023-13-45"          # Génère FormatException (mois 13 invalide)

# Sortie:
# 17/06/2023 00:00:00
# 17/06/2023 00:00:00
# Erreur de format: 'Pas une date' n'est pas une date valide
# Erreur de format: '2023-13-45' n'est pas une date valide

# Exemple 3: Conversion de chaîne en GUID
function Convert-ToGuid {
    param (
        [string]$GuidString
    )

    try {
        return [Guid]::Parse($GuidString)
    } catch [System.FormatException] {
        Write-Host "Erreur de format: '$GuidString' n'est pas un GUID valide"
        return $null
    }
}

Convert-ToGuid -GuidString "12345678-1234-1234-1234-123456789012" # Fonctionne
Convert-ToGuid -GuidString "Pas un GUID"                          # Génère FormatException
Convert-ToGuid -GuidString "12345678-1234-1234-1234-12345678901"  # Génère FormatException (trop court)

# Sortie:
# 12345678-1234-1234-1234-123456789012
# Erreur de format: 'Pas un GUID' n'est pas un GUID valide
# Erreur de format: '12345678-1234-1234-1234-12345678901' n'est pas un GUID valide

# Exemple 4: Formatage de chaîne avec placeholders
function Format-Message {
    param (
        [string]$Template,
        [object[]]$Args
    )

    try {
        return [string]::Format($Template, $Args)
    } catch [System.FormatException] {
        Write-Host "Erreur de format: Le template '$Template' est invalide avec les arguments fournis"
        return $null
    }
}

Format-Message -Template "Bonjour {0}, vous avez {1} messages" -Args @("John", 5)  # Fonctionne
Format-Message -Template "Bonjour {0}, vous avez {1} messages" -Args @("John")     # Génère FormatException (argument manquant)
Format-Message -Template "Bonjour {0}, vous avez {2} messages" -Args @("John", 5)  # Génère FormatException (index hors limites)

# Sortie:
# Bonjour John, vous avez 5 messages
# Erreur de format: Le template 'Bonjour {0}, vous avez {1} messages' est invalide avec les arguments fournis
# Erreur de format: Le template 'Bonjour {0}, vous avez {2} messages' est invalide avec les arguments fournis

# Exemple 5: Conversion de base64
function Convert-FromBase64 {
    param (
        [string]$Base64String
    )

    try {
        $bytes = [Convert]::FromBase64String($Base64String)
        return [System.Text.Encoding]::UTF8.GetString($bytes)
    } catch [System.FormatException] {
        Write-Host "Erreur de format: '$Base64String' n'est pas une chaîne base64 valide"
        return $null
    }
}

$validBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("Hello World"))
Convert-FromBase64 -Base64String $validBase64        # Fonctionne
Convert-FromBase64 -Base64String "Pas du base64"     # Génère FormatException
Convert-FromBase64 -Base64String "SGVsbG8gV29ybGQ="  # Fonctionne (équivalent à "Hello World")
Convert-FromBase64 -Base64String "SGVsbG8gV29ybGQ"   # Peut générer FormatException (longueur incorrecte)

# Sortie:
# Hello World
# Erreur de format: 'Pas du base64' n'est pas une chaîne base64 valide
# Hello World
# Erreur de format: 'SGVsbG8gV29ybGQ' n'est pas une chaîne base64 valide
```

### Prévention des FormatException

Voici plusieurs techniques pour éviter les `FormatException` :

#### 1. Utilisation de méthodes TryParse

Les méthodes `TryParse` sont disponibles pour la plupart des types qui supportent la conversion depuis une chaîne. Elles retournent un booléen indiquant si la conversion a réussi, plutôt que de lever une exception.

```powershell
function Convert-ToNumberSafely {
    param (
        [string]$InputString
    )

    $number = 0
    $success = [int]::TryParse($InputString, [ref]$number)

    if ($success) {
        return $number
    } else {
        Write-Host "La conversion a échoué: '$InputString' n'est pas un nombre valide"
        return $null
    }
}

Convert-ToNumberSafely -InputString "123"    # Retourne 123
Convert-ToNumberSafely -InputString "abc"    # Retourne null sans exception
```

#### 2. Validation préalable avec des expressions régulières

Vous pouvez utiliser des expressions régulières pour valider le format avant de tenter la conversion.

```powershell
function Convert-ToDateSafely {
    param (
        [string]$DateString
    )

    # Expression régulière simple pour une date au format YYYY-MM-DD
    if ($DateString -match '^\d{4}-\d{2}-\d{2}$') {
        try {
            return [DateTime]::Parse($DateString)
        } catch {
            Write-Host "La date est au bon format mais invalide: $DateString"
            return $null
        }
    } else {
        Write-Host "Format de date incorrect: $DateString"
        return $null
    }
}

Convert-ToDateSafely -DateString "2023-06-17"  # Fonctionne
Convert-ToDateSafely -DateString "06-17-2023"  # Format incorrect
Convert-ToDateSafely -DateString "2023-13-45"  # Format correct mais date invalide
```

#### 3. Utilisation de valeurs par défaut

Fournir une valeur par défaut en cas d'échec de conversion.

```powershell
function Get-NumberWithDefault {
    param (
        [string]$InputString,
        [int]$DefaultValue = 0
    )

    $number = 0
    if ([int]::TryParse($InputString, [ref]$number)) {
        return $number
    } else {
        return $DefaultValue
    }
}

Get-NumberWithDefault -InputString "123"     # Retourne 123
Get-NumberWithDefault -InputString "abc"     # Retourne 0 (défaut)
Get-NumberWithDefault -InputString "xyz" -DefaultValue 42  # Retourne 42
```

#### 4. Utilisation de cultures spécifiques

Pour les conversions sensibles à la culture (comme les dates et les nombres), spécifier explicitement la culture à utiliser.

```powershell
function Convert-ToDateWithCulture {
    param (
        [string]$DateString,
        [string]$CultureName = "fr-FR"
    )

    try {
        $culture = [System.Globalization.CultureInfo]::GetCultureInfo($CultureName)
        return [DateTime]::Parse($DateString, $culture)
    } catch [System.FormatException] {
        Write-Host "Erreur de format: '$DateString' n'est pas une date valide dans la culture $CultureName"
        return $null
    }
}

Convert-ToDateWithCulture -DateString "17/06/2023" -CultureName "fr-FR"  # Fonctionne
Convert-ToDateWithCulture -DateString "06/17/2023" -CultureName "en-US"  # Fonctionne
Convert-ToDateWithCulture -DateString "17/06/2023" -CultureName "en-US"  # Peut échouer (selon la culture)
```

### Débogage des FormatException

Lorsque vous rencontrez une `FormatException`, voici quelques étapes pour la déboguer efficacement :

1. **Examiner la valeur d'entrée** : Vérifiez que la valeur d'entrée est celle que vous attendez.

2. **Vérifier le format attendu** : Assurez-vous de comprendre le format exact attendu par la méthode de conversion.

3. **Considérer les problèmes de culture** : Les formats de date et de nombre peuvent varier selon la culture.

4. **Utiliser des méthodes de débogage** : Affichez la valeur d'entrée et le format attendu.

```powershell
function Debug-FormatException {
    param (
        [string]$InputValue,
        [string]$TargetType
    )

    Write-Host "Tentative de conversion de: '$InputValue' en $TargetType"
    Write-Host "Type actuel: $($InputValue.GetType().FullName)"
    Write-Host "Longueur: $($InputValue.Length)"

    # Afficher les caractères individuels (utile pour détecter les caractères invisibles)
    Write-Host "Caractères individuels:"
    for ($i = 0; $i -lt $InputValue.Length; $i++) {
        $char = $InputValue[$i]
        $code = [int][char]$char
        Write-Host "  Position $i : '$char' (code: $code)"
    }

    # Tentative de conversion avec gestion d'erreur
    try {
        $result = switch ($TargetType) {
            "Int32" { [int]::Parse($InputValue) }
            "Double" { [double]::Parse($InputValue) }
            "DateTime" { [DateTime]::Parse($InputValue) }
            "Guid" { [Guid]::Parse($InputValue) }
            default { throw "Type cible non supporté: $TargetType" }
        }

        Write-Host "Conversion réussie: $result"
        return $result
    } catch {
        Write-Host "Erreur: $($_.Exception.GetType().FullName)"
        Write-Host "Message: $($_.Exception.Message)"
        return $null
    }
}

Debug-FormatException -InputValue "123" -TargetType "Int32"
Debug-FormatException -InputValue "123.45" -TargetType "Int32"
Debug-FormatException -InputValue "123,45" -TargetType "Double"  # Peut échouer selon la culture
```

### Différence entre FormatException et autres exceptions de conversion

Il est important de comprendre la différence entre `FormatException` et d'autres exceptions qui peuvent survenir lors de conversions :

- **FormatException** : Le format de l'entrée est incorrect (par exemple, des lettres dans une chaîne numérique).

- **OverflowException** : Le format est correct, mais la valeur est trop grande ou trop petite pour le type cible.

- **ArgumentNullException** : L'entrée est null alors qu'une valeur non nulle est attendue.

- **ArgumentException** : L'argument est invalide pour une raison autre que le format.

```powershell
function Compare-ConversionExceptions {
    param (
        [string]$TestCase
    )

    try {
        switch ($TestCase) {
            "Format" {
                # Génère FormatException
                return [int]::Parse("abc")
            }
            "Overflow" {
                # Génère OverflowException
                return [byte]::Parse("1000")
            }
            "ArgumentNull" {
                # Génère ArgumentNullException
                return [int]::Parse($null)
            }
            default {
                throw "Cas de test inconnu: $TestCase"
            }
        }
    } catch {
        return @{
            ExceptionType = $_.Exception.GetType().FullName
            Message = $_.Exception.Message
        }
    }
}

Compare-ConversionExceptions -TestCase "Format"
Compare-ConversionExceptions -TestCase "Overflow"
Compare-ConversionExceptions -TestCase "ArgumentNull"

# Sortie:
# ExceptionType : System.FormatException
# Message      : Input string was not in a correct format.
#
# ExceptionType : System.OverflowException
# Message      : Value was either too large or too small for a Byte.
#
# ExceptionType : System.ArgumentNullException
# Message      : Value cannot be null. Parameter name: String
```

### Bonnes pratiques pour éviter les FormatException

1. **Utiliser TryParse** : Préférez les méthodes `TryParse` aux méthodes `Parse` pour éviter les exceptions.

2. **Valider les entrées** : Validez le format des entrées avant de tenter la conversion.

3. **Spécifier la culture** : Pour les conversions sensibles à la culture, spécifiez explicitement la culture à utiliser.

4. **Fournir des exemples** : Dans les messages d'erreur, fournissez des exemples de formats valides.

5. **Documenter les formats attendus** : Documentez clairement les formats attendus pour les entrées.

6. **Gérer les cas limites** : Prévoyez des cas pour les entrées vides, null, ou contenant des caractères spéciaux.

7. **Utiliser des types appropriés** : Utilisez le type le plus approprié pour la conversion (par exemple, `decimal` pour les valeurs monétaires).

### Résumé

`FormatException` est une exception courante qui survient lors de la conversion de données d'un format à un autre, particulièrement lors de la conversion de chaînes de caractères en types numériques, dates, ou autres types structurés. Elle indique que le format de l'entrée ne correspond pas au format attendu par la méthode de conversion.

En comprenant les scénarios courants qui génèrent des `FormatException` et en appliquant les techniques de prévention appropriées, vous pouvez créer des applications plus robustes qui gèrent élégamment les erreurs de format et fournissent des retours utiles aux utilisateurs.

## IndexOutOfRangeException et ses contextes

### Vue d'ensemble

`IndexOutOfRangeException` est une exception qui est levée lorsqu'un programme tente d'accéder à un élément d'un tableau ou d'une collection à l'aide d'un index qui est en dehors des limites valides. Cette exception est l'une des plus courantes dans le développement .NET et indique généralement une erreur de logique dans le code.

### Hiérarchie

```
System.Exception
└── System.SystemException
    └── System.IndexOutOfRangeException
```

### Description

`IndexOutOfRangeException` est levée automatiquement par le runtime .NET lorsqu'un code tente d'accéder à un élément d'un tableau ou d'une collection en utilisant un index négatif ou un index supérieur ou égal à la longueur du tableau. Comme `NullReferenceException`, elle est généralement levée par le runtime lui-même plutôt que par le code utilisateur.

### Propriétés spécifiques

`IndexOutOfRangeException` n'ajoute pas de propriétés spécifiques à celles héritées de `System.Exception`.

### Constructeurs principaux

```csharp
IndexOutOfRangeException()
IndexOutOfRangeException(string message)
IndexOutOfRangeException(string message, Exception innerException)
```

### Contextes courants

1. **Accès à un index négatif** : Tentative d'accéder à un élément d'un tableau avec un index négatif.

2. **Accès à un index trop grand** : Tentative d'accéder à un élément d'un tableau avec un index supérieur ou égal à la longueur du tableau.

3. **Erreur de calcul d'index** : Erreur dans le calcul d'un index, conduisant à une valeur en dehors des limites.

4. **Boucle mal bornée** : Boucle `for` ou `while` qui ne vérifie pas correctement les limites du tableau.

5. **Confusion entre longueur et index maximal** : Confusion entre la longueur d'un tableau (n) et l'index maximal valide (n-1).

### Exemples en PowerShell

```powershell
# Exemple 1: Accès à un index négatif
function Access-NegativeIndex {
    $array = @(1, 2, 3, 4, 5)

    try {
        # Ceci va générer une IndexOutOfRangeException
        return $array[-1]  # En PowerShell, cela fonctionne en fait (retourne le dernier élément)
                           # Mais en C#, cela générerait une IndexOutOfRangeException
    } catch {
        Write-Host "Erreur: $($_.Exception.GetType().FullName)"
        Write-Host "Message: $($_.Exception.Message)"
        return $null
    }
}

# Note: Pour simuler le comportement C# en PowerShell
function Access-NegativeIndexCSharpStyle {
    $array = [array]@(1, 2, 3, 4, 5)

    try {
        # Simuler l'accès à un index négatif comme en C#
        $index = -1
        if ($index -lt 0 -or $index -ge $array.Length) {
            throw [System.IndexOutOfRangeException]::new("Index was outside the bounds of the array.")
        }
        return $array[$index]
    } catch {
        Write-Host "Erreur: $($_.Exception.GetType().FullName)"
        Write-Host "Message: $($_.Exception.Message)"
        return $null
    }
}

Access-NegativeIndexCSharpStyle

# Sortie:
# Erreur: System.IndexOutOfRangeException
# Message: Index was outside the bounds of the array.

# Exemple 2: Accès à un index trop grand
function Access-TooLargeIndex {
    $array = @(1, 2, 3, 4, 5)

    try {
        # Ceci va générer une IndexOutOfRangeException
        return $array[10]
    } catch {
        Write-Host "Erreur: $($_.Exception.GetType().FullName)"
        Write-Host "Message: $($_.Exception.Message)"
        return $null
    }
}

Access-TooLargeIndex

# Sortie:
# Erreur: System.IndexOutOfRangeException
# Message: Index was outside the bounds of the array.

# Exemple 3: Erreur de calcul d'index
function Calculate-InvalidIndex {
    param (
        [array]$Array,
        [int]$Position
    )

    try {
        # Calcul d'index incorrect qui peut générer une IndexOutOfRangeException
        $index = $Position * 2 - $Array.Length
        return $Array[$index]
    } catch [System.IndexOutOfRangeException] {
        Write-Host "Erreur d'index: L'index calculé ($index) est en dehors des limites du tableau (0..$($Array.Length - 1))"
        return $null
    }
}

$array = @(1, 2, 3, 4, 5)
Calculate-InvalidIndex -Array $array -Position 4  # Génère un index de 3, valide
Calculate-InvalidIndex -Array $array -Position 5  # Génère un index de 5, invalide

# Sortie:
# 4
# Erreur d'index: L'index calculé (5) est en dehors des limites du tableau (0..4)

# Exemple 4: Boucle mal bornée
function Iterate-WithInvalidBounds {
    $array = @(1, 2, 3, 4, 5)

    try {
        # Boucle mal bornée qui va générer une IndexOutOfRangeException
        for ($i = 0; $i <= $array.Length; $i++) {
            Write-Host "Élément à l'index $i : $($array[$i])"
        }
    } catch {
        Write-Host "Erreur à l'itération $i : $($_.Exception.GetType().FullName)"
        Write-Host "Message: $($_.Exception.Message)"
    }
}

Iterate-WithInvalidBounds

# Sortie:
# Élément à l'index 0 : 1
# Élément à l'index 1 : 2
# Élément à l'index 2 : 3
# Élément à l'index 3 : 4
# Élément à l'index 4 : 5
# Erreur à l'itération 5 : System.IndexOutOfRangeException
# Message: Index was outside the bounds of the array.

# Exemple 5: Confusion entre longueur et index maximal
function Demonstrate-LengthVsMaxIndex {
    $array = @(1, 2, 3, 4, 5)
    $length = $array.Length
    $maxIndex = $length - 1

    Write-Host "Longueur du tableau: $length"
    Write-Host "Index maximal valide: $maxIndex"

    try {
        # Erreur courante: utiliser la longueur comme index
        Write-Host "Tentative d'accès à l'index $length..."
        $value = $array[$length]
        Write-Host "Valeur: $value"  # Cette ligne ne sera jamais exécutée
    } catch {
        Write-Host "Erreur: $($_.Exception.GetType().FullName)"
        Write-Host "Message: $($_.Exception.Message)"
    }

    # Accès correct à l'index maximal
    Write-Host "Tentative d'accès à l'index $maxIndex..."
    $value = $array[$maxIndex]
    Write-Host "Valeur: $value"
}

Demonstrate-LengthVsMaxIndex

# Sortie:
# Longueur du tableau: 5
# Index maximal valide: 4
# Tentative d'accès à l'index 5...
# Erreur: System.IndexOutOfRangeException
# Message: Index was outside the bounds of the array.
# Tentative d'accès à l'index 4...
# Valeur: 5
```

### Prévention des IndexOutOfRangeException

Voici plusieurs techniques pour éviter les `IndexOutOfRangeException` :

#### 1. Vérification des limites avant l'accès

```powershell
function Access-ArraySafely {
    param (
        [array]$Array,
        [int]$Index
    )

    if ($Index -lt 0 -or $Index -ge $Array.Length) {
        Write-Host "Index $Index hors limites (0..$($Array.Length - 1))"
        return $null
    }

    return $Array[$Index]
}

$array = @(1, 2, 3, 4, 5)
Access-ArraySafely -Array $array -Index 2   # Retourne 3
Access-ArraySafely -Array $array -Index 10  # Retourne null avec message d'erreur
```

#### 2. Utilisation de méthodes sécurisées pour les collections

```powershell
function Get-ElementSafely {
    param (
        [System.Collections.ArrayList]$List,
        [int]$Index
    )

    # ArrayList a une méthode Count au lieu de Length
    if ($Index -ge 0 -and $Index -lt $List.Count) {
        return $List[$Index]
    } else {
        Write-Host "Index $Index hors limites (0..$($List.Count - 1))"
        return $null
    }
}

$list = [System.Collections.ArrayList]::new()
$list.AddRange(@(1, 2, 3, 4, 5))

Get-ElementSafely -List $list -Index 2   # Retourne 3
Get-ElementSafely -List $list -Index 10  # Retourne null avec message d'erreur
```

#### 3. Utilisation de l'opérateur d'indexation sécurisée (en PowerShell)

```powershell
function Access-ArrayWithSafeOperator {
    param (
        [array]$Array,
        [int]$Index
    )

    # En PowerShell, si l'index est hors limites, $null est retourné au lieu de lever une exception
    $result = $Array[$Index]

    if ($null -eq $result -and ($Index -lt 0 -or $Index -ge $Array.Length)) {
        Write-Host "Index $Index hors limites (0..$($Array.Length - 1))"
    }

    return $result
}

$array = @(1, 2, 3, 4, 5)
Access-ArrayWithSafeOperator -Array $array -Index 2   # Retourne 3
Access-ArrayWithSafeOperator -Array $array -Index 10  # Retourne null avec message d'erreur
```

#### 4. Utilisation de boucles foreach au lieu de for

```powershell
function Iterate-Safely {
    param (
        [array]$Array
    )

    # Utiliser foreach au lieu de for pour éviter les problèmes d'index
    foreach ($item in $Array) {
        Write-Host "Élément: $item"
    }
}

$array = @(1, 2, 3, 4, 5)
Iterate-Safely -Array $array
```

#### 5. Utilisation de méthodes d'extension LINQ (en C#) ou équivalent en PowerShell

```powershell
function Get-ElementWithLinq {
    param (
        [array]$Array,
        [int]$Index
    )

    # Équivalent de LINQ FirstOrDefault en PowerShell
    if ($Index -ge 0 -and $Index -lt $Array.Length) {
        return $Array[$Index]
    } else {
        return $null  # Valeur par défaut
    }
}

$array = @(1, 2, 3, 4, 5)
Get-ElementWithLinq -Array $array -Index 2   # Retourne 3
Get-ElementWithLinq -Array $array -Index 10  # Retourne null sans erreur
```

### Débogage des IndexOutOfRangeException

Lorsque vous rencontrez une `IndexOutOfRangeException`, voici quelques étapes pour la déboguer efficacement :

1. **Identifier l'index problématique** : Déterminez quelle valeur d'index a causé l'exception.

2. **Vérifier les limites du tableau** : Vérifiez la longueur du tableau et les limites valides.

3. **Examiner la logique de calcul d'index** : Si l'index est calculé, vérifiez la logique de calcul.

4. **Vérifier les boucles** : Assurez-vous que les conditions de boucle sont correctes.

5. **Utiliser des points d'arrêt** : Placez des points d'arrêt avant l'accès au tableau pour inspecter les valeurs.

```powershell
function Debug-IndexOutOfRange {
    param (
        [array]$Array,
        [int]$Index
    )

    Write-Host "Débogage d'accès au tableau:"
    Write-Host "- Tableau: $Array"
    Write-Host "- Longueur du tableau: $($Array.Length)"
    Write-Host "- Index demandé: $Index"
    Write-Host "- Limites valides: 0..$($Array.Length - 1)"

    if ($Index -lt 0) {
        Write-Host "ERREUR: Index négatif"
        return $null
    }

    if ($Index -ge $Array.Length) {
        Write-Host "ERREUR: Index supérieur ou égal à la longueur du tableau"
        return $null
    }

    Write-Host "Accès valide"
    return $Array[$Index]
}

$array = @(1, 2, 3, 4, 5)
Debug-IndexOutOfRange -Array $array -Index 2
Debug-IndexOutOfRange -Array $array -Index 5
Debug-IndexOutOfRange -Array $array -Index -1
```

### Différence entre IndexOutOfRangeException et ArgumentOutOfRangeException

Il est important de comprendre la différence entre `IndexOutOfRangeException` et `ArgumentOutOfRangeException` :

- **IndexOutOfRangeException** : Levée par le runtime lorsqu'un code tente d'accéder à un élément d'un tableau avec un index en dehors des limites valides. Généralement, cette exception n'est pas levée explicitement par le code utilisateur.

- **ArgumentOutOfRangeException** : Levée explicitement par le code lorsqu'un argument est en dehors de la plage de valeurs valides pour ce paramètre. Cette exception est utilisée pour la validation des entrées.

```powershell
function Compare-OutOfRangeExceptions {
    # Ceci génère une IndexOutOfRangeException (erreur de runtime)
    function Access-ArrayUnsafely {
        param (
            [array]$Array,
            [int]$Index
        )

        # Pas de vérification des limites
        return $Array[$Index]
    }

    # Ceci génère une ArgumentOutOfRangeException (validation explicite)
    function Access-ArrayWithValidation {
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

    $array = @(1, 2, 3, 4, 5)

    try {
        Access-ArrayUnsafely -Array $array -Index 10
    } catch {
        Write-Host "Exception 1: $($_.Exception.GetType().FullName)"
        Write-Host "Message 1: $($_.Exception.Message)"
    }

    try {
        Access-ArrayWithValidation -Array $array -Index 10
    } catch {
        Write-Host "Exception 2: $($_.Exception.GetType().FullName)"
        Write-Host "Message 2: $($_.Exception.Message)"
    }
}

Compare-OutOfRangeExceptions

# Sortie:
# Exception 1: System.IndexOutOfRangeException
# Message 1: Index was outside the bounds of the array.
# Exception 2: System.ArgumentOutOfRangeException
# Message 2: L'index doit être compris entre 0 et 4
# Parameter name: Index
# Actual value was 10.
```

### Bonnes pratiques pour éviter les IndexOutOfRangeException

1. **Vérifier les limites** : Toujours vérifier que l'index est dans les limites valides avant d'accéder à un élément d'un tableau.

2. **Utiliser foreach** : Préférer les boucles `foreach` aux boucles `for` lorsque possible pour éviter les problèmes d'index.

3. **Faire attention aux boucles** : S'assurer que les conditions de boucle sont correctes, en particulier pour les boucles `for`.

4. **Utiliser des méthodes sécurisées** : Utiliser des méthodes qui gèrent automatiquement les limites, comme `ElementAtOrDefault` en LINQ (C#).

5. **Valider les entrées** : Valider les index fournis par l'utilisateur ou calculés à partir de données externes.

6. **Comprendre la différence entre longueur et index maximal** : Se rappeler que l'index maximal est toujours la longueur du tableau moins un.

7. **Utiliser des collections plus sûres** : Considérer l'utilisation de collections qui offrent des méthodes d'accès plus sûres, comme `Dictionary<TKey, TValue>` en C# ou `[hashtable]` en PowerShell.

### Résumé

`IndexOutOfRangeException` est une exception courante qui survient lorsqu'un code tente d'accéder à un élément d'un tableau ou d'une collection avec un index en dehors des limites valides. Elle indique généralement une erreur de logique dans le code, comme une boucle mal bornée ou un calcul d'index incorrect.

En comprenant les contextes courants qui génèrent des `IndexOutOfRangeException` et en appliquant les techniques de prévention appropriées, vous pouvez écrire un code plus robuste qui évite ces erreurs courantes et améliore la fiabilité de vos applications.
