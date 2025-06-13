# Bonnes Pratiques PowerShell

Ce document présente les bonnes pratiques à suivre lors de l'écriture de scripts PowerShell dans le cadre du projet.

## Table des matières

- [Structure des scripts](#structure-des-scripts)

- [Gestion des erreurs](#gestion-des-erreurs)

- [Paramètres et arguments](#paramètres-et-arguments)

- [Exécution en mode batch](#exécution-en-mode-batch)

- [Logging](#logging)

- [Performance](#performance)

- [Sécurité](#sécurité)

## Structure des scripts

- Utilisez toujours un bloc `[CmdletBinding()]` pour vos scripts
- Documentez vos fonctions et scripts avec des commentaires basés sur le format d'aide
- Organisez votre code en fonctions réutilisables
- Suivez une convention de nommage cohérente (Verb-Noun pour les fonctions)
- Utilisez des verbes approuvés par PowerShell (`Get-Verb` pour voir la liste)

## Gestion des erreurs

- Utilisez `$ErrorActionPreference = 'Stop'` au début de vos scripts
- Implémentez des blocs `try/catch` pour gérer les erreurs de manière appropriée
- Utilisez `Write-Error` pour signaler des erreurs
- Retournez des codes d'erreur appropriés avec `exit`

## Paramètres et arguments

- Utilisez des paramètres nommés plutôt que des arguments positionnels
- Définissez des valeurs par défaut pour les paramètres optionnels
- Utilisez des types de données appropriés pour les paramètres
- Validez les entrées avec des attributs de validation

## Exécution en mode batch

### Exécuter un script PowerShell en batch sans confirmations

| Étape | Commande / Action | Notes rapides |
|------|-------------------|---------------|
| 1 |**Ouvrir** une console PowerShell (admin si nécessaire) | `Win + X → Windows Terminal (Admin)` |
| 2 |**Débloquer** le script par session : <br>`Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force` | Bypass temporaire – ne touche pas la politique système |
| 3 |**Lancer** votre script avec le switch **-Force** : <br>`& "D:\scripts\Batch-Update.ps1" -Force -OtherParam "xyz"` | Le `&` appelle le fichier ; tous les autres paramètres suivent |
| 4 |Si votre script *n'expose pas* encore le paramètre **-Force**, ajoutez-le : |  |
|  |```powershell
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Force,
    [string]$Path = "."
)

if (-not $Force) {
    if (-not (Get-YesNo "OK to modify $Path ?")) { return }
}
# … modifications par lot ici …

```| `SupportsShouldProcess` active aussi `-Confirm` / `-WhatIf` |
| 5 |**À l'intérieur** du script, pour les cmdlets natives :<br>`Remove-Item $file -Recurse -Force -Confirm:$false` | `-Confirm:$false` = aucun prompt même si `SupportsShouldProcess` |

#### Bonnes pratiques pour l'exécution en mode batch

- **Toujours** prévoir un dry-run : `YourScript.ps1 -WhatIf` (grâce à *ShouldProcess*).
- Documenter que le mode **batch** est déclenché par **-Force** (exemples dans vos guides : `Start-ModelTraining -Force`)
- Conserver des sauvegardes ou un contrôle de version avant des suppressions massives.
- En production, préférer `-Confirm:$false` sur les cmdlets unitaires plutôt que de supprimer toutes les confirmations globalement.

## Logging

- Utilisez `Write-Verbose` pour les messages de débogage
- Utilisez `Write-Information` pour les messages d'information
- Utilisez `Write-Warning` pour les avertissements
- Implémentez un système de journalisation pour les scripts critiques

## Performance

- Évitez d'utiliser `ForEach-Object` et `Where-Object` pour de grandes collections
- Utilisez des tableaux et des hashtables pour stocker des données en mémoire
- Utilisez `ForEach` au lieu de `ForEach-Object` pour de meilleures performances
- Utilisez `ForEach-Object -Parallel` pour les opérations parallèles (PowerShell 7+)

## Sécurité

- N'incluez jamais de mots de passe ou d'informations sensibles en clair dans vos scripts
- Utilisez `SecureString` pour les mots de passe et les informations sensibles
- Utilisez des mécanismes d'authentification sécurisés
- Validez toutes les entrées utilisateur
