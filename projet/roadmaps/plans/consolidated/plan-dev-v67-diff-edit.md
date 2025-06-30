# Plan de Développement v67 - Intégration de la méthode diff Edit (Cline)

---

## Roadmap Granularisée & Actionnable (Standards avancés .clinerules/)

### 1. Analyse et Spécifications

- [ ] **Recensement des cas d’usage**
  - Livrable : `usecases_diffedit.md`
  - Commande : `go run cmd/roadmap-runner/main.go --list-usecases`
  - Script Go à créer : `core/scanmodules/usecase_scanner.go` (+ test)
  - Format : Markdown
  - Validation : revue croisée, log d’exécution
  - Traçabilité : commit Git, log JSON

- [ ] **Analyse d’écart**
  - Livrable : `gap_analysis_diffedit.md`
  - Commande : `go run core/gapanalyzer/gapanalyzer.go --target=diffedit`
  - Script Go à adapter : `core/gapanalyzer/gapanalyzer.go` (+ test)
  - Format : Markdown/CSV
  - Validation : badge de couverture, rapport CI
  - Rollback : backup `.bak`, commit revert

- [ ] **Recueil des besoins**
  - Livrable : `requirements_diffedit.md`
  - Commande : `go run cmd/roadmap-runner/main.go --collect-requirements`
  - Script Go à créer : `core/scanmodules/requirements_collector.go` (+ test)
  - Format : Markdown
  - Validation : feedback équipe, log
  - Traçabilité : versionning, log

- [ ] **Spécification détaillée**
  - Livrable : `spec_diffedit.md`
  - Commande : `go run cmd/docgen/main.go --spec=diffedit`
  - Script Go à créer : `core/docmanager/spec_generator.go` (+ test)
  - Format : Markdown
  - Validation : lint Markdown, revue croisée
  - Rollback : backup, commit revert

---

### 2. Développement CLI/Script

- [ ] **Développement du parser diff Edit**
  - Livrable : `core/diffedit/parser.go`, `core/diffedit/parser_test.go`
  - Commande : `go test ./core/diffedit/`
  - Script Go natif prioritaire, tests unitaires
  - Format : Go, JSON pour logs
  - Validation : badge couverture, CI
  - Rollback : git revert

- [ ] **Gestion fichiers & encodage**
  - Livrable : `core/diffedit/filehandler.go`, `core/diffedit/filehandler_test.go`
  - Commande : `go test ./core/diffedit/`
  - Format : Go, logs JSON
  - Validation : tests, logs, CI
  - Rollback : backup `.bak`

- [ ] **Backup & rollback automatique**
  - Livrable : `core/diffedit/backup.go`, `core/diffedit/backup_test.go`
  - Commande : `go test ./core/diffedit/`
  - Validation : test restauration, logs
  - Rollback : restauration `.bak`

- [ ] **Batch mode & reporting**
  - Livrable : `core/diffedit/batch.go`, `core/diffedit/batch_test.go`, `reports/diffedit_batch_report.json`
  - Commande : `go run core/diffedit/batch.go --input=...`
  - Format : JSON, Markdown
  - Validation : rapport CI, logs
  - Rollback : rollback ciblé

---

### 3. Intégration VS Code

- [ ] **Snippet & génération bloc**
  - Livrable : `.vscode/diffedit-snippets.code-snippets`
  - Commande : palette VS Code
  - Validation : test manuel, log insertion
  - Traçabilité : commit snippet

- [ ] **Extension application patch**
  - Livrable : `vscode-extension/`, `vscode-extension/test/`
  - Commande : palette, output pane
  - Script Node.js à créer, tests associés
  - Validation : badge CI extension, logs
  - Rollback : désinstallation extension

---

### 4. Automatisation & CI/CD

- [ ] **Hook pre-commit**
  - Livrable : `.git/hooks/pre-commit-diffedit.sh`
  - Commande : `bash .git/hooks/pre-commit-diffedit.sh`
  - Validation : blocage commit si erreur, log
  - Rollback : suppression hook

