# Règles de migration documentaire Roo-Code

Ce fichier est subordonné à [.roo/rules/rules.md](rules.md).  
Il détaille les bonnes pratiques, conventions et procédures pour l’import/export et la migration de données dans le projet Roo-Code.

---

## 1. Procédures d’import/export

- Utiliser MigrationManager pour orchestrer les exports et imports de données (jobs, configs, tenants, etc.).
- Vérifier la compatibilité ascendante et descendante avant toute migration.
- Documenter les formats utilisés (JSON, YAML, Markdown, etc.) et les conventions de nommage.

---

## 2. Gestion des versions

- Utiliser VersionManagerImpl pour comparer, valider et sélectionner les versions compatibles.
- Documenter les contraintes de version et les procédures de rollback en cas d’échec.

---

## 3. Compatibilité et tests

- Effectuer des tests d’intégrité et de compatibilité après chaque migration.
- Documenter les scénarios de test et les résultats dans `.github/docs/incidents/`.

---