# README – BackupManager (cmd/backup-modified-files)

## Fonctionnalités

- Sauvegarde automatique des artefacts critiques (.bak)
- Archivage des logs de rollback
- Test de restauration à partir des backups
- Notification Kilo Code après backup/restauration (interopérabilité)
- Intégration CI/CD via pipeline YAML (ci/pipeline-backup.yml)

## Interfaces & Points d’extension

- Fonction principale : backupFile(src string)
- Notification Kilo Code : NotifyKilo()
- Extension possible via hooks dans le pipeline YAML

## Utilisation

```bash
go run cmd/backup-modified-files/main.go
go test ./cmd/backup-modified-files/
go run cmd/backup-modified-files/notify_kilo.go
```

## Checklist collaborative Roo/Kilo

- [x] Sauvegarde .bak générée
- [x] Log rollback archivé
- [ ] Notification envoyée à Kilo Code
- [ ] Rapport partagé Roo/Kilo
- [ ] Audit de cohérence effectué

## Cas limites & exceptions

- Fichiers source absents : backup ignoré, log d’erreur
- Permissions insuffisantes : erreur, log
- Notification Kilo Code non reçue : relance manuelle

## Audit & adaptation

- Script d’audit à prévoir pour vérifier la présence des backups, logs, notifications et synchronisation Roo/Kilo
- Adaptation du workflow selon les résultats d’audit et les cas limites
