# Règles globales pour Kilo Code

Ce document décrit les règles globales à suivre pour le développement avec Kilo Code. Ces règles sont définies dans le fichier `settings.json` et affectent tous les projets Kilo Code.

## 1. Configuration des règles globales

Les règles globales de Kilo Code sont configurées dans le fichier `settings.json`. Ce fichier contient les paramètres qui affectent tous les projets Kilo Code.

### 1.1. Paramètres principaux

*   `kilocode.rules.enable` : Active ou désactive les règles Kilo Code.
    *   Valeurs possibles : `true` (activé), `false` (désactivé).
    *   Par défaut : `true`.
*   `kilocode.rules.severity` : Définit la sévérité des violations de règles.
    *   Valeurs possibles : `error` (erreur), `warning` (avertissement), `information` (information).
    *   Par défaut : `warning`.

### 1.2. Règles personnalisées

*   `kilocode.rules.customRules` : Définit les règles personnalisées à appliquer.
    *   Ce paramètre permet de définir des règles spécifiques au projet, en plus des règles par défaut de Kilo Code.
    *   Les règles personnalisées sont définies sous forme d'un tableau d'objets JSON, où chaque objet représente une règle.
    *   Chaque règle doit contenir les propriétés suivantes :
        *   `id` : Un identifiant unique pour la règle.
        *   `message` : Un message descriptif de la règle.
        *   `severity` : La sévérité de la violation de la règle (error, warning, information).
        *   `pattern` : Un motif (expression régulière) à rechercher dans le code.
        *   `match` : Le type de correspondance à effectuer (par exemple, `line`, `file`).

### 1.3. Exemple de configuration

```json
{
  "kilocode.rules.enable": true,
  "kilocode.rules.severity": "warning",
  "kilocode.rules.customRules": [
    {
      "id": "KC001",
      "message": "Les commentaires doivent commencer par une majuscule.",
      "severity": "warning",
      "pattern": "^// [a-z]",
      "match": "line"
    },
    {
      "id": "KC002",
      "message": "Les noms de variables doivent être en camelCase.",
      "severity": "error",
      "pattern": "[A-Z]",
      "match": "line"
    }
  ]
}
```

Ce document fournit une vue d'ensemble des règles globales pour Kilo Code. Pour plus d'informations, veuillez consulter la documentation officielle : `https://kilocode.ai/docs/advanced-usage/custom-rules`.