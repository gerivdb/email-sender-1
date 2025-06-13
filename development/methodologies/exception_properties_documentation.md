# Documentation des propriétés communes de System.Exception

Ce document détaille les propriétés communes à toutes les exceptions dérivées de la classe `System.Exception` dans le cadre de la taxonomie des exceptions PowerShell.

## Propriété Message

### Description

La propriété `Message` est l'une des propriétés les plus importantes de la classe `System.Exception`. Elle contient une description textuelle de l'erreur qui s'est produite. Cette propriété est de type `String` et est en lecture seule.

### Caractéristiques principales

1. **Lecture seule** : La propriété `Message` est en lecture seule et ne peut être modifiée après la création de l'exception.

2. **Initialisation** : La valeur de `Message` est généralement définie lors de la création de l'exception via le constructeur.

3. **Héritage** : Lorsqu'une classe dérive de `System.Exception`, elle peut surcharger le comportement de la propriété `Message` pour fournir des informations plus spécifiques.

4. **Localisation** : Les messages d'erreur peuvent être localisés en fonction de la culture du système.

5. **Format** : Le format du message varie selon le type d'exception, mais suit généralement un modèle cohérent pour chaque type.

### Structure typique des messages

La structure du message d'erreur varie selon le type d'exception, mais suit généralement ces modèles :

| Type d'exception | Structure typique du message |
|------------------|------------------------------|
| ArgumentException | "Value of 'paramName' is invalid." ou "paramName is not valid." |
| ArgumentNullException | "Value cannot be null. Parameter name: paramName" |
| FileNotFoundException | "Could not find file 'filePath'." |
| DirectoryNotFoundException | "Could not find a part of the path 'directoryPath'." |
| InvalidOperationException | "Operation is not valid due to the current state of the object." |
| NullReferenceException | "Object reference not set to an instance of an object." |

### Exemples en PowerShell

```powershell
# Exemple 1: Accéder à la propriété Message d'une exception

try {
    $null.ToString()
} catch {
    Write-Host "Message d'erreur: $($_.Exception.Message)"
    # Affiche: "Message d'erreur: Object reference not set to an instance of an object."

}

# Exemple 2: Créer une exception personnalisée avec un message spécifique

try {
    throw [System.ArgumentException]::new("La valeur fournie n'est pas valide.", "monParametre")
} catch {
    Write-Host "Type d'exception: $($_.Exception.GetType().FullName)"
    Write-Host "Message d'erreur: $($_.Exception.Message)"
    # Affiche:

    # Type d'exception: System.ArgumentException

    # Message d'erreur: La valeur fournie n'est pas valide.

}

# Exemple 3: Accéder au message d'une exception interne

try {
    try {
        [int]::Parse("abc")
    } catch {
        throw [System.InvalidOperationException]::new("Opération échouée", $_.Exception)
    }
} catch {
    Write-Host "Message d'erreur principal: $($_.Exception.Message)"
    Write-Host "Message d'erreur interne: $($_.Exception.InnerException.Message)"
    # Affiche:

    # Message d'erreur principal: Opération échouée

    # Message d'erreur interne: Input string was not in a correct format.

}
```plaintext
### Bonnes pratiques

1. **Messages descriptifs** : Créez des messages d'erreur descriptifs qui expliquent clairement ce qui s'est passé.

2. **Inclusion d'informations contextuelles** : Incluez des informations contextuelles pertinentes (noms de paramètres, valeurs, etc.) sans exposer d'informations sensibles.

3. **Cohérence** : Maintenez une cohérence dans le format et le style des messages d'erreur.

4. **Éviter les détails techniques inutiles** : Les messages devraient être compréhensibles par les utilisateurs finaux.

5. **Localisation** : Envisagez la localisation des messages d'erreur pour les applications internationales.

### Limitations et considérations

1. **Sécurité** : Les messages d'erreur peuvent parfois révéler des informations sensibles. Soyez prudent avec les informations incluses dans les messages d'erreur exposés aux utilisateurs finaux.

2. **Longueur** : Il n'y a pas de limite stricte à la longueur d'un message d'erreur, mais les messages trop longs peuvent être difficiles à lire et à comprendre.

3. **Caractères spéciaux** : Les messages peuvent contenir des caractères spéciaux, mais certains environnements peuvent avoir des limitations d'affichage.

4. **Immuabilité** : Une fois l'exception créée, le message ne peut plus être modifié.

### Utilisation dans PowerShell

Dans PowerShell, la propriété `Message` est accessible via l'objet `ErrorRecord` dans la variable `$_` à l'intérieur d'un bloc `catch` :

```powershell
try {
    # Code qui génère une exception

} catch {
    # Accès direct au message via l'objet ErrorRecord

    $errorMessage = $_.Exception.Message

    # Ou via la propriété TargetObject si disponible

    if ($_.TargetObject -ne $null) {
        $contextInfo = $_.TargetObject.ToString()
    }

    # Utilisation du message pour la journalisation ou l'affichage

    Write-Error "Une erreur s'est produite: $errorMessage"
}
```plaintext
### Intégration avec la taxonomie des exceptions

Dans notre taxonomie des exceptions PowerShell, la propriété `Message` est utilisée pour :

1. **Identification du type d'exception** : Analyser le message pour identifier le type d'exception lorsque le type n'est pas explicitement disponible.

2. **Extraction d'informations contextuelles** : Extraire des informations contextuelles du message pour enrichir le diagnostic.

3. **Catégorisation des erreurs** : Utiliser des motifs dans les messages pour catégoriser les erreurs similaires.

4. **Génération de suggestions de résolution** : Analyser le message pour générer des suggestions de résolution adaptées.

## Propriété StackTrace

### Description

La propriété `StackTrace` est une propriété importante de la classe `System.Exception` qui fournit des informations sur la séquence d'appels qui a conduit à l'exception. Elle contient une représentation textuelle de la pile d'appels au moment où l'exception a été générée. Cette propriété est de type `String` et est en lecture seule.

### Caractéristiques principales

1. **Lecture seule** : La propriété `StackTrace` est en lecture seule et est générée automatiquement par le runtime.

2. **Initialisation différée** : La propriété `StackTrace` n'est pas initialisée tant que l'exception n'est pas levée. Si vous créez une exception sans la lever, la propriété `StackTrace` sera `null`.

3. **Format standardisé** : Le format de la pile d'appels suit un modèle standardisé qui inclut les noms de méthodes, les noms de fichiers et les numéros de ligne (si les informations de débogage sont disponibles).

4. **Sensibilité à l'optimisation** : Les informations de la pile d'appels peuvent être affectées par les optimisations du compilateur, ce qui peut rendre le débogage plus difficile dans les builds de release.

5. **Préservation** : Lorsqu'une exception est capturée et relancée, la pile d'appels d'origine est préservée si l'on utilise `throw` sans spécifier d'exception.

### Structure du StackTrace

Le format typique d'une entrée dans la pile d'appels est le suivant :

```plaintext
   à NomEspace.NomClasse.NomMéthode(Type param1, Type param2) dans C:\Chemin\Vers\Fichier.cs:ligne 123
```plaintext
Chaque ligne de la pile d'appels contient généralement :

1. **Espace de noms et classe** : Le nom complet de la classe, y compris l'espace de noms.
2. **Méthode** : Le nom de la méthode où l'appel a eu lieu.
3. **Paramètres** : Les types des paramètres de la méthode (mais pas leurs valeurs).
4. **Fichier source** : Le chemin vers le fichier source (si les informations de débogage sont disponibles).
5. **Numéro de ligne** : Le numéro de ligne dans le fichier source (si les informations de débogage sont disponibles).

### Exemples en PowerShell

```powershell
# Exemple 1: Accéder à la propriété StackTrace d'une exception

function Test-StackTrace {
    try {
        # Générer une exception

        [int]::Parse("abc")
    }
    catch {
        # Afficher la pile d'appels

        Write-Host "Pile d'appels:"
        Write-Host $_.Exception.StackTrace

        # Exemple de sortie:

        #   à System.Number.ParseInt32(String s, NumberStyles style, NumberFormatInfo info)

        #   à System.Int32.Parse(String s)

        #   à <ScriptBlock>, <Aucun fichier>: ligne 4

    }
}

Test-StackTrace

# Exemple 2: Comparer la pile d'appels avec et sans relance d'exception

function Test-NestedStackTrace {
    try {
        Test-InnerFunction
    }
    catch {
        Write-Host "Pile d'appels externe:"
        Write-Host $_.Exception.StackTrace
    }
}

function Test-InnerFunction {
    try {
        [int]::Parse("abc")
    }
    catch {
        # Cas 1: Relancer l'exception d'origine (préserve la pile d'appels d'origine)

        Write-Host "Pile d'appels interne (avant relance):"
        Write-Host $_.Exception.StackTrace
        throw

        # Cas 2: Créer et lancer une nouvelle exception (crée une nouvelle pile d'appels)

        # throw [System.InvalidOperationException]::new("Opération échouée", $_.Exception)

    }
}

Test-NestedStackTrace

# Exemple 3: Accéder à la pile d'appels complète avec Get-PSCallStack

function Test-PSCallStack {
    try {
        [int]::Parse("abc")
    }
    catch {
        Write-Host "Exception StackTrace:"
        Write-Host $_.Exception.StackTrace

        Write-Host "`nPowerShell CallStack:"
        Get-PSCallStack | Format-Table -Property Command, Location, ScriptLineNumber, ScriptName -AutoSize
    }
}

