# Workflow de Remédiation Structurelle GoModFiles

## Objectif
Automatiser la synchronisation, la détection des écarts, le refactoring sécurisé, la génération et l’archivage des rapports, la validation croisée et le feedback utilisateur pour la structure GoModFiles.

## Étapes du workflow

1. **Audit des modules**
   - Script : `go run cmd/go/dependency-manager/audit_modules/main.go`
   - Livrables : `backup/gomod_audit.json`, `backup/gomod_audit.md`

2. **Validation de la structure monorepo**
   - Script : `go run cmd/go/dependency-manager/validate_monorepo_structure/main.go`
   - Livrable : `backup/monorepo_structure_validation.json`

3. **Scan des go.mod parasites**
   - Script : `go run cmd/go/dependency-manager/scan_go_mods/scan_go_mods.go`
   - Livrables : `backup/go_mod_parasites.json`, `backup/go_mod_parasites.md`

4. **Scan des imports internes**
   - Script : `go run cmd/go/dependency-manager/scan_imports/main.go`
   - Livrables : `backup/imports_internal.json`, `backup/imports_internal.md`

5. **Scan des imports non conformes**
   - Script : `go run cmd/go/dependency-manager/scan_non_compliant_imports/main.go`
   - Livrables : `backup/imports_non_compliant.json`, `backup/imports_non_compliant.md`

6. **Planification de la suppression des go.mod parasites**
   - Script : `go run cmd/go/dependency-manager/plan_go_mod_deletion/main.go`
   - Livrables : `backup/go_mod_to_delete.json`, `backup/go_mod_delete_plan.md`

7. **Proposition de corrections**
   - Script : `go run cmd/go/dependency-manager/propose_go_mod_fixes/main.go`
   - Livrables : `backup/fix_go_mod_parasites.sh`, `backup/go_mod_fix_plan.json`

8. **Suppression des fichiers parasites**
   - Script : `go run cmd/go/dependency-manager/delete_go_mods/main.go`
   - Livrable : `backup/go_mod_deletion_report.json`

9. **Application des corrections imports**
   - Script : `go run cmd/go/dependency-manager/apply_imports/apply_imports.go`
   - Livrable : `backup/apply_import_correction_report.json`

10. **Génération du rapport de dépendances**
    - Script : `go run cmd/go/dependency-manager/generate_dep_report/main.go`
    - Livrables : `backup/dependencies_report.json`, `backup/dependencies_report.md`

11. **Génération du rapport final de phase**
    - Script : `go run cmd/go/dependency-manager/generate_report/generate_report.go`
    - Livrable : `backup/phase_completion_report.md`

12. **Archivage des rapports**
    - Script : `Compress-Archive`
    - Livrable : `backup/gomod_remediation_archive.zip`

13. **Log de fin**
    - Script : `Write-Output`
    - Livrable : log terminal

## Intégration CI/CD

- Ajouter le script PowerShell dans le pipeline CI/CD.
- Définir un job dédié pour la remédiation GoModFiles.
- Archiver les livrables en artefacts du pipeline.

## Traçabilité et robustesse

- Tous les rapports et backups sont archivés.
- Les logs et rapports sont générés à chaque étape.
- La procédure est entièrement automatisée et documentée.

## Feedback utilisateur

- Les rapports finaux et l’archive sont accessibles pour validation et retour.
