# Rollback & Restauration — SynchronisationManager

> **Ce document décrit les procédures de rollback et de restauration pour le composant SynchronisationManager, conformément aux standards Roo Code.**  
> _Phase 3 du plan : [plan-dev-v113-autmatisation-doc-roo.md](../../projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)_

---

## Résumé

Ce guide fournit :
- Les étapes séquencées pour restaurer l’état du SynchronisationManager après incident ou erreur critique.
- Les scripts et points de restauration recommandés.
- Des exemples concrets et liens croisés vers les artefacts de référence.
- La conformité aux exigences Roo Code (RollbackManager, validation, traçabilité).

---

## Procédures de restauration

### 1. Identification du point de restauration

- Localiser le dernier snapshot ou état valide :
  - Fichier de sauvegarde généré automatiquement (`synchronisation_backup.yaml` ou équivalent).
  - Historique des opérations : voir [SyncHistoryManager](../../../AGENTS.md#synchistorymanager).
- Vérifier la cohérence du schéma avec [`synchronisation_schema.yaml`](synchronisation_schema.yaml).

### 2. Sauvegarde de l’état courant (avant rollback)

- Exporter l’état actuel pour éviter toute perte de données :
  - Script Go :
    ```bash
    go run synchronisation_doc.go --export --output=synchronisation_backup_pre_rollback.yaml
    ```
  - Vérifier la validité du fichier exporté via :
    ```bash
    go test synchronisation/main_test.go -run TestExportValidation
    ```

### 3. Restauration de l’état antérieur

- Importer le snapshot ou état de référence :
    ```bash
    go run synchronisation_doc.go --import --input=synchronisation_backup.yaml
    ```
- Contrôler la conformité au schéma :
    ```bash
    go run synchronisation_doc.go --validate --input=synchronisation_backup.yaml
    ```
- Vérifier la réussite via les tests unitaires :
    ```bash
    go test synchronisation/main_test.go
    ```

### 4. Utilisation du RollbackManager

- Si activé, déclencher la restauration via le RollbackManager :
    ```go
    // Exemple Go
    err := RollbackManager.RollbackLast()
    if err != nil {
        // Consigner l’erreur dans ErrorManager
    }
    ```
- Consulter la documentation du RollbackManager dans [AGENTS.md](../../../AGENTS.md#rollbackmanager).

### 5. Validation post-restauration

- Exécuter l’ensemble des tests de synchronisation :
    ```bash
    go test synchronisation/main_test.go
    ```
- Vérifier la génération correcte du reporting :  
  Voir [`synchronisation_report.md`](synchronisation_report.md).

---

## Exemples de scripts

- Export :  
  `go run synchronisation_doc.go --export --output=synchronisation_backup.yaml`
- Import :  
  `go run synchronisation_doc.go --import --input=synchronisation_backup.yaml`
- Validation schéma :  
  `go run synchronisation_doc.go --validate --input=synchronisation_backup.yaml`

---

## Points de restauration recommandés

- Avant toute opération critique, générer un snapshot :  
  `synchronisation_backup_<timestamp>.yaml`
- Conserver un historique dans un dossier dédié (`backups/` ou équivalent).
- Documenter chaque rollback dans le reporting associé.

---

## Liens croisés

- **Plan de référence** : [plan-dev-v113-autmatisation-doc-roo.md](../../projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)
- **Schéma YAML** : [synchronisation_schema.yaml](synchronisation_schema.yaml)
- **Code Go** : [synchronisation_doc.go](synchronisation_doc.go)
- **Tests** : [synchronisation/main_test.go](synchronisation/main_test.go)
- **Reporting** : [synchronisation_report.md](synchronisation_report.md)
- **AGENTS.md** : [AGENTS.md](../../../AGENTS.md#rollbackmanager)

---

## Conformité Roo Code

- Respect des standards de rollback documentaire ([rules-maintenance.md](../../../.roo/rules/rules-maintenance.md)).
- Utilisation du RollbackManager pour la traçabilité et la sécurité.
- Validation systématique par tests unitaires et contrôle de schéma.
- Documentation de chaque opération de restauration dans le reporting.