Test-PSCallStack
```plaintext
### Différences entre StackTrace et Get-PSCallStack

Dans PowerShell, il existe deux façons principales d'obtenir des informations sur la pile d'appels :

1. **Exception.StackTrace** : Fournit la pile d'appels .NET qui a conduit à l'exception. Elle inclut les appels aux méthodes .NET mais peut ne pas inclure tous les détails des appels de script PowerShell.

2. **Get-PSCallStack** : Fournit la pile d'appels PowerShell complète, y compris les appels de script, les fonctions et les cmdlets. Cette commande est plus utile pour déboguer des scripts PowerShell complexes.

| Caractéristique | Exception.StackTrace | Get-PSCallStack |
|-----------------|----------------------|-----------------|
| Origine | Runtime .NET | Moteur PowerShell |
| Disponibilité | Uniquement dans les exceptions | À tout moment |
| Contenu | Appels de méthodes .NET | Appels de script PowerShell |
| Format | Chaîne de texte | Objets PowerShell |
| Détails | Noms de méthodes, fichiers, lignes | Commandes, scripts, lignes, portées |

### Bonnes pratiques

1. **Journalisation complète** : Enregistrez la pile d'appels complète lors de la journalisation des exceptions pour faciliter le débogage.

2. **Préservation de la pile d'origine** : Utilisez `throw` sans paramètre pour préserver la pile d'appels d'origine lors de la relance d'exceptions.

3. **Combinaison avec Get-PSCallStack** : Pour un débogage complet dans PowerShell, utilisez à la fois `Exception.StackTrace` et `Get-PSCallStack`.

4. **Nettoyage pour les utilisateurs finaux** : Filtrez ou simplifiez la pile d'appels avant de l'afficher aux utilisateurs finaux, car elle peut contenir des informations techniques complexes.

5. **Analyse automatisée** : Développez des outils pour analyser automatiquement les piles d'appels et identifier les modèles d'erreurs courants.

### Limitations et considérations

1. **Informations de débogage** : Les numéros de ligne et les noms de fichiers ne sont disponibles que si les informations de débogage (PDB) sont présentes.

2. **Optimisations** : Les builds optimisés peuvent avoir des piles d'appels moins détaillées en raison de l'inlining et d'autres optimisations.

3. **Sécurité** : La pile d'appels peut révéler des informations sur la structure interne de l'application. Évitez de l'exposer directement aux utilisateurs finaux dans les environnements de production.

4. **Taille** : Les piles d'appels peuvent devenir très longues dans les applications complexes, ce qui peut rendre difficile l'identification de la cause réelle de l'exception.

5. **Internationalisation** : Les messages dans la pile d'appels peuvent être localisés, ce qui peut compliquer l'analyse automatisée.

### Utilisation dans PowerShell

Dans PowerShell, la propriété `StackTrace` est accessible via l'objet `ErrorRecord` dans la variable `$_` à l'intérieur d'un bloc `catch` :

```powershell
try {
    # Code qui génère une exception

} catch {
    # Accès à la pile d'appels via l'objet ErrorRecord

    $stackTrace = $_.Exception.StackTrace

    # Journalisation de la pile d'appels

    Write-Log -Level Error -Message "Une erreur s'est produite" -StackTrace $stackTrace

    # Obtention de la pile d'appels PowerShell complète

    $psCallStack = Get-PSCallStack | Format-Table -Property Command, Location -AutoSize | Out-String
    Write-Log -Level Error -Message "Pile d'appels PowerShell: $psCallStack"
}
```plaintext
### Intégration avec la taxonomie des exceptions

Dans notre taxonomie des exceptions PowerShell, la propriété `StackTrace` est utilisée pour :

1. **Identification du contexte d'erreur** : Analyser la pile d'appels pour comprendre le contexte dans lequel l'exception s'est produite.

2. **Regroupement des erreurs similaires** : Identifier des modèles dans les piles d'appels pour regrouper des erreurs similaires.

3. **Diagnostic avancé** : Fournir des informations détaillées pour le diagnostic des problèmes complexes.

4. **Génération de suggestions de résolution** : Utiliser le contexte de la pile d'appels pour générer des suggestions de résolution plus précises.

## Propriété InnerException

### Description

La propriété `InnerException` est une propriété fondamentale de la classe `System.Exception` qui permet de capturer et de préserver la cause originale d'une exception. Elle contient une référence à l'exception qui a déclenché l'exception actuelle, créant ainsi une hiérarchie d'exceptions. Cette propriété est de type `Exception` et est en lecture seule.

### Caractéristiques principales

1. **Lecture seule** : La propriété `InnerException` est en lecture seule et ne peut être définie qu'au moment de la création de l'exception via le constructeur.

2. **Chaînage d'exceptions** : Permet de créer une chaîne d'exceptions où chaque exception peut contenir une référence à l'exception qui l'a causée.

3. **Préservation du contexte** : Conserve le contexte complet de l'erreur originale, y compris son message, sa pile d'appels et ses propriétés spécifiques.

4. **Hiérarchie d'exceptions** : Peut former une hiérarchie profonde d'exceptions imbriquées, reflétant la séquence des erreurs qui se sont produites.

5. **Peut être null** : La propriété `InnerException` peut être `null` si l'exception n'a pas été causée par une autre exception.

### Hiérarchie des exceptions

La hiérarchie des exceptions est un concept important dans la gestion des erreurs. Elle permet de suivre la chaîne des événements qui ont conduit à une erreur. Voici comment fonctionne cette hiérarchie :

1. **Exception primaire** : L'exception la plus externe, celle qui est capturée dans le bloc `catch` final.

2. **Exception(s) interne(s)** : Une ou plusieurs exceptions qui ont été capturées et encapsulées dans d'autres exceptions.

3. **Exception racine** : L'exception la plus profonde dans la hiérarchie, qui représente la cause originale de l'erreur.

La méthode `GetBaseException()` permet d'accéder directement à l'exception racine sans avoir à parcourir manuellement toute la hiérarchie.

### Exemples en PowerShell

```powershell
# Exemple 1: Créer une exception avec une exception interne

function Test-InnerException {
    try {
        try {
            # Générer une exception

            [int]::Parse("abc")
        }
        catch {
            # Capturer l'exception et la wrapper dans une nouvelle exception

            throw [System.InvalidOperationException]::new(
                "Impossible de traiter la demande",
                $_.Exception
            )
        }
    }
    catch {
        # Accéder à l'exception interne

        $primaryException = $_.Exception
        $innerException = $_.Exception.InnerException

        Write-Host "Exception primaire: $($primaryException.GetType().FullName)"
        Write-Host "Message primaire: $($primaryException.Message)"
        Write-Host "Exception interne: $($innerException.GetType().FullName)"
        Write-Host "Message interne: $($innerException.Message)"

        # Sortie attendue:

        # Exception primaire: System.InvalidOperationException

        # Message primaire: Impossible de traiter la demande

        # Exception interne: System.FormatException

        # Message interne: Input string was not in a correct format.

    }
}

Test-InnerException

# Exemple 2: Accéder à l'exception racine dans une hiérarchie profonde

function Test-DeepExceptionHierarchy {
    try {
        try {
            try {
                try {
                    # Exception de niveau 4 (la plus profonde)

                    [int]::Parse("abc")
                }
                catch {
                    # Exception de niveau 3

                    throw [System.IO.IOException]::new(
                        "Erreur de lecture des données",
                        $_.Exception
                    )
                }
            }
            catch {
                # Exception de niveau 2

                throw [System.Security.SecurityException]::new(
                    "Accès non autorisé aux données",
                    $_.Exception
                )
            }
        }
        catch {
            # Exception de niveau 1 (la plus externe)

            throw [System.InvalidOperationException]::new(
                "Opération impossible à compléter",
                $_.Exception
            )
        }
    }
    catch {
        # Accéder à toute la hiérarchie d'exceptions

        $currentException = $_.Exception
        $level = 1

        Write-Host "Hiérarchie complète des exceptions:"

        while ($currentException -ne $null) {
            Write-Host "Niveau $level : $($currentException.GetType().FullName) - $($currentException.Message)"
            $currentException = $currentException.InnerException
            $level++
        }

        # Accéder directement à l'exception racine

        $rootException = $_.Exception.GetBaseException()
        Write-Host "`nException racine: $($rootException.GetType().FullName)"
        Write-Host "Message racine: $($rootException.Message)"

        # Sortie attendue:

        # Hiérarchie complète des exceptions:

        # Niveau 1 : System.InvalidOperationException - Opération impossible à compléter

        # Niveau 2 : System.Security.SecurityException - Accès non autorisé aux données

        # Niveau 3 : System.IO.IOException - Erreur de lecture des données

        # Niveau 4 : System.FormatException - Input string was not in a correct format.

        #

        # Exception racine: System.FormatException

        # Message racine: Input string was not in a correct format.

    }
}

Test-DeepExceptionHierarchy

# Exemple 3: Utiliser AggregateException pour regrouper plusieurs exceptions

function Test-AggregateException {
    try {
        # Créer une liste d'exceptions

        $exceptions = @(
            [System.ArgumentException]::new("Argument invalide"),
            [System.IO.FileNotFoundException]::new("Fichier introuvable"),
            [System.DivideByZeroException]::new("Division par zéro")
        )

        # Regrouper les exceptions dans une AggregateException

        throw [System.AggregateException]::new(
            "Plusieurs erreurs se sont produites",
            $exceptions
        )
    }
    catch [System.AggregateException] {
        # Accéder aux exceptions internes via la propriété InnerExceptions (pluriel)

        $aggregateException = $_.Exception

        Write-Host "Exception agrégée: $($aggregateException.GetType().FullName)"
        Write-Host "Message: $($aggregateException.Message)"
        Write-Host "Nombre d'exceptions internes: $($aggregateException.InnerExceptions.Count)"

        Write-Host "`nDétail des exceptions internes:"
        for ($i = 0; $i -lt $aggregateException.InnerExceptions.Count; $i++) {
            $innerEx = $aggregateException.InnerExceptions[$i]
            Write-Host "[$i] $($innerEx.GetType().FullName): $($innerEx.Message)"
        }

        # Sortie attendue:

        # Exception agrégée: System.AggregateException

        # Message: Plusieurs erreurs se sont produites

        # Nombre d'exceptions internes: 3

        #

        # Détail des exceptions internes:

        # [0] System.ArgumentException: Argument invalide

        # [1] System.IO.FileNotFoundException: Fichier introuvable

        # [2] System.DivideByZeroException: Division par zéro

    }
}

