# Configuration et Utilisation du JSON dans n8n

Ce guide offre une exploration détaillée des capacités d'automatisation de n8n, avec un accent particulier sur les extraits JSON pour diverses configurations de nœuds. Cette fiche de référence sert de ressource complète pour les débutants comme pour les utilisateurs avancés souhaitant exploiter toute la puissance de la plateforme d'automatisation de workflow de n8n.

## Comprendre la Structure de Données de n8n

n8n transmet les données entre les nœuds sous forme de tableau d'objets, suivant une structure spécifique essentielle à comprendre pour créer des workflows efficaces. Toutes les données dans n8n suivent ce modèle fondamental :

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
```

Chaque entrée dans ce tableau est appelée un "item" et les nœuds traitent chaque item individuellement. Cette structure permet le traitement parallèle de plusieurs éléments de données à travers votre workflow. À partir de la version 0.166.0, lors de l'utilisation des nœuds Function ou Code, n8n ajoute automatiquement la clé json si elle est manquante et enveloppe les items dans un tableau si nécessaire.

## Travailler avec les Données JSON de n8n

Lors de la manipulation de données dans n8n, vous aurez fréquemment besoin d'accéder aux propriétés des nœuds précédents. Vous pouvez utiliser des expressions pour cela :

```
{{ $json.property1 }}
```

Pour les propriétés imbriquées plus profondes :

```
{{ $json.parent.child.property }}
```

Pour accéder aux données d'un nœud précédent spécifique :

```
{{ $node["NodeName"].json.property }}
```

## Configuration du Nœud Edit Fields (Set)

Le nœud Edit Fields est essentiel pour manipuler les données du workflow. Il vous permet de définir de nouvelles données et d'écraser des données existantes.

### Mode de Mappage Manuel

```json
{
  "newField": "{{ $json.existingField }}",
  "combinedField": "{{ $json.firstName }} {{ $json.lastName }}",
  "staticField": "This is a static value"
}
```

### Mode de Sortie JSON

```json
{
  "mode": "jsonOutput",
  "jsonOutput": {
    "newField": "{{ $json.existingField }}",
    "processedData": {
      "id": "{{ $json.id }}",
      "timestamp": "{{ $now }}"
    }
  }
}
```

### Support de la Notation par Points

Par défaut, n8n prend en charge la notation par points dans les noms de champs. Définir un nom comme `number.one` avec la valeur 20 produit :

```json
{
  "number": {
    "one": 20
  }
}
```

Pour désactiver ce comportement, sélectionnez Add Option > Support Dot Notation et définissez-le sur off.

## Implémentation du Nœud Code

Le nœud Code offre des moyens puissants de transformer les données par programmation. Il propose deux modes opérationnels :

### Exécuter Une Fois pour Tous les Items

Ce mode traite toutes les données entrantes en une seule fois, utile pour les opérations sur plusieurs items :

```javascript
// Exemple : Obtenir un Tableau à partir d'un Objet
const newItems = [];
const inputData = $input.all().json;
for (const item of inputData) {
  newItems.push({
    json: {
      modifiedData: item.originalData,
      timestamp: new Date().toISOString()
    }
  });
}
return newItems;
```

### Exécuter Une Fois pour Chaque Item

Ce mode traite chaque item individuellement :

```javascript
// Exemple : Transformer un seul item
const item = $json;
item.processed = true;
item.modifiedAt = new Date().toISOString();
return { json: item };
```

### Diviser le JSON en Items Séparés

Une tâche courante est de diviser un JSON imbriqué en items individuels :

```javascript
// Diviser les données webhook entrantes en items séparés
let results = [];
for (const item of $('Webhook').all()) {
  const students = item.json.body.students;
  for (studentKey of Object.keys(students)) {
    results.push({
      json: students[studentKey]
    });
  }
}
return results;
```

## Utiliser les Expressions dans n8n

Les expressions permettent de définir des paramètres dynamiques basés sur les données des nœuds précédents, du workflow ou de votre environnement.

### Syntaxe d'Expression de Base

Toutes les expressions ont le format `{{ your expression here }}`.

### Accéder aux Données des Nœuds Précédents

Pour obtenir des données d'un corps de webhook :

```
{{ $json.city }}
```

Cela accède aux données JSON entrantes en utilisant la variable $json de n8n et trouve la valeur de la propriété city.

## Configuration du Nœud AI Agent

Le nœud AI Agent apporte de puissantes capacités d'IA aux workflows n8n. Il fournit six options d'agent LangChain :

### Tools Agent (Par Défaut)

Cet agent utilise des outils externes et des API pour effectuer des actions et récupérer des informations. Exemple de configuration JSON :

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
```

