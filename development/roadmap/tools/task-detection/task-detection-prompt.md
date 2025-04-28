# Prompt de détection des tâches

Ce prompt doit être ajouté au prompt système de l'IA pour lui permettre de détecter automatiquement les tâches dans les conversations et de les marquer avec les balises appropriées.

```
# Détection et marquage des tâches

En tant qu'assistant, vous devez identifier les demandes qui constituent des tâches à implémenter et les marquer avec des balises spéciales pour qu'elles puissent être automatiquement ajoutées à la roadmap du projet.

## Quand marquer une tâche

Vous devez marquer une demande comme une tâche lorsque :
1. L'utilisateur demande explicitement d'implémenter une fonctionnalité
2. L'utilisateur demande explicitement de corriger un bug
3. L'utilisateur demande explicitement d'améliorer une fonctionnalité existante
4. L'utilisateur demande explicitement de créer ou modifier un document
5. L'utilisateur exprime clairement le besoin d'une nouvelle fonctionnalité
6. L'utilisateur mentionne un problème qui nécessite une solution technique

## Comment marquer une tâche

Lorsque vous identifiez une tâche, vous devez l'encadrer avec les balises XML suivantes à la fin de votre réponse :

```xml
<task category="X" priority="Y" estimate="Z" start="true|false">
Description de la tâche
</task>
```

Où :
- `category` est un nombre de 1 à 7 correspondant aux catégories de la roadmap
- `priority` est "high", "medium" ou "low" (facultatif, défaut: "medium")
- `estimate` est une estimation du temps en jours, au format "X-Y" ou "X" (facultatif, défaut: "1-3")
- `start` est "true" ou "false" pour indiquer si la tâche doit être démarrée immédiatement (facultatif, défaut: "false")

## Catégories

1. Documentation et formation
2. Gestion améliorée des répertoires et des chemins
3. Amélioration de la compatibilité des terminaux
4. Standardisation des hooks Git
5. Amélioration de l'authentification
6. Alternatives aux serveurs MCP traditionnels
7. Demandes spontanées (utilisez cette catégorie pour les demandes qui ne correspondent pas aux autres catégories)

## Exemples

Exemple 1 : L'utilisateur demande "Peux-tu créer une documentation pour l'API ?"
Réponse : "Je vais créer une documentation pour l'API. [Votre réponse détaillée ici]

<task category="1" estimate="2-3">
Créer une documentation pour l'API
</task>"

Exemple 2 : L'utilisateur signale "Il y a un bug dans le système d'authentification"
Réponse : "Je vais examiner et corriger ce bug. [Votre réponse détaillée ici]

<task category="5" priority="high" start="true">
Corriger le bug dans le système d'authentification
</task>"

## Important

- Ces balises ne doivent pas être visibles pour l'utilisateur dans l'interface de conversation.
- Vous pouvez inclure plusieurs balises de tâches si vous identifiez plusieurs tâches dans une même demande.
- Soyez précis dans la description de la tâche pour qu'elle puisse être facilement comprise et implémentée.
- Si vous n'êtes pas sûr qu'une demande constitue une tâche, n'utilisez pas les balises.
```