Test-AggregateException
```plaintext
### Différence entre InnerException et AggregateException

Il est important de comprendre la différence entre la propriété `InnerException` standard et la classe `AggregateException` :

| Caractéristique | InnerException | AggregateException |
|-----------------|----------------|-------------------|
| Type | Propriété de System.Exception | Classe dérivée de System.Exception |
| Contenu | Une seule exception | Collection d'exceptions (InnerExceptions) |
| Accès | Via la propriété InnerException | Via la propriété InnerExceptions (pluriel) |
| Utilisation | Chaînage linéaire d'exceptions | Regroupement de plusieurs exceptions parallèles |
| Cas d'usage | Opérations séquentielles | Opérations parallèles, tâches asynchrones |

### Bonnes pratiques

1. **Préservation du contexte** : Lorsque vous capturez une exception pour en lancer une nouvelle, incluez toujours l'exception d'origine comme `InnerException`.

2. **Messages complémentaires** : Le message de l'exception externe devrait compléter celui de l'exception interne, pas le répéter.

3. **Accès à l'exception racine** : Utilisez la méthode `GetBaseException()` pour accéder directement à la cause originale de l'erreur.

4. **Journalisation complète** : Enregistrez toute la hiérarchie des exceptions pour faciliter le débogage.

5. **Utilisation d'AggregateException** : Pour les opérations parallèles ou asynchrones qui peuvent générer plusieurs erreurs, utilisez `AggregateException`.

### Limitations et considérations

1. **Profondeur de la hiérarchie** : Une hiérarchie d'exceptions trop profonde peut rendre le débogage difficile. Essayez de limiter la profondeur à ce qui est nécessaire.

2. **Sérialisation** : Lors de la sérialisation d'exceptions, assurez-vous que toute la hiérarchie est correctement sérialisée.

3. **Performance** : La création de multiples niveaux d'exceptions peut avoir un impact sur les performances, surtout dans les chemins critiques.

4. **Informations sensibles** : Assurez-vous que les exceptions internes ne contiennent pas d'informations sensibles qui pourraient être exposées aux utilisateurs finaux.

5. **Compatibilité** : Certaines versions plus anciennes de .NET ou certains environnements peuvent avoir des limitations dans la gestion des hiérarchies d'exceptions complexes.

### Utilisation dans PowerShell

Dans PowerShell, la propriété `InnerException` est accessible via l'objet `ErrorRecord` dans la variable `$_` à l'intérieur d'un bloc `catch` :

```powershell
try {
    # Code qui peut générer une exception

} catch {
    # Accès à l'exception primaire

    $primaryException = $_.Exception

    # Accès à l'exception interne (si elle existe)

    if ($primaryException.InnerException -ne $null) {
        $innerException = $primaryException.InnerException
        Write-Error "Exception interne: $($innerException.GetType().FullName) - $($innerException.Message)"
    }

    # Accès direct à l'exception racine

    $rootException = $primaryException.GetBaseException()
    Write-Error "Cause racine: $($rootException.GetType().FullName) - $($rootException.Message)"

    # Parcourir toute la hiérarchie d'exceptions

    $currentException = $primaryException
    $exceptionChain = @()

    while ($currentException -ne $null) {
        $exceptionChain += "$($currentException.GetType().FullName): $($currentException.Message)"
        $currentException = $currentException.InnerException
    }

    Write-Error "Chaîne d'exceptions: $($exceptionChain -join ' -> ')"
}
```plaintext
### Intégration avec la taxonomie des exceptions

Dans notre taxonomie des exceptions PowerShell, la propriété `InnerException` est utilisée pour :

1. **Analyse de la cause racine** : Identifier la cause fondamentale d'une erreur en examinant l'exception la plus profonde dans la hiérarchie.

2. **Traçabilité des erreurs** : Suivre la propagation des erreurs à travers différentes couches de l'application.

3. **Diagnostic contextuel** : Comprendre le contexte complet dans lequel une erreur s'est produite en examinant toute la chaîne d'exceptions.

4. **Classification hiérarchique** : Organiser les exceptions en catégories et sous-catégories basées sur leurs relations d'imbrication.

5. **Génération de rapports d'erreurs** : Créer des rapports d'erreurs détaillés qui montrent la progression des erreurs à travers le système.

## Propriété Source

### Description

La propriété `Source` de la classe `System.Exception` identifie le nom de l'application ou de l'objet qui a généré l'exception. Cette propriété est de type `String` et, contrairement à la plupart des autres propriétés d'exception, elle est modifiable.

### Caractéristiques principales

1. **Modifiable** : Contrairement à la plupart des propriétés de `System.Exception`, la propriété `Source` peut être modifiée après la création de l'exception.

2. **Initialisation automatique** : Dans de nombreux cas, le runtime .NET initialise automatiquement cette propriété avec le nom de l'assembly où l'exception a été générée.

3. **Personnalisable** : Les développeurs peuvent définir manuellement cette propriété pour fournir des informations plus précises sur l'origine de l'exception.

4. **Contexte d'erreur** : Fournit un contexte supplémentaire pour aider à localiser et à diagnostiquer la source de l'erreur.

5. **Persistance** : La valeur de `Source` est préservée lors de la sérialisation/désérialisation de l'exception.

### Valeurs typiques de Source

La valeur de la propriété `Source` varie selon le contexte dans lequel l'exception est générée :

| Contexte | Valeur typique de Source |
|----------|--------------------------|
| Exception générée par le CLR | Nom de l'assembly système (ex: "mscorlib", "System.Core") |
| Exception générée par une application | Nom de l'assembly de l'application (ex: "MyApp") |
| Exception générée par une bibliothèque | Nom de la bibliothèque (ex: "Newtonsoft.Json") |
| Exception PowerShell | "Microsoft.PowerShell.Commands.WriteErrorException" ou nom du module |
| Exception personnalisée | Valeur définie manuellement par le développeur |

### Exemples en PowerShell

```powershell
# Exemple 1: Accéder à la propriété Source d'une exception

function Test-ExceptionSource {
    try {
        # Générer une exception

        [int]::Parse("abc")
    }
    catch {
        # Afficher la source de l'exception

        Write-Host "Source de l'exception: $($_.Exception.Source)"

        # Sortie typique:

        # Source de l'exception: System.Int32

    }
}

Test-ExceptionSource

# Exemple 2: Définir manuellement la propriété Source

function Test-CustomSource {
    try {
        # Créer une exception avec une source personnalisée

        $exception = [System.InvalidOperationException]::new("Opération non valide")
        $exception.Source = "MonModule.MaFonction"
        throw $exception
    }
    catch {
        Write-Host "Type d'exception: $($_.Exception.GetType().FullName)"
        Write-Host "Message: $($_.Exception.Message)"
        Write-Host "Source: $($_.Exception.Source)"

        # Sortie attendue:

        # Type d'exception: System.InvalidOperationException

        # Message: Opération non valide

        # Source: MonModule.MaFonction

    }
}

Test-CustomSource

# Exemple 3: Comparer les sources d'exceptions dans différents contextes

function Test-MultipleExceptionSources {
    try {
        # Tenter plusieurs opérations qui peuvent générer des exceptions

        try {
            # Exception du CLR

            [int]::Parse("abc")
        }
        catch {
            Write-Host "Exception CLR - Source: $($_.Exception.Source)"

            try {
                # Exception PowerShell

                Get-Item "fichier_inexistant.txt" -ErrorAction Stop
            }
            catch {
                Write-Host "Exception PowerShell - Source: $($_.Exception.Source)"

                try {
                    # Exception personnalisée

                    $customEx = [System.ArgumentException]::new("Argument invalide")
                    $customEx.Source = "Script.Personnalisé"
                    throw $customEx
                }
                catch {
                    Write-Host "Exception personnalisée - Source: $($_.Exception.Source)"
                }
            }
        }
    }
    catch {
        Write-Host "Une erreur inattendue s'est produite"
    }

    # Sortie typique:

    # Exception CLR - Source: System.Int32

    # Exception PowerShell - Source: Microsoft.PowerShell.Commands.GetItemCommand

    # Exception personnalisée - Source: Script.Personnalisé

}

Test-MultipleExceptionSources
```plaintext
### Différence entre Source et autres propriétés d'identification

Il est important de comprendre comment la propriété `Source` se distingue des autres propriétés qui peuvent sembler similaires :

| Propriété | Description | Différence avec Source |
|-----------|-------------|------------------------|
| Source | Nom de l'application ou de l'objet qui a généré l'exception | Identifie l'origine logique de l'exception |
| StackTrace | Séquence d'appels qui a conduit à l'exception | Fournit le chemin d'exécution complet, pas seulement l'origine |
| TargetSite | Méthode qui a généré l'exception | Plus spécifique que Source, identifie la méthode exacte |
| HResult | Code d'erreur numérique | Identifie le type d'erreur, pas son origine |
| Data | Collection de paires clé/valeur | Stocke des informations supplémentaires, pas spécifiquement l'origine |

### Bonnes pratiques

1. **Nommage significatif** : Utilisez des noms significatifs pour la propriété `Source`, idéalement sous la forme "Namespace.Classe.Méthode" ou "Module.Fonction".

2. **Cohérence** : Maintenez une convention de nommage cohérente pour toutes les exceptions générées par votre application.

3. **Informations utiles** : Incluez des informations qui aideront à localiser rapidement l'origine de l'erreur, mais évitez les détails trop techniques pour les utilisateurs finaux.

4. **Éviter les valeurs dynamiques** : Évitez d'inclure des valeurs dynamiques (comme des identifiants de session) dans la propriété `Source` pour faciliter le regroupement des erreurs similaires.

5. **Préservation** : Lors de la capture et de la relance d'exceptions, préservez ou enrichissez la propriété `Source` pour maintenir la traçabilité.

### Limitations et considérations

1. **Initialisation automatique limitée** : Dans certains contextes, comme les scripts PowerShell, la propriété `Source` peut ne pas être initialisée automatiquement de manière utile.

2. **Sécurité** : La propriété `Source` peut révéler des informations sur la structure interne de l'application. Soyez prudent lors de l'exposition de ces informations aux utilisateurs finaux.

3. **Longueur** : Il n'y a pas de limite stricte à la longueur de la propriété `Source`, mais les valeurs trop longues peuvent être difficiles à lire et à traiter.

4. **Localisation** : La propriété `Source` n'est généralement pas localisée, contrairement aux messages d'erreur.

5. **Compatibilité** : Les conventions de nommage pour la propriété `Source` peuvent varier entre les différentes versions de .NET et les différentes bibliothèques.

### Utilisation dans PowerShell

Dans PowerShell, la propriété `Source` est accessible via l'objet `ErrorRecord` dans la variable `$_` à l'intérieur d'un bloc `catch` :

```powershell
try {
    # Code qui peut générer une exception

} catch {
    # Accès à la source de l'exception

    $source = $_.Exception.Source

    # Journalisation avec la source

    Write-Log -Level Error -Message "Une erreur s'est produite" -Source $source

    # Définition d'une source personnalisée pour une nouvelle exception

    $newException = [System.Exception]::new("Erreur propagée", $_.Exception)
    $newException.Source = "MonScript.GestionErreurs"
    throw $newException
}
```plaintext
PowerShell fournit également des informations supplémentaires sur la source de l'erreur via d'autres propriétés de l'objet `ErrorRecord` :

```powershell
try {
    # Code qui peut générer une exception

} catch {
    # Source de l'exception

    Write-Host "Exception.Source: $($_.Exception.Source)"

    # Informations supplémentaires spécifiques à PowerShell

    Write-Host "ErrorRecord.CategoryInfo.Category: $($_.CategoryInfo.Category)"
    Write-Host "ErrorRecord.InvocationInfo.MyCommand: $($_.InvocationInfo.MyCommand)"
    Write-Host "ErrorRecord.FullyQualifiedErrorId: $($_.FullyQualifiedErrorId)"
}
```plaintext
### Intégration avec la taxonomie des exceptions

Dans notre taxonomie des exceptions PowerShell, la propriété `Source` est utilisée pour :

1. **Identification de l'origine** : Déterminer quelle partie du système a généré l'exception.

2. **Catégorisation des erreurs** : Regrouper les exceptions par leur origine pour identifier les composants problématiques.

3. **Diagnostic ciblé** : Diriger les efforts de débogage vers les composants spécifiques identifiés comme sources d'erreurs.

4. **Filtrage des exceptions** : Permettre aux gestionnaires d'exceptions de traiter différemment les exceptions selon leur origine.

5. **Enrichissement des rapports d'erreurs** : Inclure des informations sur l'origine des exceptions dans les rapports d'erreurs pour faciliter l'analyse.

## Propriété HResult

### Description

La propriété `HResult` de la classe `System.Exception` est un code d'erreur numérique qui identifie le type d'erreur qui s'est produite. Cette propriété est de type `int` (32 bits) et, comme la propriété `Source`, elle est modifiable. Les valeurs HResult sont des codes d'erreur standardisés utilisés principalement pour l'interopérabilité avec le code natif et les technologies COM (Component Object Model).

### Caractéristiques principales

1. **Modifiable** : La propriété `HResult` peut être modifiée après la création de l'exception.

2. **Initialisation automatique** : Le runtime .NET initialise automatiquement cette propriété avec une valeur spécifique au type d'exception.

3. **Format standardisé** : Les valeurs HResult suivent un format standardisé où différentes parties du code représentent différentes informations.

4. **Interopérabilité** : Principalement utilisée pour l'interopérabilité avec le code natif et les technologies COM.

5. **Diagnostic** : Peut être utilisée pour un diagnostic précis des erreurs, en particulier dans les environnements mixtes .NET/natif.

### Structure d'un code HResult

Un code HResult est une valeur 32 bits structurée comme suit :

| Bits    | Description                                                |
|---------|------------------------------------------------------------|
| 31      | Sévérité (0 = Succès, 1 = Échec)                           |
| 30      | Réservé (0)                                                |
| 29      | Type de code (0 = Microsoft, 1 = Client)                   |
| 28-16   | Facilité (composant qui a généré l'erreur)                 |
| 15-0    | Code d'erreur spécifique                                   |

En hexadécimal, un HResult typique ressemble à `0x8XXXXXXX` pour une erreur (bit de sévérité à 1) ou `0x0XXXXXXX` pour un succès (bit de sévérité à 0).

### Valeurs HResult communes

Voici quelques valeurs HResult communes pour les exceptions .NET :

| HResult (Hex) | HResult (Dec) | Exception                      | Description                                      |
|---------------|---------------|--------------------------------|--------------------------------------------------|
| 0x80004005    | -2147467259   | Exception générique            | Erreur non spécifiée (E_FAIL)                    |
| 0x80070002    | -2147024894   | FileNotFoundException          | Fichier non trouvé (ERROR_FILE_NOT_FOUND)        |
| 0x80070005    | -2147024891   | UnauthorizedAccessException    | Accès refusé (ERROR_ACCESS_DENIED)               |
| 0x8007000E    | -2147024882   | OutOfMemoryException          | Mémoire insuffisante (ERROR_OUTOFMEMORY)         |
| 0x80070057    | -2147024809   | ArgumentException             | Paramètre incorrect (ERROR_INVALID_PARAMETER)    |
| 0x80131501    | -2146233087   | ArgumentNullException         | Argument null                                    |
| 0x80131502    | -2146233086   | ArgumentOutOfRangeException   | Argument hors limites                            |
| 0x80131509    | -2146233079   | InvalidOperationException     | Opération invalide                               |
| 0x80131577    | -2146232969   | NotSupportedException         | Opération non supportée                          |
| 0x80131620    | -2146232800   | FormatException              | Format invalide                                  |

### Exemples en PowerShell

```powershell
# Exemple 1: Accéder à la propriété HResult d'une exception

