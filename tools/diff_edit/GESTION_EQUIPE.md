# Gestion des conflits en équipe (diff Edit Go natif)

- **Branches distinctes** : chaque diff Edit doit être appliqué sur une branche dédiée pour éviter les conflits.
- **Convention de verrouillage/notification** : mettre en place un fichier `LOCKS.md` ou utiliser un bot/hook pour notifier l’édition d’un fichier critique.
- **Validation du diff** : toujours valider le diff dans Git/VS Code avant merge (dry-run, review, CI).
- **Hooks/scripts de détection** : ajouter un hook Git `pre-commit` ou `pre-push` (ex : script Go qui vérifie l’unicité du bloc SEARCH et la non-concurrence sur le fichier cible).

## Exemple de hook Git (pre-commit)

```sh
#!/bin/sh
# Vérifie l’unicité du bloc SEARCH avant commit
go run tools/diff_edit/go/diffedit.go --file <fichier> --patch <bloc-diff> --dry-run
```

## Artefacts

- Documentation dans le README
- Exemple de hook/script dans `tools/diff_edit/hooks/`
- Convention de branches et de notification dans `LOCKS.md`
