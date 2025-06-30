# Dependency Manager - Documentation Technique

Ce document fournit une documentation technique détaillée pour le Dependency Manager, y compris son architecture, le fonctionnement de ses scripts, les structures de données utilisées, et les directives de contribution.

## Table des Matières

- [Architecture](#architecture)
- [Concepts Clés](#concepts-clés)
- [Utilisation des Scripts](#utilisation-des-scripts)
    - [audit_modules](#audit_modules)
    - [scan_non_compliant_imports](#scan_non_compliant_imports)
    - [validate_monorepo_structure](#validate_monorepo_structure)
    - [plan_go_mod_deletion](#plan_go_mod_deletion)
    - [delete_go_mods](#delete_go_mods)
    - [scan_imports](#scan_imports)
    - [generate_dep_report](#generate_dep_report)
    - [propose_go_mod_fixes](#propose_go_mod_fixes)
- [Structures de Données](#structures-de-données)
- [Gestion des Erreurs](#gestion-des-erreurs)
- [Contribution](#contribution)

---

## Architecture

Le Dependency Manager est une suite de scripts Go conçus pour automatiser la gestion des dépendances et la conformité de la structure d'un monorepo Go. Chaque script est un exécutable indépendant, mais ils sont conçus pour fonctionner ensemble dans un pipeline CI/CD.

- **Structure des scripts** : Chaque fonctionnalité est encapsulée dans un package Go séparé (`cmd/go/dependency-manager/<feature_name>/`). Le point d'entrée de chaque exécutable est `main.go`, qui expose une fonction `RunX()` pour permettre les tests unitaires et l'intégration programmatique.
- **Rapports** : Les scripts génèrent des rapports au format JSON (pour l'analyse machine) et Markdown (pour la lecture humaine), stockés dans `development/managers/dependency-manager/reports/`.
- **Automatisation** : L'intégration CI/CD est gérée via GitHub Actions (`.github/workflows/ci-pipeline.yml`).

## Concepts Clés

- **Monorepo Go** : Un seul dépôt Git contenant plusieurs modules Go. La convention préférée est d'avoir un seul `go.mod` à la racine du dépôt.
- **Imports Conformes** : Les imports internes au projet doivent suivre la convention `email_sender/core/...`. Tout import interne ne respectant pas ce format ou utilisant des chemins relatifs (`./`, `../`) est considéré comme non conforme.
- **Dépendances Directes vs. Indirectes** : Distinction entre les dépendances directement listées dans `go.mod` et celles requises par les dépendances directes.
- **Modules Parasites** : Tout fichier `go.mod` ou `go.sum` qui n'est pas situé à la racine du monorepo est considéré comme parasite et doit être supprimé pour maintenir la cohérence.

## Utilisation des Scripts

Chaque script peut être exécuté indépendamment. Les chemins de sortie sont généralement horodatés pour conserver un historique des rapports.

### `audit_modules`

Scanne le monorepo pour recenser tous les fichiers `go.mod` et `go.sum`, et identifie les modules Go détectés, leur emplacement et leurs dépendances initiales. Il détecte également les modules non conformes à la convention `email_sender/core/...` ou qui ne sont pas à la racine.

- **Chemin** : `cmd/go/dependency-manager/audit_modules/main.go`
- **Fonction Exportée** : `RunAudit(outputJSONPath, outputMDPath string) error`
- **Arguments CLI** :
    - `--output-json <path>` : Chemin pour le rapport JSON.
    - `--output-md <path>` : Chemin pour le rapport Markdown.
- **Exemple d'utilisation** :
  ```bash
  go run email_sender/cmd/go/dependency-manager/audit_modules/main.go --output-json development/managers/dependency-manager/reports/$(date +%Y%m%d%H%M%S)/initial_go_mod_list.json --output-md development/managers/dependency-manager/reports/$(date +%Y%m%d%H%M%S)/initial_module_audit.md
  ```
- **Livrables** : `initial_go_mod_list.json`, `initial_module_audit.md`

### `scan_non_compliant_imports`

Analyse les fichiers `.go` pour détecter les imports qui ne respectent pas la convention `email_sender/core/...` (ex: imports relatifs, imports basés sur le chemin du fichier).

- **Chemin** : `cmd/go/dependency-manager/scan_non_compliant_imports/main.go`
- **Fonction Exportée** : `RunScan(outputJSONPath, outputMDPath string) (ScanReport, error)`
- **Arguments CLI** :
    - `--output-json <path>` : Chemin pour le rapport JSON des imports non conformes.
    - `--output-md <path>` : Chemin pour le rapport Markdown des imports non conformes.
- **Exemple d'utilisation** :
  ```bash
  go run email_sender/cmd/go/dependency-manager/scan_non_compliant_imports/main.go --output-json development/managers/dependency-manager/reports/$(date +%Y%m%d%H%M%S)/non_compliant_imports.json --output-md development/managers/dependency-manager/reports/$(date +%Y%m%d%H%M%S)/non_compliant_imports_report.md
  ```
- **Livrables** : `non_compliant_imports.json`, `non_compliant_imports_report.md`

### `validate_monorepo_structure`

Vérifie qu'il ne reste qu'un seul `go.mod` à la racine, exécute `go mod tidy` et `go build ./...`, et génère un rapport JSON de validation.

- **Chemin** : `cmd/go/dependency-manager/validate_monorepo_structure/main.go`
- **Fonction Exportée** : `RunValidation() (ValidationReport, error)`
- **Arguments CLI** :
    - `--output-json <path>` : Chemin pour le rapport JSON de validation.
- **Exemple d'utilisation** :
  ```bash
  go run email_sender/cmd/go/dependency-manager/validate_monorepo_structure/main.go --output-json development/managers/dependency-manager/reports/$(date +%Y%m%d%H%M%S)/monorepo_structure_validation.json
  ```
- **Livrables** : `monorepo_structure_validation.json`

### `plan_go_mod_deletion`

Génère la liste des `go.mod` et `go.sum` secondaires à supprimer (hors racine), basée sur un audit précédent.

- **Chemin** : `cmd/go/dependency-manager/plan_go_mod_deletion/main.go`
- **Fonction Exportée** : `RunPlan(inputGoModListPath, inputGoSumListPath, outputJSONPath, outputMDPath string) (PlanReport, error)`
- **Arguments CLI** :
    - `--input-go-mod-list <path>` : Fichier JSON listant tous les `go.mod` (généré par `audit_modules`).
    - `--input-go-sum-list <path>` : Fichier JSON listant tous les `go.sum` (généré par `audit_modules`).
    - `--output-json <path>` : Chemin pour le plan de suppression JSON.
    - `--output-md <path>` : Chemin pour le rapport Markdown du plan de suppression.
- **Exemple d'utilisation** :
  ```bash
  go run email_sender/cmd/go/dependency-manager/plan_go_mod_deletion/main.go --input-go-mod-list development/managers/dependency-manager/reports/<timestamp_audit>/initial_go_mod_list.json --input-go-sum-list development/managers/dependency-manager/reports/<timestamp_audit>/initial_go_sum_list.json --output-json development/managers/dependency-manager/reports/$(date +%Y%m%d%H%M%S)/go_mod_to_delete.json --output-md development/managers/dependency-manager/reports/$(date +%Y%m%d%H%M%S)/go_mod_delete_plan.md
  ```
- **Livrables** : `go_mod_to_delete.json`, `go_mod_delete_plan.md`

### `delete_go_mods`

Supprime les fichiers `go.mod` et `go.sum` listés dans un fichier JSON. Génère un rapport JSON du succès/échec de chaque suppression.

- **Chemin** : `cmd/go/dependency-manager/delete_go_mods/main.go`
- **Fonction Exportée** : `RunDelete(inputJSONPath, outputReportPath string) error`
- **Arguments CLI** :
    - `--input-json <path>` : Fichier JSON listant les fichiers à supprimer (généré par `plan_go_mod_deletion`).
    - `--report <path>` : Chemin pour le rapport JSON de suppression.
- **Exemple d'utilisation** :
  ```bash
  go run email_sender/cmd/go/dependency-manager/delete_go_mods/main.go --input-json development/managers/dependency-manager/reports/<timestamp_plan>/go_mod_to_delete.json --report development/managers/dependency-manager/reports/$(date +%Y%m%d%H%M%S)/go_mod_deletion_report.json
  ```
- **Livrables** : `go_mod_deletion_report.json`

### `scan_imports`

Scanne tous les fichiers `.go` du monorepo pour recenser les imports internes (conformes à `email_sender/core/...`).

- **Chemin** : `cmd/go/dependency-manager/scan_imports/main.go`
- **Fonction Exportée** : `RunScan(rootDir, outputJSONPath, outputMDPath string) (ScanReport, error)`
- **Arguments CLI** :
    - `--root <path>` : Racine du monorepo à scanner (par défaut `.` pour le répertoire courant).
    - `--output-json <path>` : Chemin pour le rapport JSON des imports.
    - `--output-md <path>` : Chemin pour le rapport Markdown des imports.
- **Exemple d'utilisation** :
  ```bash
  go run email_sender/cmd/go/dependency-manager/scan_imports/main.go --output-json development/managers/dependency-manager/reports/$(date +%Y%m%d%H%M%S)/list_internal_imports.json --output-md development/managers/dependency-manager/reports/$(date +%Y%m%d%H%M%S)/report_internal_imports.md
  ```
- **Livrables** : `list_internal_imports.json`, `report_internal_imports.md`

### `generate_dep_report`

Génère un rapport détaillé des dépendances Go du monorepo, incluant versions, chemins, et informations sur les modules principaux/indirects.

- **Chemin** : `cmd/go/dependency-manager/generate_dep_report/main.go`
- **Fonction Exportée** : `RunGenerateReport(outputJSONPath, outputMDPath, outputSVGPath string) (DependenciesReport, error)`
- **Arguments CLI** :
    - `--output-json <path>` : Chemin pour le rapport JSON des dépendances.
    - `--output-md <path>` : Chemin pour le rapport Markdown des dépendances.
    - `--output-svg <path>` : Chemin pour le graphique SVG des dépendances (actuellement un placeholder).
- **Exemple d'utilisation** :
  ```bash
  go run email_sender/cmd/go/dependency-manager/generate_dep_report/main.go --output-json development/managers/dependency-manager/reports/$(date +%Y%m%d%H%M%S)/dependencies_report.json --output-md development/managers/dependency-manager/reports/$(date +%Y%m%d%H%M%S)/dependencies_report.md --output-svg development/managers/dependency-manager/reports/$(date +%Y%m%d%H%M%S)/dependencies_graph.svg
  ```
- **Livrables** : `dependencies_report.json`, `dependencies_report.md`, `dependencies_graph.svg` (placeholder)

### `propose_go_mod_fixes`

Prend en entrée la liste des `go.mod` parasites, génère un script shell pour les supprimer, et un plan d'action JSON. Peut potentiellement générer un patch pour ajuster les imports (non implémenté).

- **Chemin** : `cmd/go/dependency-manager/propose_go_mod_fixes/main.go`
- **Fonction Exportée** : `RunProposeFixes(inputJSONPath, outputScriptPath, outputPatchPath, outputJSONReportPath string) (FixPlanReport, error)`
- **Arguments CLI** :
    - `--input-json <path>` : Fichier JSON listant les `go.mod` parasites (généré par `scan_go_mods`).
    - `--output-script <path>` : Chemin pour le script shell de suppression.
    - `--output-patch <path>` : Chemin pour le fichier de patch (non implémenté).
    - `--output-json-report <path>` : Chemin pour le rapport JSON du plan de correction.
- **Exemple d'utilisation** :
  ```bash
  go run email_sender/cmd/go/dependency-manager/propose_go_mod_fixes/main.go --input-json development/managers/dependency-manager/reports/<timestamp_scan_go_mods>/list_go_mod_parasites.json --output-script development/managers/dependency-manager/reports/$(date +%Y%m%d%H%M%S)/fix_go_mod_parasites.sh --output-patch development/managers/dependency-manager/reports/$(date +%Y%m%d%H%M%S)/fix_go_mod_parasites.patch --output-json-report development/managers/dependency-manager/reports/$(date +%Y%m%d%H%M%S)/go_mod_fix_plan.json
  ```
- **Livrables** : `fix_go_mod_parasites.sh`, `fix_go_mod_parasites.patch` (placeholder), `go_mod_fix_plan.json`

---

## Structures de Données

Voici les définitions des structures Go utilisées par les scripts du Dependency Manager pour les rapports et la communication interne.

- `GoModInfo` (utilisé par `audit_modules`)
- `AuditReport` (utilisé par `audit_modules`)
- `NonCompliantImport` (utilisé par `scan_non_compliant_imports`)
- `ScanReport` (utilisé par `scan_non_compliant_imports` et `scan_imports`)
- `ValidationReport` (utilisé par `validate_monorepo_structure`)
- `PlanReport` (utilisé par `plan_go_mod_deletion`)
- `DeletionResult` (utilisé par `delete_go_mods`)
- `DeletionReport` (utilisé par `delete_go_mods`)
- `FileImports` (utilisé par `scan_imports`)
- `DependenciesReport` (utilisé par `generate_dep_report`)
- `FixPlanReport` (utilisé par `propose_go_mod_fixes`)

*(Les définitions exactes des structs se trouvent dans les fichiers `main.go` de chaque script.)*

---

## Gestion des Erreurs

Chaque fonction `RunX()` et `main()` des scripts est conçue pour retourner un code d'erreur non nul en cas de problème, permettant une intégration facile dans les pipelines CI/CD où un échec de commande peut arrêter le workflow. Les messages d'erreur sont détaillés pour faciliter le débogage.

---

## Contribution

Pour contribuer au Dependency Manager :

1.  **Cloner le dépôt.**
2.  **Installer Go** (version 1.21 ou supérieure).
3.  **Exécuter les tests unitaires** : `go test email_sender/cmd/go/dependency-manager/...`
4.  **Développer** : Ajouter de nouvelles fonctionnalités ou corriger des bugs dans les scripts existants. Assurez-vous que les nouvelles fonctionnalités ont des tests unitaires correspondants.
5.  **Mettre à jour la documentation** : Si des changements affectent le comportement ou l'interface des scripts, mettez à jour ce document et les plans associés.
6.  **Soumettre une Pull Request.**

---
