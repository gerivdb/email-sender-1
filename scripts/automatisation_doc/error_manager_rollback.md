### Phase : Procédures de rollback Roo ErrorManager

- **Objectif** : Définir, documenter et valider les procédures de rollback pour ErrorManager afin d’assurer la restauration fiable de l’état documentaire et la résilience du système.
- **Livrables** : `error_manager_rollback.md`, scripts/commandes de rollback, liens Roo.
- **Dépendances** : Schéma YAML Roo, spécification technique, reporting, tests unitaires ErrorManager.
- **Risques** : Rollback incomplet, perte de logs d’erreur, dérive documentaire, absence de point de restauration, scripts non testés.
- **Outils/Agents mobilisés** : RollbackManager, ErrorManager, scripts Go, CI/CD, audit Roo.

#### Tâches actionnables

- [ ] Décrire les scénarios de rollback typiques (ex : restauration d’un état antérieur après une erreur critique, annulation d’une opération de catalogage d’erreur, rollback d’une migration de schéma d’erreur).
- [ ] Générer un script Go de rollback documentaire (ex : `rollback_error_manager.go`) ou documenter la commande à utiliser.
- [ ] Définir les points de restauration et la gestion des états intermédiaires.
- [ ] Documenter la procédure d’exécution du rollback (commande CLI, paramètres, logs attendus).
- [ ] Valider la procédure par test manuel ou automatisé (ex : test d’intégration, dry-run).
- [ ] Lier la procédure à la CI/CD pour garantir la traçabilité et la reproductibilité.
- [ ] Archiver les logs et états avant/après rollback.
- [ ] Mettre à jour la documentation croisée (README, AGENTS.md, plan, checklist).

#### Scripts/Commandes

- `go run scripts/rollback/rollback_error_manager.go --restore-point=YYYYMMDD-HHMM`
- `go run scripts/backup/backup.go --before-rollback`
- `go run scripts/aggregate-diagnostics/aggregate-diagnostics.go --after-rollback`
- Utiliser RollbackManager : appel de [`RollbackLast()`](AGENTS.md#RollbackManager:RollbackLast)

#### Fichiers attendus

- `scripts/automatisation_doc/error_manager_rollback.md` (présent)
- `scripts/rollback/rollback_error_manager.go` (optionnel, à générer si besoin)
- Logs : `logs/rollback_error_manager_*.log`
- Snapshots d’état documentaire (avant/après rollback)

#### Critères de validation

- Procédure testée sur un cas réel ou simulé (dry-run accepté)
- Logs de rollback complets et archivés
- Restauration vérifiée par test d’intégrité documentaire
- Documentation croisée à jour (README, AGENTS.md, plan, checklist)
- Intégration CI/CD validée (job de rollback, badge, monitoring)

#### Rollback/versionning

- Points de restauration documentés (timestamp, état, logs)
- Script de rollback versionné dans le dépôt
- Procédure de rollback reproductible et traçable
- Possibilité de rollback multiple (historique)

#### Orchestration & CI/CD

- Ajout d’un job de rollback dans `.github/workflows/ci.yml`
- Monitoring automatisé du rollback (alerte en cas d’échec)
- Badge de statut rollback dans la documentation

#### Documentation & traçabilité

- Liens croisés : [`README.md`](README.md), [`AGENTS.md`](AGENTS.md), [`plan-dev-v113-autmatisation-doc-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md), [`checklist-actionnable.md`](checklist-actionnable.md)
- Reporting automatisé post-rollback (logs, état, feedback)
- Historique des rollbacks documenté

#### Risques & mitigation

- Risque de rollback partiel : prévoir des tests d’intégrité et des backups systématiques
- Risque de perte de logs : archivage automatique avant rollback
- Risque de dérive documentaire : validation croisée post-rollback

#### Questions ouvertes, hypothèses & ambiguïtés

- Hypothèse : Les points de restauration sont générés automatiquement à chaque opération critique ErrorManager.
- Question : Faut-il prévoir un rollback sélectif (par composant) ou global ?
- Ambiguïté : Les dépendances croisées avec d’autres managers sont-elles toutes restaurées ?

#### Auto-critique & raffinement

- Limite : La procédure ne couvre pas les rollbacks multi-managers complexes.
- Suggestion : Ajouter des tests d’intégration multi-managers et une analyse d’impact.
- Feedback : Collecter les retours utilisateurs sur la clarté et la robustesse du rollback ErrorManager.