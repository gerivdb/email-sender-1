# 📦 Module Go : scanmodules

Ce module permet de scanner récursivement une arborescence de fichiers, de détecter le langage de chaque fichier, et d’exporter la cartographie au format JSON.

## Utilisation CLI

```bash
go run cmd/scanmodules/main.go <répertoire_racine> [fichier_sortie.json]
```

- Par défaut, le fichier de sortie est `init-cartographie-scan.json`.
- Pour générer l’audit attendu par la roadmap :
  ```bash
  go run cmd/scanmodules/main.go . audit-managers-scan.json
  ```

## Fonctions principales

- `ScanDir(root string) ([]ModuleInfo, error)` : Scanne tous les fichiers du dossier racine.
- `ExportModules(modules []ModuleInfo, outPath string) error` : Exporte la liste des modules au format JSON.

## Structure du JSON

Chaque entrée contient :
- `name`, `path`, `type`, `lang`, `role`, `deps`, `outputs`

## Tests

- Les tests unitaires sont dans `scanmodules_test.go` :
  - Détection de fichiers Go
  - Export JSON et vérification du contenu

## Conformité

- Migration complète depuis `scan-modules.js` (voir roadmap phase 2)
- Compatible Go 1.20+
