# Bonnes pratiques pour n8n dans EMAIL SENDER 1
*Version 2025-05-15*

Ce guide rassemble les bonnes pratiques pour l'utilisation de n8n dans le projet EMAIL SENDER 1, basées sur l'analyse des documents de référence et des exemples pratiques.

## 1. Structure des workflows

### 1.1 Pattern fondamental pour l'automatisation d'emails

```
+---------+      +----------------+      +-------+      +---------+      +----------------+
|  CRON   | ---> | Read Contacts  | ---> |  IF   | ---> |  Send   | ---> | Update Status  |
| (Sched) |      | (Notion/GCal)  |      | Filter|      | Email 1 |      | (e.g., Contacted)|
+---------+      +----------------+      +-------+      +---------+      +----------------+
                                                                               |
                                                                               V
+---------+      +----------------+      +-------+      +---------+      +----------------+
|  Wait   | <--- | Update Status  | <--- |  Send   | <--- |  IF   | <--- | Read Status    |
| (Delay) |      | (e.g., FollowUp)|      | Email 2 |      | NoReply?|      | (Check Reply)  |
+---------+      +----------------+      +---------+      +-------+      +----------------+
     |
     V
  (End or Loop)
```

Ce pattern `Trigger -> Read -> Filter -> Act -> Update -> Wait -> Re-check -> Conditional Act -> Update` est la base de nos workflows d'automatisation d'emails.

### 1.2 Modularité des workflows

- **Diviser par fonction** : Créer des workflows distincts pour chaque phase (Prospection, Suivi, Traitement des réponses)
- **Centraliser la configuration** : Utiliser un workflow dédié (Email Sender - Config) pour stocker les paramètres communs
- **Réutiliser les sous-workflows** : Utiliser le nœud "Execute Workflow" pour appeler des sous-workflows communs

### 1.3 Nommage et organisation

- **Convention de nommage** : `Email Sender - [Phase/Fonction]`
- **Versionnement** : Archiver les versions précédentes dans `/src/n8n/workflows/archive`
- **Documentation** : Ajouter des notes dans chaque nœud pour expliquer son rôle

## 2. Gestion des données

### 2.1 Sources de données

- **Notion** : Source principale pour les contacts et le suivi des statuts
- **Google Calendar** : Source pour les disponibilités
- **Fichiers JSON/YAML** : Pour les configurations statiques

### 2.2 Transformation des données

- **Nœud "Set"** : Utiliser pour préparer les données avant de les envoyer à d'autres nœuds
- **Nœud "Function"** : Pour les transformations complexes nécessitant du code JavaScript
- **Expressions n8n** : Utiliser `{{ $json.VariableName }}` pour l'insertion dynamique de données

### 2.3 Gestion des états

- **Importance critique** : La gestion des états est fondamentale pour le bon fonctionnement des workflows
- **Mise à jour après chaque action** : Toujours mettre à jour le statut dans Notion après chaque action significative
- **Vérification avant action** : Toujours re-vérifier l'état avant d'envoyer un email de suivi

## 3. Intégration avec les services IA

### 3.1 Personnalisation des emails avec OpenRouter/DeepSeek

```
+-----------------+      +--------------+      +-----------------+      +---------+
| Read Contact    | ---> | Prepare Data | ---> | Call AI (MCP)   | ---> | Send    |
| (Notion)        |      | (Name, Context)|      | (Get Persnlzd Txt)|      | Email   |
+-----------------+      +--------------+      +-----------------+      +---------+
                                 |                     |
                                 +---------------------+
                                       (Pass Data)
```

- **Préparation du contexte** : Utiliser le nœud "Set" pour préparer les données à envoyer à l'IA
- **Prompts efficaces** : Structurer les prompts avec des instructions claires et des exemples
- **Gestion des tokens** : Surveiller l'utilisation des tokens et optimiser les prompts

### 3.2 Analyse des réponses

