# Roo-Code – Synchronisation des références croisées

## Objectif

Automatiser la gestion, la mise à jour et l’audit des références croisées entre les fichiers de règles Roo-Code.

## Installation

- Requiert Go >= 1.21
- Placez tous les scripts dans `.roo/tools/`
- Configuration dans `.roo/tools/refs_sync.config.yaml`

## Usage

- Scan des fichiers : `go run refs_sync.go --scan`
- Injection des références : `go run refs_sync.go --inject`
- Vérification des verrous : `go run refs_sync.go --check-locks`
- Simulation dry-run : `go run refs_sync.go --dry-run`
- Orchestration globale : `go run auto-roadmap-runner.go`
- Rollback : `bash rollback_refs_sync.sh`
- Tests : `go test refs_sync_test.go`

## CI/CD

- Workflow GitHub Actions `.github/workflows/refs_sync.yml` : scan, injection, tests, reporting, rollback, documentation

## FAQ

- **Comment restaurer un fichier ?**  
  Utilisez le script `rollback_refs_sync.sh` pour restaurer les fichiers `.md` depuis leurs backups `.bak`.

- **Comment ajouter un nouveau fichier à synchroniser ?**  
  Ajoutez-le dans la config YAML et relancez le scan/injection.

- **Comment vérifier la conformité des sections ?**  
  Utilisez le mode dry-run et consultez le rapport d’audit.

## Troubleshooting

- Vérifiez les permissions sur les fichiers pour éviter les verrous.
- Consultez les logs et rapports générés dans `.roo/tools/`.

## Traçabilité

- Tous les rapports, logs et historiques sont archivés dans `.roo/tools/`.
- Les opérations sont automatisées et validées par CI/CD.

## Proactivité & Automatisation

- Le système est autonome : scan, injection, tests, reporting, rollback et documentation sont automatisés.
- L’orchestrateur et le workflow CI/CD garantissent la proactivité et la robustesse.
