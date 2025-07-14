# Règles d'espace de travail pour Kilo Code

Ce document décrit les règles d'espace de travail à suivre pour le développement avec Kilo Code. Ces règles sont définies dans le fichier `.vscode/settings.json` et affectent uniquement le projet courant.

## 1. Configuration des règles d'espace de travail

Les règles d'espace de travail de Kilo Code sont configurées dans le fichier `.vscode/settings.json`. Ce fichier contient les paramètres qui affectent uniquement le projet courant.

### 1.1. Paramètres principaux

Les règles d'espace de travail peuvent inclure des paramètres tels que :

*   `kilocode.rules.enable` : Active ou désactive les règles Kilo Code pour ce projet.
    *   Valeurs possibles : `true` (activé), `false` (désactivé).
    *   Par défaut : `true`.
*   `kilocode.rules.severity` : Définit la sévérité des violations de règles pour ce projet.
    *   Valeurs possibles : `error` (erreur), `warning` (avertissement), `information` (information).
    *   Par défaut : `warning`.

### 1.2. Règles personnalisées

*   `kilocode.rules.customRules` : Définit les règles personnalisées à appliquer pour ce projet.
    *   Ce paramètre permet de définir des règles spécifiques au projet, en plus des règles globales de Kilo Code.
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
  "kilocode.rules.severity": "error",
  "kilocode.rules.customRules": [
    {
      "id": "KC003",
      "message": "Les fonctions doivent avoir une documentation JSDoc.",
      "severity": "error",
      "pattern": "/\\*\\*[\\s\\S]*?\\*/",
      "match": "file"
    }
  ]
}
```

Ce document fournit une vue d'ensemble des règles d'espace de travail pour Kilo Code. Pour plus d'informations, veuillez consulter la documentation officielle : `https://kilocode.ai/docs/advanced-usage/custom-rules`.
## Usage du système d’override intelligent Kilo Code

Ce projet utilise le système d’override intelligent décrit dans [`system-prompt-code`](.kilocode/system-prompt-code:1) :
- Les règles globales et locales sont fusionnées, priorisées et adaptées dynamiquement selon le contexte, le mode actif et le workflow.
- Orchestrator pilote l’application des règles, déclenche des audits ciblés et propose des ajustements automatiques en cas de blocage.
- Chaque modification, override ou ajout de règle est documenté, tracé et historisé pour garantir la cohérence, la robustesse et l’amélioration continue.
- Les exemples, workflows et bonnes pratiques sont détaillés dans [`system-prompt-code`](.kilocode/system-prompt-code:1).

Pour toute adaptation, consultez et mettez à jour ce fichier ainsi que [`system-prompt-code`](.kilocode/system-prompt-code:1) pour garantir la cohérence du projet.