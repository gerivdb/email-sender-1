# Orchestration PowerShell pour la remédiation GoModFiles

# 1. Audit modules
go run cmd/go/dependency-manager/audit_modules/main.go --output-json backup/gomod_audit.json --output-md backup/gomod_audit.md

# 2. Validation structure monorepo
go run cmd/go/dependency-manager/validate_monorepo_structure/main.go --output-json backup/monorepo_structure_validation.json

# 3. Scan go.mod parasites
go run cmd/go/dependency-manager/scan_go_mods/scan_go_mods.go --output-json backup/go_mod_parasites.json --output-md backup/go_mod_parasites.md

# 4. Scan imports internes
go run cmd/go/dependency-manager/scan_imports/main.go --output-json backup/imports_internal.json --output-md backup/imports_internal.md

# 5. Scan imports non conformes
go run cmd/go/dependency-manager/scan_non_compliant_imports/main.go --output-json backup/imports_non_compliant.json --output-md backup/imports_non_compliant.md

# 6. Planification suppression go.mod parasites
go run cmd/go/dependency-manager/plan_go_mod_deletion/main.go --input-go-mod-list backup/go_mod_parasites.json --input-go-sum-list backup/gomod_audit.json --output-json backup/go_mod_to_delete.json --output-md backup/go_mod_delete_plan.md

# 7. Proposition de corrections
go run cmd/go/dependency-manager/propose_go_mod_fixes/main.go --input-json backup/go_mod_to_delete.json --output-script backup/fix_go_mod_parasites.sh --output-json-report backup/go_mod_fix_plan.json

# 8. Suppression des fichiers parasites
go run cmd/go/dependency-manager/delete_go_mods/main.go --input-json backup/go_mod_to_delete.json --report backup/go_mod_deletion_report.json

# 9. Application des corrections imports (si patch généré)
go run cmd/go/dependency-manager/apply_imports/apply_imports.go --input-patch backup/fix_go_mod_parasites.patch --report backup/apply_import_correction_report.json

# 10. Génération rapport de dépendances
go run cmd/go/dependency-manager/generate_dep_report/main.go --output-json backup/dependencies_report.json --output-md backup/dependencies_report.md

# 11. Génération rapport final de phase
go run cmd/go/dependency-manager/generate_report/generate_report.go --phase "GoMod Remediation" --output-md backup/phase_completion_report.md

# 12. Archivage des rapports
Compress-Archive -Path backup/*.json, backup/*.md, backup/*.sh, backup/*.patch -DestinationPath backup/gomod_remediation_archive.zip

# 13. Log de fin
Write-Output "Remédiation GoModFiles terminée. Tous les rapports et backups sont archivés dans backup/gomod_remediation_archive.zip"