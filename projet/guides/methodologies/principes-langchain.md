# Principes de Langchain pour EMAIL SENDER 1
*Version 2025-05-16*

Ce guide présente les principes fondamentaux de Langchain et leur application dans le projet EMAIL SENDER 1, en se concentrant sur l'intégration avec AugmentCode, MCP et n8n.

## 1. Introduction à Langchain

### 1.1 Qu'est-ce que Langchain ?

Langchain est un framework open-source permettant aux développeurs IA de combiner des LLMs (comme GPT-4 ou DeepSeek) avec des sources externes de calcul et de données. Il est disponible en Python et JavaScript/TypeScript.

### 1.2 Le problème que Langchain résout

```ascii
+---------------------+       +--------------------------+
| LLM (Connaissance   |       | Vos Données Spécifiques  |
| Générale - GPT-4,   |       | (Notion, GCal, Code,     |
| DeepSeek)           |       |  Roadmaps, Docs Augment) |
+---------------------+       +--------------------------+
        ^                                 ^
        |                                 |
        +------------ LANGCHAIN -----------+
                     (Le Pont)
                      Permet :
                  1. Accès aux données
                  2. Prise d'actions
```

Les LLMs ont une connaissance générale impressionnante, mais ils n'ont pas accès à vos données spécifiques (documents internes, bases de données propriétaires, code source, etc.). Langchain permet de connecter un LLM à ces sources de données propriétaires et de lui permettre de prendre des actions basées sur les informations traitées.

### 1.3 Pertinence pour EMAIL SENDER 1

- **Accès aux données** : Connecter les LLMs aux contacts (Notion LOT1), disponibilités (Notion/GCal)
- **Personnalisation** : Générer des emails personnalisés en utilisant ces données
- **Analyse** : Traiter les réponses et déclencher des suivis appropriés

## 2. Concepts clés de Langchain

### 2.1 Components (Composants)

- **LLM Wrappers** : Interfaces pour se connecter aux LLMs (OpenAI, HuggingFace, OpenRouter, DeepSeek)
- **Prompt Templates** : Pour créer des prompts dynamiques et éviter le hardcoding
- **Indexes** : Pour la récupération d'informations pertinentes (inclut VectorStores et Embeddings)

### 2.2 Chains (Chaînes)

Assemblent les composants pour résoudre une tâche spécifique. Exemples :
- **LLMChain** : Combine un LLM et un PromptTemplate
- **SimpleSequentialChain** : Enchaîne plusieurs chaînes où la sortie de l'une est l'entrée de la suivante

### 2.3 Agents

Permettent aux LLMs d'interagir avec leur environnement (ex: faire une requête API, exécuter du code) et de prendre des décisions sur les outils à utiliser.

```ascii
+-------------------+   +----------------------+   +---------------------+
|    COMPONENTS     |   |        CHAINS        |   |       AGENTS        |
|-------------------|   |----------------------|   |---------------------|
| - LLM Wrappers    |<--| Assemblent les       |<--| LLM + Outils pour   |
| - Prompt Templates|   | composants pour une  |   | interagir avec      |
| - Indexes (Vector |   | tâche.               |   | l'environnement.    |
|   Stores, Embed.) |   | Ex: LLMChain,        |   | Ex: Python Agent,   |
|                   |   | SimpleSequentialChain|   | API Agent.          |
+-------------------+   +----------------------+   +---------------------+
```

## 3. Pipeline RAG (Retrieval Augmented Generation)

Le pipeline RAG est le cœur du système pour interroger ses propres données.

### 3.1 Préparation des données

```ascii
[Document Source] ----> [Découpage en Chunks] ----> [Création d'Embeddings] ----> [Stockage en VectorStore]
(ex: roadmap.md)      (morceaux de texte)         (vecteurs numériques)         (ex: Pinecone, Qdrant)
```

1. **Document** : Votre source de données (ex: un fichier `.md` de roadmap, une base Notion)
2. **Chunking (Découpage)** : Le document est découpé en plus petits morceaux (chunks)
3. **Embeddings (Plongements Vectoriels)** : Chaque chunk est transformé en une représentation vectorielle numérique
4. **VectorStore (Base de Données Vectorielle)** : Ces embeddings sont stockés dans une base de données spécialisée

### 3.2 Interrogation et génération

