# Procédures de Rollback — PipelineManager Roo

> **Référence croisée** : [`pipeline_manager.go`](pipeline_manager.go), [`pipeline_schema.yaml`](pipeline_schema.yaml), [`pipeline_manager_report.md`](pipeline_manager_report.md), [`plan-dev-v113-autmatisation-doc-roo.md`](../../projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md), [`README.md`](../../README.md)

---

## 1. Contexte et objectifs

Le rollback du PipelineManager Roo vise à restaurer un état documentaire cohérent après :
- Échec d’exécution d’un pipeline (DAG, séquence, plugin)
- Erreur critique lors du chargement ou de la validation YAML
- Problème d’intégrité ou de cohérence détecté en production

Objectifs :
- Garantir la traçabilité et la réversibilité des opérations
- Limiter l’impact des erreurs sur les documents et workflows
- Permettre un retour rapide à un état stable, manuellement ou automatiquement

---

## 2. Procédures de rollback

### 2.1 Rollback automatisé via interface Go

- Utiliser la méthode `Rollback(ctx context.Context, id string) error` du PipelineManager.
- L’identifiant `id` correspond à l’exécution ou au pipeline à restaurer.
- Exemple d’appel :

```go
err := pipelineManager.Rollback(ctx, "pipeline-execution-uuid")
if err != nil {
    // Gestion d’erreur centralisée via ErrorManager
}
```

- La méthode restaure l’état documentaire à partir du snapshot ou de l’historique associé.

### 2.2 Rollback manuel (CLI ou script)

- Identifier l’exécution à annuler (via logs, reporting ou interface utilisateur).
- Restaurer le fichier YAML d’origine ou l’état documentaire sauvegardé.
- Exemple de commande PowerShell :

```powershell
# Restauration d’un snapshot YAML
Copy-Item -Path "backups/pipeline_XYZ.yaml.bak" -Destination "pipelines/pipeline_XYZ.yaml" -Force
```

- Vérifier la cohérence via la commande de validation :

```bash
go run scripts/automatisation_doc/pipeline_manager.go --validate pipelines/pipeline_XYZ.yaml
```

### 2.3 Rollback par plugin ou extension

- Si un plugin a modifié l’état, utiliser son propre mécanisme de rollback (voir documentation du plugin).
- Le PipelineManager doit appeler le hook de rollback du plugin si disponible.

---

## 3. Points de vigilance

- Toujours valider l’état restauré (YAML, logs, reporting) avant reprise des opérations.
- Documenter toute opération de rollback dans le reporting central.
- En cas d’échec du rollback, escalader vers le support ou l’équipe d’architecture.

---

## 4. Critères de validation

- L’état documentaire après rollback est conforme au schéma [`pipeline_schema.yaml`](pipeline_schema.yaml)
- Les tests unitaires passent sur l’état restauré
- Aucun workflow bloqué ou incohérent après rollback
- Traçabilité complète dans les logs et le reporting

---

## 5. Liens croisés et ressources

- [pipeline_manager.go](pipeline_manager.go)
- [pipeline_schema.yaml](pipeline_schema.yaml)
- [pipeline_manager_report.md](pipeline_manager_report.md)
- [plan-dev-v113-autmatisation-doc-roo.md](../../projet/roadmaps/plans/consolidated/plan-dev-v113-autmatisation-doc-roo.md)
- [README.md](../../README.md)
- [checklist-actionnable.md](../../checklist-actionnable.md)

---

## 6. Risques & mitigation

- **Rollback incomplet** : valider systématiquement l’état restauré, prévoir des tests de non-régression.
- **Perte de données** : toujours effectuer une sauvegarde avant toute opération critique.
- **Dérive documentaire** : croiser les logs, reporting et états YAML pour détecter toute incohérence.

---

## 7. Auto-critique & axes d’amélioration

- Limite : le rollback dépend de la qualité des snapshots et de la granularité de l’historique.
- Suggestion : automatiser la sauvegarde avant chaque exécution critique, renforcer les hooks de rollback plugin.
- Feedback : intégrer des tests de rollback dans la CI/CD et enrichir la documentation utilisateur.
