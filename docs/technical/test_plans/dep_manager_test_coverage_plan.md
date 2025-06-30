# Plan de Couverture des Tests Unitaires pour le Dependency Manager

Ce document identifie les composants du Dependency Manager qui nécessitent des tests unitaires et décrit la stratégie de couverture.

## Objectif

Assurer la robustesse, la fiabilité et la maintenabilité du Dependency Manager en couvrant les fonctionnalités critiques par des tests unitaires.

## Composants à Tester et Stratégie

Chaque script Go refactorisé pour exposer une fonction `RunX` exportable doit avoir son propre fichier de test (`_test.go`) dans le même répertoire que le script.

### 1. `audit_modules`

- **Fichier de Test** : `cmd/go/dependency-manager/audit_modules/audit_modules_test.go`
- **Fonctions à Tester** :
    - `RunAudit()` : Vérifier la détection correcte des `go.mod` et `go.sum`, l'extraction des informations de base (module name, version Go, dépendances), et l'identification des modules non conformes.
- **Cas de Test** :
    - Répertoire vide.
    - Répertoire avec un seul `go.mod` valide à la racine.
    - Répertoire avec plusieurs `go.mod` (certains non conformes).
    - Répertoire avec `go.sum` associés.
    - Répertoire avec des fichiers `vendor/` ou cachés (`.`).

### 2. `scan_non_compliant_imports`

- **Fichier de Test** : `cmd/go/dependency-manager/scan_non_compliant_imports/scan_non_compliant_imports_test.go`
- **Fonctions à Tester** :
    - `RunScan()` : Vérifier la détection des imports non conformes (imports relatifs, imports internes ne suivant pas la convention `email_sender/core/...`).
- **Cas de Test** :
    - Fichiers Go avec imports conformes.
    - Fichiers Go avec imports relatifs (`../`).
    - Fichiers Go avec imports non conformes à la convention `email_sender/core/...`.
    - Fichiers Go sans imports.
    - Fichiers Go avec erreurs de syntaxe (le parser devrait gérer cela).

### 3. `validate_monorepo_structure`

- **Fichier de Test** : `cmd/go/dependency-manager/validate_monorepo_structure/validate_monorepo_structure_test.go`
- **Fonctions à Tester** :
    - `RunValidation()` : Vérifier la validation de la structure du monorepo (un seul `go.mod` à la racine, `go mod tidy` et `go build` sans erreur).
- **Cas de Test** :
    - Structure monorepo valide.
    - Multiples `go.mod` (invalide).
    - Aucun `go.mod` (invalide).
    - `go mod tidy` échoue (invalide).
    - `go build ./...` échoue (invalide).

### 4. `plan_go_mod_deletion`

- **Fichier de Test** : `cmd/go/dependency-manager/plan_go_mod_deletion/plan_go_mod_deletion_test.go`
- **Fonctions à Tester** :
    - `RunPlan()` : Vérifier la génération correcte du plan de suppression (`go_mod_to_delete.json`, `go_mod_delete_plan.md`).
- **Cas de Test** :
    - Liste d'entrée avec des `go.mod`/`go.sum` secondaires.
    - Liste d'entrée sans `go.mod`/`go.sum` secondaires.
    - Fichiers d'entrée vides ou invalides.

### 5. `delete_go_mods`

- **Fichier de Test** : `cmd/go/dependency-manager/delete_go_mods/delete_go_mods_test.go`
- **Fonctions à Tester** :
    - `RunDelete()` : Vérifier la suppression effective des fichiers et la génération du rapport de suppression.
- **Cas de Test** :
    - Fichiers existants à supprimer.
    - Fichiers non existants.
    - Erreurs de permission.
    - Fichier d'entrée vide.

### 6. `scan_imports`

- **Fichier de Test** : `cmd/go/dependency-manager/scan_imports/scan_imports_test.go`
- **Fonctions à Tester** :
    - `RunScan()` : Vérifier la détection et le recensement des imports internes (conformes à `email_sender/core/...`).
- **Cas de Test** :
    - Fichiers Go avec divers imports internes.
    - Fichiers Go sans imports internes.
    - Fichiers Go avec imports externes et standard.

### 7. `generate_dep_report`

- **Fichier de Test** : `cmd/go/dependency-manager/generate_dep_report/generate_dep_report_test.go`
- **Fonctions à Tester** :
    - `RunGenerateReport()` : Vérifier la génération du rapport de dépendances complet (`dependencies_report.json`, `dependencies_report.md`).
- **Cas de Test** :
    - Projet Go avec dépendances directes et indirectes.
    - Projet Go sans dépendances.
    - Vérification de l'extraction des informations (`Path`, `Version`, `Main`, `Indirect`, `Dir`, `GoMod`).

### 8. `propose_go_mod_fixes`

- **Fichier de Test** : `cmd/go/dependency-manager/propose_go_mod_fixes/propose_go_mod_fixes_test.go`
- **Fonctions à Tester** :
    - `RunProposeFixes()` : Vérifier la génération du script de suppression et du plan d'action JSON.
- **Cas de Test** :
    - Liste d'entrée avec des `go.mod` parasites.
    - Liste d'entrée vide.
    - Vérification du contenu du script shell généré.

## Outils et Méthodologie

- **Framework de Test** : `testing` intégré de Go.
- **Mocks/Stubs** : Utilisation de mocks pour les appels système (ex: `os.Remove`, `exec.Command`) si nécessaire, pour isoler les tests unitaires.
- **Couverture de Code** : Maintenir une couverture de code élevée (cible > 80%) pour les fonctions testées.
- **Données de Test (Fixtures)** : Utiliser un répertoire `tests/fixtures/` pour stocker les données de test (ex: contenu de `go.mod` factices, extraits de code Go).

Ce plan assure une couverture de test adéquate pour les fonctionnalités clés du Dependency Manager.