```ascii
+---------------+
| User Question |
+-------+-------+
        | (Embedding de la question)
        V
+---------------------+   <--- (Similarity Search) ---+
| VectorStore         |                               |
| (Contient les       |                               |
|  embeddings des     |                               |
|  chunks de docs)    |                               |
+--------+------------+                               |
        | (Récupération des chunks pertinents)        |
        V                                             |
+-------------------------------------------------------+
| LLM (ex: GPT-4, DeepSeek)                             |
| Input: User Question + Chunks Pertinents (Contexte)   |
+-----------------------+-------------------------------+
                        |
                        V
              +-----------------+
              | Réponse/Action  |
              +-----------------+
```

1. **Question Utilisateur** : L'utilisateur pose une question
2. **Embedding de la Question** : La question est transformée en embedding
3. **Similarity Search** : L'embedding de la question est comparé aux embeddings des chunks dans le VectorStore
4. **Récupération d'Infos Pertinentes** : Les chunks les plus similaires sont récupérés
5. **Augmentation du Prompt** : La question originale ET les chunks pertinents sont envoyés au LLM
6. **Réponse/Action du LLM** : Le LLM génère une réponse ou initie une action

## 4. Application à EMAIL SENDER 1

### 4.1 Workflow de prospection (Phase 1)

```ascii
[Notion: Contact LOT1] --> MCP --> [Context_Contact]
                                         |
[GCal: Dispos BOOKING1]--> MCP --> [Context_Dispos]
                                         |
[Template Email Perso]-------------------+---LLMChain (Langchain)--> [Email Prêt] --> [Gmail]
(PromptTemplate)                           (OpenRouter/DeepSeek)
```

1. **Données d'entrée** : Fiche contact Notion (via MCP)
2. **PromptTemplate Langchain** : Template d'email avec variables
3. **LLMChain (avec OpenRouter/DeepSeek)** : Génère le brouillon d'email
4. **Action** : Envoi via Gmail (via n8n)

### 4.2 Traitement des réponses (Phase 3)

1. **Donnée d'entrée** : Email de réponse
2. **Agent Langchain** :
   - **Outil 1 (Analyse de sentiment/intention LLM)** : Classifie la réponse
   - **Outil 2 (Notion API)** : Met à jour le statut du contact dans LOT1
   - **Outil 3 (Google Calendar API)** : Si proposition de date, vérifie/crée l'événement
   - **Outil 4 (LLMChain pour rédaction)** : Rédige une réponse appropriée

## 5. Application au ROADMAPPER

### 5.1 Mode GRAN (Décomposition)

1. Input: `Invoke-AugmentMode -Mode GRAN -FilePath "path/to/roadmap.md" -TaskIdentifier "1.2.3"`
2. **Agent Langchain (Mode GRAN)** :
   - **Outil 1 (MCP Filesystem)** : Lire `roadmap.md` et extraire la tâche "1.2.3"
   - **Outil 2 (VectorStore "Roadmaps Passées")** : Chercher des décompositions similaires
   - **Outil 3 (LLM Interaction)** : Proposer des sous-tâches au LLM
   - **Outil 4 (MCP Filesystem)** : Mettre à jour `roadmap.md` avec les sous-tâches

### 5.2 Mode DEV-R (Implémentation)

Similaire, mais les outils seraient orientés vers la compréhension du code existant (via MCP GitHub), la génération de code simple, et l'exécution de tests (Pester/pytest).

## 6. Intégration avec AugmentCode

### 6.1 AugmentCode et Langchain

AugmentCode peut utiliser Langchain comme bibliothèque principale pour construire les fonctionnalités de EMAIL SENDER et ROADMAPPER.

Les Modes Opérationnels (GRAN, DEV-R, ARCHI, etc.) peuvent être implémentés comme des Agents Langchain spécialisés, chacun avec ses propres outils.

### 6.2 Intégration avec MCP

```ascii
User Command (Invoke-AugmentMode)
     |
     V
+---------------------+
| AugmentCode (Core)  |
| (Orchestrateur)     |
+----+------------+---+
     |            |
(Lance Agent) (Prépare Contexte via MCP)
     V            V
+---------------------+      +---------------------------------+
| Agent Langchain     |----->| MCP (Filesystem, GitHub, etc.)  |
| (Mode Spécifique)   |      +---------------------------------+
| - LLM               |
| - PromptTemplate    |
| - Tools (MCP, Scripts) |
| - VectorStore (Memories)|
+---------+-----------+
          |
          V
Actions (Modification de fichiers,
         Appel API, etc.)
```

