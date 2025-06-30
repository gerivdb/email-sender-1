# Plan d'Intégration CI/CD pour le Dependency Manager

Ce document décrit les modifications et les ajouts nécessaires au pipeline CI/CD pour intégrer le Dependency Manager et ses scripts de cohérence.

## Objectifs

- Automatiser l'exécution des scripts du Dependency Manager (audit, scan, planification, génération de rapports).
- Assurer la conformité des dépendances et de la structure du monorepo à chaque push/pull request.
- Fournir des retours rapides et des rapports détaillés sur l'état des dépendances.
- Configurer des notifications en cas d'échec des vérifications.

## Composants du Pipeline Impactés

Le pipeline principal (`.github/workflows/ci-pipeline.yml`) sera mis à jour pour inclure les étapes suivantes :

### 1. Préparation de l'environnement

- **Checkout du code** : Standard.
- **Setup Go** : Assurer une version de Go compatible.

### 2. Exécution des Scripts du Dependency Manager

Les scripts seront exécutés dans l'ordre logique de leurs dépendances, en s'assurant que les outputs d'un script peuvent être utilisés comme inputs pour le suivant.

- **Génération du Rapport de Dépendances (`generate_dep_report`)** :
    - **Objectif** : Créer un rapport complet des dépendances Go utilisées.
    - **Commande** : `go run email_sender/cmd/go/dependency-manager/generate_dep_report --output-json <path_json> --output-md <path_md>`
    - **Artefacts** : `dependencies_report.json`, `dependencies_report.md`

- **Audit des Modules (`audit_modules`)** :
    - **Objectif** : Recenser les fichiers `go.mod` et `go.sum` et identifier les modules non conformes.
    - **Commande** : `go run email_sender/cmd/go/dependency-manager/audit_modules --output-json <path_json> --output-md <path_md>`
    - **Artefacts** : `initial_go_mod_list.json`, `initial_go_sum_list.json`, `initial_module_audit.md`

- **Scan des Imports Non Conformes (`scan_non_compliant_imports`)** :
    - **Objectif** : Détecter les imports qui ne suivent pas la convention `email_sender/core/...`.
    - **Commande** : `go run email_sender/cmd/go/dependency-manager/scan_non_compliant_imports --output-json <path_json> --output-md <path_md>`
    - **Artefacts** : `non_compliant_imports.json`, `non_compliant_imports_report.md`

- **Validation de la Structure du Monorepo (`validate_monorepo_structure`)** :
    - **Objectif** : Vérifier la présence d'un seul `go.mod` à la racine et la cohérence générale du monorepo.
    - **Commande** : `go run email_sender/cmd/go/dependency-manager/validate_monorepo_structure --output-json <path_json>`
    - **Artefacts** : `monorepo_structure_validation.json`

- **Planification de la Suppression des `go.mod` Secondaires (`plan_go_mod_deletion`)** :
    - **Objectif** : Identifier les `go.mod` et `go.sum` à supprimer.
    - **Commande** : `go run email_sender/cmd/go/dependency-manager/plan_go_mod_deletion --input-go-mod-list <path_go_mod_list> --input-go-sum-list <path_go_sum_list> --output-json <path_json> --output-md <path_md>`
    - **Artefacts** : `go_mod_to_delete.json`, `go_mod_delete_plan.md`

- **Proposition de Correctifs pour `go.mod` (`propose_go_mod_fixes`)** :
    - **Objectif** : Générer des scripts ou patchs pour corriger les problèmes de `go.mod`.
    - **Commande** : `go run email_sender/cmd/go/dependency-manager/propose_go_mod_fixes --input-json <path_input_json> --output-script <path_script> --output-patch <path_patch> --output-json-report <path_json_report>`
    - **Artefacts** : `fix_go_mod_parasites.sh`, `fix_go_mod_parasites.patch`, `go_mod_fix_plan.json`

### 3. Archivage des Rapports

- Tous les rapports générés par les scripts du Dependency Manager seront archivés en tant qu'artefacts de build.

### 4. Notifications

- Les notifications Slack existantes seront mises à jour pour inclure des liens directs vers les artefacts de rapport en cas d'échec.

## Conditions d'Échec du Pipeline

Le pipeline doit échouer si :

- L'un des scripts du Dependency Manager retourne un code d'erreur non nul.
- La validation de la structure du monorepo (`validate_monorepo_structure`) indique une non-conformité.

## Fréquence d'Exécution

- **Sur Push/Pull Request** : Tous les scripts du Dependency Manager seront exécutés pour chaque modification du code.
- **Quotidiennement (Nightly Build)** : Une exécution complète de tous les scripts sera déclenchée chaque nuit pour un suivi régulier de l'état des dépendances.

## Points à Affiner

- **Gestion des chemins** : S'assurer que les chemins d'entrée/sortie des scripts sont correctement gérés dans l'environnement CI/CD (utilisation de variables d'environnement ou de chemins relatifs cohérents).
- **Intégration de `go mod tidy` et `go build ./...`** : Ces commandes sont cruciales pour la validation et devraient être exécutées à des points pertinents du pipeline.
- **Génération de badges de statut** : Mettre en place la mise à jour automatique des badges de statut dans le README pour chaque vérification du Dependency Manager.
