---
date: 2025-04-05
title: Enseignements sur l'encodage et les caractères accentués
tags: []
related: []
---

## Enseignements sur l'encodage et les caractères accentués

1. **Encodage des fichiers PowerShell** : Les fichiers PowerShell contenant des caractères accentués français nécessitent un encodage approprié (UTF-8 avec BOM).
2. **Clés dupliquées dans les tables de hachage** : PowerShell est sensible aux clés dupliquées dans les tables de hachage (`@{}`), même si visuellement les caractères semblent différents.
3. **Solutions alternatives** :
   - Utiliser des séquences d'échappement Unicode (ex: `` `u0300 ``) plutôt que des caractères accentués directs
   - Préférer la méthode `.Replace()` des chaînes plutôt que l'opérateur `-replace` pour les caractères spéciaux
   - Éviter les tables de hachage complexes avec des caractères accentués comme clés

#

