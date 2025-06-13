---
date: 2025-04-05
title: Bonnes pratiques de codage PowerShell
tags: []
related: []
---

## Bonnes pratiques de codage PowerShell

1. **Éviter les variables non utilisées** : Les variables déclarées mais non utilisées génèrent des avertissements et peuvent indiquer des problèmes potentiels.
2. **Utilisation de Write-Host** : Bien que pratique, `Write-Host` n'est pas recommandé dans les scripts professionnels. Alternatives : `Write-Output`, `Write-Verbose` ou `Write-Information`.
3. **Espaces en fin de ligne** : Les espaces en fin de ligne sont considérés comme une mauvaise pratique et génèrent des avertissements.
4. **Verbes d'action dans les noms de fonctions** : Les fonctions qui modifient l'état du système devraient implémenter le paramètre `ShouldProcess`.

#

