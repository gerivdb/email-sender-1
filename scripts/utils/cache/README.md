# Module LocalCache

Ce module fournit une implémentation simple et efficace d'un système de cache local persistant basé sur la bibliothèque DiskCache.

## Caractéristiques

- **Persistance** : Les données sont stockées sur disque et survivent aux redémarrages
- **TTL (Time-To-Live)** : Expiration automatique des éléments du cache
- **Mémoïsation** : Décorateur pour mettre en cache les résultats de fonctions
- **Statistiques** : Suivi des hits, misses et autres métriques
- **Configuration** : Support pour les fichiers de configuration JSON
- **Gestionnaire de contexte** : Utilisation avec `with`

## Installation

Assurez-vous d'avoir installé la dépendance requise :

```bash
pip install diskcache
```

## Utilisation de base

```python
from scripts.utils.cache.local_cache import LocalCache

# Créer une instance avec les paramètres par défaut
cache = LocalCache()

# Stocker une valeur (avec TTL de 1 heure par défaut)
cache.set("ma_cle", "ma_valeur")

# Stocker une valeur avec TTL personnalisé (en secondes)
cache.set("cle_temporaire", "valeur", ttl=60)  # expire après 60 secondes

# Récupérer une valeur
valeur = cache.get("ma_cle")
print(valeur)  # Affiche "ma_valeur"

# Récupérer une valeur avec une valeur par défaut
valeur = cache.get("cle_inexistante", "valeur_par_defaut")
print(valeur)  # Affiche "valeur_par_defaut"

# Supprimer une valeur
cache.delete("ma_cle")

# Vider le cache
cache.clear()

# Obtenir des statistiques
stats = cache.get_statistics()
print(stats)
```

## Utilisation avec un fichier de configuration

```python
from scripts.utils.cache.local_cache import LocalCache, create_cache_from_config

# Créer une instance à partir d'un fichier de configuration
cache = LocalCache(config_path="chemin/vers/config.json")

# Ou utiliser la fonction utilitaire
cache = create_cache_from_config("chemin/vers/config.json")
```

Format du fichier de configuration :

```json
{
    "DefaultTTL": 3600,
    "MaxDiskSize": 1000,
    "CachePath": "D:\\chemin\\vers\\cache",
    "EvictionPolicy": "LRU"
}
```

## Mémoïsation de fonctions

```python
from scripts.utils.cache.local_cache import LocalCache

cache = LocalCache()

# Décorer une fonction pour mettre en cache ses résultats
@cache.memoize(ttl=300)  # Cache les résultats pendant 5 minutes
def fonction_couteuse(param):
    print(f"Exécution de la fonction coûteuse avec param={param}")
    # Calcul coûteux...
    return param.upper()

# Premier appel (exécute la fonction)
resultat1 = fonction_couteuse("test")
print(resultat1)  # Affiche "TEST"

# Deuxième appel (utilise le cache)
resultat2 = fonction_couteuse("test")
print(resultat2)  # Affiche "TEST" sans réexécuter la fonction
```

## Utilisation comme gestionnaire de contexte

```python
from scripts.utils.cache.local_cache import LocalCache

# Utiliser avec with pour fermer automatiquement le cache
with LocalCache() as cache:
    cache.set("ma_cle", "ma_valeur")
    valeur = cache.get("ma_cle")
    print(valeur)  # Affiche "ma_valeur"
# Le cache est automatiquement fermé à la sortie du bloc with
```

## Intégration avec le projet

Ce module est conçu pour s'intégrer avec la configuration de cache existante du projet. Il utilise le fichier `cache/cache_config.json` pour charger les paramètres de configuration.

## Tests

Pour exécuter les tests unitaires :

```bash
python -m unittest tests.unit.cache.test_local_cache
```
