<!--
# Rapport synthétique Roo — Génération et structuration des logs d’exécution batch
Ce rapport documente la structure, les conventions et la traçabilité des logs batch produits par le BatchManager Roo.  
Chaque section est commentée pour expliciter son usage et son alignement avec les standards Roo-Code.
-->

# Rapport d’exécution batch — Roo-Code

## 1. Statuts batch et conventions de log
<!--
Section décrivant les statuts possibles d’un batch, leur signification et la convention Roo pour la structuration des logs.
-->
- **Statuts principaux** :
  - `STARTED` : début du batch
  - `IN_PROGRESS` : traitement en cours
  - `SUCCESS` : batch terminé sans erreur
  - `ERROR` : erreur bloquante rencontrée
  - `ROLLBACK_TRIGGERED` : déclenchement d’un hook de rollback
  - `PARTIAL_SUCCESS` : batch terminé avec erreurs partielles

- **Convention de structuration** :
  - Format JSONL ou structuré Go : chaque entrée log contient : timestamp, batchID, statut, message, détails (optionnel), errorID (si erreur), hook (si déclenché).
  - Exemple :
    ```json
    {
      "timestamp": "2025-08-03T16:35:05Z",
      "batchID": "BATCH-20250803-001",
      "status": "ERROR",
      "message": "Erreur lors du traitement du fichier X",
      "errorID": "ERR-42",
      "hook": "rollback_plugin_v1"
    }
    ```

## 2. Gestion des erreurs et traçabilité Roo
<!--
Section expliquant la centralisation des erreurs, leur format, et la traçabilité Roo (lien avec ErrorManager, identifiants uniques, logs d’audit).
-->
- **Centralisation** : toutes les erreurs critiques sont loguées avec un identifiant unique (`errorID`), un contexte batch, et référencées dans l’ErrorManager.
- **Traçabilité Roo** : chaque log d’erreur inclut :
  - Lien croisé vers le rapport d’audit ou la fiche d’incident (si existant)
  - Référence au hook déclenché (si rollback)
  - Exemple :
    ```json
    {
      "timestamp": "...",
      "batchID": "...",
      "status": "ERROR",
      "message": "Connexion à la base échouée",
      "errorID": "ERR-DB-01",
      "auditRef": "audit-20250803-01"
    }
    ```

## 3. Déclenchement des hooks (PluginInterface)
<!--
Section dédiée à la journalisation du déclenchement des hooks de rollback, avec conventions de nommage et exemples.
-->
- **Conventions** :
  - Chaque hook déclenché est logué avec : nom du plugin, type d’action (`rollback`, `cleanup`, etc.), résultat (`success`/`failure`), détails.
  - Nommage : `rollback_plugin_<version>` ou nom explicite du plugin.
- **Exemple de log de hook** :
    ```json
    {
      "timestamp": "...",
      "batchID": "...",
      "status": "ROLLBACK_TRIGGERED",
      "hook": "rollback_plugin_v1",
      "result": "success",
      "details": "Rollback effectué sur 3 fichiers"
    }
    ```

## 4. Reporting synthétique batch
<!--
Section synthétisant les résultats d’un batch : nombre total d’items, succès, erreurs, hooks déclenchés, temps total, résumé.
-->
- **Structure du reporting** :
  - `batchID`
  - `date`
  - `totalItems`
  - `successCount`
  - `errorCount`
  - `hooksTriggered`
  - `duration`
  - `summary`
- **Exemple** :
    ```json
    {
      "batchID": "BATCH-20250803-001",
      "date": "2025-08-03",
      "totalItems": 120,
      "successCount": 117,
      "errorCount": 3,
      "hooksTriggered": ["rollback_plugin_v1"],
      "duration": "00:01:42",
      "summary": "Traitement terminé avec 3 erreurs, rollback appliqué."
    }
    ```

## 5. Exemples de logs batch Roo
<!--
Section présentant des exemples concrets de logs batch, illustrant la structuration Roo et la traçabilité.
-->
- **Log de succès** :
    ```json
    {
      "timestamp": "...",
      "batchID": "...",
      "status": "SUCCESS",
      "message": "Traitement terminé sans erreur"
    }
    ```
- **Log d’erreur avec rollback** :
    ```json
    {
      "timestamp": "...",
      "batchID": "...",
      "status": "ERROR",
      "message": "Erreur critique sur l’item 42",
      "errorID": "ERR-42",
      "hook": "rollback_plugin_v1"
    }
    ```

## 6. Conventions de nommage et organisation des fichiers logs
<!--
Section explicitant les conventions Roo pour le nommage et l’organisation des fichiers de logs batch.
-->
- **Nommage des fichiers** :  
  - `batch-<date>-<batchID>.log` (ex : `batch-20250803-BATCH-20250803-001.log`)
  - Les rapports synthétiques sont nommés `rapport-batch-<date>.md`
- **Organisation** :  
  - Les logs batch sont stockés dans un dossier dédié (`logs/batch/`), avec archivage automatique.
  - Les rapports Markdown sont centralisés à la racine documentaire ou dans `audit-reports/`.

## 7. Traçabilité Roo et liens croisés
<!--
Section listant les liens croisés vers les artefacts Roo pertinents pour la traçabilité et l’audit.
-->
- **Références croisées** :
  - [`batch_manager.go`](scripts/automatisation_doc/batch_manager.go:1)
  - [`batch_manager_test.go`](scripts/automatisation_doc/batch_manager_test.go:1)
  - [`AGENTS.md`](AGENTS.md:1)
  - [`plan-dev-v113-autmatisation-doc-roo.md`](projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md:1)
  - [`checklist-actionnable.md`](checklist-actionnable.md:1)
  - [`README.md`](README.md:1)
  - [`rules-plugins.md`](.roo/rules/rules-plugins.md:1)

## 8. Critères de validation Roo
<!--
Section listant les critères Roo pour valider la conformité des logs batch et du reporting.
-->
- Respect des statuts et du format structuré
- Présence d’identifiants uniques pour chaque erreur
- Journalisation systématique des hooks déclenchés
- Reporting synthétique conforme à la structure Roo
- Archivage et nommage des fichiers selon la convention
- Liens croisés et traçabilité documentaire assurés

---
<!--
Fin du rapport Roo.  
Ce document doit être mis à jour à chaque évolution des conventions de log ou du BatchManager.
-->