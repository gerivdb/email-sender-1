# Guide d'utilisation du MCP Gateway dans n8n

## Introduction

Le MCP Gateway (centralmind/gateway) est un serveur MCP (Model Context Protocol) qui permet d'exposer votre base de données aux agents IA via le protocole MCP ou OpenAPI 3.1. Ce guide vous explique comment configurer et utiliser le MCP Gateway dans vos workflows n8n.

## Prérequis

- n8n version 1.0.0 ou ultérieure
- Node.js 16 ou ultérieur
- Une base de données supportée (PostgreSQL, MySQL, ClickHouse, Snowflake, MSSQL, BigQuery, Oracle, SQLite, ElasticSearch, MongoDB, DuckDB)

## Installation

1. Exécutez le script `setup-mcp-gateway.ps1` pour télécharger et configurer le MCP Gateway :
   ```powershell
   .\setup-mcp-gateway.ps1
   ```

2. Définissez la variable d'environnement pour autoriser l'utilisation des outils :
   ```bash
   # Windows (PowerShell)

   $env:N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE = "true"
   
   # Linux/macOS

   export N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
   ```

3. Configurez le fichier `gateway.yaml` avec vos informations de connexion à la base de données :
   ```yaml
   api:
     name: Gateway API
     description: API générée par Gateway
     version: '1.0'
   database:
     type: postgres
     connection: "postgres://user:password@localhost:5432/database?sslmode=disable"
     tables: []
   ```

## Configuration des identifiants MCP dans n8n

1. Ouvrez n8n et accédez à "Credentials"
2. Cliquez sur "Create New"
3. Recherchez "MCP Client (STDIO) API" et sélectionnez-le
4. Configurez les identifiants comme suit :
   - **Nom** : MCP Gateway
   - **Command** : Chemin complet vers le binaire gateway.exe
   - **Arguments** : start --config Chemin/vers/gateway.yaml mcp-stdio
   - **Environments** : N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true

## Génération de l'API

Avant d'utiliser le MCP Gateway, vous devez générer une API à partir de votre base de données :

1. Exécutez la commande de découverte :
   ```bash
   .\gateway\gateway.exe discover --ai-provider gemini --connection-string "postgresql://user:password@host:5432/database?sslmode=disable" --prompt "Générer une API en lecture seule"
   ```

2. Cette commande analysera votre schéma de base de données et générera un fichier `gateway.yaml` avec la configuration de l'API.

3. Vous pouvez personnaliser ce fichier selon vos besoins.

## Utilisation du MCP Gateway dans un workflow

1. Ajoutez un nœud "MCP Client" à votre workflow
2. Configurez le nœud comme suit :
   - **Connection Type** : Command Line (STDIO)
   - **Credentials** : Sélectionnez les identifiants MCP Gateway que vous avez créés
   - **Operation** : Choisissez l'opération souhaitée (List Tools, Execute Tool, etc.)

3. Pour l'opération "Execute Tool" :
   - **Tool Name** : Nom de l'outil Gateway à exécuter
   - **Parameters** : Paramètres de l'outil au format JSON

## Fonctionnalités principales

Le MCP Gateway offre de nombreuses fonctionnalités :

1. **Génération automatique d'API** - Crée des API automatiquement en utilisant un LLM basé sur le schéma de la table et des données échantillonnées
2. **Support de bases de données structurées** - Prend en charge PostgreSQL, MySQL, ClickHouse, Snowflake, MSSQL, BigQuery, Oracle, SQLite, ElasticSearch, MongoDB, DuckDB
3. **Support de plusieurs protocoles** - Fournit des API en tant que REST ou serveur MCP, y compris le mode SSE
4. **Documentation API** - Documentation Swagger générée automatiquement et spécification OpenAPI 3.1.0
5. **Protection PII** - Implémente des plugins pour la suppression des données PII et sensibles
6. **Configuration flexible** - Facilement extensible via la configuration YAML et le système de plugins
7. **Options de déploiement** - Exécutez en tant que binaire ou conteneur Docker avec un chart Helm prêt à l'emploi
8. **Support de plusieurs fournisseurs d'IA** - Support pour OpenAI, Anthropic, Amazon Bedrock, Google Gemini et Google VertexAI
9. **Local et sur site** - Support pour les LLM auto-hébergés via des points de terminaison et des modèles d'IA configurables
10. **Sécurité au niveau des lignes (RLS)** - Contrôle d'accès aux données granulaire à l'aide de scripts Lua
11. **Options d'authentification** - Support intégré pour les clés API et OAuth
12. **Surveillance complète** - Intégration avec OpenTelemetry (OTel) pour le suivi des requêtes et les pistes d'audit
13. **Optimisation des performances** - Implémente des stratégies de mise en cache basées sur le temps et LRU

## Exemple d'utilisation

### Interrogation d'une base de données

```json
{
  "tool_name": "get_customers",
  "parameters": {
    "limit": 10,
    "offset": 0
  }
}
```plaintext
### Recherche avec filtres

```json
{
  "tool_name": "search_orders",
  "parameters": {
    "status": "completed",
    "date_from": "2025-01-01",
    "date_to": "2025-04-01"
  }
}
```plaintext
## Dépannage

Si vous rencontrez des problèmes :

1. Vérifiez que la variable d'environnement `N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE` est définie sur "true"
2. Assurez-vous que le binaire Gateway est correctement installé et accessible
3. Vérifiez que votre fichier de configuration `gateway.yaml` est correctement configuré
4. Vérifiez que les chemins dans la configuration des identifiants MCP sont corrects et utilisent des chemins absolus
5. Redémarrez n8n après avoir effectué ces modifications

## Ressources supplémentaires

- [Documentation officielle de Gateway](https://docs.centralmind.ai)
- [GitHub de Gateway](https://github.com/centralmind/gateway)
- [Documentation sur les connecteurs de base de données](https://docs.centralmind.ai/connectors/)
- [Documentation sur les plugins](https://docs.centralmind.ai/plugins/)
