# Instructions pour Projet N8N

## Objectif
Créer un workflow N8N fonctionnel et complet sous forme de fichier JSON valide, prêt à être importé dans l'interface N8N.

## Exigences Techniques

### 1. Utilisation des Ressources de Référence
- Intégrer les meilleures pratiques et structures JSON des documents suivants:
  - **Guide des astuces N8N**
  - **N8N Cheat Sheet Guide**
  - **Workflow de gestion de communication + stockage de notes**
  - Autres workflows d'exemple fournis
- Respecter les directives concernant la structure des nœuds, les connexions, la gestion de la mémoire et le traitement des erreurs.

### 2. Structure du Workflow
- Commencer par un nœud **Déclencheur de Chat** qui reçoit les messages utilisateur
- Intégrer un nœud de **Traitement Principal** qui peut appeler plusieurs outils (outil de temps, calculatrice, etc.)
- Inclure des nœuds **Sticky Note** aux endroits stratégiques pour documenter le workflow
- S'assurer que chaque nœud référence correctement les données en amont (en utilisant `$node["NomDuNoeud"]`) et transmet le contexte pertinent

### 3. Configuration Spécifique des Nœuds
- Pour les nœuds **OpenRouter**, toujours configurer:
  - `"operation": "complete"`
  - `"resource": "text"`
  - `"model": "deepseek/deepseek-chat-v3-0324:free"`
  - Paramètre `"temperature"` approprié (ex: 0.1 pour des tâches précises, 0.7 pour des tâches créatives)
- Chaque nœud **OpenRouter** qui renvoie des données structurées doit avoir `"responseFormat": "json_object"`
- Vérifier que **tous les nœuds** sont correctement connectés dans la section `"connections"`
- Les nœuds de code doivent inclure une gestion des erreurs (try/catch)
- Fournir des références aux credentials (sans exposer les clés réelles)
- Ajouter des nœuds finaux qui marquent clairement la fin du workflow

### 4. Intégrité du JSON
- Ne pas utiliser de placeholders comme `"API_KEY_HERE"` ou `[VOTRE_ID_DOC]`
- Utiliser des références génériques si nécessaire (ex: `"{{ mesCredentials }}"`)
- Le JSON doit être complet et prêt à être copié-collé, avec un minimum de modifications manuelles

### 5. Clarification des Détails Manquants
- Si des détails sur certains nœuds sont manquants, demander des clarifications avant de générer le JSON final

### 6. Format de Sortie
- Produire uniquement un JSON valide dans un bloc de code
- Pas d'images ou de tentatives de capture d'écran
- Pas de commentaires superflus en dehors du bloc de code

## Objectif Final
Fournir un fichier JSON autonome qui peut être importé directement dans N8N, représentant un flux de communication avec traitement avancé, incluant des outils pertinents et des notes explicatives, en s'appuyant sur les meilleures pratiques de la base de connaissances.

## Exemple de Structure de Base
```json
{
  "name": "Workflow Communication Avancée",
  "nodes": [
    {
      "parameters": {
        "chatTriggerConfig": {
          "option1": "value1"
        }
      },
      "name": "Déclencheur Chat",
      "type": "n8n-nodes-base.chatTrigger",
      "position": [100, 300]
    },
    {
      "parameters": {
        "operation": "complete",
        "resource": "text",
        "model": "deepseek/deepseek-chat-v3-0324:free",
        "temperature": 0.7
      },
      "name": "Traitement Principal",
      "type": "n8n-nodes-base.openRouter",
      "position": [300, 300]
    }
  ],
  "connections": {
    "Déclencheur Chat": {
      "main": [
        [
          {
            "node": "Traitement Principal",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  }
}
```

Si des détails sur certains nœuds sont manquants ou peu clairs, veuillez les lister et demander des précisions avant de produire le JSON final.