- [ ] **Pipeline CI**
  - Livrable : `.github/workflows/diffedit.yml`
  - Commande : `go test`, `go run ...`
  - Validation : badge CI, rapport coverage
  - Rollback : revert pipeline

- [ ] **Reporting & monitoring**
  - Livrable : `reports/diffedit_ci_report.json`
  - Commande : `go run core/diffedit/report.go`
  - Format : JSON, HTML
  - Validation : archivage rapport, notification
  - Traçabilité : logs, artefacts CI

---

### 5. Gestion des erreurs & robustesse

- [ ] **Tests SEARCH non unique/absent**
  - Livrable : `core/diffedit/error_test.go`
  - Commande : `go test`
  - Validation : badge test, log erreur
  - Rollback : backup, log

- [ ] **Gestion encodage & gros fichiers**
  - Livrable : `core/diffedit/encoding.go`, `core/diffedit/encoding_test.go`
  - Commande : `go test`
  - Validation : logs, badge test
  - Rollback : skip fichier, log

---

### 6. Documentation & Exemples

- [ ] **README & guides**
  - Livrable : `README.md`, `docs/diffedit_guide.md`
  - Validation : lint Markdown, revue croisée
  - Traçabilité : versionning

- [ ] **Exemples & FAQ**
  - Livrable : `examples/`, `docs/FAQ.md`
  - Validation : test manuel, feedback équipe

---

### 7. Orchestration & CI/CD

- [ ] **Orchestrateur global**
  - Livrable : `cmd/auto-roadmap-runner/main.go`
  - Commande : `go run cmd/auto-roadmap-runner/main.go`
  - Validation : logs, badge CI, reporting
  - Rollback : git revert

- [ ] **Intégration pipeline**
  - Livrable : `.github/workflows/auto-roadmap.yml`
  - Commande : CI/CD, badge, notification
  - Validation : reporting, artefacts

---

### 8. Traçabilité & standards .clinerules/

- [ ] **Logs & versionning**
  - Livrable : `logs/diffedit.log`, `logs/diffedit_history.json`
  - Validation : archivage, reporting

- [ ] **Validation croisée & automatisation**
  - Livrable : badge CI, rapport revue croisée
  - Validation : logs, feedback automatisé

---

## Dépendances & Procédures

- Chaque étape dépend de la validation de la précédente (ex : parser avant batch, batch avant CI).
- Avant toute suppression/modification de masse, générer la liste des fichiers concernés et demander confirmation.
- Procéder par étapes atomiques, vérifier l’état du projet avant/après chaque modification majeure.
- Si une tâche n’est pas automatisable, fournir un script Go minimal ou une commande Bash, ou expliciter la procédure manuelle et la traçabilité.

---

## Exemples de scripts Go natifs

- `core/diffedit/parser.go` : parsing SEARCH/REPLACE, tests unitaires.
- `core/diffedit/filehandler.go` : gestion fichiers, backup, rollback.
- `core/diffedit/batch.go` : traitement batch, reporting JSON.
- `cmd/auto-roadmap-runner/main.go` : orchestration globale, reporting CI.

---

## Robustesse & Adaptation LLM

- Actions atomiques, vérification état avant/après.
- Signalement immédiat en cas d’échec, alternative proposée.
- Limitation profondeur modifications, traçabilité maximale.
- Scripts Bash/Go proposés si automatisation impossible.

---

## [ ] Cases à cocher pour chaque livrable/action (à compléter lors de l’exécution)

- [ ] Recensement usecases
- [ ] Analyse d’écart
- [ ] Recueil besoins
- [ ] Spécification détaillée
- [ ] Développement parser
- [ ] Gestion fichiers/encodage
- [ ] Backup/rollback
- [ ] Batch mode/reporting
- [ ] Snippet VS Code
- [ ] Extension VS Code
- [ ] Hook pre-commit
- [ ] Pipeline CI
- [ ] Reporting/monitoring
- [ ] Tests erreurs/robustesse
- [ ] Documentation/guides
- [ ] Exemples/FAQ
- [ ] Orchestrateur global
- [ ] Intégration pipeline
- [ ] Logs/versionning
- [ ] Validation croisée
