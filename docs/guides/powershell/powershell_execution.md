# Exécution PowerShell

Ce document décrit les bonnes pratiques et directives spécifiques à l'exécution de scripts PowerShell.

## PS_EXEC
- **VERBS** : 
  - `validate_against(dictionary)` : Valider les verbes utilisés contre le dictionnaire des verbes approuvés

- **SIZE** : 
  - `premeasure_UTF8(input)` : Mesurer à l'avance la taille UTF-8 de l'entrée

- **STRUCTURE** : 
  - `auto_template(parsable)` : Utiliser un modèle automatique analysable

- **MODULARITY** : 
  - `1_function = 1_responsibility` : Une fonction = une responsabilité

- **OPTIMIZE** : 
  - `compact_syntax()` : Utiliser une syntaxe compacte

## Conventions de nommage

- Utiliser les verbes approuvés pour les noms de fonctions (Get-, Set-, New-, Remove-, etc.)
- Utiliser le format PascalCase pour les noms de fonctions et de variables publiques
- Utiliser le format camelCase pour les variables locales
- Préfixer les variables privées avec un underscore (_)

## Gestion des erreurs

- Utiliser try/catch pour gérer les exceptions
- Utiliser $ErrorActionPreference = 'Stop' pour arrêter l'exécution en cas d'erreur
- Utiliser Write-Error pour signaler les erreurs
- Utiliser -ErrorAction pour contrôler le comportement en cas d'erreur

## Bonnes pratiques

- Utiliser [CmdletBinding()] pour les fonctions avancées
- Utiliser SupportsShouldProcess pour les fonctions qui modifient l'état du système
- Utiliser les paramètres obligatoires avec [Parameter(Mandatory=$true)]
- Utiliser les commentaires d'aide pour documenter les fonctions
- Utiliser les types de retour avec [OutputType()]
- Utiliser les validations de paramètres avec [ValidateNotNullOrEmpty()], etc.
- Vérifier les valeurs null avec $null -eq $variable (et non l'inverse)
- Utiliser les pipelines pour chaîner les commandes
- Utiliser les alias uniquement dans les scripts interactifs, pas dans les scripts partagés
