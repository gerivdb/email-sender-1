# Standards de Codage pour les Scripts

Ce document définit les standards de codage à suivre pour tous les scripts du projet. Ces standards visent à améliorer la lisibilité, la maintenabilité et la cohérence du code.

## Table des matières

1. [Standards Généraux](#standards-généraux)
2. [Standards pour PowerShell](#standards-pour-powershell)
3. [Standards pour Python](#standards-pour-python)
4. [Standards pour les Scripts Batch](#standards-pour-les-scripts-batch)
5. [Standards pour les Scripts Shell](#standards-pour-les-scripts-shell)

## Standards Généraux

Ces standards s'appliquent à tous les types de scripts.

### Structure des Fichiers

- **En-tête de fichier** : Chaque script doit commencer par un en-tête qui contient :
  - Nom du script
  - Description
  - Auteur
  - Date de création
  - Date de dernière modification
  - Version
  - Paramètres (si applicable)
  - Exemples d'utilisation

- **Encodage** : Tous les fichiers doivent être encodés en UTF-8 avec BOM pour les scripts PowerShell, et UTF-8 sans BOM pour les autres types de scripts.

- **Fins de ligne** : Utiliser LF (Unix) pour les scripts Python, Shell et les fichiers de configuration. Utiliser CRLF (Windows) pour les scripts PowerShell et Batch.

### Nommage

- **Noms de fichiers** : Utiliser des noms descriptifs qui reflètent la fonction du script.
  - PowerShell : `Verb-Noun.ps1` (utiliser des verbes approuvés)
  - Python : `snake_case.py`
  - Batch : `kebab-case.cmd` ou `kebab-case.bat`
  - Shell : `kebab-case.sh`

- **Noms de variables** : Utiliser des noms descriptifs qui reflètent le contenu de la variable.
  - PowerShell : `PascalCase` pour les variables publiques, `camelCase` pour les variables locales
  - Python : `snake_case`
  - Batch : `UPPER_SNAKE_CASE`
  - Shell : `snake_case`

- **Noms de fonctions** : Utiliser des noms descriptifs qui reflètent l'action de la fonction.
  - PowerShell : `Verb-Noun` (utiliser des verbes approuvés)
  - Python : `snake_case`
  - Batch : `kebab-case` ou `snake_case`
  - Shell : `snake_case`

### Documentation

- **Commentaires** : Ajouter des commentaires pour expliquer le "pourquoi" plutôt que le "comment".
  - Éviter les commentaires évidents qui répètent simplement le code.
  - Documenter les parties complexes ou non intuitives du code.
  - Utiliser des commentaires de section pour diviser le code en sections logiques.

- **Documentation des fonctions** : Chaque fonction doit être documentée avec :
  - Description
  - Paramètres (avec types et descriptions)
  - Valeur de retour (avec type et description)
  - Exemples d'utilisation (si nécessaire)

### Organisation du Code

- **Indentation** : Utiliser 4 espaces pour l'indentation (pas de tabulations).

- **Longueur des lignes** : Limiter les lignes à 120 caractères maximum.

- **Espacement** : Utiliser des lignes vides pour séparer les sections logiques du code.

- **Ordre des sections** : Organiser le code dans l'ordre suivant :
  1. En-tête du fichier
  2. Importations / Inclusions
  3. Déclarations de variables globales
  4. Définitions de fonctions
  5. Code principal

## Standards pour PowerShell

### Style de Code

- **Verbes approuvés** : Utiliser uniquement les verbes approuvés pour les noms de fonctions et de cmdlets. Voir la liste complète avec `Get-Verb`.

- **Paramètres** : Utiliser le bloc `param()` au début du script ou de la fonction pour déclarer les paramètres.
  - Utiliser les attributs `[Parameter()]` pour définir les propriétés des paramètres.
  - Utiliser les attributs de validation (`[ValidateNotNullOrEmpty()]`, etc.) pour valider les entrées.

- **Types** : Déclarer explicitement les types des paramètres et des variables lorsque c'est possible.

- **Gestion des erreurs** : Utiliser `try/catch` pour gérer les erreurs.
  - Utiliser `$ErrorActionPreference = 'Stop'` au début du script pour que les erreurs non gérées arrêtent l'exécution.
  - Utiliser `-ErrorAction Stop` pour les cmdlets qui peuvent générer des erreurs.

- **Logging** : Utiliser une fonction de logging cohérente dans tous les scripts.
  - Définir différents niveaux de log (INFO, WARNING, ERROR, etc.).
  - Inclure un timestamp dans les messages de log.

- **Retour de valeurs** : Éviter d'utiliser `Write-Output` ou `Write-Host` pour retourner des valeurs. Utiliser plutôt `return` ou laisser la valeur être retournée implicitement.

- **Comparaisons** : Placer `$null` à gauche lors des comparaisons avec `$null` (ex: `if ($null -eq $variable)`).

- **Chemins de fichiers** : Utiliser `Join-Path` pour construire des chemins de fichiers.

### Structure des Scripts

- **Modules** : Pour les scripts complexes, envisager de les organiser en modules PowerShell.

- **Fonctions** : Diviser le code en fonctions réutilisables avec une responsabilité unique.

- **Commentaires de région** : Utiliser `#region` et `#endregion` pour organiser le code en sections.

### Exemple d'en-tête de script PowerShell

```powershell
<#
.SYNOPSIS
    Brève description du script.
.DESCRIPTION
    Description détaillée du script.
.PARAMETER Param1
    Description du premier paramètre.
.PARAMETER Param2
    Description du deuxième paramètre.
.EXAMPLE
    .\Script-Name.ps1 -Param1 Value1 -Param2 Value2
    Description de ce que fait cet exemple.
.NOTES
    Nom du fichier    : Script-Name.ps1
    Auteur           : Nom de l'auteur
    Date de création  : YYYY-MM-DD
    Dernière modification : YYYY-MM-DD
    Version          : 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, HelpMessage="Description du paramètre")]
    [string]$Param1,
    
    [Parameter(Mandatory=$false)]
    [int]$Param2 = 0
)

# Code du script
```

## Standards pour Python

### Style de Code

- **PEP 8** : Suivre les recommandations de PEP 8 pour le style de code Python.

- **Docstrings** : Utiliser des docstrings pour documenter les modules, classes et fonctions.
  - Utiliser le format Google, NumPy ou reStructuredText.

- **Imports** : Organiser les imports dans l'ordre suivant :
  1. Modules de la bibliothèque standard
  2. Modules tiers
  3. Modules locaux
  - Séparer chaque groupe par une ligne vide.

- **Classes** : Suivre les principes de la programmation orientée objet.
  - Utiliser des méthodes de classe (`@classmethod`) et des méthodes statiques (`@staticmethod`) lorsque c'est approprié.

- **Type Hints** : Utiliser des annotations de type pour les paramètres et les valeurs de retour.

- **Gestion des erreurs** : Utiliser des blocs `try/except` pour gérer les erreurs.
  - Capturer des exceptions spécifiques plutôt que d'utiliser un bloc `except` générique.

- **Contextes** : Utiliser des gestionnaires de contexte (`with`) pour les ressources qui doivent être nettoyées.

### Structure des Scripts

- **Modules** : Organiser le code en modules et packages.

- **Main** : Utiliser la clause `if __name__ == "__main__":` pour le code qui doit être exécuté lorsque le script est lancé directement.

### Exemple d'en-tête de script Python

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Nom du script : script_name.py
Description : Brève description du script.
Auteur : Nom de l'auteur
Date de création : YYYY-MM-DD
Dernière modification : YYYY-MM-DD
Version : 1.0

Exemples d'utilisation :
    python script_name.py arg1 arg2
    python script_name.py --option value
"""

import sys
import os
from typing import List, Dict, Optional

# Code du script

def main():
    """Point d'entrée principal du script."""
    # Code principal

if __name__ == "__main__":
    main()
```

## Standards pour les Scripts Batch

### Style de Code

- **Variables** : Utiliser des noms en majuscules pour les variables.
  - Initialiser les variables avec `set` (ex: `set "VAR=value"`).

- **Commentaires** : Utiliser `::` pour les commentaires.

- **Labels** : Utiliser des noms descriptifs pour les labels, préfixés par `:`.

- **Gestion des erreurs** : Utiliser `if errorlevel 1` pour vérifier les codes de retour.

- **Chemins** : Toujours mettre les chemins entre guillemets pour gérer les espaces.

### Structure des Scripts

- **Sections** : Diviser le script en sections avec des labels.

- **Fonctions** : Utiliser des labels comme fonctions, avec `call :label` pour les appeler.

### Exemple d'en-tête de script Batch

```batch
@echo off
setlocal enabledelayedexpansion

::-----------------------------------------------------------------------------
:: Nom du script : script-name.cmd
:: Description   : Brève description du script.
:: Auteur        : Nom de l'auteur
:: Date de création : YYYY-MM-DD
:: Dernière modification : YYYY-MM-DD
:: Version       : 1.0
::
:: Utilisation   : script-name.cmd [arg1] [arg2]
::-----------------------------------------------------------------------------

:: Code du script
```

## Standards pour les Scripts Shell

### Style de Code

- **Shebang** : Commencer par `#!/bin/bash` ou `#!/bin/sh` selon les besoins.

- **Variables** : Utiliser des noms en minuscules pour les variables.
  - Toujours utiliser `${VAR}` plutôt que `$VAR` pour éviter les ambiguïtés.

- **Commentaires** : Utiliser `#` pour les commentaires.

- **Fonctions** : Définir des fonctions avec `function_name() { ... }`.

- **Gestion des erreurs** : Utiliser `set -e` pour arrêter le script en cas d'erreur.
  - Utiliser `trap` pour nettoyer avant de quitter.

- **Chemins** : Toujours mettre les chemins entre guillemets pour gérer les espaces.

### Structure des Scripts

- **Fonctions** : Diviser le code en fonctions réutilisables.

- **Main** : Utiliser une fonction `main` comme point d'entrée principal.

### Exemple d'en-tête de script Shell

```bash
#!/bin/bash
#-----------------------------------------------------------------------------
# Nom du script : script-name.sh
# Description   : Brève description du script.
# Auteur        : Nom de l'auteur
# Date de création : YYYY-MM-DD
# Dernière modification : YYYY-MM-DD
# Version       : 1.0
#
# Utilisation   : ./script-name.sh [arg1] [arg2]
#-----------------------------------------------------------------------------

# Arrêter le script en cas d'erreur
set -e

# Code du script

main() {
    # Code principal
}

# Appel de la fonction principale
main "$@"
```

## Conclusion

Ces standards de codage sont conçus pour améliorer la qualité et la maintenabilité du code. Ils doivent être suivis par tous les développeurs travaillant sur le projet. Des exceptions peuvent être faites dans des cas particuliers, mais elles doivent être documentées et justifiées.

Les outils d'analyse de code et de formatage automatique seront utilisés pour vérifier et appliquer ces standards.
