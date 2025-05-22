# Cartographie et usages des fichiers mcp-config.json dans le projet EMAIL_SENDER_1

Ce document explicite la présence de plusieurs fichiers `mcp-config.json` dans le projet, leur structure et leur usage respectif. Il complète le guide de configuration existant.

## 1. Fichier principal : `projet/mcp/config/mcp-config.json`
- **Usage** : Configuration centrale des serveurs MCP (filesystem, github, gcp, notion, gateway, etc.).
- **Structure** : Clé racine `mcpServers` listant chaque serveur avec ses commandes, arguments, variables d’environnement, activation, et chemin de config spécifique.
- **Utilisé par** : Scripts de gestion MCP, démarrage/arrêt de serveurs, MCP Manager, orchestration centralisée.

## 2. Variante : `projet/config/mcp-config.json`
- **Usage** : Variante générée ou utilisée par certains scripts batch/PowerShell ou orchestrateurs alternatifs.
- **Structure** : Clé racine `servers` (et non `mcpServers`), chaque serveur a ses propres paramètres (port, host, apiKey, etc.).
- **Utilisé par** : Outils ou extensions qui attendent une structure différente, ou pour des tests/expérimentations.

## 3. `src/mcp/servers/mcp-config.json`
- **Usage** : Configuration pour des serveurs MCP utilisés dans le code source (tests, scripts Python, intégrations spécifiques).
- **Structure** : Clé racine `mcpServers`, format similaire à la config principale mais adaptée à l’environnement de développement ou à des outils spécifiques.
- **Utilisé par** : Scripts Python, tests, intégrations personnalisées.

## 4. `development/scripts/script-manager/configuration/mcp-config.json`
- **Usage** : Configuration dédiée au gestionnaire de scripts (Script Manager).
- **Structure** : Clé racine `mcpServers` (souvent limité à un ou deux serveurs), et une section `commands` pour les sous-commandes du manager.
- **Utilisé par** : Script Manager, génération et organisation de scripts via Hygen ou PowerShell.

## 5. `development/scripts/maintenance/mcp/mcp-config.json`
- **Usage** : Configuration pour les scripts de maintenance du projet.
- **Structure** : Clé racine `mcpServers` (ex : desktop-commander), section `commands` pour les tâches de maintenance (organisation, hooks git, etc.).
- **Utilisé par** : Scripts de maintenance, automatisation des tâches d’entretien du projet.

---

## Schéma récapitulatif

```
projet/mcp/config/mcp-config.json
   └─> Serveurs MCP principaux (prod/dev) – orchestration, démarrage, gestion centralisée
projet/config/mcp-config.json
   └─> Variante pour scripts batch, extensions, tests, orchestrateurs alternatifs
src/mcp/servers/mcp-config.json
   └─> Configs pour tests, scripts Python, intégrations spécifiques
development/scripts/script-manager/configuration/mcp-config.json
   └─> Script Manager (organisation, génération de scripts)
development/scripts/maintenance/mcp/mcp-config.json
   └─> Maintenance projet (organisation, hooks, automatisation)
```

## Remarques
- Chaque fichier répond à un usage ou un contexte précis (production, développement, maintenance, extension, tests).
- Les structures peuvent différer selon les besoins des outils ou orchestrateurs qui les consomment.
- La documentation principale sur la configuration MCP se trouve dans `projet/mcp/docs/guides/configuration.md`.
- Ce document complète la documentation existante et doit être mis à jour en cas d’ajout ou de modification de fichiers de configuration MCP.
