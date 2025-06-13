# Syntaxe des balises de tâches

Ce document définit la syntaxe des balises utilisées pour marquer les tâches dans les conversations avec l'IA.

## Format général

Les tâches sont marquées à l'aide de balises XML spéciales dans le format suivant :

```xml
<task category="X" priority="Y" estimate="Z">
Description de la tâche
</task>
```plaintext
## Attributs

Les balises de tâches peuvent inclure les attributs suivants :

| Attribut | Description | Valeurs possibles | Obligatoire |
|----------|-------------|-------------------|-------------|
| `category` | Catégorie de la tâche | 1-7 (correspond aux catégories de la roadmap) | Oui |
| `priority` | Niveau de priorité | "high", "medium", "low" | Non (défaut: "medium") |
| `estimate` | Estimation du temps | Format "X-Y" ou "X" en jours | Non (défaut: "1-3") |
| `start` | Démarrer immédiatement | "true", "false" | Non (défaut: "false") |

## Exemples

### Tâche simple

```xml
<task category="1">
Créer une documentation pour la nouvelle API
</task>
```plaintext
### Tâche prioritaire

```xml
<task category="3" priority="high" estimate="2-4" start="true">
Corriger le bug d'authentification dans le module de connexion
</task>
```plaintext
### Tâche avec estimation précise

```xml
<task category="2" estimate="1">
Ajouter une fonction de validation des chemins
</task>
```plaintext
## Règles d'utilisation

1. L'IA doit utiliser ces balises lorsqu'elle identifie une demande qui constitue une tâche à implémenter.
2. Les balises doivent être placées à la fin de la réponse de l'IA, après avoir répondu à la demande de l'utilisateur.
3. Une réponse peut contenir plusieurs balises de tâches si plusieurs tâches sont identifiées.
4. Les balises ne doivent pas être visibles pour l'utilisateur dans l'interface de conversation.
5. Si l'utilisateur demande explicitement d'ajouter une tâche à la roadmap, l'IA doit utiliser ces balises.

## Catégories

Les catégories correspondent à celles définies dans la roadmap :

1. Documentation et formation
2. Gestion améliorée des répertoires et des chemins
3. Amélioration de la compatibilité des terminaux
4. Standardisation des hooks Git
5. Amélioration de l'authentification
6. Alternatives aux serveurs MCP traditionnels
7. Demandes spontanées
