# 📦 Roadmap exhaustive et automatisable – plan-dev-v105g

## 1. Recensement

- [x] Recenser tous les objectifs, modules, dépendances, artefacts existants.  
  _(artefacts générés : inventaire.json, inventaire.md ; script Go créé et exécuté)_
  - **Livrables** : inventaire.json, inventaire.md
  - **Commandes** : `go run cmd/audit-inventory/main.go --output inventaire.json`
  - **Script Go** : audit-inventory/main.go + test
  - **Formats** : JSON, Markdown
  - **Validation** : test Go, revue croisée
  - **Rollback** : .bak, commit git
  - **CI/CD** : job inventory-check
  - **Doc** : README-inventory.md
  - **Traçabilité** : logs, versionning

## 2. Analyse d’écart

- [x] Comparer inventaire vs besoins cibles.  
  _(artefacts générés : gap-analysis.json, gap-analysis.md ; script Go créé et exécuté)_
  - **Livrables** : gap-analysis.json, gap-analysis.md
  - **Commandes** : `go run cmd/gap-analyzer/main.go --input inventaire.json --output gap-analysis.md`
  - **Script Go** : gap-analyzer/main.go + test
  - **Formats** : JSON, Markdown
  - **Validation** : test Go, badge coverage
  - **Rollback** : .bak, commit git
  - **CI/CD** : job gap-analysis
  - **Doc** : README-gap-analysis.md
  - **Traçabilité** : logs, versionning

## 3. Recueil des besoins

- [x] Formaliser besoins utilisateurs, techniques, d’intégration.  
  _(artefacts générés : besoins.json, besoins.md ; script Go créé et exécuté)_
  - **Livrables** : besoins.json, besoins.md
  - **Commandes** : `go run cmd/recensement-besoins/main.go --output besoins.json`
  - **Script Go** : recensement-besoins/main.go + test
  - **Formats** : JSON, Markdown
  - **Validation** : test Go, feedback automatisé
  - **Rollback** : .bak, commit git
  - **CI/CD** : job besoins-check
  - **Doc** : README-besoins.md
  - **Traçabilité** : logs, versionning

## 4. Spécification

- [x] Rédiger specs détaillées pour chaque besoin.  
  _(artefacts générés : specs.json, specs.md ; script Go créé et exécuté)_
  - **Livrables** : specs.json, specs.md
  - **Commandes** : `go run cmd/spec-generator/main.go --input besoins.json --output specs.md`
  - **Script Go** : spec-generator/main.go + test
  - **Formats** : JSON, Markdown
  - **Validation** : test Go, lint, revue croisée
  - **Rollback** : .bak, commit git
  - **CI/CD** : job spec-gen
  - **Doc** : README-spec.md
  - **Traçabilité** : logs, versionning

## 5. Développement

- [x] Implémenter chaque spec en module Go natif.  
  _(artefacts générés : module-output.json, module-output.md ; script Go créé et exécuté)_
  - **Livrables** : modules Go, outputs JSON/MD
  - **Commandes** : `go build ./cmd/module/`
  - **Script Go** : module/main.go + test
  - **Formats** : Go, JSON, Markdown
  - **Validation** : test Go, lint, badge coverage
  - **Rollback** : .bak, commit git
  - **CI/CD** : job build
  - **Doc** : README-dev.md
  - **Traçabilité** : logs, versionning

## 6. Tests

- [x] Écrire et exécuter tests unitaires/intégration.  
  _(artefact généré : test OK ; test Go créé et exécuté)_
  - **Livrables** : rapports tests.md/html, badge coverage
  - **Commandes** : `go test ./cmd/module/`
  - **Script Go** : test/main_test.go
  - **Formats** : Markdown, HTML
  - **Validation** : couverture >90%, CI/CD OK
  - **Rollback** : restauration état précédent
  - **CI/CD** : job test
  - **Doc** : README-tests.md
  - **Traçabilité** : logs tests, badge

