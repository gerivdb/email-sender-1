# Adaptateurs de cache

Ce module fournit des adaptateurs de cache pour diffÃ©rents types de requÃªtes et d'API.

## Adaptateurs disponibles

- **CacheAdapter** : Interface abstraite pour les adaptateurs de cache
- **HttpCacheAdapter** : Adaptateur pour les requÃªtes HTTP gÃ©nÃ©riques
- **N8nCacheAdapter** : Adaptateur spÃ©cifique pour l'API n8n

## Installation

Assurez-vous d'avoir installÃ© les dÃ©pendances requises :

```bash
pip install requests diskcache
```

## Utilisation de base

### Adaptateur HTTP

```python
from scripts.utils.cache.adapters.http_adapter import HttpCacheAdapter

# CrÃ©er une instance de l'adaptateur HTTP
adapter = HttpCacheAdapter()

# Effectuer une requÃªte GET avec mise en cache
response = adapter.get("https://api.example.com/data")

# Effectuer une requÃªte avec des paramÃ¨tres
response = adapter.get("https://api.example.com/search", params={"q": "query"})

# Effectuer une requÃªte POST avec mise en cache
response = adapter.post("https://api.example.com/create", json={"name": "test"})

# Forcer une requÃªte fraÃ®che (ignorer le cache)
response = adapter.get("https://api.example.com/data", force_refresh=True)

# Invalider une entrÃ©e du cache
adapter.invalidate_url("https://api.example.com/data")

# Vider le cache
adapter.clear()
```

### Adaptateur n8n

```python
from scripts.utils.cache.adapters.n8n_adapter import N8nCacheAdapter

# CrÃ©er une instance de l'adaptateur n8n
adapter = N8nCacheAdapter(api_url="http://localhost:5678/api/v1", api_key="your-api-key")

# RÃ©cupÃ©rer la liste des workflows
workflows = adapter.get_workflows()

# RÃ©cupÃ©rer les workflows actifs
active_workflows = adapter.get_workflows(active=True)

# RÃ©cupÃ©rer les workflows avec un tag spÃ©cifique
tagged_workflows = adapter.get_workflows(tags=["email"])

# RÃ©cupÃ©rer les derniÃ¨res exÃ©cutions
executions = adapter.get_executions(limit=10)

# RÃ©cupÃ©rer les exÃ©cutions d'un workflow spÃ©cifique
workflow_executions = adapter.get_executions(workflow_id="123", limit=5)

# ExÃ©cuter un workflow
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

# CrÃ©er un adaptateur HTTP Ã  partir d'un fichier de configuration
http_adapter = create_http_adapter_from_config("path/to/config.json")

# CrÃ©er un adaptateur n8n Ã  partir d'un fichier de configuration
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

## Utilisation du dÃ©corateur de mise en cache

Vous pouvez utiliser le dÃ©corateur `cached` pour mettre en cache les rÃ©sultats d'une fonction :

```python
from scripts.utils.cache.adapters.http_adapter import HttpCacheAdapter

adapter = HttpCacheAdapter()

# DÃ©corer une fonction pour mettre en cache ses rÃ©sultats
@adapter.cached(ttl=300)  # Cache les rÃ©sultats pendant 5 minutes
def get_data(url, params=None):
    return adapter.get(url, params=params).json()

# Premier appel (exÃ©cute la fonction)
data1 = get_data("https://api.example.com/data")

# DeuxiÃ¨me appel (utilise le cache)
data2 = get_data("https://api.example.com/data")
```

## Exemples

Consultez les scripts d'exemple pour plus de dÃ©tails sur l'utilisation des adaptateurs :

- `http_example.py` : Exemples d'utilisation de l'adaptateur HTTP
- `n8n_example.py` : Exemples d'utilisation de l'adaptateur n8n
