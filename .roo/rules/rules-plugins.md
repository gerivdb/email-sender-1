# Règles d’extension et gestion des plugins Roo-Code

Ce fichier est subordonné à [.roo/rules/rules.md](rules.md).  
Il détaille les conventions, modèles et bonnes pratiques pour l’extension du projet Roo-Code via plugins et stratégies.

---

## 1. Principes généraux

- Centraliser la gestion des plugins via PluginInterface et ExtensibleManagerType.
- Documenter chaque plugin : objectif, interfaces, points d’intégration, impacts.
- Privilégier la modularité, la sécurité et la traçabilité des extensions.

---

## 2. Convention de développement de plugins

- Respecter les interfaces définies dans [`AGENTS.md`](../AGENTS.md) pour chaque type de plugin (cache, vectorisation, orchestration, etc.).
- Documenter les méthodes obligatoires et les points d’extension.
- Prévoir des mécanismes de registre, activation/désactivation et gestion des erreurs.

---

## 3. Sécurité et validation

- Valider systématiquement les plugins avant activation (compatibilité, sécurité, performance).
- Documenter les procédures de test et de validation dans la documentation centrale.
- Prévoir des hooks ou callbacks pour la gestion des erreurs et des incidents.

---

## 4. Overrides et modes spécifiques

- Si un mode Roo-Code nécessite des conventions d’extension particulières (ex : mode code, mode debug), ajouter une section dédiée et référencer le prompt système concerné.
- Les prompts système doivent indiquer explicitement les adaptations ou exceptions à ces règles.

---

## 5. Maintenance

- Mettre à jour ce fichier à chaque évolution des pratiques ou des interfaces de plugin.
- Documenter les nouveaux types de plugins ou stratégies dans la documentation centrale.

---