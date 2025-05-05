# Templates d'architectures d'agents IA pour n8n

Ce dossier contient des templates de workflows n8n implémentant différentes architectures d'agents IA pour le projet Email Sender 1.

## Templates disponibles

### 1. agent-single-tools.json
Template implémentant l'architecture "Agent unique + Outils".

### 2. agents-sequential.json
Template implémentant l'architecture "Agents séquentiels".

### 3. agent-mcp-tools.json
Template implémentant l'architecture "Agent + MCP Servers + Outils".

### 4. agent-router.json
Template implémentant l'architecture "Agent + Router".

### 5. agent-human-loop.json
Template implémentant l'architecture "Agent + Human in the Loop".

### 6. agent-dynamic-call.json
Template implémentant l'architecture "Agent unique + Appel dynamique d'autres agents".

### 7. agents-hierarchy-parallel.json
Template implémentant l'architecture "Hiérarchie d'agents + Agents parallèles + Outils partagés".

### 8. agents-hierarchy-loop-rag.json
Template implémentant l'architecture "Hiérarchie d'agents + Boucle + Agents parallèles + RAG partagé".

## Utilisation

Pour importer un template dans n8n:

1. Ouvrez l'interface n8n
2. Cliquez sur "Workflows" dans le menu de gauche
3. Cliquez sur le bouton "Import" en haut à droite
4. Sélectionnez le fichier JSON du template à importer
5. Configurez les credentials nécessaires (OpenAI, Gmail, etc.)
6. Adaptez le workflow à vos besoins spécifiques

## Documentation

Pour plus d'informations sur ces architectures, consultez la documentation complète:
[Architectures d'agents IA pour n8n](../../../docs/architecture/ai-agent-architectures.md)