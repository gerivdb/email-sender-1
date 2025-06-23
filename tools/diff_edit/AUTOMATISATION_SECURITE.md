# Automatisation et sécurité diff Edit (Go natif)

## Option de prévisualisation du diff (`--dry-run`)

- Déjà implémentée dans le CLI Go (`diffedit.go`).
- Usage :

  ```sh
  go run tools/diff_edit/go/diffedit.go --file <fichier> --patch <bloc-diff> --dry-run
  ```

## Rollback/Undo (restauration du backup)

- Après chaque patch, un backup est généré automatiquement (`<fichier>.bak-YYYYMMDD-HHMMSS`).
- Pour rollback :

  ```sh
  cp <fichier>.bak-YYYYMMDD-HHMMSS <fichier>
  ```

- (Avancé) Un script Go `undo.go` peut automatiser la restauration du dernier backup.

## Support multi-fichiers et batch (avancé)

- Un script Go `batch_diffedit.go` peut appliquer un patch à plusieurs fichiers listés dans un fichier ou un dossier.
- Exemple d’usage :

  ```sh
  go run tools/diff_edit/go/batch_diffedit.go --files list.txt --patch patch.txt
  ```

## Log détaillé (avant/après, timestamp, user)

- Le CLI Go logge chaque opération (succès, erreurs, backup créé).
- Pour un log avancé, ajouter une écriture dans un fichier log (ex : `diffedit.log`) avec timestamp, user (os/user), fichier, patch appliqué.

---

## Artefacts fournis

- `diffedit.go` : CLI Go natif avec dry-run, backup, logs.
- `batch_diffedit.go` : (à créer si besoin) pour le support multi-fichiers.
- `undo.go` : (à créer si besoin) pour automatiser le rollback.
- Documentation d’usage et logs.
