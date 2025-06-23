# Commande personnalisée VS Code : Générer un bloc diff Edit

## Utilisation

1. Sélectionner le texte à patcher dans l’éditeur VS Code.
2. Taper le préfixe `diffedit` pour insérer le squelette du bloc diff Edit.
3. Remplacer `${1:Texte de remplacement}` par le nouveau contenu.

## Snippet à ajouter dans les paramètres utilisateur ou projet

```json
{
  "Diff Edit Block": {
    "prefix": "diffedit",
    "body": [
      "------- SEARCH",
      "$TM_SELECTED_TEXT",
      "=======",
      "${1:Texte de remplacement}",
      "+++++++ REPLACE"
    ],
    "description": "Bloc diff Edit pour patch ciblé"
  }
}
```

## Résultat attendu

Un bloc diff Edit prêt à l’emploi, généré automatiquement depuis la sélection.
