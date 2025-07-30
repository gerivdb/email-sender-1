# Règles de développement et architecture Roo-Code

Ce fichier est subordonné à [.roo/rules/rules.md](rules.md).  
Il détaille les standards, conventions et bonnes pratiques spécifiques au développement et à l’architecture du projet Roo-Code.

---

## 1. Principes généraux

- Respecter les conventions de nommage (slug, emoji, PascalCase, snake_case selon le contexte).
- Privilégier la lisibilité, la modularité et la testabilité du code.
- Documenter chaque module, fonction et interface selon le modèle central.
- Utiliser des patterns d’architecture adaptés (ex : manager/agent, plugin, stratégie).

---

## 2. Standards de développement

- **Langages principaux** : Go, TypeScript, Markdown.
- **Tests unitaires** :  
  - Couvrir chaque fonctionnalité critique.
  - Utiliser des mocks pour les dépendances.
- **Gestion des erreurs** :  
  - Centraliser via ErrorManager.
  - Documenter les cas limites et scénarios d’échec.

---

## 3. Conventions d’architecture

- Utiliser le modèle manager/agent pour l’orchestration des fonctionnalités.
- Prévoir des points d’extension via PluginInterface ou stratégies.
- Documenter les interfaces dans [`AGENTS.md`](../AGENTS.md) et référencer ici.

---

## 4. Overrides et modes spécifiques

- Si un mode Roo-Code nécessite des conventions particulières (ex : mode debug, mode code), ajouter une section dédiée et référencer le prompt système concerné.
- Les prompts système doivent indiquer explicitement les adaptations ou exceptions à ces règles.

---

## 5. Maintenance

- Mettre à jour ce fichier à chaque évolution des standards ou des besoins techniques.
- Documenter les nouveaux patterns ou conventions dans la documentation centrale.

---