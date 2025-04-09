---
title: Problèmes de gestion des chemins de fichiers dans le cache disque de PSCacheManager
date: 2025-04-09T16:50:00
severity: medium
components: [cache, filesystem, powershell]
resolution: fixed
---

# Problèmes de gestion des chemins de fichiers dans le cache disque de PSCacheManager

## Description du problème
Lors de l'intégration du module PSCacheManager dans des scripts manipulant des chemins de fichiers complexes, plusieurs problèmes ont été identifiés :

1. **Chemins trop longs** : Les clés de cache basées sur des chemins complets dépassaient souvent la limite de 260 caractères de Windows, provoquant des erreurs `PathTooLongException`.

2. **Caractères invalides** : Certaines clés de cache contenaient des caractères non autorisés dans les noms de fichiers Windows (ex: `<`, `>`, `:`, `"`, etc.), causant des erreurs lors de la création des fichiers de cache.

3. **Performances dégradées** : L'accumulation de nombreux fichiers dans un seul répertoire de cache entraînait une dégradation des performances du système de fichiers.

## Impact
Ces problèmes limitaient l'utilisation du cache disque dans des scénarios réels, particulièrement lors de l'analyse de scripts avec des chemins profondément imbriqués ou des noms de fichiers contenant des caractères spéciaux.

## Solution appliquée

### 1. Normalisation des noms de fichiers
Implémentation d'une méthode `GetNormalizedCachePath` qui :
- Remplace les caractères invalides par des underscores
- Tronque les chemins trop longs et ajoute un hash MD5 pour garantir l'unicité

```powershell
# Remplacer les caractères invalides
$invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
$safeKey = $key
foreach ($char in $invalidChars) {
    $safeKey = $safeKey.Replace($char, '_')
}

# Si le chemin est trop long, utiliser un hash
if ($safeKey.Length -gt 100) {
    $hash = Get-ShortHash -InputString $key
    $shortKey = $safeKey.Substring(0, 90) + "_" + $hash
    $safeKey = $shortKey
}
```

### 2. Structure de dossiers à deux niveaux
Création d'une structure de dossiers à deux niveaux pour éviter d'avoir trop de fichiers dans un seul répertoire :

```powershell
# Créer une structure de dossiers à deux niveaux
$firstLevel = $safeKey.Substring(0, [Math]::Min(2, $safeKey.Length))
$cachePath = Join-Path -Path $CacheBasePath -ChildPath $firstLevel
```

### 3. Modification des méthodes de persistance
Mise à jour des méthodes `SaveToDisk`, `LoadFromDisk` et `RemoveFromDisk` pour utiliser la nouvelle méthode de normalisation des chemins.

## Leçons apprises

1. **Limites du système de fichiers** : Les limites de longueur de chemin et de caractères valides dans les noms de fichiers Windows doivent être prises en compte dès la conception d'un système de cache disque.

2. **Hachage pour l'unicité** : L'utilisation d'un hash MD5 tronqué (8 caractères) offre un bon compromis entre unicité et longueur de chemin.

3. **Structure de dossiers hiérarchique** : Une structure à deux niveaux améliore significativement les performances lorsque le nombre de fichiers de cache augmente.

## Prévention future

1. **Validation des clés de cache** : Encourager l'utilisation de clés de cache concises et significatives dans la documentation.

2. **Tests avec des chemins extrêmes** : Ajouter des tests unitaires spécifiques pour les chemins longs et les caractères spéciaux.

3. **Surveillance de la taille du cache** : Implémenter un mécanisme de surveillance pour éviter une croissance excessive du cache disque.

## Recommandations pour les utilisateurs du module

1. Utiliser des clés de cache concises et significatives
2. Éviter d'utiliser des chemins complets comme clés de cache
3. Configurer le chemin de base du cache dans un emplacement avec un chemin court (ex: C:\Cache)
4. Mettre en place un nettoyage périodique du cache disque
