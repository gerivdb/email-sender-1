# Intégrations IA & LLM dans n8n

Ce document détaille les différentes façons d'intégrer des modèles de langage (LLM) et des fonctionnalités d'IA dans vos workflows n8n.

## Modèle de Chat OpenAI (GPT-3.5/GPT-4)

Utilise l'API Chat d'OpenAI pour générer des réponses. Vous spécifiez le modèle, les prompts et les paramètres comme la température.

Ce nœud peut prendre un prompt système et un prompt utilisateur pour générer une complétion. Par exemple, pour utiliser le modèle GPT-3.5 Turbo avec un rôle système et un message utilisateur :

```json
{
  "name": "ChatGPT",
  "type": "n8n-nodes-langchain.lmChatOpenAi",
  "typeVersion": 1,
  "parameters": {
    "model": "gpt-3.5-turbo",
    "temperature": 0.7,
    "maxTokens": 500,
    "systemPrompt": "You are a helpful assistant.",
    "userPrompt": "Hello! How can I automate tasks with n8n?"
  },
  "credentials": {
    "openAiApi": {
      "id": "YOUR_CRED_ID",
      "name": "OpenAI API"
    }
  }
}
```

**Explication :** Cette configuration définit le nœud Chat OpenAI pour utiliser le modèle GPT-3.5 avec un message système fournissant le contexte et un message utilisateur. La réponse sera disponible en tant que sortie du nœud. Assurez-vous d'avoir configuré des identifiants API OpenAI nommés "OpenAI API", référencés dans les credentials. Vous pouvez ajuster la température pour le caractère aléatoire et maxTokens pour la longueur.

## Complétion de Texte OpenAI

Pour les modèles de complétion de texte GPT-3 (comme text-davinci-003), vous pouvez utiliser le nœud OpenAI en mode complétion. Fournissez un prompt et des paramètres. Par exemple :

```json
{
  "name": "OpenAI Completion",
  "type": "n8n-nodes-langchain.openai",
  "typeVersion": 1,
  "parameters": {
    "model": "text-davinci-003",
    "prompt": "Summarize the following text: {{$json[\"content\"]}}",
    "temperature": 0.5,
    "maxTokens": 200
  },
  "credentials": {
    "openAiApi": {
      "name": "OpenAI API"
    }
  }
}
```

**Explication :** Cela enverra un prompt au point de terminaison de complétion d'OpenAI pour résumer un contenu provenant des données d'entrée. La syntaxe `{{$json["content"]}}` insère des données du nœud précédent. Le nœud utilise les identifiants API OpenAI. La sortie apparaît dans le JSON du nœud (champ result contenant le texte de complétion).

## Agents IA (avec Outils)

