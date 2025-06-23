# Format standardisé des blocs diff Edit (SEARCH/REPLACE)

Un bloc diff Edit est structuré ainsi :

```
------- SEARCH
<texte à rechercher>
=======
<texte de remplacement>
+++++++ REPLACE
```

- Le bloc SEARCH doit correspondre exactement au texte à remplacer (idéalement avec 1-2 lignes de contexte avant/après).
- Le bloc REPLACE contient le nouveau texte à insérer.
- Les séparateurs sont fixes et doivent être respectés.

## Exemple

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

Après application :

```markdown
# Titre
Nouveau contenu inséré par diff Edit.
```