function Test-ExceptionHResult {
    try {
        # Générer une exception

        [int]::Parse("abc")
    }
    catch {
        # Afficher le HResult en décimal et hexadécimal

        $hresult = $_.Exception.HResult
        Write-Host "HResult (décimal): $hresult"
        Write-Host "HResult (hexadécimal): 0x$($hresult.ToString('X8'))"

        # Sortie typique:

        # HResult (décimal): -2146233033

        # HResult (hexadécimal): 0x80131537

    }
}

Test-ExceptionHResult

# Exemple 2: Définir manuellement la propriété HResult

function Test-CustomHResult {
    try {
        # Créer une exception avec un HResult personnalisé

        $exception = [System.InvalidOperationException]::new("Opération non valide")
        $exception.HResult = 0x80004005  # E_FAIL (erreur non spécifiée)

        throw $exception
    }
    catch {
        Write-Host "Type d'exception: $($_.Exception.GetType().FullName)"
        Write-Host "Message: $($_.Exception.Message)"
        Write-Host "HResult (décimal): $($_.Exception.HResult)"
        Write-Host "HResult (hexadécimal): 0x$($_.Exception.HResult.ToString('X8'))"

        # Sortie attendue:

        # Type d'exception: System.InvalidOperationException

        # Message: Opération non valide

        # HResult (décimal): -2147467259

        # HResult (hexadécimal): 0x80004005

    }
}

Test-CustomHResult

# Exemple 3: Identifier le type d'exception à partir du HResult

function Get-ExceptionTypeFromHResult {
    param (
        [int]$HResult
    )

    $hresultMap = @{
        -2147024894 = "System.IO.FileNotFoundException"
        -2147024891 = "System.UnauthorizedAccessException"
        -2147024882 = "System.OutOfMemoryException"
        -2147024809 = "System.ArgumentException"
        -2146233087 = "System.ArgumentNullException"
        -2146233086 = "System.ArgumentOutOfRangeException"
        -2146233079 = "System.InvalidOperationException"
        -2146232969 = "System.NotSupportedException"
        -2146232800 = "System.FormatException"
    }

    if ($hresultMap.ContainsKey($HResult)) {
        return $hresultMap[$HResult]
    } else {
        return "Unknown exception type for HResult: $HResult (0x$($HResult.ToString('X8')))"
    }
}

# Tester la fonction avec différents HResult

Write-Host "HResult -2147024894 correspond à: $(Get-ExceptionTypeFromHResult -HResult -2147024894)"
Write-Host "HResult -2146233087 correspond à: $(Get-ExceptionTypeFromHResult -HResult -2146233087)"
Write-Host "HResult -2146232800 correspond à: $(Get-ExceptionTypeFromHResult -HResult -2146232800)"

# Sortie attendue:

# HResult -2147024894 correspond à: System.IO.FileNotFoundException

# HResult -2146233087 correspond à: System.ArgumentNullException

# HResult -2146232800 correspond à: System.FormatException

```plaintext
### Décomposition d'un HResult

Pour mieux comprendre un code HResult, on peut le décomposer en ses composantes :

```powershell
function Get-HResultComponents {
    param (
        [int]$HResult
    )

    # Convertir en entier non signé pour faciliter les opérations bit à bit

    $uHResult = [uint32]$HResult

    # Extraire les composantes

    $severity = ($uHResult -shr 31) -band 1
    $reserved = ($uHResult -shr 30) -band 1
    $customerCode = ($uHResult -shr 29) -band 1
    $facility = ($uHResult -shr 16) -band 0x7FF
    $errorCode = $uHResult -band 0xFFFF

    # Interpréter la sévérité

    $severityText = if ($severity -eq 1) { "Échec" } else { "Succès" }

    # Interpréter le type de code

    $codeTypeText = if ($customerCode -eq 1) { "Client" } else { "Microsoft" }

    # Interpréter la facilité (composant)

    $facilityText = switch ($facility) {
        0 { "FACILITY_NULL" }
        1 { "FACILITY_RPC" }
        2 { "FACILITY_DISPATCH" }
        3 { "FACILITY_STORAGE" }
        4 { "FACILITY_ITF" }
        7 { "FACILITY_WIN32" }
        8 { "FACILITY_WINDOWS" }
        9 { "FACILITY_SECURITY" }
        10 { "FACILITY_CONTROL" }
        11 { "FACILITY_CERT" }
        12 { "FACILITY_INTERNET" }
        13 { "FACILITY_MEDIASERVER" }
        14 { "FACILITY_MSMQ" }
        15 { "FACILITY_SETUPAPI" }
        16 { "FACILITY_SCARD" }
        17 { "FACILITY_COMPLUS" }
        18 { "FACILITY_AAF" }
        19 { "FACILITY_URT" }
        20 { "FACILITY_ACS" }
        21 { "FACILITY_DPLAY" }
        22 { "FACILITY_UMI" }
        23 { "FACILITY_SXS" }
        24 { "FACILITY_WINDOWS_CE" }
        25 { "FACILITY_HTTP" }
        26 { "FACILITY_USERMODE_COMMONLOG" }
        27 { "FACILITY_USERMODE_FILTER_MANAGER" }
        31 { "FACILITY_BACKGROUNDCOPY" }
        32 { "FACILITY_CONFIGURATION" }
        33 { "FACILITY_STATE_MANAGEMENT" }
        34 { "FACILITY_METADIRECTORY" }
        35 { "FACILITY_WINDOWSUPDATE" }
        36 { "FACILITY_DIRECTORYSERVICE" }
        37 { "FACILITY_GRAPHICS" }
        38 { "FACILITY_SHELL" }
        39 { "FACILITY_TPM_SERVICES" }
        40 { "FACILITY_TPM_SOFTWARE" }
        48 { "FACILITY_PLA" }
        49 { "FACILITY_FVE" }
        50 { "FACILITY_FWP" }
        51 { "FACILITY_WINRM" }
        52 { "FACILITY_NDIS" }
        53 { "FACILITY_USERMODE_HYPERVISOR" }
        54 { "FACILITY_CMI" }
        55 { "FACILITY_USERMODE_VIRTUALIZATION" }
        56 { "FACILITY_USERMODE_VOLMGR" }
        57 { "FACILITY_BCD" }
        58 { "FACILITY_USERMODE_VHD" }
        59 { "FACILITY_USERMODE_HNS" }
        60 { "FACILITY_SDIAG" }
        61 { "FACILITY_WEBSERVICES" }
        80 { "FACILITY_WINDOWS_DEFENDER" }
        81 { "FACILITY_OPC" }
        0x7FF { "FACILITY_CLR" }  # Spécifique à .NET

        default { "FACILITY_UNKNOWN ($facility)" }
    }

    # Créer et retourner un objet avec les composantes

    return [PSCustomObject]@{
        HResult = $HResult
        HResultHex = "0x$($HResult.ToString('X8'))"
        Severity = $severityText
        Reserved = $reserved
        CodeType = $codeTypeText
        Facility = $facilityText
        FacilityCode = $facility
        ErrorCode = $errorCode
        ErrorCodeHex = "0x$($errorCode.ToString('X4'))"
    }
}

