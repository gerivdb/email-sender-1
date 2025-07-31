# Règles de développement et architecture Roo-Code

Ce fichier est subordonné à [.roo/rules/rules.md](rules.md).  
Il détaille les standards, conventions et bonnes pratiques spécifiques au développement et à l’architecture du projet Roo-Code.

---

## 1. Standards de développement

- **Langages principaux** : Go, TypeScript, Markdown.
- **Tests unitaires** :
  - Couvrir chaque fonctionnalité critique.
  - Utiliser des mocks pour les dépendances.
- **Gestion des erreurs** :
  - Centraliser via ErrorManager.
  - Documenter les cas limites et scénarios d’échec.

---

## 2. Conventions d’architecture

- Utiliser le modèle manager/agent pour l’orchestration des fonctionnalités.
- Prévoir des points d’extension via PluginInterface ou stratégies.
- Documenter les interfaces dans [`AGENTS.md`](../AGENTS.md) et référencer ici.

---