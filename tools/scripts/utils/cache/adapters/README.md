# Adaptateurs de cache

Ce module fournit des adaptateurs de cache pour différents types de requêtes et d'API.

## Adaptateurs disponibles

- **CacheAdapter** : Interface abstraite pour les adaptateurs de cache
- **HttpCacheAdapter** : Adaptateur pour les requêtes HTTP génériques
- **N8nCacheAdapter** : Adaptateur spécifique pour l'API n8n

## Installation

Assurez-vous d'avoir installé les dépendances requises :

```bash
pip install requests diskcache
```

## Utilisation de base

### Adaptateur HTTP

```python
from scripts.utils.cache.adapters.http_adapter import HttpCacheAdapter

# Créer une instance de l'adaptateur HTTP
adapter = HttpCacheAdapter()

# Effectuer une requête GET avec mise en cache
response = adapter.get("https://api.example.com/data")

# Effectuer une requête avec des paramètres
response = adapter.get("https://api.example.com/search", params={"q": "query"})

# Effectuer une requête POST avec mise en cache
response = adapter.post("https://api.example.com/create", json={"name": "test"})

# Forcer une requête fraîche (ignorer le cache)
response = adapter.get("https://api.example.com/data", force_refresh=True)

# Invalider une entrée du cache
adapter.invalidate_url("https://api.example.com/data")

# Vider le cache
adapter.clear()
```

### Adaptateur n8n

```python
from scripts.utils.cache.adapters.n8n_adapter import N8nCacheAdapter

# Créer une instance de l'adaptateur n8n
adapter = N8nCacheAdapter(api_url="http://localhost:5678/api/v1", api_key="your-api-key")

# Récupérer la liste des workflows
workflows = adapter.get_workflows()

# Récupérer les workflows actifs
active_workflows = adapter.get_workflows(active=True)

# Récupérer les workflows avec un tag spécifique
tagged_workflows = adapter.get_workflows(tags=["email"])

# Récupérer les dernières exécutions
executions = adapter.get_executions(limit=10)

# Récupérer les exécutions d'un workflow spécifique
workflow_executions = adapter.get_executions(workflow_id="123", limit=5)

# Exécuter un workflow
result = adapter.execute_workflow("123", data={"input": "value"})

# Invalider le cache des workflows
adapter.invalidate_workflows_cache()

# Invalider tout le cache
adapter.invalidate_all_cache()
```

## Utilisation avec un fichier de configuration

Vous pouvez utiliser un fichier de configuration JSON pour configurer les adaptateurs :

```python
from scripts.utils.cache.adapters.http_adapter import create_http_adapter_from_config
from scripts.utils.cache.adapters.n8n_adapter import create_n8n_adapter_from_config

# Créer un adaptateur HTTP à partir d'un fichier de configuration
http_adapter = create_http_adapter_from_config("path/to/config.json")

# Créer un adaptateur n8n à partir d'un fichier de configuration
n8n_adapter = create_n8n_adapter_from_config("path/to/config.json")
```

Exemple de fichier de configuration :

```json
{
  "http": {
    "default_ttl": 3600,
    "methods_to_cache": ["GET", "HEAD"],
    "status_codes_to_cache": [200, 203, 300, 301, 302, 304, 307, 308],
    "ignore_query_params": ["_", "timestamp", "nocache", "rand"],
    "ignore_headers": ["User-Agent", "Accept-Encoding", "Connection", "Cache-Control", "Pragma"],
    "vary_headers": ["Accept", "Accept-Language", "Content-Type"]
  },
  "n8n": {
    "api_url": "http://localhost:5678/api/v1",
    "api_key": "your-api-key",
    "default_ttl": 3600,
    "workflows_ttl": 3600,
    "executions_ttl": 1800,
    "credentials_ttl": 7200,
    "tags_ttl": 7200,
    "users_ttl": 7200
  }
}
```

## Utilisation du décorateur de mise en cache

Vous pouvez utiliser le décorateur `cached` pour mettre en cache les résultats d'une fonction :

```python
from scripts.utils.cache.adapters.http_adapter import HttpCacheAdapter

adapter = HttpCacheAdapter()

# Décorer une fonction pour mettre en cache ses résultats
@adapter.cached(ttl=300)  # Cache les résultats pendant 5 minutes
def get_data(url, params=None):
    return adapter.get(url, params=params).json()

# Premier appel (exécute la fonction)
data1 = get_data("https://api.example.com/data")

# Deuxième appel (utilise le cache)
data2 = get_data("https://api.example.com/data")
```

## Exemples

Consultez les scripts d'exemple pour plus de détails sur l'utilisation des adaptateurs :

- `http_example.py` : Exemples d'utilisation de l'adaptateur HTTP
- `n8n_example.py` : Exemples d'utilisation de l'adaptateur n8n