MCP sert de couche d'abstraction pour l'accès aux données (filesystem, github, gcp). Langchain, au sein d'AugmentCode, utilisera MCP comme un "Tool" ou un "Document Loader" pour récupérer le contexte nécessaire avant de le passer aux LLMs.

### 6.3 Intégration avec n8n

**Option 1 : Langchain comme service appelé par n8n**
- n8n récupère des données (ex: nouveau contact Notion)
- n8n fait un appel API à un endpoint AugmentCode (qui utilise Langchain) pour générer un email
- n8n reçoit l'email et l'envoie

**Option 2 : n8n comme outil pour un Agent Langchain**
- Un agent Langchain peut avoir un "Tool" qui déclenche un workflow n8n spécifique via l'API de n8n

## 7. Implémentation pratique

### 7.1 Setup de base

```python
# Installation
pip install langchain langchain-openai pinecone-client python-dotenv

# Configuration
from dotenv import load_dotenv
load_dotenv()  # Charge les variables d'environnement depuis .env
```

### 7.2 LLM Wrappers

```python
# Pour les modèles OpenAI standard
from langchain.llms import OpenAI
llm = OpenAI(model_name="text-davinci-003")
result = llm("explain large language models in one sentence")

# Pour les modèles de chat (GPT-3.5, GPT-4)
from langchain.schema import AIMessage, HumanMessage, SystemMessage
from langchain.chat_models import ChatOpenAI
chat = ChatOpenAI(model_name="gpt-3.5-turbo", temperature=0.3)
messages = [
    SystemMessage(content="You are an expert data scientist"),
    HumanMessage(content="Write a Python script...")
]
response = chat(messages)
print(response.content)
```

### 7.3 Prompt Templates

```python
from langchain import PromptTemplate

template = """
You are an expert in email marketing.
Write a personalized email to {name} from {company}, who is {role}.
The email should present our {product} and suggest a meeting.
Our available dates are: {dates}.
"""

prompt = PromptTemplate(
    input_variables=["name", "company", "role", "product", "dates"],
    template=template
)

formatted_prompt = prompt.format(
    name="John Smith",
    company="Acme Corp",
    role="CTO",
    product="AI Email Assistant",
    dates="June 15, June 22, July 10"
)
```

### 7.4 Chains

```python
from langchain.chains import LLMChain

chain = LLMChain(llm=chat, prompt=prompt)
email = chain.run({
    "name": "John Smith",
    "company": "Acme Corp",
    "role": "CTO",
    "product": "AI Email Assistant",
    "dates": "June 15, June 22, July 10"
})
```

### 7.5 RAG (Retrieval Augmented Generation)

```python
# Text Splitting
from langchain.text_splitter import RecursiveCharacterTextSplitter
text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=100)
docs = text_splitter.create_documents([long_text])

# Embeddings
from langchain.embeddings import OpenAIEmbeddings
embeddings = OpenAIEmbeddings(model_name="text-embedding-ada-002")

# VectorStore
from langchain.vectorstores import Chroma
vectorstore = Chroma.from_documents(docs, embeddings)

# Retrieval
query = "What are the key features of our product?"
relevant_docs = vectorstore.similarity_search(query, k=3)

# RAG
from langchain.chains import RetrievalQA
qa_chain = RetrievalQA.from_chain_type(
    llm=chat,
    chain_type="stuff",
    retriever=vectorstore.as_retriever()
)
answer = qa_chain.run(query)
```

## 8. Conclusion

Langchain n'est pas juste un outil de plus ; c'est un paradigme de construction pour les applications IA modernes. Pour EMAIL SENDER 1 :

1. **Modularité** : Les composants de Langchain s'alignent parfaitement avec la granularité adaptative
2. **Extensibilité** : Ajouter de nouvelles sources de données ou capacités devient plus structuré
3. **Contextualisation Puissante** : La combinaison VectorStores + RAG est la méthode standard pour donner aux LLMs une connaissance approfondie de vos projets spécifiques
4. **Agentivité** : Le concept d'Agent de Langchain est la clé pour qu'AugmentCode soit un véritable assistant proactif

## 9. Ressources additionnelles

- [Documentation officielle Langchain](https://python.langchain.com/docs/get_started/introduction)
- [Tutoriels Langchain](https://python.langchain.com/docs/use_cases/question_answering/)
- [Intégration Augment-n8n](/projet/guides/n8n/integration-augment-n8n.md)
- [Guide des modes opérationnels Augment](/projet/guides/methodologies/modes-operationnels-augment.md)
