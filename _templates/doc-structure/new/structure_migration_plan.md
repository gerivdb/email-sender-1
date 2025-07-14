# Plan de migration de la structure `cmd/gapanalyzer/`

## Objectif
Respecter la convention Go : un seul package par dossier.

## État initial
- [`cmd/gapanalyzer/main.go`](cmd/gapanalyzer/main.go:1) — package `main`
- [`cmd/gapanalyzer/gapanalyzer.go`](cmd/gapanalyzer/gapanalyzer.go:1) — package `gapanalyzer`

## Actions
1. Backup automatique de `cmd/gapanalyzer/` dans `/backup/gapanalyzer/`
2. Déplacement de `gapanalyzer.go` dans un nouveau dossier : `cmd/gapanalyzer/gapanalyzer/`
3. Mise à jour du diagramme Mermaid
4. Vérification compilation et lint Go
5. Archivage du plan et des logs

## Diagramme Mermaid

```mermaid
graph TD
    A[cmd/gapanalyzer/] --> B[main.go (package main)]
    A --> C[gapanalyzer.go (package gapanalyzer)]
    C -.-> D[cmd/gapanalyzer/gapanalyzer/gapanalyzer.go (package gapanalyzer)]
```

## Étapes détaillées
- Script PowerShell : backup, déplacement, vérification
- Mise à jour du diagramme dans `/docs/gapanalyzer/`
- Archivage du plan et logs