# Mode <%= h.modeName %>

## Description
Résumé du mode, son objectif principal et son rôle dans le workflow.

## Objectifs
- Liste des objectifs spécifiques du mode.

## Commandes principales
- <COMMANDE> : Description courte
- ...

## Fonctionnement
- Étapes clés du mode (séquentiel, déclencheurs, automatisations, etc.)

## Bonnes pratiques
- Conseils d’utilisation, pièges à éviter, standards à respecter.

## Intégration avec les autres modes
- Comment ce mode s’articule avec les autres (ex : TEST s’active après DEV-R, DEBUG après TEST, etc.)
- Exemples de combinaisons typiques.

## Exemples d’utilisation
```powershell
# Exemple d’appel du mode en CLI ou via snippet
Invoke-AugmentMode -Mode "<%= h.modeName %>" -FilePath "<roadmap>" -TaskIdentifier "<id>"
```

## Snippet VS Code (optionnel)
```json
{
  "Mode <%= h.modeName %>": {
    "prefix": "<%= h.snippetPrefix %>",
    "body": [
      "# Mode <%= h.modeName %>",
      "",
      "## Description",
      "Résumé du mode, son objectif principal et son rôle dans le workflow.",
      "",
      "## Objectifs",
      "- ...",
      "",
      "## Commandes principales",
      "- ...",
      "",
      "## Fonctionnement",
      "- ...",
      "",
      "## Bonnes pratiques",
      "- ...",
      "",
      "## Intégration avec les autres modes",
      "- ...",
      "",
      "## Exemples d’utilisation",
      "# ..."
    ],
    "description": "Insère le template du mode <%= h.modeName %>."
  }
}
```

## Documentation associée et approfondissements

Pour aller plus loin :
- [Les 16 bases de la programmation](../programmation_16_bases.md) : Document de référence supérieur sur les principes fondamentaux du projet.
- [Structure de la taxonomie des exceptions PowerShell](../exception_taxonomy_structure.md)
- [Propriétés communes de System.Exception](../exception_properties_documentation.md)
- [Exceptions du namespace System](../system_exceptions_documentation.md)
- [Exceptions du namespace System.IO](../system_io_exceptions_documentation.md)
