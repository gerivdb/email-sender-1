# README – Recensement Initial du Template-Manager Go

Ce module génère le rapport de recensement (`recensement.json`) listant tous les managers et artefacts du dépôt.

## Usage

```bash
go run main.go
```

## Test

```bash
go test
```

## Rollback

Une sauvegarde automatique est créée : `recensement.json.bak`.

## Traçabilité

Tous les logs et outputs sont versionnés pour audit et rollback.