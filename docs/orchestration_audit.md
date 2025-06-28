# Audit des scripts d'orchestration et de leurs dépendances

Ce rapport liste tous les scripts d'automatisation identifiés, leurs dépendances et leurs points d'entrée.

## Scripts Identifiés

| Chemin du script | Description | Point d'entrée | Dépendances | Statut (Présent/Absent) |
|---|---|---|---|---|
| cmd/audit_read_file/audit_read_file.go | Scans code for read_file usages | `go run` | Aucune | Présent |
| cmd/gap_analysis/gap_analysis.go | Compares read_file usages with user needs | `go run` | docs/read_file_usage_audit.md, docs/read_file_user_needs.md | Présent |
| cmd/gen_read_file_spec/gen_read_file_spec.go | Generates read_file specification template | `go run` | docs/read_file_user_needs.md | Présent |
| cmd/read_file_navigator/read_file_navigator.go | CLI for navigating large files | `go run` | pkg/common/read_file.go | Présent |
| cmd/audit_rollback_points/audit_rollback_points.go | Audits critical files for rollback | `go run` | Aucune | Présent |
| cmd/gen_rollback_spec/gen_rollback_spec.go | Generates rollback specification template | `go run` | docs/rollback_points_audit.md | Présent |
| cmd/auto-roadmap-runner.go | Global roadmap orchestrator | `go run` | scripts/backup/backup.go, scripts/backup/backup_test.go, scripts/gen_read_file_report/gen_read_file_report.go, scripts/gen_rollback_report/gen_rollback_report.go | Absent |
| scripts/gen_user_needs_template.sh | Generates user needs template | `bash` | Aucune | Présent |
| scripts/collect_user_needs.sh | Collects user needs interactively (Bash) | `bash` | docs/read_file_user_needs.md | Présent |
| scripts/validate_and_archive_user_needs.sh | Validates and archives user needs | `bash` | docs/read_file_user_needs.md | Présent |
| scripts/archive_spec.sh | Archives read_file specification | `bash` | specs/read_file_spec.md | Présent |
| scripts/gen_read_file_report.go | Generates read_file test and coverage report | `go run` | pkg/common/read_file_test.go, integration/read_file_integration_test.go | Présent |
| scripts/vscode_read_file_selection.js | VSCode extension for selection analysis | `node` | cmd/read_file_navigator/read_file_navigator.go | Présent |
| scripts/collect_user_feedback.sh | Collects user feedback interactively (Bash) | `bash` | docs/read_file_user_feedback.md | Présent |
| scripts/collect_user_feedback.ps1 | Collects user feedback interactively (PowerShell) | `pwsh -File` | docs/read_file_user_feedback.md | Présent |
| scripts/backup/backup.go | Automated backup script | `go run` | Aucune | Présent |
| scripts/backup/backup_test.go | Tests for backup script | `go test` | scripts/backup/backup.go | Absent |
| scripts/git_versioning.sh | Automates critical git operations | `bash` | Aucune | Présent |
| scripts/gen_rollback_report/gen_rollback_report.go | Generates rollback and versioning report | `go run` | backup/, git | Présent |

## Recommandations

Vérifiez que tous les scripts nécessaires sont présents et que leurs dépendances sont satisfaites avant d'exécuter l'orchestrateur global.