### Agent Conversationnel

Cet agent maintient le contexte, comprend l'intention de l'utilisateur et fournit des réponses pertinentes. Idéal pour les chatbots et les assistants virtuels :

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
```

### Construire un Agent IA avec Mémoire

Pour créer un agent IA avec mémoire à long terme :

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
```

## Exporter et Importer des Workflows

n8n sauvegarde les workflows au format JSON, permettant un partage et une réutilisation faciles.

### Méthode Copier-Coller

Vous pouvez copier une partie ou la totalité d'un workflow en utilisant les raccourcis clavier standard (Ctrl+C/Cmd+C et Ctrl+V/Cmd+V).

### Importer des Workflows JSON

Pour importer un workflow JSON d'une source externe :

1. Créez un nouveau workflow dans n8n
2. Copiez le script JSON
3. Collez-le directement dans l'éditeur de workflow en utilisant Ctrl+V/Cmd+V
4. Connectez tous les comptes requis
5. Personnalisez selon les besoins
6. Sauvegardez le workflow

## Parcourir les Données JSON

Travailler avec des tableaux d'objets JSON est courant dans n8n :

### Utiliser le Nœud Item Lists

Pour diviser un tableau à partir de données entrantes :

```
{{ $json.body.block }}
```

Cela divise chaque bloc en items séparés qui peuvent être traités individuellement.

## Outils et Convertisseurs

n8n fournit plusieurs outils de conversion :

### Convertisseur XML vers JSON

```json
{
  "operation": "convert",
  "source": "xml",
  "target": "json",
  "data": "{{ $json.xmlData }}"
}
```

### Convertisseur CSV vers JSON

```json
{
  "operation": "convert",
  "source": "csv",
  "target": "json",
  "data": "{{ $json.csvData }}"
}
```

## Intégration avec des Services Tiers

n8n excelle dans la connexion de diverses plateformes et services.

### Intégration Google Sheets

```json
{
  "operation": "appendOrUpdate",
  "sheetId": "YOUR_SHEET_ID",
  "range": "A:Z",
  "data": "{{ $json.rowData }}"
}
```

### Automatiser la Génération de JSON avec OpenAI

Vous pouvez utiliser le nœud OpenAI pour générer automatiquement du JSON structuré :

```json
{
  "model": "gpt-4",
  "prompt": "Generate a JSON object with the following structure: {{ $json.structure }}",
  "temperature": 0.2,
  "output": "json"
}
```

## Fonctionnalités Avancées et Astuces

### Accéder aux Données d'un Webhook

Lors de la réception de données via un webhook, accédez à des éléments spécifiques en utilisant des expressions :

```
{{ $json.body.ticker }}
{{ $json.body.tf }}
```

Pour les représentations de chaînes de JSON, vous devrez d'abord analyser la chaîne :

```javascript
// Dans un nœud Code
const parsedBody = JSON.parse($json.body);
return { json: parsedBody };
```

### Ajouter des Données du Nœud Précédent à Chaque Item

Lorsque vous divisez des données mais que vous avez besoin de conserver des informations de la source originale :

```javascript
// Dans un nœud Code
const results = [];
const eventName = $('Webhook').first().json.body.event.event_name;
for (const student of $json.body.students) {
  results.push({
    json: {
      ...student,
      eventName: eventName
    }
  });
}
return results;
```

## Bonnes Pratiques pour la Manipulation de JSON dans n8n

1. **Structure Cohérente** : Maintenez une structure de données cohérente tout au long de votre workflow pour faciliter le débogage et la maintenance.

2. **Validation des Données** : Utilisez des nœuds IF ou des blocs try/catch dans les nœuds Code pour valider les données avant de les traiter.

3. **Documentation** : Utilisez des nœuds Sticky Note pour documenter la structure des données à différentes étapes du workflow.

4. **Gestion des Erreurs** : Prévoyez des chemins alternatifs pour gérer les cas où les données ne correspondent pas à la structure attendue.

5. **Optimisation des Performances** : Pour les grands ensembles de données, utilisez "Run Once for All Items" dans les nœuds Code plutôt que de traiter chaque item individuellement.

6. **Expressions Robustes** : Utilisez l'opérateur de chaînage optionnel (`?.`) dans les expressions pour éviter les erreurs lorsque les propriétés peuvent être manquantes.

7. **Débogage** : Utilisez des nœuds Set temporaires avec `console.log()` pour inspecter les données à différentes étapes du workflow.
