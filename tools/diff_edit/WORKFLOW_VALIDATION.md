# Procédure d’utilisation du workflow diff Edit (Go natif)

## Étapes

1. **Génération du bloc diff Edit**
   - Utiliser le snippet VS Code `diffedit` ou le générer via un script Go si besoin.
2. **Application du patch**
   - Utiliser le CLI Go :

     ```sh
     go run tools/diff_edit/go/diffedit.go --file <fichier> --patch <bloc-diff> [--dry-run]
     ```

3. **Validation du diff**
   - Vérifier le résultat dans Git/VS Code avant commit.
   - Utiliser l’option `--dry-run` pour prévisualiser le diff.

## Bonnes pratiques

- Toujours inclure 1-2 lignes de contexte dans le bloc SEARCH.
- Vérifier l’unicité du bloc SEARCH dans le fichier.
- Vérifier l’encodage du fichier (UTF-8 sans BOM recommandé).
- Toujours générer un backup avant modification.
- Documenter le contexte, le rollback et les logs dans le commit.

## Checklist avant application

- [ ] Bloc SEARCH unique dans le fichier
- [ ] Encodage UTF-8 sans BOM
- [ ] Backup généré automatiquement
- [ ] Contexte (1-2 lignes) inclus dans SEARCH

## Exemple de log

```
Patch appliqué avec succès. Backup: <fichier>.bak-YYYYMMDD-HHMMSS
```
