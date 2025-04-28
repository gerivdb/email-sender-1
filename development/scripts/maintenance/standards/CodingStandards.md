# Standards de Codage pour les Scripts

Ce document dÃ©finit les standards de codage Ã  suivre pour tous les scripts du projet. Ces standards visent Ã  amÃ©liorer la lisibilitÃ©, la maintenabilitÃ© et la cohÃ©rence du code.

## Table des matiÃ¨res

1. [Standards GÃ©nÃ©raux](#standards-gÃ©nÃ©raux)
2. [Standards pour PowerShell](#standards-pour-powershell)
3. [Standards pour Python](#standards-pour-python)
4. [Standards pour les Scripts Batch](#standards-pour-les-scripts-batch)
5. [Standards pour les Scripts Shell](#standards-pour-les-scripts-shell)

## Standards GÃ©nÃ©raux

Ces standards s'appliquent Ã  tous les types de scripts.

### Structure des Fichiers

- **En-tÃªte de fichier** : Chaque script doit commencer par un en-tÃªte qui contient :
  - Nom du script
  - Description
  - Auteur
  - Date de crÃ©ation
  - Date de derniÃ¨re modification
  - Version
  - ParamÃ¨tres (si applicable)
  - Exemples d'utilisation

- **Encodage** : Tous les fichiers doivent Ãªtre encodÃ©s en UTF-8 avec BOM pour les scripts PowerShell, et UTF-8 sans BOM pour les autres types de scripts.

- **Fins de ligne** : Utiliser LF (Unix) pour les scripts Python, Shell et les fichiers de configuration. Utiliser CRLF (Windows) pour les scripts PowerShell et Batch.

### Nommage

- **Noms de fichiers** : Utiliser des noms descriptifs qui reflÃ¨tent la fonction du script.
  - PowerShell : `Verb-Noun.ps1` (utiliser des verbes approuvÃ©s)
  - Python : `snake_case.py`
  - Batch : `kebab-case.cmd` ou `kebab-case.bat`
  - Shell : `kebab-case.sh`

- **Noms de variables** : Utiliser des noms descriptifs qui reflÃ¨tent le contenu de la variable.
  - PowerShell : `PascalCase` pour les variables publiques, `camelCase` pour les variables locales
  - Python : `snake_case`
  - Batch : `UPPER_SNAKE_CASE`
  - Shell : `snake_case`

- **Noms de fonctions** : Utiliser des noms descriptifs qui reflÃ¨tent l'action de la fonction.
  - PowerShell : `Verb-Noun` (utiliser des verbes approuvÃ©s)
  - Python : `snake_case`
  - Batch : `kebab-case` ou `snake_case`
  - Shell : `snake_case`

### Documentation

- **Commentaires** : Ajouter des commentaires pour expliquer le "pourquoi" plutÃ´t que le "comment".
  - Ã‰viter les commentaires Ã©vidents qui rÃ©pÃ¨tent simplement le code.
  - Documenter les parties complexes ou non intuitives du code.
  - Utiliser des commentaires de section pour diviser le code en sections logiques.

- **Documentation des fonctions** : Chaque fonction doit Ãªtre documentÃ©e avec :
  - Description
  - ParamÃ¨tres (avec types et descriptions)
  - Valeur de retour (avec type et description)
  - Exemples d'utilisation (si nÃ©cessaire)

### Organisation du Code

- **Indentation** : Utiliser 4 espaces pour l'indentation (pas de tabulations).

- **Longueur des lignes** : Limiter les lignes Ã  120 caractÃ¨res maximum.

- **Espacement** : Utiliser des lignes vides pour sÃ©parer les sections logiques du code.

- **Ordre des sections** : Organiser le code dans l'ordre suivant :
  1. En-tÃªte du fichier
  2. Importations / Inclusions
  3. DÃ©clarations de variables globales
  4. DÃ©finitions de fonctions
  5. Code principal

## Standards pour PowerShell

### Style de Code

- **Verbes approuvÃ©s** : Utiliser uniquement les verbes approuvÃ©s pour les noms de fonctions et de cmdlets. Voir la liste complÃ¨te avec `Get-Verb`.

- **ParamÃ¨tres** : Utiliser le bloc `param()` au dÃ©but du script ou de la fonction pour dÃ©clarer les paramÃ¨tres.
  - Utiliser les attributs `[Parameter()]` pour dÃ©finir les propriÃ©tÃ©s des paramÃ¨tres.
  - Utiliser les attributs de validation (`[ValidateNotNullOrEmpty()]`, etc.) pour valider les entrÃ©es.

- **Types** : DÃ©clarer explicitement les types des paramÃ¨tres et des variables lorsque c'est possible.

- **Gestion des erreurs** : Utiliser `try/catch` pour gÃ©rer les erreurs.
  - Utiliser `$ErrorActionPreference = 'Stop'` au dÃ©but du script pour que les erreurs non gÃ©rÃ©es arrÃªtent l'exÃ©cution.
  - Utiliser `-ErrorAction Stop` pour les cmdlets qui peuvent gÃ©nÃ©rer des erreurs.

- **Logging** : Utiliser une fonction de logging cohÃ©rente dans tous les scripts.
  - DÃ©finir diffÃ©rents niveaux de log (INFO, WARNING, ERROR, etc.).
  - Inclure un timestamp dans les messages de log.

- **Retour de valeurs** : Ã‰viter d'utiliser `Write-Output` ou `Write-Host` pour retourner des valeurs. Utiliser plutÃ´t `return` ou laisser la valeur Ãªtre retournÃ©e implicitement.

- **Comparaisons** : Placer `$null` Ã  gauche lors des comparaisons avec `$null` (ex: `if ($null -eq $variable)`).

- **Chemins de fichiers** : Utiliser `Join-Path` pour construire des chemins de fichiers.

### Structure des Scripts

- **Modules** : Pour les scripts complexes, envisager de les organiser en modules PowerShell.

- **Fonctions** : Diviser le code en fonctions rÃ©utilisables avec une responsabilitÃ© unique.

- **Commentaires de rÃ©gion** : Utiliser `#region` et `#endregion` pour organiser le code en sections.

### Exemple d'en-tÃªte de script PowerShell

```powershell
<#
.SYNOPSIS
    BrÃ¨ve description du script.
.DESCRIPTION
    Description dÃ©taillÃ©e du script.
.PARAMETER Param1
    Description du premier paramÃ¨tre.
.PARAMETER Param2
    Description du deuxiÃ¨me paramÃ¨tre.
.EXAMPLE
    .\Script-Name.ps1 -Param1 Value1 -Param2 Value2
    Description de ce que fait cet exemple.
.NOTES
    Nom du fichier    : Script-Name.ps1
    Auteur           : Nom de l'auteur
    Date de crÃ©ation  : YYYY-MM-DD
    DerniÃ¨re modification : YYYY-MM-DD
    Version          : 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, HelpMessage="Description du paramÃ¨tre")]
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
  1. Modules de la bibliothÃ¨que standard
  2. Modules tiers
  3. Modules locaux
  - SÃ©parer chaque groupe par une ligne vide.

- **Classes** : Suivre les principes de la programmation orientÃ©e objet.
  - Utiliser des mÃ©thodes de classe (`@classmethod`) et des mÃ©thodes statiques (`@staticmethod`) lorsque c'est appropriÃ©.

- **Type Hints** : Utiliser des annotations de type pour les paramÃ¨tres et les valeurs de retour.

- **Gestion des erreurs** : Utiliser des blocs `try/except` pour gÃ©rer les erreurs.
  - Capturer des exceptions spÃ©cifiques plutÃ´t que d'utiliser un bloc `except` gÃ©nÃ©rique.

- **Contextes** : Utiliser des gestionnaires de contexte (`with`) pour les ressources qui doivent Ãªtre nettoyÃ©es.

### Structure des Scripts

- **Modules** : Organiser le code en modules et packages.

- **Main** : Utiliser la clause `if __name__ == "__main__":` pour le code qui doit Ãªtre exÃ©cutÃ© lorsque le script est lancÃ© directement.

### Exemple d'en-tÃªte de script Python

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Nom du script : script_name.py
Description : BrÃ¨ve description du script.
Auteur : Nom de l'auteur
Date de crÃ©ation : YYYY-MM-DD
DerniÃ¨re modification : YYYY-MM-DD
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
    """Point d'entrÃ©e principal du script."""
    # Code principal

if __name__ == "__main__":
    main()
```

## Standards pour les Scripts Batch

### Style de Code

- **Variables** : Utiliser des noms en majuscules pour les variables.
  - Initialiser les variables avec `set` (ex: `set "VAR=value"`).

- **Commentaires** : Utiliser `::` pour les commentaires.

- **Labels** : Utiliser des noms descriptifs pour les labels, prÃ©fixÃ©s par `:`.

- **Gestion des erreurs** : Utiliser `if errorlevel 1` pour vÃ©rifier les codes de retour.

- **Chemins** : Toujours mettre les chemins entre guillemets pour gÃ©rer les espaces.

### Structure des Scripts

- **Sections** : Diviser le script en sections avec des labels.

- **Fonctions** : Utiliser des labels comme fonctions, avec `call :label` pour les appeler.

### Exemple d'en-tÃªte de script Batch

```batch
@echo off
setlocal enabledelayedexpansion

::-----------------------------------------------------------------------------
:: Nom du script : script-name.cmd
:: Description   : BrÃ¨ve description du script.
:: Auteur        : Nom de l'auteur
:: Date de crÃ©ation : YYYY-MM-DD
:: DerniÃ¨re modification : YYYY-MM-DD
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
  - Toujours utiliser `${VAR}` plutÃ´t que `$VAR` pour Ã©viter les ambiguÃ¯tÃ©s.

- **Commentaires** : Utiliser `#` pour les commentaires.

- **Fonctions** : DÃ©finir des fonctions avec `function_name() { ... }`.

- **Gestion des erreurs** : Utiliser `set -e` pour arrÃªter le script en cas d'erreur.
  - Utiliser `trap` pour nettoyer avant de quitter.

- **Chemins** : Toujours mettre les chemins entre guillemets pour gÃ©rer les espaces.

### Structure des Scripts

- **Fonctions** : Diviser le code en fonctions rÃ©utilisables.

- **Main** : Utiliser une fonction `main` comme point d'entrÃ©e principal.

### Exemple d'en-tÃªte de script Shell

```bash
#!/bin/bash
#-----------------------------------------------------------------------------
# Nom du script : script-name.sh
# Description   : BrÃ¨ve description du script.
# Auteur        : Nom de l'auteur
# Date de crÃ©ation : YYYY-MM-DD
# DerniÃ¨re modification : YYYY-MM-DD
# Version       : 1.0
#
# Utilisation   : ./script-name.sh [arg1] [arg2]
#-----------------------------------------------------------------------------

# ArrÃªter le script en cas d'erreur
set -e

# Code du script

main() {
    # Code principal
}

# Appel de la fonction principale
main "$@"
```

## Conclusion

Ces standards de codage sont conÃ§us pour amÃ©liorer la qualitÃ© et la maintenabilitÃ© du code. Ils doivent Ãªtre suivis par tous les dÃ©veloppeurs travaillant sur le projet. Des exceptions peuvent Ãªtre faites dans des cas particuliers, mais elles doivent Ãªtre documentÃ©es et justifiÃ©es.

Les outils d'analyse de code et de formatage automatique seront utilisÃ©s pour vÃ©rifier et appliquer ces standards.
