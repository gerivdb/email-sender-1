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
- **Traçabilité du mode d’exécution** :
  - Pour toute action critique (écriture, édition, suppression), transmettre explicitement le mode d’exécution à Roo pour garantir la conformité et la traçabilité documentaire.
  - Source : [`rules.md`](rules.md:Principes transverses), applicable à tous les modes Roo.

---

## 2. Conventions d’architecture

- Utiliser le modèle manager/agent pour l’orchestration des fonctionnalités.
- Prévoir des points d’extension via PluginInterface ou stratégies.
- Documenter les interfaces dans [`AGENTS.md`](../AGENTS.md) et référencer ici.

---

## 3. Points d’extension

- **PluginInterface** : Ajout dynamique de plugins, stratégies, managers (voir [`AGENTS.md`](../AGENTS.md), [`rules-plugins.md`](rules-plugins.md)).
- **QualityGatePlugin** : Extension des quality gates CI/CD (voir [`rules-plugins.md`](rules-plugins.md), [`tools-registry.md`](tools-registry.md)).
- **Autres points d’extension** : Définis dans chaque manager (voir [`AGENTS.md`](../AGENTS.md)), à documenter dans le fichier du domaine concerné.

---

## 4. Références croisées

- Source : [`rules.md`](rules.md), [`tools-registry.md`](tools-registry.md), [`AGENTS.md`](../AGENTS.md), [`rules-plugins.md`](rules-plugins.md)