# Guide Complet des Extraits JSON pour l'Automatisation n8n

Lors de la création d'automatisations dans n8n, la gestion appropriée des configurations JSON est essentielle, en particulier pour les nœuds avancés comme le module Agent IA. Ce guide compile des extraits JSON clés et des modèles pour configurer efficacement divers composants n8n, avec un accent particulier sur la fonctionnalité Agent IA.

## Structure Fondamentale des Données JSON de n8n

Dans n8n, les données circulent entre les nœuds dans une structure JSON standardisée. Comprendre cette structure est crucial pour une automatisation efficace :

```json
[
  {
    "json": {
      "property1": "value1",
      "property2": "value2"
    },
    "binary": {}
  },
  {
    "json": {
      "property1": "anotherValue1",
      "property2": "anotherValue2"
    },
    "binary": {}
  }
]
```plaintext
Chaque élément de ce tableau représente une donnée traitée dans votre workflow. À partir de la version 0.166.0, n8n ajoute automatiquement la clé json si elle est manquante et enveloppe les éléments dans un tableau si nécessaire lors de l'utilisation des nœuds Function ou Code.

## Configuration JSON du Module Agent IA

Le module Agent IA dans n8n propose plusieurs types d'agents, chacun nécessitant des configurations JSON spécifiques. Voici des extraits pour les types les plus courants :

### Configuration de l'Agent Tools (Par Défaut)

```json
{
  "agent": "tools",
  "model": {
    "provider": "openai",
    "model": "gpt-4",
    "temperature": 0.7
  },
  "systemMessage": "You are a helpful assistant that uses tools to find information and accomplish tasks.",
  "memory": true,
  "verbose": true
}
```plaintext
Cette configuration met en place l'Agent Tools par défaut qui peut utiliser des outils externes et des API pour effectuer des actions et récupérer des informations.

### Configuration de l'Agent Conversationnel

```json
{
  "agent": "conversational",
  "model": {
    "provider": "openai",
    "model": "gpt-3.5-turbo",
    "temperature": 0.8
  },
  "systemMessage": "You are a helpful customer service agent for our company.",
  "memory": true
}
```plaintext
L'Agent Conversationnel est idéal pour les chatbots et les assistants virtuels, car il peut maintenir le contexte et comprendre l'intention de l'utilisateur.

### Configuration d'Agent avec Mémoire

```json
{
  "agent": "tools",
  "model": {
    "provider": "openai",
    "model": "gpt-4",
    "temperature": 0.7
  },
  "systemMessage": "You are an assistant with memory capabilities. Use your tools to remember important information from our conversations.",
  "memory": true,
  "tools": ["memory-add", "memory-retrieve"]
}
```plaintext
Cette configuration crée un agent IA avec des capacités de mémoire à long terme pour maintenir le contexte à travers les interactions.

## Gestion des Problèmes de Sortie de l'Agent IA

Un défi courant avec l'Agent IA est qu'il produit souvent des résultats sous forme de chaîne de caractères à l'intérieur d'un objet JSON, ce qui peut causer des problèmes lors du traitement ultérieur :

```json
{
  "output": "{\n \"countries\": [\n {\n \"name\": \"China\",\n \"population\": 1411778724\n },\n {\n \"name\": \"India\",\n \"population\": 1387297452\n },\n {\n \"name\": \"United States\",\n \"population\": 331893745\n },\n {\n \"name\": \"Indonesia\",\n \"population\": 276362965\n },\n {\n \"name\": \"Pakistan\",\n \"population\": 225199937\n }\n ]\n}"
}
```plaintext
Pour traiter cette sortie, vous devrez généralement utiliser un nœud Code pour analyser la chaîne en un objet JSON approprié :

```javascript
// Analyser la sortie chaîne de l'Agent IA en JSON utilisable
const outputStr = $json.output;
let parsedData;
try {
  parsedData = JSON.parse(outputStr);
  return { json: parsedData };
} catch (error) {
  // Gérer le cas où la sortie n'est pas un JSON valide
  return { json: { error: "Could not parse output as JSON", original: outputStr } };
}
```plaintext
## Fournir des Exemples JSON aux Agents IA

