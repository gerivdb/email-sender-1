# Mode dry-run et rollback (diff Edit Go natif)

## Option --dry-run

- Le script Go `diffedit.go` supporte l’option `--dry-run` pour prévisualiser le diff sans appliquer la modification.
- Usage :

  ```sh
  go run tools/diff_edit/go/diffedit.go --file <fichier> --patch <bloc-diff> --dry-run
  ```

## Backup automatique

- À chaque patch, un backup du fichier d’origine est généré automatiquement (`<fichier>.bak-YYYYMMDD-HHMMSS`).

## Rollback facile

- Pour restaurer le fichier, utiliser le script Go `undo.go` :

  ```sh
  go run tools/diff_edit/go/undo.go --file <fichier>
  ```

- Ou manuellement :

  ```sh
  cp <fichier>.bak-YYYYMMDD-HHMMSS <fichier>
  ```

- Possibilité de patch inverse via Git si versionné.

## Documentation

- Toutes les étapes sont détaillées dans le README et les artefacts du dossier `tools/diff_edit/`.
