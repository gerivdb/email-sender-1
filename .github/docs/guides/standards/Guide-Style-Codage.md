# Guide de style de codage pour EMAIL_SENDER_1

*Version 1.0 - 2025-05-15*

Ce guide définit les standards et conventions de codage pour le projet EMAIL_SENDER_1. Il vise à assurer la cohérence, la lisibilité et la maintenabilité du code à travers tout le projet.

## Table des matières

1. [Principes généraux](#principes-généraux)

2. [Conventions de nommage](#conventions-de-nommage)

3. [Organisation des fichiers et dossiers](#organisation-des-fichiers-et-dossiers)

4. [Formatage du code](#formatage-du-code)

5. [Documentation](#documentation)

6. [Tests](#tests)

7. [Gestion des erreurs](#gestion-des-erreurs)

8. [Performances](#performances)

9. [Sécurité](#sécurité)

10. [Bonnes pratiques par langage](#bonnes-pratiques-par-langage)

## Principes généraux

### SOLID

- **S**ingle Responsibility Principle : Une classe ou un module ne doit avoir qu'une seule raison de changer
- **O**pen/Closed Principle : Les entités doivent être ouvertes à l'extension mais fermées à la modification
- **L**iskov Substitution Principle : Les objets d'une classe dérivée doivent pouvoir remplacer les objets de la classe de base
- **I**nterface Segregation Principle : Plusieurs interfaces spécifiques valent mieux qu'une interface générale
- **D**ependency Inversion Principle : Dépendre des abstractions, pas des implémentations

### DRY (Don't Repeat Yourself)

- Éviter la duplication de code
- Extraire les fonctionnalités communes dans des fonctions ou modules réutilisables
- Utiliser des constantes pour les valeurs répétées

### KISS (Keep It Simple, Stupid)

- Privilégier la simplicité et la clarté
- Éviter les solutions complexes quand une solution simple suffit
- Diviser les problèmes complexes en sous-problèmes plus simples

### YAGNI (You Aren't Gonna Need It)

- Ne pas ajouter de fonctionnalités avant qu'elles ne soient nécessaires
- Éviter la sur-ingénierie
- Se concentrer sur les besoins actuels plutôt que sur les besoins futurs hypothétiques

## Conventions de nommage

> **Note** : Pour des conventions de nommage détaillées, voir le document [Conventions-Nommage.md](./Conventions-Nommage.md).

### Principes généraux de nommage

- Utiliser des noms descriptifs qui expliquent clairement le but de l'élément
- Éviter les abréviations sauf si elles sont très courantes et claires
- Préférer la clarté à la concision
- Utiliser les mêmes termes pour les mêmes concepts dans tout le projet

### Conventions par langage

#### PowerShell

- Fonctions : Format `Verbe-Nom` en PascalCase avec un verbe approuvé
- Variables globales et de script : PascalCase avec préfixe `$script:` ou `$global:`
- Variables locales : camelCase
- Constantes : MAJUSCULES_AVEC_UNDERSCORES avec préfixe `$script:`

#### Python

- Fonctions et méthodes : snake_case
- Classes : PascalCase
- Variables et attributs : snake_case
- Constantes : MAJUSCULES_AVEC_UNDERSCORES

#### JavaScript/TypeScript

- Fonctions et méthodes : camelCase
- Classes et composants React : PascalCase
- Variables : camelCase
- Constantes globales : MAJUSCULES_AVEC_UNDERSCORES

## Organisation des fichiers et dossiers

> **Note** : Pour une organisation détaillée des fichiers et dossiers, voir le document [Organisation-Fichiers-Dossiers.md](./Organisation-Fichiers-Dossiers.md).

### Principes généraux d'organisation

- Séparer clairement les différentes parties du projet selon leur fonction
- Regrouper les fichiers liés par leur fonctionnalité plutôt que par leur type
- Maintenir une hiérarchie logique et intuitive
- Organiser le code en modules indépendants et réutilisables

### Structure racine du projet

```plaintext
EMAIL_SENDER_1/
├── development/        # Code de développement et outils

├── docs/               # Documentation du projet

├── projet/             # Configuration et planification du projet

├── src/                # Code source principal

└── tests/              # Tests automatisés

```plaintext
### Bonnes pratiques

- Limiter la taille des fichiers à environ 300-500 lignes
- Diviser les fichiers volumineux en modules plus petits et plus spécifiques
- Un fichier = une responsabilité
- Limiter la profondeur de l'arborescence à 4-5 niveaux maximum

## Formatage du code

### Indentation et espacement

- Utiliser 4 espaces pour l'indentation (pas de tabulations)
- Limiter les lignes à 120 caractères maximum
- Utiliser des lignes vides pour séparer les sections logiques du code
- Ajouter un espace après les virgules et autour des opérateurs

### Accolades et parenthèses

- Placer les accolades ouvrantes sur la même ligne que la déclaration
- Placer les accolades fermantes sur une nouvelle ligne
- Utiliser des accolades même pour les blocs à une seule instruction

### Commentaires

- Utiliser des commentaires pour expliquer le "pourquoi", pas le "comment"
- Commenter les sections complexes ou non évidentes
- Maintenir les commentaires à jour avec le code
- Éviter les commentaires redondants qui répètent simplement le code

### Ordre des éléments

- Organiser le code dans un ordre logique et cohérent
- Regrouper les éléments liés
- Suivre une structure prévisible dans tous les fichiers

## Documentation

### Documentation du code

- Documenter toutes les fonctions, classes et modules publics
- Utiliser des commentaires de documentation (docstrings) pour décrire le but, les paramètres et les valeurs de retour
- Inclure des exemples d'utilisation dans la documentation
- Maintenir la documentation à jour avec le code

### Documentation du projet

- Maintenir un README.md à la racine du projet qui explique le but, l'installation et l'utilisation
- Documenter l'architecture et les décisions de conception
- Fournir des guides d'utilisation et des tutoriels
- Inclure des diagrammes et des schémas pour illustrer les concepts complexes

### Format de documentation

#### PowerShell

Utiliser le format de commentaire d'aide PowerShell :

```powershell
<#

.SYNOPSIS
    Description courte de la fonction.
.DESCRIPTION
    Description détaillée de la fonction.
.PARAMETER Param1
    Description du paramètre 1.
.PARAMETER Param2
    Description du paramètre 2.
.EXAMPLE
    Example-Function -Param1 "Value1" -Param2 "Value2"
    Description de l'exemple.
.NOTES
    Version: 1.0.0
    Auteur: Nom de l'auteur
    Date de création: YYYY-MM-DD
#>

```plaintext
#### Python

Utiliser le format de docstring Google :

```python
def function_name(param1, param2):
    """Description courte de la fonction.

    Description détaillée de la fonction sur
    plusieurs lignes si nécessaire.

    Args:
        param1: Description du paramètre 1.
        param2: Description du paramètre 2.

    Returns:
        Description de la valeur de retour.

    Raises:
        ExceptionType: Description de quand l'exception est levée.

    Examples:
        >>> function_name("value1", "value2")
        "result"
    """
```plaintext
#### JavaScript/TypeScript

Utiliser le format JSDoc :

```javascript
/**
 * Description courte de la fonction.
 *
 * Description détaillée de la fonction sur
 * plusieurs lignes si nécessaire.
 *
 * @param {string} param1 - Description du paramètre 1.
 * @param {number} param2 - Description du paramètre 2.
 * @returns {boolean} Description de la valeur de retour.
 * @throws {Error} Description de quand l'erreur est levée.
 *
 * @example
 * // Exemple d'utilisation
 * functionName("value1", 42);
 */
```plaintext
## Tests

### Principes généraux de test

- Écrire des tests pour toutes les fonctionnalités critiques
- Suivre l'approche TDD (Test-Driven Development) quand c'est possible
- Maintenir une couverture de test élevée (au moins 80%)
- Tester les cas normaux et les cas limites

### Types de tests

- **Tests unitaires** : Tester les fonctions et classes individuelles
- **Tests d'intégration** : Tester l'interaction entre les composants
- **Tests de performance** : Tester les performances et l'efficacité
- **Tests de sécurité** : Tester la résistance aux attaques et aux vulnérabilités

### Organisation des tests

- Organiser les tests de manière à refléter la structure du code source
- Nommer les fichiers de test de manière cohérente (ex: `Function.Tests.ps1`, `test_module.py`)
- Séparer les données de test du code de test

### Bonnes pratiques de test

- Écrire des tests indépendants qui peuvent être exécutés dans n'importe quel ordre
- Éviter les dépendances entre les tests
- Utiliser des mocks et des stubs pour isoler les composants
- Nettoyer après les tests (supprimer les fichiers temporaires, etc.)

## Gestion des erreurs

### Principes généraux de gestion des erreurs

- Gérer les erreurs de manière cohérente et prévisible
- Fournir des messages d'erreur clairs et utiles
- Logger les erreurs avec suffisamment de contexte
- Distinguer les erreurs attendues des erreurs inattendues

### Techniques de gestion des erreurs

#### PowerShell

- Utiliser `try/catch/finally` pour gérer les exceptions
- Utiliser `$ErrorActionPreference = 'Stop'` pour transformer les erreurs non terminales en exceptions
- Utiliser `Write-Error` pour signaler les erreurs
- Utiliser `throw` pour lever des exceptions

```powershell
try {
    $result = Invoke-RiskyOperation -Param "Value"
    if (-not $result) {
        Write-Error "L'opération a échoué."
        return
    }
}
catch [System.IO.FileNotFoundException] {
    Write-Error "Le fichier n'a pas été trouvé : $_"
}
catch {
    Write-Error "Une erreur inattendue s'est produite : $_"
}
finally {
    # Nettoyage

}
```plaintext
#### Python

- Utiliser `try/except/finally` pour gérer les exceptions
- Capturer des exceptions spécifiques plutôt que toutes les exceptions
- Utiliser des exceptions personnalisées pour les erreurs spécifiques à l'application
- Utiliser `logging` pour enregistrer les erreurs

```python
try:
    result = risky_operation(param)
    if not result:
        raise ValueError("L'opération a échoué.")
except FileNotFoundError as e:
    logging.error(f"Le fichier n'a pas été trouvé : {e}")
except Exception as e:
    logging.error(f"Une erreur inattendue s'est produite : {e}")
finally:
    # Nettoyage

```plaintext
#### JavaScript/TypeScript

- Utiliser `try/catch/finally` pour gérer les exceptions
- Utiliser `async/await` avec `try/catch` pour les opérations asynchrones
- Utiliser des classes d'erreur personnalisées pour les erreurs spécifiques à l'application
- Utiliser un système de logging pour enregistrer les erreurs

```javascript
try {
    const result = await riskyOperation(param);
    if (!result) {
        throw new Error("L'opération a échoué.");
    }
} catch (error) {
    if (error instanceof NotFoundError) {
        console.error(`Le fichier n'a pas été trouvé : ${error.message}`);
    } else {
        console.error(`Une erreur inattendue s'est produite : ${error.message}`);
    }
} finally {
    // Nettoyage
}
```plaintext
## Performances

### Principes généraux d'optimisation

- Optimiser pour la lisibilité et la maintenabilité d'abord, puis pour les performances
- Mesurer avant d'optimiser
- Se concentrer sur les goulots d'étranglement identifiés
- Documenter les optimisations et leurs raisons

### Techniques d'optimisation

#### PowerShell

- Utiliser `ForEach-Object -Parallel` pour le traitement parallèle
- Utiliser `[System.Collections.Generic.List[T]]` au lieu de tableaux pour les collections dynamiques
- Éviter les appels inutiles à `Where-Object` et `ForEach-Object` pour les grandes collections
- Utiliser des requêtes SQL efficaces plutôt que de filtrer de grands ensembles de données en mémoire

#### Python

- Utiliser des structures de données appropriées (dictionnaires pour les recherches, etc.)
- Utiliser des compréhensions de liste au lieu de boucles quand c'est possible
- Utiliser `multiprocessing` ou `threading` pour le traitement parallèle
- Utiliser des bibliothèques optimisées comme NumPy pour les opérations numériques

#### JavaScript/TypeScript

- Minimiser les manipulations du DOM
- Utiliser la délégation d'événements
- Éviter les fuites de mémoire en nettoyant les écouteurs d'événements
- Utiliser des techniques de mémoïsation pour les fonctions coûteuses

## Sécurité

### Principes généraux de sécurité

- Ne jamais faire confiance aux entrées utilisateur
- Appliquer le principe du moindre privilège
- Protéger les données sensibles
- Maintenir les dépendances à jour

### Techniques de sécurité

#### PowerShell

- Utiliser `ConvertTo-SecureString` et `PSCredential` pour les mots de passe
- Éviter d'utiliser `Invoke-Expression` avec des entrées non fiables
- Valider toutes les entrées utilisateur
- Utiliser des jetons d'accès plutôt que des mots de passe quand c'est possible

#### Python

- Utiliser des bibliothèques de sécurité éprouvées (comme `cryptography`)
- Éviter d'utiliser `eval()` ou `exec()` avec des entrées non fiables
- Utiliser des requêtes paramétrées pour les bases de données
- Échapper correctement les sorties HTML

#### JavaScript/TypeScript

- Utiliser des bibliothèques de sécurité éprouvées
- Éviter d'utiliser `eval()` ou `new Function()` avec des entrées non fiables
- Protéger contre les attaques XSS en échappant les sorties
- Utiliser HTTPS pour toutes les communications

## Bonnes pratiques par langage

### PowerShell

#### Structure des scripts

- Commencer par un bloc `#Requires` pour spécifier les dépendances

- Utiliser un bloc `param()` au début du script pour déclarer les paramètres
- Organiser le code en sections logiques avec des commentaires de région
- Terminer les scripts par une valeur de retour explicite

#### Paramètres

- Utiliser les attributs `[Parameter()]` pour définir les propriétés des paramètres
- Utiliser les attributs de validation (`[ValidateNotNullOrEmpty()]`, etc.) pour valider les entrées
- Fournir des valeurs par défaut pour les paramètres optionnels
- Utiliser `[CmdletBinding()]` pour activer les fonctionnalités avancées

#### Gestion des erreurs

- Utiliser `[CmdletBinding(SupportsShouldProcess = $true)]` pour les fonctions qui modifient l'état
- Utiliser `$PSCmdlet.ShouldProcess()` pour confirmer les actions destructives
- Utiliser `$PSCmdlet.ThrowTerminatingError()` pour les erreurs graves
- Utiliser `Write-Verbose` et `Write-Debug` pour les informations de diagnostic

### Python

#### Structure des modules

- Suivre la structure de package standard
- Utiliser `__init__.py` pour définir l'API publique
- Suivre le principe "explicit is better than implicit"
- Utiliser des imports absolus plutôt que relatifs

#### Style de code

- Suivre PEP 8 pour le style de code
- Utiliser des type hints pour améliorer la lisibilité et permettre la vérification statique
- Utiliser des docstrings pour documenter les modules, classes et fonctions
- Utiliser des classes pour encapsuler l'état et le comportement

#### Gestion des erreurs

- Créer des exceptions personnalisées pour les erreurs spécifiques à l'application
- Utiliser des contextes (`with`) pour gérer les ressources
- Utiliser `logging` plutôt que `print` pour les messages de diagnostic
- Valider les entrées au plus tôt

### JavaScript/TypeScript

#### Structure des modules

- Utiliser ES modules (`import`/`export`) plutôt que CommonJS (`require`)
- Exporter une API claire et bien définie
- Minimiser les effets de bord
- Utiliser des modules petits et ciblés

#### Style de code

- Utiliser ESLint avec une configuration appropriée
- Préférer les fonctions fléchées pour les fonctions anonymes
- Utiliser la déstructuration pour accéder aux propriétés des objets
- Utiliser les fonctionnalités modernes de JavaScript (async/await, etc.)

#### Gestion des erreurs

- Utiliser des promesses ou async/await pour le code asynchrone
- Gérer les erreurs à tous les niveaux de la chaîne de promesses
- Créer des classes d'erreur personnalisées pour les erreurs spécifiques à l'application
- Valider les entrées au plus tôt
