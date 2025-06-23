# README diff Edit (Go natif)

## Usage

- Générer un bloc diff Edit avec le snippet VS Code ou manuellement.
- Appliquer le patch avec le CLI Go :

  ```sh
  go run tools/diff_edit/go/diffedit.go --file <fichier> --patch <bloc-diff> [--dry-run]
  ```

- Pour rollback :

  ```sh
  go run tools/diff_edit/go/undo.go --file <fichier>
  ```

- Pour batch multi-fichiers :

  ```sh
  go run tools/diff_edit/go/batch_diffedit.go --files list.txt --patch patch.txt
  ```

## Exemples concrets

### Avant/Après (Markdown)

Avant :

```markdown
# Titre
Ancien contenu à remplacer.
```

Bloc diff Edit :

```
------- SEARCH
Ancien contenu à remplacer.
=======
Nouveau contenu inséré par diff Edit.
+++++++ REPLACE
```

Après :

```markdown
# Titre
Nouveau contenu inséré par diff Edit.
```

### Avant/Après (Go)

Avant :

```go
func Addition(a, b int) int {
    return a + b // ancienne implémentation
}
```

Bloc diff Edit :

```
------- SEARCH
return a + b // ancienne implémentation
=======
return a + b // nouvelle implémentation diff Edit
+++++++ REPLACE
```

Après :

```go
func Addition(a, b int) int {
    return a + b // nouvelle implémentation diff Edit
}
```

## Limitations

- Bloc SEARCH doit être unique dans le fichier.
- Encodage UTF-8 sans BOM recommandé.
- Non adapté aux fichiers binaires ou très volumineux.

## Rollback

- Un backup est généré automatiquement à chaque patch.
- Utiliser `undo.go` pour restaurer le dernier backup.

## Template de prompt diff Edit (usage quotidien)

```
------- SEARCH
<texte à remplacer>
=======
<texte de remplacement>
+++++++ REPLACE
```

## Tableau de cas d’usage

| Type de fichier      | Exemple SEARCH           | Exemple REPLACE                | Remarque                        |
|----------------------|-------------------------|--------------------------------|---------------------------------|
| Markdown             | Ancien contenu          | Nouveau contenu                | Simple remplacement             |
| Code Go              | return a + b            | return a + b // modifié        | Avec contexte                   |
| Config JSON          | "key": "old"            | "key": "new"                   | Attention aux espaces           |
| Batch multi-fichiers | Bloc commun dans plusieurs fichiers | Bloc modifié         | Gérer les erreurs partielles    |
