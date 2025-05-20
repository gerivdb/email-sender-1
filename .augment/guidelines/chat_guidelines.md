# EMAIL SENDER 1 — Augment Guidelines
*Version 2025-05-15 — à conserver dans `/docs/README_EMAIL_SENDER_1.md`*

---

## 1. Architecture du projet

### 1.1 Composants principaux
- **n8n workflows** : Automatisation des processus d'envoi d'emails et gestion des réponses
- **MCP (Model Context Protocol)** : Serveurs pour fournir du contexte aux modèles IA
- **Scripts PowerShell/Python** : Utilitaires et intégrations
- **Notion + Google Calendar** : Sources de données (contacts, disponibilités)
- **OpenRouter/DeepSeek** : Services IA pour personnalisation des messages

### 1.2 Structure des dossiers
```
/src/n8n/workflows/       → Workflows n8n actifs (*.json)
/src/n8n/workflows/archive → Versions archivées
/src/mcp/servers/         → Serveurs MCP (filesystem, github, gcp)
/projet/guides/           → Documentation méthodologique
/projet/roadmaps/         → Roadmap et planification
/projet/config/           → Fichiers de configuration
/development/scripts/     → Scripts d'automatisation et modes
/docs/guides/augment/     → Guides spécifiques à Augment
```

[... le reste du contenu des guidelines ...]

> **Règle d'or** : *Granularité adaptative, tests systématiques, documentation claire*.
> Pour toute question, utiliser le mode approprié et progresser par étapes incrémentelles.
