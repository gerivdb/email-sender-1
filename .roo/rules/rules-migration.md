# Règles de migration documentaire Roo-Code

Ce fichier est subordonné à [.roo/rules/rules.md](rules.md).  
Il détaille les bonnes pratiques, conventions et procédures pour l’import/export et la migration de données dans le projet Roo-Code.

---

## 1. Principes généraux

- Centraliser les opérations de migration via MigrationManager.
- Documenter chaque opération d’import/export : périmètre, format, compatibilité, impacts.
- Privilégier la traçabilité et la réversibilité des migrations.

---

## 2. Procédures d’import/export

- Utiliser MigrationManager pour orchestrer les exports et imports de données (jobs, configs, tenants, etc.).
- Vérifier la compatibilité ascendante et descendante avant toute migration.
- Documenter les formats utilisés (JSON, YAML, Markdown, etc.) et les conventions de nommage.

---

## 3. Gestion des versions

- Utiliser VersionManagerImpl pour comparer, valider et sélectionner les versions compatibles.
- Documenter les contraintes de version et les procédures de rollback en cas d’échec.

---

## 4. Compatibilité et tests

- Effectuer des tests d’intégrité et de compatibilité après chaque migration.
- Documenter les scénarios de test et les résultats dans `.github/docs/incidents/`.

---

## 5. Overrides et modes spécifiques

- Si un mode Roo-Code nécessite des procédures de migration particulières (ex : mode maintenance, mode debug), ajouter une section dédiée et référencer le prompt système concerné.
- Les prompts système doivent indiquer explicitement les adaptations ou exceptions à ces règles.

---

## 6. Maintenance

- Mettre à jour ce fichier à chaque évolution des pratiques ou des outils de migration.
- Documenter les nouveaux formats ou procédures dans la documentation centrale.

---