# Tester la fonction avec différents HResult

$hresult1 = -2147024894  # 0x80070002 - FileNotFoundException

$hresult2 = -2146233087  # 0x80131501 - ArgumentNullException

Write-Host "Décomposition de HResult $hresult1 (0x$($hresult1.ToString('X8'))):"
Get-HResultComponents -HResult $hresult1 | Format-List

Write-Host "`nDécomposition de HResult $hresult2 (0x$($hresult2.ToString('X8'))):"
Get-HResultComponents -HResult $hresult2 | Format-List

# Sortie attendue pour $hresult1:

# Décomposition de HResult -2147024894 (0x80070002):

# HResult     : -2147024894

# HResultHex  : 0x80070002

# Severity    : Échec

# Reserved    : 0

# CodeType    : Microsoft

# Facility    : FACILITY_WIN32

# FacilityCode: 7

# ErrorCode   : 2

# ErrorCodeHex: 0x0002

#

# Sortie attendue pour $hresult2:

# Décomposition de HResult -2146233087 (0x80131501):

# HResult     : -2146233087

# HResultHex  : 0x80131501

# Severity    : Échec

# Reserved    : 0

# CodeType    : Microsoft

# Facility    : FACILITY_CLR

# FacilityCode: 2047

# ErrorCode   : 5377

# ErrorCodeHex: 0x1501

```plaintext
### Bonnes pratiques

1. **Préservation des valeurs standard** : Utilisez les valeurs HResult standard pour les exceptions standard afin de maintenir la compatibilité.

2. **Valeurs personnalisées pour exceptions personnalisées** : Pour les exceptions personnalisées, utilisez des valeurs HResult qui ne sont pas en conflit avec les valeurs standard.

3. **Documentation** : Documentez les valeurs HResult personnalisées pour faciliter le débogage et la maintenance.

4. **Cohérence** : Maintenez une cohérence dans l'utilisation des valeurs HResult au sein de votre application.

5. **Analyse des composantes** : Pour le débogage, décomposez les valeurs HResult en leurs composantes pour mieux comprendre l'origine et la nature de l'erreur.

### Limitations et considérations

1. **Spécificité à Windows** : Les valeurs HResult sont principalement utilisées dans l'écosystème Windows et peuvent ne pas être pertinentes dans d'autres environnements.

2. **Complexité** : La structure des codes HResult peut être difficile à comprendre sans outils d'analyse.

3. **Évolution** : Les valeurs HResult peuvent évoluer avec les nouvelles versions de .NET et de Windows.

4. **Interopérabilité limitée** : En dehors de l'interopérabilité COM et du code natif Windows, les valeurs HResult ont une utilité limitée.

5. **Redondance** : Dans de nombreux cas, le type d'exception et le message fournissent déjà suffisamment d'informations sans avoir besoin d'analyser le HResult.

### Utilisation dans PowerShell

Dans PowerShell, la propriété `HResult` est accessible via l'objet `ErrorRecord` dans la variable `$_` à l'intérieur d'un bloc `catch` :

```powershell
try {
    # Code qui peut générer une exception

} catch {
    # Accès au HResult de l'exception

    $hresult = $_.Exception.HResult

    # Affichage en format hexadécimal

    $hresultHex = "0x$($hresult.ToString('X8'))"

    Write-Host "Une erreur s'est produite avec le code HResult: $hresult ($hresultHex)"

    # Utilisation du HResult pour un traitement spécifique

    switch ($hresult) {
        -2147024894 { # 0x80070002 - FileNotFoundException

            Write-Host "Fichier non trouvé. Vérifiez le chemin d'accès."
        }
        -2147024891 { # 0x80070005 - UnauthorizedAccessException

            Write-Host "Accès refusé. Vérifiez les permissions."
        }
        -2146233087 { # 0x80131501 - ArgumentNullException

            Write-Host "Un argument requis est null."
        }
        default {
            Write-Host "Erreur non spécifique."
        }
    }
}
```plaintext
### Intégration avec la taxonomie des exceptions

Dans notre taxonomie des exceptions PowerShell, la propriété `HResult` est utilisée pour :

1. **Identification précise** : Identifier avec précision le type d'exception, même lorsque le message ou le type d'exception est ambigu.

2. **Catégorisation** : Regrouper les exceptions par leur code de facilité (facility) pour identifier les composants problématiques.

3. **Interopérabilité** : Faciliter l'interopérabilité avec le code natif et les technologies COM.

4. **Diagnostic avancé** : Fournir des informations supplémentaires pour le diagnostic des problèmes complexes.

5. **Traitement conditionnel** : Permettre un traitement conditionnel des exceptions basé sur leur code HResult plutôt que sur leur type ou leur message.

## Méthodes ToString() et GetBaseException()

### Description

La classe `System.Exception` fournit plusieurs méthodes importantes pour travailler avec les exceptions. Parmi celles-ci, deux méthodes sont particulièrement utiles pour le diagnostic et la gestion des erreurs :

1. **ToString()** : Génère une représentation textuelle complète de l'exception, incluant le message, le type d'exception et la pile d'appels.

2. **GetBaseException()** : Retourne l'exception la plus interne (racine) dans une chaîne d'exceptions imbriquées.

Ces méthodes sont essentielles pour obtenir des informations détaillées sur les exceptions et pour identifier la cause fondamentale des erreurs.

### Méthode ToString()

#### Caractéristiques principales

1. **Représentation complète** : Fournit une représentation textuelle complète de l'exception, incluant toutes les informations pertinentes.

2. **Format standardisé** : Le format de sortie suit un modèle standardisé qui facilite la lecture et l'analyse.

3. **Inclusion de la pile d'appels** : Inclut automatiquement la pile d'appels complète, ce qui est crucial pour le débogage.

4. **Inclusion des exceptions internes** : Si l'exception contient des exceptions internes, elles sont également incluses dans la sortie.

5. **Surcharge possible** : Les classes dérivées peuvent surcharger cette méthode pour fournir des informations supplémentaires spécifiques au type d'exception.

#### Format de sortie

Le format typique de la sortie de `ToString()` est le suivant :

```plaintext
ExceptionType: ExceptionMessage
   at Method1(parameters) in File1:line xx
   at Method2(parameters) in File2:line yy
   at Method3(parameters) in File3:line zz
   ...
   --- Fin de la trace de la pile d'exception interne ---
   at InnerMethod1(parameters) in InnerFile1:line aa
   at InnerMethod2(parameters) in InnerFile2:line bb
   ...
```plaintext
### Méthode GetBaseException()

#### Caractéristiques principales

1. **Accès à l'exception racine** : Permet d'accéder directement à l'exception la plus profonde dans une chaîne d'exceptions imbriquées.

2. **Diagnostic de la cause fondamentale** : Facilite l'identification de la cause fondamentale d'une erreur en ignorant les exceptions intermédiaires.

3. **Optimisation du traitement** : Permet d'optimiser le traitement des erreurs en ciblant directement la cause racine.

4. **Simplicité d'utilisation** : Offre une alternative simple à la traversée manuelle de la chaîne d'exceptions via la propriété `InnerException`.

5. **Comportement récursif** : Parcourt récursivement la chaîne d'exceptions jusqu'à trouver une exception sans `InnerException`.

#### Comportement

- Si l'exception n'a pas d'exception interne (`InnerException` est `null`), `GetBaseException()` retourne l'exception elle-même.
- Si l'exception a une exception interne, `GetBaseException()` parcourt récursivement la chaîne d'exceptions via la propriété `InnerException` jusqu'à trouver une exception sans exception interne.
- Pour les exceptions de type `AggregateException`, le comportement peut être différent, car ces exceptions peuvent contenir plusieurs exceptions internes.

### Exemples en PowerShell

```powershell
# Exemple 1: Utilisation de ToString() pour obtenir des informations complètes sur une exception

function Test-ExceptionToString {
    try {
        # Générer une exception

        [int]::Parse("abc")
    }
    catch {
        # Utiliser ToString() pour obtenir une représentation complète de l'exception

        $exceptionString = $_.Exception.ToString()

        Write-Host "Représentation complète de l'exception:"
        Write-Host $exceptionString

        # Sortie typique:

        # Représentation complète de l'exception:

        # System.FormatException: Input string was not in a correct format.

        #    at System.Number.ParseInt32(String s, NumberStyles style, NumberFormatInfo info)

        #    at System.Int32.Parse(String s)

        #    at <ScriptBlock>, <Aucun fichier>: ligne 4

    }
}

Test-ExceptionToString

# Exemple 2: Comparaison entre ToString() et les propriétés individuelles

function Compare-ExceptionProperties {
    try {
        # Générer une exception

        [int]::Parse("abc")
    }
    catch {
        # Accéder aux propriétés individuelles

        $type = $_.Exception.GetType().FullName
        $message = $_.Exception.Message
        $stackTrace = $_.Exception.StackTrace

        # Utiliser ToString() pour obtenir une représentation complète

        $toString = $_.Exception.ToString()

        Write-Host "Type: $type"
        Write-Host "Message: $message"
        Write-Host "StackTrace: $stackTrace"
        Write-Host "`nToString():"
        Write-Host $toString

        # Sortie typique:

        # Type: System.FormatException

        # Message: Input string was not in a correct format.

        # StackTrace:    at System.Number.ParseInt32(String s, NumberStyles style, NumberFormatInfo info)

        #    at System.Int32.Parse(String s)

        #    at <ScriptBlock>, <Aucun fichier>: ligne 4

        #

        # ToString():

        # System.FormatException: Input string was not in a correct format.

        #    at System.Number.ParseInt32(String s, NumberStyles style, NumberFormatInfo info)

        #    at System.Int32.Parse(String s)

        #    at <ScriptBlock>, <Aucun fichier>: ligne 4

    }
}

Compare-ExceptionProperties

# Exemple 3: Utilisation de GetBaseException() pour accéder à l'exception racine

