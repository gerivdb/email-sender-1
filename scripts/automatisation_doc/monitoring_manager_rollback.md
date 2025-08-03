# Procédures de Rollback — MonitoringManager Roo

## Objectif

Décrire les procédures de rollback et de restauration documentaire pour le MonitoringManager, en garantissant la traçabilité, la sécurité et la conformité Roo Code.

## Procédures détaillées

- **Rollback automatique via RollbackManager**
  - Utiliser la méthode `RollbackLast()` pour restaurer l’état documentaire antérieur en cas d’échec critique ou de dérive des métriques.
  - Exemple Go :
    ```go
    err := rollbackManager.RollbackLast()
    if err != nil {
        errorManager.ProcessError(ctx, err, "MonitoringManager", "Rollback", nil)
    }
    ```
- **Restauration des métriques et alertes**
  - Restaurer les snapshots de métriques via la commande dédiée ou le script d’export/import.
  - Réactiver les alertes désactivées lors du rollback.
- **Rollback des configurations**
  - Restaurer le fichier de configuration YAML Roo (`monitoring_schema.yaml`) depuis la sauvegarde automatique (`monitoring_schema.yaml.bak`).
  - Commande PowerShell :
    ```powershell
    Copy-Item scripts/automatisation_doc/monitoring_schema.yaml.bak scripts/automatisation_doc/monitoring_schema.yaml -Force
    ```
- **Rollback CI/CD**
  - Revenir à l’état précédent du pipeline CI/CD en restaurant le workflow `.github/workflows/ci.yml` depuis le dépôt Git.
  - Commande Git :
    ```bash
    git checkout HEAD~1 -- .github/workflows/ci.yml
    ```

## Scripts/Commandes

- Rollback Go :
  - `go run scripts/automatisation_doc/monitoring_manager.go --rollback`
- Restauration manuelle des métriques :
  - `go run scripts/automatisation_doc/monitoring_manager.go --restore-metrics --from=snapshot.bak`
- Rollback configuration YAML :
  - `Copy-Item scripts/automatisation_doc/monitoring_schema.yaml.bak scripts/automatisation_doc/monitoring_schema.yaml -Force`

## Critères de validation

- État documentaire restauré conforme au dernier snapshot valide.
- Redémarrage du MonitoringManager sans perte de métriques critiques.
- Logs d’erreur centralisés via ErrorManager.
- Vérification croisée par un pair (audit manuel du rollback).
- Tests unitaires de rollback exécutés et validés.

## Risques & mitigation

- **Perte de métriques récentes** : prévoir des snapshots fréquents.
- **Rollback partiel** : valider la complétude via tests et logs.
- **Erreur de restauration de configuration** : automatiser la sauvegarde/restauration.
- **Dérive documentaire** : audit post-rollback obligatoire.

## Liens croisés & traçabilité Roo

- Plan de référence : [`plan-dev-v113-autmatisation-doc-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)
- Checklist-actionnable : [`checklist-actionnable.md`](checklist-actionnable.md)
- Documentation croisée : [`README.md`](README.md), [`AGENTS.md`](AGENTS.md)
- CI/CD : [`.github/workflows/ci.yml`](.github/workflows/ci.yml)
- Artefacts MonitoringManager : [`monitoring_schema.yaml`](scripts/automatisation_doc/monitoring_schema.yaml), [`monitoring_manager_spec.md`](scripts/automatisation_doc/monitoring_manager_spec.md), [`monitoring_manager_report.md`](scripts/automatisation_doc/monitoring_manager_report.md)

## Questions ouvertes, hypothèses & ambiguïtés

- Hypothèse : les snapshots de métriques sont générés à chaque modification critique.
- Ambiguïté : la restauration d’alertes dépend-elle d’un état externe ?
- Question : faut-il prévoir un rollback sélectif (métriques seules, alertes seules) ?

## Auto-critique & raffinement

- Limite : la procédure ne couvre pas la restauration d’états distribués multi-nœuds.
- Suggestion : intégrer un script d’audit automatique post-rollback.
- Feedback : prévoir un monitoring du rollback dans le pipeline CI/CD.