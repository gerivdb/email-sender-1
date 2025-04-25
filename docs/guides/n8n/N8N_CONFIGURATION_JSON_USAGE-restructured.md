# Configuration et Utilisation du JSON dans n8n

## Table des matières

1. [Configuration et Utilisation du JSON dans n8n](#section-1)
    1.1. [Comprendre la Structure de Données de n8n](#section-2)
    1.2. [Travailler avec les Données JSON de n8n](#section-3)
    1.3. [Configuration du Nœud Edit Fields (Set)](#section-4)
        1.3.1. [Mode de Mappage Manuel](#section-5)
        1.3.2. [Mode de Sortie JSON](#section-6)
        1.3.3. [Support de la Notation par Points](#section-7)
    1.4. [Implémentation du Nœud Code](#section-8)
        1.4.1. [Exécuter Une Fois pour Tous les Items](#section-9)
        1.4.2. [Exécuter Une Fois pour Chaque Item](#section-10)
        1.4.3. [Diviser le JSON en Items Séparés](#section-11)
    1.5. [Utiliser les Expressions dans n8n](#section-12)
        1.5.1. [Syntaxe d'Expression de Base](#section-13)
        1.5.2. [Accéder aux Données des Nœuds Précédents](#section-14)
    1.6. [Configuration du Nœud AI Agent](#section-15)
        1.6.1. [Tools Agent (Par Défaut)](#section-16)
        1.6.2. [Agent Conversationnel](#section-17)
        1.6.3. [Construire un Agent IA avec Mémoire](#section-18)
    1.7. [Exporter et Importer des Workflows](#section-19)
        1.7.1. [Méthode Copier-Coller](#section-20)
        1.7.2. [Importer des Workflows JSON](#section-21)
    1.8. [Parcourir les Données JSON](#section-22)
        1.8.1. [Utiliser le Nœud Item Lists](#section-23)
    1.9. [Outils et Convertisseurs](#section-24)
        1.9.1. [Convertisseur XML vers JSON](#section-25)
        1.9.2. [Convertisseur CSV vers JSON](#section-26)
    1.10. [Intégration avec des Services Tiers](#section-27)
        1.10.1. [Intégration Google Sheets](#section-28)
        1.10.2. [Automatiser la Génération de JSON avec OpenAI](#section-29)
        1.10.3. [Accéder aux Données d'un Webhook](#section-30)
        1.10.4. [Ajouter des Données du Nœud Précédent à Chaque Item](#section-31)
    1.11. [Bonnes Pratiques pour la Manipulation de JSON dans n8n](#section-32)

## 1. Configuration et Utilisation du JSON dans n8n <a name='section-1'></a>

Ce guide offre une exploration détaillée des capacités d'automatisation de n8n, avec un accent particulier sur les extraits JSON pour diverses configurations de nœuds. Cette fiche de référence sert de ressource complète pour les débutants comme pour les utilisateurs avancés souhaitant exploiter toute la puissance de la plateforme d'automatisation de workflow de n8n.

### 1.1. Comprendre la Structure de Données de n8n <a name='section-2'></a>

n8n transmet les données entre les nœuds sous forme de tableau d'objets, suivant une structure spécifique essentielle à comprendre pour créer des workflows efficaces. Toutes les données dans n8n suivent ce modèle fondamental :

```json
[
  {
    "json": {
      "property1": "value1",
      "property2": "value2"
    },
    "binary": {}
      "property1": "anotherValue1",
      "property2": "anotherValue2"
  }
]
```

Chaque entrée dans ce tableau est appelée un "item" et les nœuds traitent chaque item individuellement. Cette structure permet le traitement parallèle de plusieurs éléments de données à travers votre workflow. À partir de la version 0.166.0, lors de l'utilisation des nœuds Function ou Code, n8n ajoute automatiquement la clé json si elle est manquante et enveloppe les items dans un tableau si nécessaire.

### 1.2. Travailler avec les Données JSON de n8n <a name='section-3'></a>

Lors de la manipulation de données dans n8n, vous aurez fréquemment besoin d'accéder aux propriétés des nœuds précédents. Vous pouvez utiliser des expressions pour cela :

```
{{ $json.property1 }}

Pour les propriétés imbriquées plus profondes :

{{ $json.parent.child.property }}

Pour accéder aux données d'un nœud précédent spécifique :

{{ $node["NodeName"].json.property }}

```

### 1.3. Configuration du Nœud Edit Fields (Set) <a name='section-4'></a>

Le nœud Edit Fields est essentiel pour manipuler les données du workflow. Il vous permet de définir de nouvelles données et d'écraser des données existantes.

#### 1.3.1. Mode de Mappage Manuel <a name='section-5'></a>

```json
{
  "newField": "{{ $json.existingField }}",
  "combinedField": "{{ $json.firstName }} {{ $json.lastName }}",
  "staticField": "This is a static value"
}
```

#### 1.3.2. Mode de Sortie JSON <a name='section-6'></a>

```json
{
  "mode": "jsonOutput",
  "jsonOutput": {
    "newField": "{{ $json.existingField }}",
    "processedData": {
      "id": "{{ $json.id }}",
      "timestamp": "{{ $now }}"
    }
```

#### 1.3.3. Support de la Notation par Points <a name='section-7'></a>

Par défaut, n8n prend en charge la notation par points dans les noms de champs. Définir un nom comme `number.one` avec la valeur 20 produit :

```json
{
  "number": {
    "one": 20
  }
```

Pour désactiver ce comportement, sélectionnez Add Option > Support Dot Notation et définissez-le sur off.

### 1.4. Implémentation du Nœud Code <a name='section-8'></a>

Le nœud Code offre des moyens puissants de transformer les données par programmation. Il propose deux modes opérationnels :

#### 1.4.1. Exécuter Une Fois pour Tous les Items <a name='section-9'></a>

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
return newItems;
```

#### 1.4.2. Exécuter Une Fois pour Chaque Item <a name='section-10'></a>

Ce mode traite chaque item individuellement :

```javascript
// Exemple : Transformer un seul item
const item = $json;
item.processed = true;
item.modifiedAt = new Date().toISOString();
return { json: item };
```

#### 1.4.3. Diviser le JSON en Items Séparés <a name='section-11'></a>

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
return results;
```

### 1.5. Utiliser les Expressions dans n8n <a name='section-12'></a>

Les expressions permettent de définir des paramètres dynamiques basés sur les données des nœuds précédents, du workflow ou de votre environnement.

#### 1.5.1. Syntaxe d'Expression de Base <a name='section-13'></a>

Toutes les expressions ont le format `{{ your expression here }}`.

#### 1.5.2. Accéder aux Données des Nœuds Précédents <a name='section-14'></a>

Pour obtenir des données d'un corps de webhook :

```
{{ $json.city }}

Cela accède aux données JSON entrantes en utilisant la variable $json de n8n et trouve la valeur de la propriété city.

```

### 1.6. Configuration du Nœud AI Agent <a name='section-15'></a>

Le nœud AI Agent apporte de puissantes capacités d'IA aux workflows n8n. Il fournit six options d'agent LangChain :

#### 1.6.1. Tools Agent (Par Défaut) <a name='section-16'></a>

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

#### 1.6.2. Agent Conversationnel <a name='section-17'></a>

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

#### 1.6.3. Construire un Agent IA avec Mémoire <a name='section-18'></a>

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

### 1.7. Exporter et Importer des Workflows <a name='section-19'></a>

n8n sauvegarde les workflows au format JSON, permettant un partage et une réutilisation faciles.

#### 1.7.1. Méthode Copier-Coller <a name='section-20'></a>

Vous pouvez copier une partie ou la totalité d'un workflow en utilisant les raccourcis clavier standard (Ctrl+C/Cmd+C et Ctrl+V/Cmd+V).

#### 1.7.2. Importer des Workflows JSON <a name='section-21'></a>

Pour importer un workflow JSON d'une source externe :

1. Créez un nouveau workflow dans n8n
2. Copiez le script JSON
3. Collez-le directement dans l'éditeur de workflow en utilisant Ctrl+V/Cmd+V
4. Connectez tous les comptes requis
5. Personnalisez selon les besoins
6. Sauvegardez le workflow

### 1.8. Parcourir les Données JSON <a name='section-22'></a>

Travailler avec des tableaux d'objets JSON est courant dans n8n :

#### 1.8.1. Utiliser le Nœud Item Lists <a name='section-23'></a>

Pour diviser un tableau à partir de données entrantes :

```
{{ $json.body.block }}

Cela divise chaque bloc en items séparés qui peuvent être traités individuellement.

```

### 1.9. Outils et Convertisseurs <a name='section-24'></a>

n8n fournit plusieurs outils de conversion :

#### 1.9.1. Convertisseur XML vers JSON <a name='section-25'></a>

```json
{
  "operation": "convert",
  "source": "xml",
  "target": "json",
  "data": "{{ $json.xmlData }}"
}
```

#### 1.9.2. Convertisseur CSV vers JSON <a name='section-26'></a>

```json
{
  "operation": "convert",
  "source": "csv",
  "target": "json",
  "data": "{{ $json.csvData }}"
}
```

### 1.10. Intégration avec des Services Tiers <a name='section-27'></a>

n8n excelle dans la connexion de diverses plateformes et services.

#### 1.10.1. Intégration Google Sheets <a name='section-28'></a>

```json
{
  "operation": "appendOrUpdate",
  "sheetId": "YOUR_SHEET_ID",
  "range": "A:Z",
  "data": "{{ $json.rowData }}"
}
```

#### 1.10.2. Automatiser la Génération de JSON avec OpenAI <a name='section-29'></a>

Vous pouvez utiliser le nœud OpenAI pour générer automatiquement du JSON structuré :

```json
{
  "model": "gpt-4",
  "prompt": "Generate a JSON object with the following structure: {{ $json.structure }}",
  "temperature": 0.2,
  "output": "json"
}
```

#### 1.10.3. Accéder aux Données d'un Webhook <a name='section-30'></a>

Lors de la réception de données via un webhook, accédez à des éléments spécifiques en utilisant des expressions :

```
{{ $json.body.ticker }}
{{ $json.body.tf }}

Pour les représentations de chaînes de JSON, vous devrez d'abord analyser la chaîne :

```javascript
// Dans un nœud Code
const parsedBody = JSON.parse($json.body);
return { json: parsedBody };

#### 1.10.4. Ajouter des Données du Nœud Précédent à Chaque Item <a name='section-31'></a>

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
return results;
```

### 1.11. Bonnes Pratiques pour la Manipulation de JSON dans n8n <a name='section-32'></a>

1. **Structure Cohérente** : Maintenez une structure de données cohérente tout au long de votre workflow pour faciliter le débogage et la maintenance.

2. **Validation des Données** : Utilisez des nœuds IF ou des blocs try/catch dans les nœuds Code pour valider les données avant de les traiter.

3. **Documentation** : Utilisez des nœuds Sticky Note pour documenter la structure des données à différentes étapes du workflow.

4. **Gestion des Erreurs** : Prévoyez des chemins alternatifs pour gérer les cas où les données ne correspondent pas à la structure attendue.

5. **Optimisation des Performances** : Pour les grands ensembles de données, utilisez "Run Once for All Items" dans les nœuds Code plutôt que de traiter chaque item individuellement.

6. **Expressions Robustes** : Utilisez l'opérateur de chaînage optionnel (`?.`) dans les expressions pour éviter les erreurs lorsque les propriétés peuvent être manquantes.

7. **Débogage** : Utilisez des nœuds Set temporaires avec `console.log()` pour inspecter les données à différentes étapes du workflow.