n8n prend en charge des nœuds Agent avancés qui permettent à un modèle d'IA d'utiliser des outils (comme la recherche web, des calculatrices ou d'autres fonctions de nœud) pour accomplir des tâches. Par exemple, l'Agent de Fonctions OpenAI peut appeler des fonctions personnalisées, et l'Agent ReAct utilise la stratégie ReAct pour décider quel outil utiliser à chaque étape.

Voici un exemple simplifié de configuration de nœud Agent IA utilisant un modèle OpenAI et un outil (par exemple, un outil de recherche Google) :

```json
{
  "name": "AI Agent (ReAct)",
  "type": "n8n-nodes-langchain.agent",
  "typeVersion": 1,
  "parameters": {
    "agentType": "react", // Type d'agent : "react", "functions", "planAndExecute", etc.
    "model": "gpt-4", // Modèle LLM sous-jacent
    "memory": false, // Utiliser ou non la mémoire conversationnelle
    "tools": [
      {
        "name": "googleSearch", // Nom d'un nœud outil connecté
        "input": "What is n8n?" // Exemple de requête pour laquelle l'agent utilisera cet outil
      }
    ]
  }
}
```

**Explication :** Cet agent est configuré pour utiliser la stratégie ReAct avec GPT-4. Le tableau tools correspondrait à des nœuds Outil réels connectés au nœud Agent (par exemple, un nœud Google Search dans le workflow). En pratique, vous ajoutez des outils via l'interface utilisateur de l'éditeur (ils deviennent des sous-nœuds). L'agent décidera quand utiliser l'outil. Par exemple, il pourrait utiliser l'outil Google Search pour récupérer des informations nécessaires pour répondre à une question.

**Note :** Le cluster de nœuds agent gère la logique ; assurez-vous d'avoir configuré les nœuds d'outils appropriés et les identifiants (comme les clés API Google). Les agents peuvent également utiliser d'autres modes comme l'Agent de Fonctions OpenAI, l'Agent Plan-and-Execute, ou l'Agent SQL, chacun permettant à l'IA d'effectuer des tâches complexes spécifiques (par exemple, appeler des fonctions définies, décomposer une tâche en sous-tâches, ou exécuter des requêtes SQL via des identifiants de base de données fournis).

## Embeddings et Bases de Données Vectorielles

n8n fournit des nœuds pour générer des embeddings de texte avec des modèles (OpenAI, Cohere, Google PaLM, etc.) et pour les stocker/récupérer dans des bases de données vectorielles (Pinecone, Weaviate, etc.).

Par exemple, le nœud Embeddings OpenAI peut prendre du texte et retourner un vecteur. L'utilisation est simple : vous spécifiez le champ de texte à transformer en embedding et le modèle. La sortie est généralement un tableau de nombres représentant le vecteur. Ceux-ci peuvent être utilisés avec un nœud Vector Store (comme Pinecone) pour ajouter ou interroger des vecteurs.

Exemple pour un nœud Embedding OpenAI :

```json
{
  "name": "Text to Vector",
  "type": "n8n-nodes-langchain.embeddingsOpenAi",
  "typeVersion": 1,
  "parameters": {
    "model": "text-embedding-ada-002",
    "text": "={{ $json[\"content\"] }}"
  },
  "credentials": {
    "openAiApi": {
      "name": "OpenAI API"
    }
  }
}
```

**Explication :** Cela prend le champ content du JSON d'entrée et génère un embedding de 1536 dimensions en utilisant le modèle ada d'OpenAI. Vous enverriez généralement ce vecteur à un stockage ou l'utiliseriez dans une recherche de similarité.

Pour le stockage, un nœud Pinecone (ou autre base de données vectorielle) peut être utilisé, avec des opérations comme Insert Vector ou Query Vector (vous fournissez le nom de l'index, les données vectorielles, et toutes les métadonnées ou vecteurs de requête nécessaires).

Comme l'utilisation des bases de données vectorielles peut être complexe, référez-vous à la documentation spécifique des nœuds pour les noms exacts des paramètres.

Le concept clé est que les nœuds Embeddings convertissent le texte en vecteurs numériques, et les nœuds Vector Store permettent de sauvegarder et de rechercher ces vecteurs, permettant des workflows comme la recherche sémantique ou la génération augmentée par récupération.

## Intégration avec d'autres modèles

En plus d'OpenAI, n8n prend en charge d'autres fournisseurs de LLM comme :

- **Anthropic Claude** : Pour des modèles comme Claude 2 ou Claude Instant
- **Google PaLM/Gemini** : Pour les modèles de Google
- **Cohere** : Pour la génération de texte et les embeddings
- **Hugging Face** : Pour accéder à des milliers de modèles open source

La configuration est similaire à celle d'OpenAI, mais avec des paramètres spécifiques au fournisseur et des identifiants d'API différents.

## Cas d'utilisation courants

1. **Génération de contenu** : Utiliser des LLM pour créer des textes, résumés, ou traductions
2. **Analyse de sentiment** : Classifier le ton ou l'intention d'un texte
3. **Extraction d'informations** : Extraire des données structurées à partir de texte non structuré
4. **Recherche sémantique** : Trouver des documents similaires basés sur le sens plutôt que sur des mots-clés
5. **Chatbots** : Créer des assistants conversationnels avec mémoire et accès à des outils externes
6. **Classification de documents** : Catégoriser automatiquement des textes

## Bonnes pratiques

- **Gestion des tokens** : Surveillez l'utilisation des tokens pour contrôler les coûts
- **Prompts efficaces** : Concevez des prompts clairs et spécifiques pour obtenir les meilleurs résultats
- **Validation des sorties** : Vérifiez et nettoyez les sorties des LLM avant de les utiliser dans des étapes critiques
- **Mise en cache** : Envisagez de mettre en cache les résultats pour les requêtes fréquentes
- **Sécurité** : Soyez prudent avec les données sensibles envoyées aux API externes
- **Fallbacks** : Prévoyez des alternatives en cas d'échec d'un appel API
