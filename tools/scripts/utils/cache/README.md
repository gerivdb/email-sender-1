# Module LocalCache

Ce module fournit une implÃ©mentation simple et efficace d'un systÃ¨me de cache local persistant basÃ© sur la bibliothÃ¨que DiskCache.

## CaractÃ©ristiques

- **Persistance** : Les donnÃ©es sont stockÃ©es sur disque et survivent aux redÃ©marrages
- **TTL (Time-To-Live)** : Expiration automatique des Ã©lÃ©ments du cache
- **MÃ©moÃ¯sation** : DÃ©corateur pour mettre en cache les rÃ©sultats de fonctions
- **Statistiques** : Suivi des hits, misses et autres mÃ©triques
- **Configuration** : Support pour les fichiers de configuration JSON
- **Gestionnaire de contexte** : Utilisation avec `with`

## Installation

Assurez-vous d'avoir installÃ© la dÃ©pendance requise :

```bash
pip install diskcache
```

## Utilisation de base

```python
from scripts.utils.cache.local_cache import LocalCache

# CrÃ©er une instance avec les paramÃ¨tres par dÃ©faut
cache = LocalCache()

# Stocker une valeur (avec TTL de 1 heure par dÃ©faut)
cache.set("ma_cle", "ma_valeur")

# Stocker une valeur avec TTL personnalisÃ© (en secondes)
cache.set("cle_temporaire", "valeur", ttl=60)  # expire aprÃ¨s 60 secondes

# RÃ©cupÃ©rer une valeur
valeur = cache.get("ma_cle")
print(valeur)  # Affiche "ma_valeur"

# RÃ©cupÃ©rer une valeur avec une valeur par dÃ©faut
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

# CrÃ©er une instance Ã  partir d'un fichier de configuration
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

## MÃ©moÃ¯sation de fonctions

```python
from scripts.utils.cache.local_cache import LocalCache

cache = LocalCache()

# DÃ©corer une fonction pour mettre en cache ses rÃ©sultats
@cache.memoize(ttl=300)  # Cache les rÃ©sultats pendant 5 minutes
def fonction_couteuse(param):
    print(f"ExÃ©cution de la fonction coÃ»teuse avec param={param}")
    # Calcul coÃ»teux...
    return param.upper()

# Premier appel (exÃ©cute la fonction)
resultat1 = fonction_couteuse("test")
print(resultat1)  # Affiche "TEST"

# DeuxiÃ¨me appel (utilise le cache)
resultat2 = fonction_couteuse("test")
print(resultat2)  # Affiche "TEST" sans rÃ©exÃ©cuter la fonction
```

## Utilisation comme gestionnaire de contexte

```python
from scripts.utils.cache.local_cache import LocalCache

# Utiliser avec with pour fermer automatiquement le cache
with LocalCache() as cache:
    cache.set("ma_cle", "ma_valeur")
    valeur = cache.get("ma_cle")
    print(valeur)  # Affiche "ma_valeur"
# Le cache est automatiquement fermÃ© Ã  la sortie du bloc with
```

## IntÃ©gration avec le projet

Ce module est conÃ§u pour s'intÃ©grer avec la configuration de cache existante du projet. Il utilise le fichier `cache/cache_config.json` pour charger les paramÃ¨tres de configuration.

## Tests

Pour exÃ©cuter les tests unitaires :

```bash
python -m unittest tests.unit.cache.test_local_cache
```