- **Extraction d'informations** : Utiliser l'IA pour extraire des informations clés des réponses
- **Classification** : Catégoriser les réponses (intéressé, pas intéressé, demande d'informations, etc.)
- **Mise à jour automatique** : Mettre à jour le statut dans Notion en fonction de l'analyse

## 4. Sécurité et gestion des secrets

### 4.1 Stockage sécurisé des secrets

- **Ne jamais exposer les secrets** : Ne pas inclure les clés API ou les webhooks directement dans les workflows
- **Utiliser les credentials n8n** : Stocker les identifiants dans le gestionnaire de credentials de n8n
- **Couche intermédiaire** : Utiliser une fonction serverless ou un endpoint API dédié pour masquer les webhooks n8n

### 4.2 Webhooks sécurisés

- **Authentification** : Ajouter une authentification aux webhooks (header, query parameter)
- **Validation des données** : Vérifier l'intégrité et la validité des données reçues
- **Rate limiting** : Limiter le nombre d'appels aux webhooks pour éviter les abus

## 5. Optimisation des performances

### 5.1 Exécution efficace

- **Limiter les appels API** : Regrouper les opérations pour minimiser les appels API
- **Mise en cache** : Utiliser le nœud "Function" pour mettre en cache les données fréquemment utilisées
- **Pagination** : Gérer correctement la pagination pour les grandes quantités de données

### 5.2 Gestion des erreurs

- **Nœud "Error Trigger"** : Configurer pour capturer et gérer les erreurs
- **Retry** : Implémenter des mécanismes de retry pour les opérations qui peuvent échouer temporairement
- **Logging** : Enregistrer les erreurs pour analyse ultérieure

## 6. Tests et débogage

### 6.1 Tests des workflows

- **Test par nœud** : Utiliser "Run Node" pour tester chaque nœud individuellement
- **Test de bout en bout** : Tester le workflow complet avec des données de test
- **Environnement de test** : Créer un environnement de test séparé de la production

### 6.2 Débogage

- **Nœuds "Debug"** : Ajouter des nœuds "Debug" pour inspecter les données à différentes étapes
- **Logs** : Activer les logs détaillés pour les workflows critiques
- **Monitoring** : Surveiller l'exécution des workflows pour détecter les problèmes

## 7. Intégration avec le reste du projet

### 7.1 Interaction avec les scripts PowerShell/Python

- **Nœud "Execute Command"** : Pour exécuter des scripts externes
- **Webhooks bidirectionnels** : Permettre aux scripts d'appeler n8n et vice versa
- **Partage de données** : Utiliser des fichiers JSON ou une base de données pour partager des données

### 7.2 Intégration avec MCP

- **Enrichissement des prompts** : Utiliser MCP pour enrichir les prompts envoyés aux services IA
- **Contexte dynamique** : Adapter le contexte en fonction du contact et de la phase
- **Feedback loop** : Utiliser les résultats des interactions précédentes pour améliorer les futures interactions

## 8. Exemples pratiques

### 8.1 Exemple de workflow de prospection initiale

```javascript
// Nœud "Set" pour préparer les données pour l'IA
{
  "contactName": "{{ $json.firstName }} {{ $json.lastName }}",
  "contactCompany": "{{ $json.company }}",
  "contactRole": "{{ $json.role }}",
  "artistName": "{{ $workflow.variables.artistName }}",
  "artistGenre": "{{ $workflow.variables.artistGenre }}",
  "availableDates": "{{ $json.availableDates }}",
  "prompt": "Rédige un email de prospection personnalisé pour {{ $json.firstName }} {{ $json.lastName }} de {{ $json.company }}, qui est {{ $json.role }}. L'email doit présenter {{ $workflow.variables.artistName }}, un groupe de {{ $workflow.variables.artistGenre }}, et proposer des dates de concert : {{ $json.availableDates }}. Ton doit être professionnel mais chaleureux."
}

// Nœud "HTTP Request" pour appeler OpenRouter/DeepSeek
{
  "url": "https://openrouter.ai/api/v1/chat/completions",
  "method": "POST",
  "headers": {
    "Authorization": "Bearer {{ $credentials.openRouterApi.apiKey }}",
    "Content-Type": "application/json"
  },
  "body": {
    "model": "deepseek/deepseek-chat",
    "messages": [
      {
        "role": "system",
        "content": "Tu es un assistant spécialisé dans la rédaction d'emails de prospection pour des artistes musicaux."
      },
      {
        "role": "user",
        "content": "{{ $json.prompt }}"
      }
    ]
  }
}
```

### 8.2 Exemple de vérification de réponse

```javascript
// Nœud "Function" pour analyser une réponse
function processData(items) {
  for (const item of items) {
    // Appeler l'API DeepSeek pour analyser la réponse
    const response = await $http.post(
      'https://api.deepseek.com/analyze',
      {
        text: item.emailBody,
        analysis_type: 'sentiment_and_intent'
      },
      {
        headers: {
          'Authorization': `Bearer ${$credentials.deepSeekApi.apiKey}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    // Mettre à jour l'item avec les résultats de l'analyse
    item.sentiment = response.data.sentiment;
    item.intent = response.data.intent;
    item.isInterested = response.data.intent.includes('interested');
    
    // Déterminer le nouveau statut
    if (item.isInterested) {
      item.newStatus = 'Intéressé';
    } else if (response.data.intent.includes('more_info')) {
      item.newStatus = 'Demande d\'informations';
    } else if (response.data.sentiment === 'negative') {
      item.newStatus = 'Pas intéressé';
    } else {
      item.newStatus = 'Suivi requis';
    }
  }
  return items;
}
```

## 9. Ressources additionnelles

- [Documentation officielle n8n](https://docs.n8n.io/)
- [Exemples de workflows n8n](https://n8n.io/workflows/)
- [Forum n8n](https://community.n8n.io/)
- [API Notion](https://developers.notion.com/)
- [API Gmail](https://developers.google.com/gmail/api)
- [API Google Calendar](https://developers.google.com/calendar)
- [API OpenRouter](https://openrouter.ai/docs)

---

> **Conseil** : Commencez par implémenter un workflow simple et fonctionnel, puis améliorez-le progressivement. Testez chaque nœud individuellement avant de les connecter ensemble.