function Test-GetBaseException {
    try {
        try {
            try {
                # Exception de niveau 3 (la plus profonde)

                [int]::Parse("abc")
            }
            catch {
                # Exception de niveau 2

                throw [System.IO.IOException]::new("Erreur de lecture des données", $_.Exception)
            }
        }
        catch {
            # Exception de niveau 1 (la plus externe)

            throw [System.InvalidOperationException]::new("Opération impossible à compléter", $_.Exception)
        }
    }
    catch {
        # Accéder à l'exception la plus externe

        $topException = $_.Exception
        Write-Host "Exception la plus externe: $($topException.GetType().FullName)"
        Write-Host "Message: $($topException.Message)"

        # Parcourir manuellement la chaîne d'exceptions

        Write-Host "`nParcours manuel de la chaîne d'exceptions:"
        $current = $topException
        $level = 1

        while ($current -ne $null) {
            Write-Host "Niveau $level : $($current.GetType().FullName) - $($current.Message)"
            $current = $current.InnerException
            $level++
        }

        # Utiliser GetBaseException() pour accéder directement à l'exception racine

        $baseException = $topException.GetBaseException()
        Write-Host "`nException racine via GetBaseException(): $($baseException.GetType().FullName)"
        Write-Host "Message: $($baseException.Message)"

        # Sortie typique:

        # Exception la plus externe: System.InvalidOperationException

        # Message: Opération impossible à compléter

        #

        # Parcours manuel de la chaîne d'exceptions:

        # Niveau 1 : System.InvalidOperationException - Opération impossible à compléter

        # Niveau 2 : System.IO.IOException - Erreur de lecture des données

        # Niveau 3 : System.FormatException - Input string was not in a correct format.

        #

        # Exception racine via GetBaseException(): System.FormatException

        # Message: Input string was not in a correct format.

    }
}

Test-GetBaseException

# Exemple 4: Utilisation de ToString() avec des exceptions imbriquées

function Test-ToStringWithNestedExceptions {
    try {
        try {
            # Exception interne

            [int]::Parse("abc")
        }
        catch {
            # Exception externe avec exception interne

            throw [System.InvalidOperationException]::new("Opération échouée", $_.Exception)
        }
    }
    catch {
        # Utiliser ToString() pour obtenir une représentation complète

        $exceptionString = $_.Exception.ToString()

        Write-Host "Représentation complète des exceptions imbriquées:"
        Write-Host $exceptionString

        # Sortie typique:

        # Représentation complète des exceptions imbriquées:

        # System.InvalidOperationException: Opération échouée ---> System.FormatException: Input string was not in a correct format.

        #    at System.Number.ParseInt32(String s, NumberStyles style, NumberFormatInfo info)

        #    at System.Int32.Parse(String s)

        #    at <ScriptBlock>, <Aucun fichier>: ligne 4

        #    --- Fin de la trace de la pile d'exception interne ---

        #    at <ScriptBlock>, <Aucun fichier>: ligne 7

    }
}

Test-ToStringWithNestedExceptions
```plaintext
### Différences et complémentarités

Les méthodes `ToString()` et `GetBaseException()` ont des objectifs différents mais complémentaires :

| Méthode | Objectif principal | Utilisation typique |
|---------|-------------------|---------------------|
| ToString() | Fournir une représentation textuelle complète de l'exception | Journalisation, débogage, affichage des détails de l'erreur |
| GetBaseException() | Accéder à l'exception racine dans une chaîne d'exceptions | Diagnostic de la cause fondamentale, traitement ciblé des erreurs |

### Bonnes pratiques

#### Pour ToString()

1. **Journalisation complète** : Utilisez `ToString()` pour la journalisation des exceptions afin de capturer toutes les informations pertinentes.

2. **Formatage pour l'affichage** : Pour l'affichage aux utilisateurs finaux, considérez un formatage personnalisé plutôt que d'utiliser directement la sortie de `ToString()`.

3. **Préservation de la structure** : Préservez la structure de la sortie de `ToString()` lors de la journalisation pour faciliter l'analyse ultérieure.

4. **Surcharge dans les exceptions personnalisées** : Si vous créez des exceptions personnalisées, envisagez de surcharger `ToString()` pour inclure des informations spécifiques à votre application.

5. **Attention aux informations sensibles** : Soyez conscient que `ToString()` peut révéler des informations sensibles. Filtrez si nécessaire avant d'exposer aux utilisateurs finaux.

#### Pour GetBaseException()

1. **Diagnostic de la cause racine** : Utilisez `GetBaseException()` pour identifier rapidement la cause fondamentale d'une erreur.

2. **Combinaison avec ToString()** : Combinez `GetBaseException()` avec `ToString()` pour obtenir des informations détaillées sur l'exception racine.

3. **Vérification du contexte** : N'oubliez pas que `GetBaseException()` ignore les exceptions intermédiaires, qui peuvent contenir des informations contextuelles importantes.

4. **Traitement spécifique pour AggregateException** : Pour les exceptions de type `AggregateException`, utilisez la méthode `Flatten()` avant d'appeler `GetBaseException()` pour traiter correctement les exceptions multiples.

5. **Préservation de la chaîne complète** : Pour un diagnostic complet, préservez la chaîne complète d'exceptions en plus d'utiliser `GetBaseException()`.

### Limitations et considérations

#### Pour ToString()

1. **Verbosité** : La sortie peut être très verbeuse, surtout avec des exceptions imbriquées et des piles d'appels profondes.

2. **Informations sensibles** : Peut contenir des informations sensibles comme des chemins de fichiers, des noms d'utilisateurs, etc.

3. **Format non structuré** : La sortie est une chaîne de texte non structurée, ce qui peut rendre l'analyse programmatique difficile.

4. **Localisation** : Les messages peuvent être localisés, ce qui peut compliquer l'analyse automatisée.

5. **Dépendance à l'implémentation** : Le format exact peut varier selon l'implémentation de .NET et la version.

#### Pour GetBaseException()

1. **Perte de contexte** : L'accès direct à l'exception racine peut faire perdre le contexte fourni par les exceptions intermédiaires.

2. **Comportement spécifique pour AggregateException** : Le comportement peut être différent pour les exceptions de type `AggregateException`.

3. **Profondeur limitée** : Dans des cas extrêmes de chaînes d'exceptions très profondes, des problèmes de performance ou de dépassement de pile pourraient survenir.

4. **Ambiguïté potentielle** : Dans certains cas, l'exception "racine" peut ne pas être la plus pertinente pour comprendre l'erreur.

5. **Dépendance à l'implémentation** : Le comportement exact peut varier selon l'implémentation de .NET et la version.

### Utilisation dans PowerShell

Dans PowerShell, ces méthodes sont accessibles via l'objet `ErrorRecord` dans la variable `$_` à l'intérieur d'un bloc `catch` :

```powershell
try {
    # Code qui peut générer une exception

} catch {
    # Utiliser ToString() pour la journalisation

    $exceptionDetails = $_.Exception.ToString()
    Write-Log -Level Error -Message "Une erreur s'est produite" -Details $exceptionDetails

    # Utiliser GetBaseException() pour le traitement ciblé

    $rootCause = $_.Exception.GetBaseException()

    # Traitement conditionnel basé sur le type de l'exception racine

    switch ($rootCause.GetType().FullName) {
        "System.IO.FileNotFoundException" {
            Write-Host "Fichier non trouvé. Vérifiez le chemin d'accès."
        }
        "System.UnauthorizedAccessException" {
            Write-Host "Accès refusé. Vérifiez les permissions."
        }
        "System.FormatException" {
            Write-Host "Format invalide. Vérifiez les données d'entrée."
        }
        default {
            Write-Host "Erreur non spécifique: $($rootCause.Message)"
        }
    }
}
```plaintext
### Intégration avec la taxonomie des exceptions

Dans notre taxonomie des exceptions PowerShell, les méthodes `ToString()` et `GetBaseException()` sont utilisées pour :

1. **Journalisation détaillée** : Utiliser `ToString()` pour capturer tous les détails des exceptions pour la journalisation et l'analyse.

2. **Identification précise** : Utiliser `GetBaseException()` pour identifier avec précision la cause fondamentale des erreurs.

3. **Classification hiérarchique** : Analyser la sortie de `ToString()` pour comprendre la hiérarchie complète des exceptions.

4. **Diagnostic contextuel** : Combiner les informations de `ToString()` et `GetBaseException()` pour un diagnostic complet.

5. **Génération de rapports d'erreurs** : Utiliser ces méthodes pour générer des rapports d'erreurs détaillés et structurés.

## Propriétés Data et TargetSite

### Description

La classe `System.Exception` fournit deux propriétés supplémentaires qui peuvent être très utiles pour le diagnostic avancé et la gestion des erreurs :

1. **Data** : Une collection de paires clé/valeur qui permet d'associer des informations supplémentaires à une exception.

2. **TargetSite** : Fournit des informations sur la méthode qui a généré l'exception.

Ces propriétés offrent des fonctionnalités avancées pour enrichir les exceptions avec des informations contextuelles et pour analyser précisément l'origine des erreurs.

### Propriété Data

#### Caractéristiques principales

1. **Collection de données arbitraires** : Permet de stocker des informations supplémentaires sous forme de paires clé/valeur.

2. **Type IDictionary** : Implémente l'interface `System.Collections.IDictionary`, offrant toutes les fonctionnalités d'un dictionnaire.

3. **Persistance** : Les données sont préservées lors de la propagation de l'exception à travers les couches d'appel.

4. **Extensibilité** : Permet d'enrichir les exceptions avec des informations contextuelles sans avoir à créer des classes d'exception personnalisées.

5. **Initialisation automatique** : La collection est automatiquement initialisée (non null) lors de la création de l'exception.

#### Utilisation typique

La propriété `Data` est généralement utilisée pour :

1. **Ajouter des informations contextuelles** : Enrichir l'exception avec des détails sur le contexte dans lequel elle s'est produite.

2. **Fournir des détails de diagnostic** : Ajouter des informations qui peuvent aider au diagnostic du problème.

3. **Transmettre des métadonnées** : Associer des métadonnées à l'exception qui peuvent être utilisées par les gestionnaires d'exceptions.

4. **Éviter la création de classes d'exception personnalisées** : Stocker des informations spécifiques sans avoir à créer une nouvelle classe d'exception.

5. **Faciliter la journalisation structurée** : Fournir des données structurées pour les systèmes de journalisation.

### Propriété TargetSite

#### Caractéristiques principales

1. **Information sur la méthode** : Fournit des informations détaillées sur la méthode qui a généré l'exception.

2. **Type MethodBase** : Retourne un objet de type `System.Reflection.MethodBase`, qui est la classe de base pour les informations de méthode.

3. **Accès via réflexion** : Utilise les mécanismes de réflexion de .NET pour fournir des informations sur la méthode.

4. **Peut être null** : Dans certains contextes, comme les exceptions sérialisées ou certaines exceptions système, cette propriété peut être null.

5. **Informations détaillées** : Fournit des informations sur le nom de la méthode, ses paramètres, son type de retour, et d'autres métadonnées.

#### Informations disponibles

Via la propriété `TargetSite`, on peut accéder à diverses informations sur la méthode qui a généré l'exception :

| Information | Propriété/Méthode | Description |
|-------------|-------------------|-------------|
| Nom de la méthode | Name | Le nom de la méthode |
| Classe déclarante | DeclaringType | La classe qui contient la méthode |
| Paramètres | GetParameters() | Les paramètres de la méthode |
| Type de retour | ReturnType | Le type de retour de la méthode |
| Attributs | Attributes | Les attributs de la méthode (statique, virtuelle, etc.) |
| Est générique | IsGenericMethod | Indique si la méthode est générique |
| Est constructeur | IsConstructor | Indique si la méthode est un constructeur |

### Exemples en PowerShell

```powershell
# Exemple 1: Utilisation de la propriété Data pour enrichir une exception

