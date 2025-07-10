# Plan de Développement v84 — Automatisation Go/YAML

## 1. Correction syntaxique Go (`go.mod`, `go.work`)
- [x] Recensement des fichiers
- [x] Analyse d’écart
- [x] Recueil des besoins
- [x] Spécification
- [x] Développement du script de correction
- [x] Tests unitaires
- [x] Reporting
- [x] Validation CI
- [x] Rollback
- [x] Intégration CI/CD
- [x] Documentation
- [x] Traçabilité

## 2. Linting/correction YAML (Helm, CI/CD)
- [x] Recensement des fichiers YAML
- [x] Analyse d’écart
- [x] Recueil des besoins
- [x] Spécification
- [x] Développement du script de correction
- [x] Tests unitaires
- [x] Reporting
- [x] Validation CI
- [x] Rollback
- [x] Intégration CI/CD
- [x] Documentation
- [x] Traçabilité

## 3. Linting Go avancé sur tous modules
- [x] Recensement des modules
- [x] Analyse d’écart
- [x] Développement du script de lint/vet
- [x] Reporting
- [x] Validation CI
- [x] Intégration CI/CD
- [x] Documentation
- [x] Traçabilité

## 4. Reporting automatisé des erreurs
- [x] Développement du script d’agrégation
- [x] Archivage des rapports
- [x] Notification équipe
- [x] Intégration CI/CD
- [x] Documentation

## 5. Correction automatique style Go/YAML
- [x] Développement du script de formatage
- [x] Validation CI
- [x] Rollback
- [x] Documentation

## 6. Rollback automatisé
- [x] Développement du script de backup/restore
- [x] Documentation

## 7. Automatisations avancées de correction et de diagnostic

### 7.1 Correction automatique des erreurs de syntaxe Go (`go.mod`)
- [x] Script Go pour détecter et corriger automatiquement les directives inconnues (ex : `m odule` → `module`) ou lignes invalides en début de fichier.
- [x] Vérification systématique de la première ligne du `go.mod` pour s’assurer qu’elle commence par `module`.
- **Livrable** : `scripts/fix-go-mod-syntax.go`
- **Test** : `go test ./scripts/...`
- **Reporting** : Rapport Markdown/CSV des corrections syntaxiques Go.

### 7.2 Correction avancée YAML (Helm, CI/CD)
- [x] Amélioration du script `fix-yaml.go` pour corriger automatiquement :
    - erreurs d’indentation,
    - scalaires inattendus,
    - collections imbriquées non valides,
    - erreurs de type (`string | array` attendu).
- [x] Générer un rapport détaillé des corrections et des lignes problématiques.
- [x] Ajout d’un mode “auto-fix” qui tente de reformater les fichiers YAML problématiques et de signaler ceux qui nécessitent une intervention manuelle.
- **Livrable** : `scripts/fix-yaml-advanced.go`
- **Test** : `go test ./scripts/...`
- **Reporting** : Rapport Markdown/CSV des corrections YAML avancées.

### 7.3 Validation et correction des workflows GitHub Actions
- [x] Script Go pour détecter les accès contextuels invalides (`LOWERCASE_REPO`, `VERSION`, etc.) dans les fichiers `.github/workflows/*.yml` et suggérer des corrections ou des valeurs par défaut.
- **Livrable** : `scripts/fix-github-workflows.go`
- **Test** : `go test ./scripts/...`
- **Reporting** : Rapport Markdown/CSV des corrections et suggestions sur les workflows.

### 7.4 Reporting automatisé des erreurs non corrigées
- [x] Génération d’un rapport Markdown/CSV listant tous les fichiers et lignes où la correction automatique a échoué, pour faciliter la revue manuelle.
- **Livrable** : `audit-reports/unresolved-errors.md`
- **Script** : `scripts/report-unresolved-errors.go`

### 7.5 Tests de non-régression sur les correcteurs automatiques
- [x] Ajout de tests automatisés qui injectent des erreurs types dans des fichiers de test et valident que les scripts de correction les détectent et/ou corrigent.
- **Livrable** : `scripts/fix-go-mod-syntax_test.go`, `scripts/fix-yaml-advanced_test.go`, `scripts/fix-github-workflows_test.go`

## 8. Automatisations complémentaires pour erreurs résiduelles (69+)

### 8.1 Correction automatique avancée YAML/Helm
- [ ] Script Go pour corriger les erreurs de structure YAML complexes (block collections, implicit keys, flow collections, etc.) en restructurant les nœuds YAML et en reformattant les maps.
- [ ] Mode interactif ou semi-automatique pour les cas où la correction automatique échoue, avec suggestions ou patchs à valider manuellement.
- **Livrable** : `scripts/fix-yaml-structure.go`
- **Test** : `go test ./scripts/...`
- **Reporting** : Rapport Markdown/CSV des corrections structurelles YAML.

### 8.2 Détection et correction des types YAML (schéma)
- [ ] Script Go pour valider les fichiers YAML contre un schéma (ex : GitHub Sponsors) et proposer/concrétiser la conversion des types (string, array, objet).
- **Livrable** : `scripts/fix-yaml-schema.go`
- **Test** : `go test ./scripts/...`
- **Reporting** : Rapport Markdown/CSV des corrections de type YAML.

### 8.3 Correction automatique des erreurs de syntaxe Go non standards
- [ ] Extension du script de correction go.mod pour détecter et corriger d’autres directives inconnues ou lignes corrompues.
- **Livrable** : `scripts/fix-go-mod-advanced.go`
- **Test** : `go test ./scripts/...`
- **Reporting** : Rapport Markdown/CSV des corrections avancées go.mod.

### 8.4 Analyse et correction contextuelle des workflows CI/CD
- [ ] Script Go pour analyser les workflows et détecter les accès contextuels invalides, proposer des correctifs ou des valeurs de repli.
- **Livrable** : `scripts/fix-workflow-context.go`
- **Test** : `go test ./scripts/...`
- **Reporting** : Rapport Markdown/CSV des corrections contextuelles CI/CD.

### 8.5 Rapport interactif d’erreurs résiduelles
- [ ] Génération d’un rapport interactif (Markdown enrichi ou HTML) listant chaque erreur non corrigée, avec suggestion de patch, lien direct vers la ligne et bouton “corriger” ou “ignorer”.
- **Livrable** : `audit-reports/unresolved-errors-interactive.md`
- **Script** : `scripts/report-unresolved-errors-interactive.go`

### 8.6 Intégration d’un linter YAML/Helm plus robuste
- [ ] Intégration d’un linter externe (kubeval, yamllint, kubeconform) dans la CI/CD pour détecter les erreurs non gérées par les scripts natifs Go.
- **Livrable** : `.github/workflows/yaml-lint-external.yml`
- **Reporting** : Rapport YAML/Helm linter externe.

### 8.7 Automatisation de la création de tests de non-régression pour chaque type d’erreur détectée
- [ ] Génération automatique de cas de test pour chaque nouvelle erreur rencontrée, afin de garantir la non-régression lors des futures corrections.
- **Livrable** : `scripts/gen-nonreg-tests.go`
- **Test** : `go test ./scripts/...`
- **Reporting** : Rapport Markdown/CSV des nouveaux tests générés.

---

---
## Orchestration séquentielle multi-personas avec Jan
Toutes les tâches IA sont orchestrées via Jan, en mode mono-agent séquentiel, chaque persona étant simulé par un prompt système/contextuel distinct. L’historique des échanges est géré par le ContextManager et injecté à chaque tour.