Lorsque vous demandez aux agents IA de produire du JSON structuré, vous pouvez rencontrer l'erreur "Single '{' in template". Cela se produit parce que les accolades dans votre exemple JSON entrent en conflit avec la syntaxe d'expression de n8n.

Pour éviter cela, vous pouvez utiliser l'une de ces approches :

### 1. Utiliser un Nœud Code pour Générer l'Exemple

```javascript
// Générer un exemple JSON avant le nœud Agent IA
const example = {
  "data": [
    {
      "Item1": "This is a test",
      "Somedata": {
        "Frog": 6,
        "Cat": 7,
        "Dog": 9
      }
    }
  ]
};
return { json: { example: JSON.stringify(example) } };
```plaintext
Ensuite, dans votre nœud Agent IA, vous pouvez référencer cet exemple avec `{{ $json.example }}`.

### 2. Utiliser la Fonction fromAI (Méthode Plus Récente)

Pour les versions plus récentes de n8n, la fonction $fromAI fournit une approche plus propre pour gérer les sorties de l'agent IA :

```plaintext
{{ $fromAI.json.specificProperty }}
```plaintext
Cela vous permet de référencer directement les propriétés de la sortie de l'IA dans les nœuds suivants sans analyse manuelle.

## Travailler avec les Outils HTTP dans les Agents IA

Lors de la configuration d'outils HTTP pour les agents IA qui nécessitent des paramètres JSON :

```json
{
  "url": "https://api.example.com/endpoint",
  "method": "POST",
  "headers": {
    "Content-Type": "application/json"
  },
  "bodyParametersUi": {
    "parameter": [
      {
        "name": "ids",
        "value": "{{ [\"ID\"] }}"
      }
    ]
  }
}
```plaintext
Le format approprié pour les paramètres de tableau doit être explicitement décrit dans la description de l'outil pour s'assurer que l'IA les formate correctement.

## Préserver les Champs JSON d'Entrée dans la Sortie de l'Agent IA

Un défi courant est de maintenir les champs d'entrée (comme les IDs) dans la sortie de l'agent IA. Comme l'agent IA pourrait ne pas inclure de manière fiable ces champs dans sa réponse, une meilleure approche consiste à utiliser un nœud Code après l'Agent IA pour fusionner l'entrée originale avec la sortie de l'agent :

```javascript
// Préserver l'ID de l'entrée tout en utilisant la sortie de l'agent IA
const originalId = $node["PreviousNode"].first().json.id;
const aiOutput = $json.output;
return {
  json: {
    id: originalId,
    aiResult: aiOutput
    // Ajoutez tout autre champ que vous souhaitez préserver
  }
};
```plaintext
## Traitement de Plusieurs Éléments avec les Agents IA

Par défaut, l'Agent IA traite chaque élément individuellement, ce qui peut prendre du temps pour le traitement par lots. Pour traiter plusieurs éléments en un seul appel :

```javascript
// Collecter tous les éléments dans un seul tableau pour l'agent IA
const allItems = $input.all().map(item => item.json);
return {
  json: {
    combinedData: allItems,
    prompt: "Process all these items at once: " + JSON.stringify(allItems)
  }
};
```plaintext
## Formatage de Sortie Structurée pour les Agents IA

Pour obtenir une sortie structurée cohérente des agents IA, fournissez des instructions claires de format de sortie dans votre message système. Pour les sorties JSON :

```json
{
  "options": {
    "systemMessage": "You are a helpful assistant. Always respond in valid JSON format following this structure:\n\n{\n  \"category\": \"[Category of the request]\",\n \"response\": \"[Your detailed response]\",\n \"nextSteps\": [\"step1\", \"step2\", \"etc\"]\n}\n\nEnsure your entire response is valid JSON."
  }
}
```plaintext
## Utiliser des Expressions pour Accéder aux Données JSON

n8n fournit une syntaxe d'expression puissante pour accéder et manipuler les données JSON :

```plaintext
{{ $json.property1 }}
```plaintext
Pour les propriétés imbriquées plus profondes :

```plaintext
{{ $json.parent.child.property }}
```plaintext
Pour accéder aux données d'un nœud précédent spécifique :

```plaintext
{{ $node["NodeName"].json.property }}
```plaintext
## Techniques Avancées pour les Agents IA

### Chaînage d'Agents

Pour des tâches complexes, vous pouvez chaîner plusieurs agents IA, chacun spécialisé dans une partie spécifique du processus :

```javascript
// Nœud Code pour préparer l'entrée pour le prochain agent
const firstAgentOutput = $json.output;
// Extraire les informations pertinentes ou transformer si nécessaire
return {
  json: {
    previousAgentResult: firstAgentOutput,
    nextAgentInstruction: "Continue processing based on the previous agent's output"
  }
};
```plaintext
### Validation et Nettoyage des Sorties IA

Pour garantir que les sorties de l'IA sont utilisables dans les étapes suivantes du workflow :

```javascript
// Valider et nettoyer la sortie JSON de l'IA
const aiOutput = $json.output;
let processedOutput;

try {
  // Tenter d'analyser si c'est une chaîne JSON
  const parsedOutput = typeof aiOutput === 'string' ? JSON.parse(aiOutput) : aiOutput;
  
  // Valider les champs requis
  if (!parsedOutput.requiredField) {
    throw new Error("Missing required field");
  }
  
  // Nettoyer/normaliser les données
  processedOutput = {
    ...parsedOutput,
    normalizedField: parsedOutput.someField.trim().toLowerCase()
  };
  
  return { json: processedOutput };
} catch (error) {
  // Gérer les erreurs avec une sortie de secours
  return { 
    json: { 
      error: true, 
      message: `Failed to process AI output: ${error.message}`,
      fallbackData: { /* données de secours */ }
    } 
  };
}
```plaintext
## Bonnes Pratiques pour les Configurations JSON dans n8n

1. **Validation des Entrées/Sorties** : Toujours valider les données avant et après le traitement par l'IA
2. **Gestion des Erreurs Robuste** : Inclure des blocs try/catch pour gérer les formats inattendus
3. **Documentation** : Documenter clairement la structure attendue des données dans les messages système
4. **Tests** : Tester avec divers scénarios d'entrée pour s'assurer que votre configuration gère tous les cas
5. **Modularité** : Diviser les tâches complexes en étapes plus petites et plus gérables
6. **Versionnage** : Garder une trace des modifications de configuration pour faciliter le débogage
7. **Optimisation des Performances** : Traiter les données par lots lorsque cela est possible pour réduire les appels API
