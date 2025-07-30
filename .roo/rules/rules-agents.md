# Règles de gestion des rôles et agents Roo-Code

Ce fichier est subordonné à [.roo/rules/rules.md](rules.md).  
Il détaille les conventions, modèles et bonnes pratiques pour la gestion des rôles, agents et managers dans l’architecture Roo-Code.

---

## 1. Convention de gestion des rôles

- Respecter la nomenclature et la structure décrites dans [`AGENTS.md`](../AGENTS.md).
- Documenter les interactions entre agents/managers et les points d’intégration.
- Mettre à jour la liste brute et le détail des managers à chaque évolution.

---

## 2. Points d’extension et plugins

- Utiliser PluginInterface pour ajouter dynamiquement de nouveaux agents/managers ou stratégies.
- Documenter les conventions d’extension et les impacts sur l’architecture.

---