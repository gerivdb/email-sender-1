# Bonnes Pratiques pour l'Utilisation de Qdrant dans le MCP Manager

*Version 1.0 - 2025-05-19*

Ce document présente les meilleures pratiques pour l'utilisation de Qdrant comme base de données vectorielle dans notre système MCP Manager, en se basant sur la documentation officielle et les recommandations de Qdrant.

## 1. Choix de Configuration Matérielle

### 1.1 Scénarios d'utilisation

Qdrant propose deux scénarios principaux d'utilisation en termes de consommation de ressources :

- **Optimisé pour les performances** : Lorsque vous devez servir des recherches vectorielles aussi rapidement que possible. Dans ce cas, il faut avoir autant de données vectorielles en RAM que possible.
- **Optimisé pour le stockage** : Lorsque vous devez stocker de nombreux vecteurs et minimiser les coûts en compromettant la vitesse de recherche. Dans ce cas, l'attention doit être portée sur la vitesse du disque.

### 1.2 Recommandations matérielles

- **CPU** : Architecture 64 bits (x86_64/amd64 ou AArch64/arm64)
- **RAM** : Dépend du nombre de vecteurs, de leurs dimensions et de la configuration de quantification
- **Stockage** : SSD ou NVMe recommandé pour les performances optimales (au moins 50k IOPS)
- **Système de fichiers** : Compatible POSIX avec accès au niveau des blocs

## 2. Méthodes de Quantification

La quantification est une technique qui permet de réduire l'empreinte mémoire et d'accélérer le processus de recherche dans les espaces vectoriels de haute dimension.

### 2.1 Comparaison des méthodes

| Méthode | Précision | Vitesse | Compression | Cas d'utilisation |
|---------|-----------|---------|-------------|-------------------|
| Scalaire | 0.99 | jusqu'à x2 | 4 | Méthode universelle, bon équilibre entre précision, vitesse et compression |
| Produit | 0.7 | 0.5 | jusqu'à 64 | Lorsque l'empreinte mémoire est la priorité absolue |
| Binaire | 0.95* | jusqu'à x40 | 32 | La plus rapide, mais nécessite une distribution centrée des composants vectoriels |

*\* pour les modèles compatibles*

### 2.2 Modèles testés avec la quantification binaire

- OpenAI `text-embedding-ada-002` - 1536d
- Cohere AI `embed-english-v2.0` - 4096d

## 3. Stratégies d'Optimisation

### 3.1 Recherche rapide avec faible utilisation de mémoire

```json
{
    "vectors": {
        "size": 768,
        "distance": "Cosine",
        "on_disk": true
    },
    "quantization_config": {
        "scalar": {
            "type": "int8",
            "always_ram": true
        }
    }
}
```plaintext
- Stocke les vecteurs originaux sur disque
- Compresse les vecteurs quantifiés en `int8`
- Garde les vecteurs quantifiés en RAM

Option supplémentaire : Désactiver le rescoring pour des recherches encore plus rapides
```json
{
    "params": {
        "quantization": {
            "rescore": false
        }
    }
}
```plaintext
### 3.2 Haute précision avec faible utilisation de mémoire

```json
{
    "vectors": {
        "size": 768,
        "distance": "Cosine",
        "on_disk": true
    },
    "hnsw_config": {
        "on_disk": true,
        "m": 64,
        "ef_construct": 512
    }
}
```plaintext
- Stocke les vecteurs et l'index HNSW sur disque
- Augmente les paramètres `m` et `ef_construct` pour améliorer la précision

### 3.3 Haute précision avec recherche rapide

```json
{
    "vectors": {
        "size": 768,
        "distance": "Cosine"
    },
    "quantization_config": {
        "scalar": {
            "type": "int8",
            "always_ram": true
        }
    }
}
```plaintext
- Garde les vecteurs en RAM
- Applique la quantification scalaire avec rescoring pour une précision ajustable

## 4. Équilibrage Latence et Débit

### 4.1 Minimiser la latence

```json
{
    "optimizers_config": {
        "default_segment_number": 16
    }
}
```plaintext
- Définit le nombre de segments égal au nombre de cœurs du système
- Chaque segment est traité en parallèle

### 4.2 Maximiser le débit

```json
{
    "optimizers_config": {
        "default_segment_number": 2,
        "max_segment_size": 5000000
    }
}
```plaintext
- Utilise moins de segments mais plus grands
- Bénéficie de la taille de l'index et du nombre global plus petit de comparaisons vectorielles

## 5. Conseils pour l'Ajustement des Performances

### 5.1 Ajustement de la précision

- **Ajuster le paramètre `quantile`** : Détermine les limites de quantification. Une valeur inférieure à 1.0 exclut les valeurs extrêmes.
- **Activer le rescoring** : Réévalue les résultats de recherche top-k en utilisant les vecteurs originaux.
- **Utiliser l'oversampling** : Définit combien de vecteurs supplémentaires doivent être présélectionnés à l'aide de l'index quantifié.

### 5.2 Ajustement de la mémoire et de la vitesse

Trois modes de placement du stockage des vecteurs :

1. **Tout en RAM** : Tous les vecteurs, originaux et quantifiés, sont chargés et conservés en RAM.
2. **Originaux sur disque, quantifiés en RAM** : Mode hybride, bon équilibre entre vitesse et utilisation de la mémoire.
3. **Tout sur disque** : Tous les vecteurs sont stockés sur disque. Empreinte mémoire minimale, mais au détriment de la vitesse.

### 5.3 Paramètres de recherche

- **`hnsw_ef`** : Nombre de voisins à visiter pendant la recherche (valeur plus élevée = meilleure précision, vitesse plus lente).
- **`exact`** : Définir sur `true` pour une recherche exacte, plus lente mais plus précise.

## 6. Résolution des Problèmes Courants

### 6.1 Utilisation élevée de la mémoire malgré la configuration sur disque

- Les métriques d'utilisation de la mémoire comme rapportées par `top` ou `htop` peuvent être trompeuses.
- Qdrant utilise des techniques pour réduire la latence de recherche, y compris la mise en cache des données du disque en RAM.
- Pour limiter l'utilisation de la mémoire, utilisez des limites dans Docker ou Kubernetes.

### 6.2 Requêtes lentes ou expiration

Causes possibles :
- **Utilisation de filtres sans index de payload** : Assurez-vous d'avoir correctement configuré les index de payload.
- **Utilisation du stockage de vecteurs sur disque avec des disques lents** : Utilisez des SSD locaux avec au moins 50k IOPS.
- **Limite importante ou paramètres de requête non optimaux** : Une limite ou un décalage important peut entraîner une dégradation significative des performances.

## 7. Recommandations pour notre MCP Manager

1. **Utiliser la quantification scalaire** comme méthode par défaut pour un bon équilibre entre précision et performance
2. **Configurer le mode hybride** (vecteurs originaux sur disque, quantifiés en RAM) pour optimiser l'utilisation des ressources
3. **Ajuster les paramètres HNSW** en fonction des besoins spécifiques de précision et de vitesse
4. **Implémenter un système de surveillance** pour suivre les performances et ajuster les configurations si nécessaire
5. **Créer des snapshots réguliers** pour sauvegarder les données et faciliter la migration
6. **Utiliser des index de payload** pour optimiser les recherches avec filtres
7. **Adapter la stratégie de segmentation** en fonction de l'objectif (latence vs débit)
8. **Tester différentes configurations** pour trouver l'équilibre optimal pour chaque cas d'utilisation