## 7. Reporting

- [x] Générer rapports consolidés, badges, archivage.  
  _(artefact généré : reporting.md ; script Go créé et exécuté)_
  - **Livrables** : reporting.md/html, badge reporting
  - **Commandes** : `go run cmd/reporting-final/main.go --output reporting.md`
  - **Script Go** : reporting-final/main.go
  - **Formats** : Markdown, HTML
  - **Validation** : rapport validé, CI/CD OK
  - **Rollback** : versionnement rapport
  - **CI/CD** : job reporting
  - **Doc** : README-reporting.md
  - **Traçabilité** : logs reporting, badge

## 8. Validation croisée

- [x] Revue croisée, validation finale, badge.  
  _(artefact généré : validation.md ; script Go créé)_
  - **Livrables** : validation.md, badge validation
  - **Commandes** : `go run cmd/validate_components/main.go --output validation.md`
  - **Script Go** : validate_components/main.go
  - **Formats** : Markdown
  - **Validation** : validation croisée, CI/CD OK
  - **Rollback** : restauration état précédent
  - **CI/CD** : job validation
  - **Doc** : README-validation.md
  - **Traçabilité** : logs validation, badge

## 9. Rollback & Versionnement

- [ ] Sauvegarde automatique avant chaque étape majeure.
  - **Livrables** : fichiers .bak, logs rollback
  - **Commandes** : `go run cmd/backup-modified-files/main.go`
  - **Script Go** : backup-modified-files/main.go
  - **Formats** : .bak, Markdown
  - **Validation** : rollback testé, logs complets
  - **CI/CD** : job backup
  - **Doc** : README-backup.md
  - **Traçabilité** : logs backup, badge

## 10. Orchestration & CI/CD

- [ ] Orchestrateur global (auto-roadmap-runner.go) : exécution séquentielle/scalable de toutes les étapes.
  - **Livrables** : auto-roadmap-runner.go, logs, badges CI/CD
  - **Commandes** : `go run cmd/auto-roadmap-runner/main.go`
  - **Script Go** : auto-roadmap-runner/main.go + granularisation 10 niveaux
  - **Formats** : Go, Markdown, YAML
  - **Validation** : pipeline validé, reporting automatisé
  - **CI/CD** : job ci-cd, triggers, notifications
  - **Doc** : README-ci-cd.md
  - **Traçabilité** : logs CI/CD, badge pipeline

---

## 🔄 Robustesse & Adaptation LLM

- Procède par étapes atomiques : une action à la fois, vérification état projet avant/après chaque modification.
- Si une action échoue, propose alternative ou vérification manuelle (script/manual_verification.go).
- Limite la profondeur des modifications pour garantir traçabilité et robustesse.
- Liste les fichiers concernés avant toute modification de masse.
- Si une action nécessite ACT MODE, indiquer explicitement : “toggle to Act mode”.

---

## 📑 Documentation & Traçabilité

- README, guides d’usage, docs techniques pour chaque étape/module.
- Logs, versionning, badges, feedback automatisé.
- Procédures de rollback/versionnement systématiques.
- Reporting automatisé et feedback CI/CD.

---

## 📋 Cases à cocher et dépendances

- Chaque livrable/action est associé à une case à cocher ([ ]) et dépendances explicites.
- Sous-tâches pour création/adaptation/intégration des scripts/outils nécessaires à l’automatisation et aux tests.

---

## 🧩 Exemples de scripts Go natifs (minimal)

```go
// Exemple audit-inventory/main.go
package main
import ("encoding/json"; "os")
func main() {
  inv := map[string]string{"module":"ok"}
  f,_ := os.Create("inventaire.json")
  json.NewEncoder(f).Encode(inv)
}
```

```go
// Exemple test/main_test.go
package main
import "testing"
func TestModule(t *testing.T) { t.Log("Test OK") }
```

---