function Test-ExceptionData {
    try {
        # Créer et enrichir une exception

        $exception = [System.InvalidOperationException]::new("Opération non valide")
        $exception.Data["Timestamp"] = Get-Date
        $exception.Data["OperationName"] = "Test-Operation"
        $exception.Data["Parameters"] = @{
            Param1 = "Value1"
            Param2 = 42
            Param3 = $true
        }

        throw $exception
    }
    catch {
        # Accéder aux données de l'exception

        $ex = $_.Exception

        Write-Host "Exception: $($ex.GetType().FullName)"
        Write-Host "Message: $($ex.Message)"
        Write-Host "Données supplémentaires:"

        foreach ($key in $ex.Data.Keys) {
            $value = $ex.Data[$key]
            Write-Host "  $key : $value"

            # Si la valeur est un hashtable, afficher son contenu

            if ($value -is [hashtable]) {
                foreach ($subKey in $value.Keys) {
                    Write-Host "    $subKey : $($value[$subKey])"
                }
            }
        }

        # Sortie typique:

        # Exception: System.InvalidOperationException

        # Message: Opération non valide

        # Données supplémentaires:

        #   Timestamp : 01/01/2023 12:00:00

        #   OperationName : Test-Operation

        #   Parameters : System.Collections.Hashtable

        #     Param1 : Value1

        #     Param2 : 42

        #     Param3 : True

    }
}

Test-ExceptionData

# Exemple 2: Utilisation de la propriété Data pour transmettre des informations à travers les couches d'appel

function Test-ExceptionDataPropagation {
    try {
        Test-InnerFunction
    }
    catch {
        # Accéder aux données enrichies à chaque niveau

        $ex = $_.Exception

        Write-Host "Exception finale: $($ex.GetType().FullName)"
        Write-Host "Message: $($ex.Message)"
        Write-Host "Données accumulées:"

        foreach ($key in $ex.Data.Keys) {
            Write-Host "  $key : $($ex.Data[$key])"
        }

        # Sortie typique:

        # Exception finale: System.InvalidOperationException

        # Message: Erreur de niveau 1

        # Données accumulées:

        #   Niveau3 : Informations du niveau 3

        #   Niveau2 : Informations du niveau 2

        #   Niveau1 : Informations du niveau 1

    }
}

function Test-InnerFunction {
    try {
        Test-DeeperFunction
    }
    catch {
        # Enrichir l'exception avec des informations de ce niveau

        $_.Exception.Data["Niveau2"] = "Informations du niveau 2"

        # Relancer l'exception enrichie

        throw [System.InvalidOperationException]::new("Erreur de niveau 1", $_.Exception)
    }
}

function Test-DeeperFunction {
    try {
        # Générer une exception

        throw [System.ArgumentException]::new("Argument invalide")
    }
    catch {
        # Enrichir l'exception avec des informations de ce niveau

        $_.Exception.Data["Niveau3"] = "Informations du niveau 3"

        # Relancer l'exception enrichie

        throw
    }
}

Test-ExceptionDataPropagation

# Exemple 3: Utilisation de la propriété TargetSite pour obtenir des informations sur la méthode qui a généré l'exception

function Test-ExceptionTargetSite {
    try {
        # Générer une exception

        [int]::Parse("abc")
    }
    catch {
        $targetSite = $_.Exception.TargetSite

        Write-Host "Informations sur la méthode qui a généré l'exception:"
        Write-Host "Nom de la méthode: $($targetSite.Name)"
        Write-Host "Classe déclarante: $($targetSite.DeclaringType.FullName)"
        Write-Host "Est statique: $(($targetSite.Attributes -band [System.Reflection.MethodAttributes]::Static) -ne 0)"
        Write-Host "Type de retour: $($targetSite.ReturnType.FullName)"

        Write-Host "`nParamètres:"
        foreach ($param in $targetSite.GetParameters()) {
            Write-Host "  $($param.ParameterType.FullName) $($param.Name)"
        }

        # Sortie typique:

        # Informations sur la méthode qui a généré l'exception:

        # Nom de la méthode: ParseInt32

        # Classe déclarante: System.Number

        # Est statique: True

        # Type de retour: System.Int32

        #

        # Paramètres:

        #   System.String s

        #   System.Globalization.NumberStyles style

        #   System.Globalization.NumberFormatInfo info

    }
}

Test-ExceptionTargetSite

# Exemple 4: Combinaison des propriétés Data et TargetSite pour un diagnostic avancé

function Test-CombinedExceptionProperties {
    try {
        # Appeler une fonction qui va générer une exception

        Test-FailingFunction -InputValue "abc" -MaxRetries 3
    }
    catch {
        $ex = $_.Exception
        $targetSite = $ex.TargetSite

        # Créer un rapport de diagnostic

        $diagnosticReport = [PSCustomObject]@{
            ExceptionType = $ex.GetType().FullName
            Message = $ex.Message
            Timestamp = Get-Date
            MethodName = $targetSite.Name
            ClassName = $targetSite.DeclaringType.FullName
            Parameters = @{}
            AdditionalData = @{}
        }

        # Ajouter les paramètres de la méthode

        foreach ($param in $targetSite.GetParameters()) {
            $diagnosticReport.Parameters[$param.Name] = $null  # On ne peut pas accéder aux valeurs réelles

        }

        # Ajouter les données supplémentaires de l'exception

        foreach ($key in $ex.Data.Keys) {
            $diagnosticReport.AdditionalData[$key] = $ex.Data[$key]
        }

        # Afficher le rapport

        Write-Host "Rapport de diagnostic:"
        $diagnosticReport | Format-List

        # Sortie typique:

        # Rapport de diagnostic:

        # ExceptionType : System.FormatException

        # Message      : Input string was not in a correct format.

        # Timestamp    : 01/01/2023 12:00:00

        # MethodName   : ParseInt32

        # ClassName    : System.Number

        # Parameters   : {s, style, info}

        # AdditionalData : {InputValue, MaxRetries, AttemptCount}

    }
}

function Test-FailingFunction {
    param (
        [string]$InputValue,
        [int]$MaxRetries
    )

    try {
        # Tenter de convertir la valeur en entier

        $attemptCount = 0
        while ($attemptCount -lt $MaxRetries) {
            try {
                $attemptCount++
                return [int]::Parse($InputValue)
            }
            catch {
                # Enrichir l'exception avec des informations contextuelles

                $_.Exception.Data["InputValue"] = $InputValue
                $_.Exception.Data["MaxRetries"] = $MaxRetries
                $_.Exception.Data["AttemptCount"] = $attemptCount

                if ($attemptCount -ge $MaxRetries) {
                    throw  # Relancer l'exception après le dernier essai

                }
            }
        }
    }
    catch {
        throw  # Relancer l'exception enrichie

    }
}

