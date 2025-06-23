# Test du script diffedit.go sur un fichier markdown réel

## Fichier cible : exemple_markdown.md

Avant :

```markdown
# Titre
Ancien contenu à remplacer.
```

Bloc diff Edit (patch.txt) :

```
------- SEARCH
Ancien contenu à remplacer.
=======
Nouveau contenu inséré par diff Edit.
+++++++ REPLACE
```

Commande de test (dry-run) :

```
go run diffedit.go --file ../exemple_markdown.md --patch ../patch.txt --dry-run
```

Commande d’application réelle :

```
go run diffedit.go --file ../exemple_markdown.md --patch ../patch.txt
```

Après application :

```markdown
# Titre
Nouveau contenu inséré par diff Edit.
```

Vérifier que le backup a bien été généré et que le remplacement est correct.
