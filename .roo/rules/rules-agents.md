# Règles de gestion des rôles et agents Roo-Code

Ce fichier est subordonné à [.roo/rules/rules.md](rules.md).  
Il détaille les conventions, modèles et bonnes pratiques pour la gestion des rôles, agents et managers dans l’architecture Roo-Code.

---

## 1. Principes généraux

- Centraliser la définition des rôles et interfaces dans [`AGENTS.md`](../AGENTS.md).
- Documenter chaque agent/manager : rôle, interfaces, conventions d’utilisation, points d’extension.
- Privilégier la clarté, la modularité et la traçabilité des responsabilités.

---

## 2. Convention de gestion des rôles

- Respecter la nomenclature et la structure décrites dans [`AGENTS.md`](../AGENTS.md).
- Documenter les interactions entre agents/managers et les points d’intégration.
- Mettre à jour la liste brute et le détail des managers à chaque évolution.

---

## 3. Points d’extension et plugins

- Utiliser PluginInterface pour ajouter dynamiquement de nouveaux agents/managers ou stratégies.
- Documenter les conventions d’extension et les impacts sur l’architecture.

---

## 4. Overrides et modes spécifiques

- Si un mode Roo-Code nécessite une gestion particulière des rôles ou agents (ex : mode orchestrator, mode debug), ajouter une section dédiée et référencer le prompt système concerné.
- Les prompts système doivent indiquer explicitement les adaptations ou exceptions à ces règles.

---

## 5. Maintenance

- Mettre à jour ce fichier à chaque ajout ou modification d’agent, manager ou convention.
- Documenter les nouveaux rôles ou interfaces dans la documentation centrale.

---