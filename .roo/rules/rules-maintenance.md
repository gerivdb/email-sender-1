# Règles de maintenance documentaire Roo-Code

Ce fichier est subordonné à [.roo/rules/rules.md](rules.md).  
Il détaille les procédures, conventions et bonnes pratiques pour la maintenance, le nettoyage et l’optimisation documentaire dans le projet Roo-Code.

---

## 1. Principes généraux

- Centraliser la maintenance via MaintenanceManager et CleanupManager.
- Planifier des opérations régulières de nettoyage, optimisation et analyse de santé.
- Documenter chaque opération de maintenance : objectif, périmètre, résultats, impacts.

---

## 2. Procédures de nettoyage

- Utiliser CleanupManager pour scanner, organiser et supprimer les fichiers obsolètes ou temporaires.
- Privilégier le mode “dry-run” avant toute suppression définitive.
- Documenter les doublons, anomalies et actions correctives dans `.github/docs/incidents/`.

---

## 3. Optimisation et analyse de santé

- Intégrer des outils d’analyse de performance et de santé documentaire.
- Mettre à jour le score de santé et l’historique des opérations dans MaintenanceManager.
- Documenter les recommandations d’optimisation et les actions réalisées.

---

## 4. Rollback et restauration

- Utiliser RollbackManager pour annuler ou restaurer des opérations critiques.
- Documenter les conditions et procédures de rollback dans la documentation centrale.

---

## 5. Overrides et modes spécifiques

- Si un mode Roo-Code nécessite des procédures de maintenance particulières (ex : mode maintenance, mode autonomie), ajouter une section dédiée et référencer le prompt système concerné.
- Les prompts système doivent indiquer explicitement les adaptations ou exceptions à ces règles.

---

## 6. Maintenance

- Mettre à jour ce fichier à chaque évolution des pratiques ou des outils de maintenance.
- Documenter les nouveaux outils ou procédures dans la documentation centrale.

---