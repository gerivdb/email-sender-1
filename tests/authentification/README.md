# Tests d’authentification

Ce dossier contient les tests unitaires pour la fonctionnalité d’authentification.

## Fichiers

- `authentification_test.go` : tests unitaires (login succès, échec, expiration session)
- `authentification_test.go.bak` : sauvegarde automatique

## Exécution

```bash
go test ./tests/authentification/ -v
```

## Génération du rapport de couverture

```bash
go test ./tests/authentification/ -coverprofile=coverage.out && go tool cover -html=coverage.out -o coverage.html
```

## Sauvegarde

```powershell
pwsh tools/scripts/backup/backup.ps1