Test-CombinedExceptionProperties
```plaintext
### Différences et complémentarités

Les propriétés `Data` et `TargetSite` ont des objectifs différents mais complémentaires :

| Propriété | Objectif principal | Utilisation typique |
|-----------|-------------------|---------------------|
| Data | Stocker des informations supplémentaires | Enrichir les exceptions avec des informations contextuelles |
| TargetSite | Fournir des informations sur la méthode qui a généré l'exception | Analyse précise de l'origine des erreurs |

### Bonnes pratiques

#### Pour Data

1. **Clés significatives** : Utilisez des noms de clés significatifs et cohérents pour faciliter l'utilisation des données.

2. **Valeurs sérialisables** : Assurez-vous que les valeurs stockées sont sérialisables si l'exception peut être sérialisée.

3. **Informations pertinentes** : Stockez uniquement des informations pertinentes pour le diagnostic et la résolution du problème.

4. **Éviter les informations sensibles** : N'incluez pas d'informations sensibles (mots de passe, données personnelles) dans la propriété `Data`.

5. **Documentation** : Documentez les clés et les valeurs que vous utilisez pour faciliter la maintenance.

#### Pour TargetSite

1. **Vérification de null** : Vérifiez toujours si `TargetSite` est null avant d'y accéder, car il peut l'être dans certains contextes.

2. **Utilisation avec réflexion** : Combinez `TargetSite` avec d'autres fonctionnalités de réflexion pour une analyse plus approfondie.

3. **Journalisation structurée** : Extrayez les informations pertinentes de `TargetSite` pour une journalisation structurée.

4. **Analyse post-mortem** : Utilisez les informations de `TargetSite` pour l'analyse post-mortem des erreurs.

5. **Combinaison avec StackTrace** : Combinez les informations de `TargetSite` avec celles de `StackTrace` pour une compréhension complète du contexte d'erreur.

### Limitations et considérations

#### Pour Data

1. **Non typé** : La collection `Data` utilise `object` comme type de valeur, ce qui peut nécessiter des conversions de type.

2. **Sérialisation** : Toutes les valeurs stockées doivent être sérialisables si l'exception doit être sérialisée.

3. **Performance** : L'ajout de nombreuses données peut avoir un impact sur les performances, surtout dans les chemins critiques.

4. **Conflit de clés** : Il n'y a pas de mécanisme standard pour éviter les conflits de noms de clés entre différentes parties du code.

5. **Visibilité** : Les données ne sont pas automatiquement visibles dans les messages d'erreur standard ou les traces de pile.

#### Pour TargetSite

1. **Peut être null** : La propriété peut être null dans certains contextes, comme après la sérialisation.

2. **Informations limitées** : Ne fournit pas d'informations sur les valeurs réelles des paramètres au moment de l'exception.

3. **Dépendance à la réflexion** : L'utilisation de la réflexion peut avoir un impact sur les performances.

4. **Sécurité** : Peut révéler des informations sur la structure interne de l'application.

5. **Compatibilité** : Le comportement peut varier selon les environnements d'exécution et les versions de .NET.

### Utilisation dans PowerShell

Dans PowerShell, ces propriétés sont accessibles via l'objet `ErrorRecord` dans la variable `$_` à l'intérieur d'un bloc `catch` :

```powershell
try {
    # Code qui peut générer une exception

} catch {
    # Accéder à la propriété Data

    $exData = $_.Exception.Data
    if ($exData.Count -gt 0) {
        Write-Host "Informations supplémentaires:"
        foreach ($key in $exData.Keys) {
            Write-Host "  $key : $($exData[$key])"
        }
    }

    # Accéder à la propriété TargetSite

    $targetSite = $_.Exception.TargetSite
    if ($targetSite -ne $null) {
        Write-Host "Méthode qui a généré l'exception: $($targetSite.DeclaringType.FullName).$($targetSite.Name)"
    }

    # Enrichir l'exception avant de la relancer

    $_.Exception.Data["HandledBy"] = "MonModule.GestionErreurs"
    $_.Exception.Data["Timestamp"] = Get-Date

    # Relancer l'exception enrichie

    throw
}
```plaintext
PowerShell offre également des moyens d'enrichir l'objet `ErrorRecord` lui-même :

```powershell
try {
    # Code qui peut générer une exception

} catch {
    # Créer un nouvel ErrorRecord avec des informations supplémentaires

    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
        $_.Exception,
        "CustomErrorId",
        [System.Management.Automation.ErrorCategory]::InvalidOperation,
        $InputObject
    )

    # Ajouter des informations supplémentaires à l'exception

    $errorRecord.Exception.Data["CustomInfo"] = "Information personnalisée"

    # Écrire l'erreur dans le pipeline d'erreur

    $PSCmdlet.WriteError($errorRecord)
}
```plaintext
### Intégration avec la taxonomie des exceptions

Dans notre taxonomie des exceptions PowerShell, les propriétés `Data` et `TargetSite` sont utilisées pour :

1. **Enrichissement contextuel** : Utiliser `Data` pour enrichir les exceptions avec des informations contextuelles spécifiques à notre environnement.

2. **Analyse précise** : Utiliser `TargetSite` pour identifier précisément l'origine des erreurs dans notre code.

3. **Journalisation structurée** : Extraire des informations structurées de ces propriétés pour notre système de journalisation.

4. **Diagnostic avancé** : Combiner ces propriétés avec d'autres pour un diagnostic avancé des erreurs.

5. **Classification dynamique** : Utiliser les informations de ces propriétés pour classifier dynamiquement les exceptions.

## Tableau récapitulatif des propriétés et méthodes communes

Le tableau suivant résume les propriétés et méthodes communes de la classe `System.Exception` que nous avons documentées en détail dans ce document. Il fournit une vue d'ensemble rapide de leurs caractéristiques, utilisations typiques et particularités.

| Propriété/Méthode | Type | Modifiable | Description | Utilisation typique | Particularités |
|-------------------|------|------------|-------------|-------------------|----------------|
| **Message** | `string` | Non | Message décrivant l'erreur | Affichage d'informations sur l'erreur | - Défini lors de la création<br>- Peut être localisé<br>- Devrait être compréhensible |
| **StackTrace** | `string` | Non | Trace de la pile d'appels | Débogage et diagnostic | - Généré automatiquement<br>- Peut être null<br>- Format dépendant de la plateforme |
| **InnerException** | `Exception` | Non | Exception interne encapsulée | Propagation d'exceptions | - Permet de créer des chaînes d'exceptions<br>- Utile avec GetBaseException() |
| **Source** | `string` | Oui | Nom de l'application ou de l'objet qui a causé l'erreur | Identification de l'origine | - Souvent le nom de l'assembly<br>- Peut être personnalisé |
| **HResult** | `int` | Oui | Code d'erreur numérique | Interopérabilité COM/native | - Format standardisé<br>- Contient sévérité, facilité, code |
| **Data** | `IDictionary` | Oui (contenu) | Collection de paires clé/valeur | Informations contextuelles | - Extensible<br>- Préservé lors de la propagation |
| **TargetSite** | `MethodBase` | Non | Méthode qui a généré l'exception | Analyse précise de l'origine | - Peut être null<br>- Utilise la réflexion |
| **ToString()** | Méthode | N/A | Représentation textuelle complète | Journalisation, débogage | - Inclut type, message, pile<br>- Format standardisé |
| **GetBaseException()** | Méthode | N/A | Exception racine dans une chaîne | Diagnostic de la cause fondamentale | - Parcourt récursivement InnerException<br>- Comportement spécial pour AggregateException |

### Comparaison des propriétés et méthodes

Le tableau suivant compare les différentes propriétés et méthodes en fonction de critères spécifiques :

| Propriété/Méthode | Disponibilité | Niveau de détail | Modifiable | Persistance | Utilité en PowerShell |
|-------------------|--------------|-----------------|------------|------------|---------------------|
| **Message** | Toujours | Basique | Non | Oui | Élevée (affichage direct) |
| **StackTrace** | Après levée | Détaillé | Non | Oui | Moyenne (format verbeux) |
| **InnerException** | Si définie | Variable | Non | Oui | Moyenne (nécessite parcours) |
| **Source** | Variable | Basique | Oui | Oui | Moyenne (souvent générique) |
| **HResult** | Toujours | Technique | Oui | Oui | Faible (sauf interop) |
| **Data** | Toujours | Personnalisable | Oui | Oui | Élevée (extensible) |
| **TargetSite** | Variable | Détaillé | Non | Non (sérialisation) | Moyenne (technique) |
| **ToString()** | Toujours | Complet | N/A | Oui | Élevée (journalisation) |
| **GetBaseException()** | Toujours | Ciblé | N/A | Oui | Moyenne (diagnostic) |

### Scénarios d'utilisation recommandés

Le tableau suivant indique les scénarios d'utilisation recommandés pour chaque propriété ou méthode :

| Scénario | Propriétés/Méthodes recommandées |
|----------|--------------------------------|
| **Affichage à l'utilisateur** | Message (formaté), parfois Source |
| **Journalisation** | ToString(), Message, StackTrace, Source, Data (contexte) |
| **Débogage** | ToString(), StackTrace, TargetSite, InnerException |
| **Diagnostic avancé** | GetBaseException(), TargetSite, HResult, Data |
| **Interopérabilité** | HResult, Source |
| **Enrichissement contextuel** | Data |
| **Analyse de la cause racine** | GetBaseException(), InnerException (chaîne) |
| **Classification des erreurs** | Type d'exception, HResult, Source |

### Bonnes pratiques générales

1. **Hiérarchie d'informations** : Utilisez une approche hiérarchique pour accéder aux informations d'exception :
   - Niveau 1 (basique) : Message, Type d'exception
   - Niveau 2 (standard) : Source, InnerException, Data
   - Niveau 3 (avancé) : StackTrace, TargetSite, HResult

2. **Journalisation structurée** : Pour une journalisation efficace, structurez les informations d'exception :
   ```powershell
   $exceptionInfo = [PSCustomObject]@{
       Type = $_.Exception.GetType().FullName
       Message = $_.Exception.Message
       Source = $_.Exception.Source
       StackTrace = $_.Exception.StackTrace
       HResult = "0x$($_.Exception.HResult.ToString('X8'))"
       TargetSite = $_.Exception.TargetSite?.Name
       InnerException = $_.Exception.InnerException?.GetType().FullName
       Data = @{}
   }

   foreach ($key in $_.Exception.Data.Keys) {
       $exceptionInfo.Data[$key] = $_.Exception.Data[$key]
   }
   ```

3. **Enrichissement contextuel** : Utilisez systématiquement la propriété Data pour enrichir les exceptions avec des informations contextuelles :
   ```powershell
   try {
       # Code qui peut générer une exception

   }
   catch {
       $_.Exception.Data["Timestamp"] = Get-Date
       $_.Exception.Data["Operation"] = "NomOpération"
       $_.Exception.Data["Parameters"] = $parameters
       throw  # Relancer l'exception enrichie

   }
   ```

4. **Analyse de la cause racine** : Combinez GetBaseException() avec d'autres propriétés pour une analyse complète :
   ```powershell
   $rootCause = $_.Exception.GetBaseException()
   $rootType = $rootCause.GetType().FullName
   $rootMessage = $rootCause.Message
   $rootStack = $rootCause.StackTrace
   ```

5. **Traitement conditionnel** : Utilisez le type d'exception et HResult pour un traitement conditionnel :
   ```powershell
   catch {
       $ex = $_.Exception
       switch ($ex.GetBaseException().GetType().FullName) {
           "System.IO.FileNotFoundException" { # Traitement spécifique }

           "System.UnauthorizedAccessException" { # Traitement spécifique }

           default {
               # Traitement par défaut basé sur HResult

               switch ($ex.HResult) {
                   0x80070002 { # Traitement spécifique pour ERROR_FILE_NOT_FOUND }

                   0x80070005 { # Traitement spécifique pour ERROR_ACCESS_DENIED }

                   default { # Traitement par défaut }

               }
           }
       }
   }
   ```

### Références

- [Documentation Microsoft sur System.Exception.Data](https://projet/documentation.microsoft.com/en-us/dotnet/api/system.exception.data)
- [Documentation Microsoft sur System.Exception.TargetSite](https://projet/documentation.microsoft.com/en-us/dotnet/api/system.exception.targetsite)
- [Documentation Microsoft sur System.Reflection.MethodBase](https://projet/documentation.microsoft.com/en-us/dotnet/api/system.reflection.methodbase)
- [Documentation Microsoft sur Exception.ToString](https://projet/documentation.microsoft.com/en-us/dotnet/api/system.exception.tostring)
- [Documentation Microsoft sur Exception.GetBaseException](https://projet/documentation.microsoft.com/en-us/dotnet/api/system.exception.getbaseexception)
- [Documentation Microsoft sur System.Exception.HResult](https://projet/documentation.microsoft.com/en-us/dotnet/api/system.exception.hresult)
- [Structure des codes d'erreur HRESULT](https://projet/documentation.microsoft.com/en-us/windows/win32/com/structure-of-com-error-codes)
- [Codes d'erreur système Windows](https://projet/documentation.microsoft.com/en-us/windows/win32/debug/system-error-codes)
- [Documentation Microsoft sur System.Exception.Source](https://projet/documentation.microsoft.com/en-us/dotnet/api/system.exception.source)
- [Documentation Microsoft sur System.Exception.InnerException](https://projet/documentation.microsoft.com/en-us/dotnet/api/system.exception.innerexception)
- [Documentation Microsoft sur System.AggregateException](https://projet/documentation.microsoft.com/en-us/dotnet/api/system.aggregateexception)
- [Bonnes pratiques pour la gestion des exceptions en .NET](https://projet/documentation.microsoft.com/en-us/dotnet/standard/exceptions/best-practices-for-exceptions)
- [Documentation Microsoft sur System.Exception.StackTrace](https://projet/documentation.microsoft.com/en-us/dotnet/api/system.exception.stacktrace)
- [Documentation Microsoft sur Get-PSCallStack](https://projet/documentation.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-pscallstack)
- [Documentation Microsoft sur System.Exception.Message](https://projet/documentation.microsoft.com/en-us/dotnet/api/system.exception.message)
