# Spécification de l'Orchestrateur Global

Ce document spécifie l'orchestrateur global qui coordonnera l'exécution séquentielle des différents scripts d'automatisation du projet.

## 1. Objectifs

- Automatiser l'exécution de la feuille de route de développement.
- Gérer les dépendances entre les scripts.
- Fournir un point d'entrée unique pour l'exécution des tâches complexes.
- Améliorer la traçabilité et le reporting des opérations automatisées.

## 2. Fonctionnalités

### 2.1 Exécution Séquentielle des Scripts

L'orchestrateur exécutera les scripts dans un ordre prédéfini, en gérant les dépendances.
- **Scripts à orchestrer**:
    - `cmd/audit_read_file/audit_read_file.go`
    - `cmd/gap_analysis/gap_analysis.go`
    - `scripts/gen_user_needs_template.sh`
    - `scripts/collect_user_needs.sh`
    - `scripts/validate_and_archive_user_needs.sh`
    - `cmd/gen_read_file_spec/gen_read_file_spec.go`
    - `scripts/archive_spec.sh`
    - `pkg/common/read_file.go` (construction/tests)
    - `pkg/common/read_file_test.go` (exécution tests)
    - `cmd/read_file_navigator/read_file_navigator.go` (construction/tests)
    - `scripts/vscode_read_file_selection.js` (validation)
    - `scripts/gen_read_file_report.go`
    - `docs/read_file_README.md` (validation)
    - `scripts/collect_user_feedback.sh` (collecte)
    - `scripts/collect_user_feedback.ps1` (collecte)
    - `cmd/audit_rollback_points/audit_rollback_points.go`
    - `cmd/gen_rollback_spec/gen_rollback_spec.go`
    - `scripts/backup/backup.go`
    - `scripts/backup/backup_test.go`
    - `scripts/git_versioning.sh`
    - `scripts/gen_rollback_report/gen_rollback_report.go`

### 2.2 Gestion des Erreurs et Reprise

- En cas d'échec d'un script, l'orchestrateur doit:
    - Enregistrer l'erreur.
    - Arrêter l'exécution ou tenter une reprise selon la configuration.
    - Notifier l'utilisateur.

### 2.3 Reporting Centralisé

- Générer un rapport global de l'exécution de l'orchestrateur, incluant le statut de chaque script, les logs pertinents et les erreurs.

## 3. Architecture Proposée (`cmd/auto-roadmap-runner.go`)

L'orchestrateur sera un binaire Go autonome, capable d'exécuter d'autres commandes shell ou Go.

```go
// cmd/auto-roadmap-runner.go (Structure simplifiée)
package main

import (
	"fmt"
	"os/exec"
)

func main() {
	fmt.Println("# Orchestration globale : démarrage")
	
	// Exemple d'exécution d'un script Go
	cmd := exec.Command("go", "run", "cmd/audit_read_file/audit_read_file.go")
	output, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Printf("Erreur lors de l'exécution de l'audit: %v\n%s\n", err, output)
		os.Exit(1)
	}
	fmt.Println("Audit read_file terminé.")
	
	// ... autres exécutions de scripts ...

	fmt.Println("# Orchestration globale : terminée")
}
```

## 4. Critères d'Acceptation

- L'orchestrateur doit exécuter tous les scripts définis dans le plan.
- Les dépendances entre les scripts doivent être respectées.
- Le reporting doit être clair et complet.
- La gestion des erreurs doit être robuste.
- Le script doit être facile à configurer et à étendre.

## 5. Plan de Tests

- **Tests Unitaires**: Pour la logique interne de l'orchestrateur (gestion des dépendances, erreurs).
- **Tests d'Intégration**: Exécution de chaînes complètes de scripts et vérification des sorties.

## 6. Exigences Non Fonctionnelles

- **Performance**: L'orchestrateur ne doit pas introduire de latence significative.
- **Sécurité**: Exécution sécurisée des scripts.
- **Maintenabilité**: Code modulaire et bien commenté.

---
**Date de génération**: 2025-06-28 20:29:24 CEST
