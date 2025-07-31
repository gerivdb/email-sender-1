# Règles de maintenance documentaire Roo-Code

Ce fichier est subordonné à [.roo/rules/rules.md](rules.md).  
Il détaille les procédures, conventions et bonnes pratiques pour la maintenance, le nettoyage et l’optimisation documentaire dans le projet Roo-Code.

---

## 1. Procédures de nettoyage

- Utiliser CleanupManager pour scanner, organiser et supprimer les fichiers obsolètes ou temporaires.
- Privilégier le mode “dry-run” avant toute suppression définitive.
- Documenter les doublons, anomalies et actions correctives dans `.github/docs/incidents/`.

---

## 2. Optimisation et analyse de santé

- Intégrer des outils d’analyse de performance et de santé documentaire.
- Mettre à jour le score de santé et l’historique des opérations dans MaintenanceManager.
- Documenter les recommandations d’optimisation et les actions réalisées.

---

## 3. Rollback et restauration

- Utiliser RollbackManager pour annuler ou restaurer des opérations critiques.
- Documenter les conditions et procédures de rollback dans la documentation centrale.

---