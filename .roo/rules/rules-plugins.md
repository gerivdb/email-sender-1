# Règles d’extension et gestion des plugins Roo-Code

Ce fichier est subordonné à [.roo/rules/rules.md](rules.md).  
Il détaille les conventions, modèles et bonnes pratiques pour l’extension du projet Roo-Code via plugins et stratégies.

---

## 1. Convention de développement de plugins

- Respecter les interfaces définies dans [`AGENTS.md`](../AGENTS.md) pour chaque type de plugin (cache, vectorisation, orchestration, etc.).
- Documenter les méthodes obligatoires et les points d’extension.
- Prévoir des mécanismes de registre, activation/désactivation et gestion des erreurs.

---

## 2. Sécurité et validation

- Valider systématiquement les plugins avant activation (compatibilité, sécurité, performance).
- Documenter les procédures de test et de validation dans la documentation centrale.
- Prévoir des hooks ou callbacks pour la gestion des erreurs et des incidents.

---