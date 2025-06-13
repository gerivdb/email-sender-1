# Rapport Détaillé sur les Niveaux des Agents IA - Analyse du Post de Ashpreet Bedi

## Introduction

Ce rapport est basé sur un post publié par Ashpreet Bedi sur X le 18 mai 2025 à 20:02 UTC, disponible à l'adresse suivante : [https://x.com/ashpreetbedi/status/1924193924995744158](https://x.com/ashpreetbedi/status/1924193924995744158). Le post détaille une classification des agents IA en cinq niveaux de complexité croissante, en utilisant le framework **Agno** comme exemple. Ce rapport vise à analyser chaque niveau, à expliquer les concepts techniques, et à explorer comment ces informations peuvent être utiles pour des projets de développement d'agents IA.

---

## Contexte Général

### Auteur et Objectif

Ashpreet Bedi, utilisateur de X sous le pseudonyme `@ashpreetbedi`, est probablement un ingénieur ou un chercheur spécialisé dans l'IA, travaillant avec le framework **Agno**, une bibliothèque légère et performante pour la création d'agents IA. Le post a pour objectif d'expliquer les **cinq niveaux de complexité des agents IA**, allant de configurations simples à des systèmes agentiques complexes. Il s'adresse principalement aux développeurs et ingénieurs IA cherchant à comprendre comment structurer et améliorer leurs agents.

### Qu'est-ce qu'Agno ?

Agno est une bibliothèque open-source conçue pour construire des agents IA avec des fonctionnalités comme la mémoire, la recherche de connaissances, et le raisonnement. Elle est **agnostique aux modèles** (compatible avec plus de 23 fournisseurs de modèles, comme OpenAI ou Gemini), ce qui permet une grande flexibilité. Agno est également optimisée pour la performance, la simplicité, et la fiabilité.

---

## Analyse des Cinq Niveaux des Agents IA

### Niveau 1 : Agent avec Outils et Instructions

#### Description

Le niveau 1 est le plus simple. Il s'agit d'un agent IA qui utilise un modèle de langage (LLM) avec des **instructions** et des **outils** pour interagir avec des environnements externes. Ashpreet note que beaucoup de personnes perçoivent les agents IA comme de simples "LLM + appels d'outils dans une boucle", ce qui reflète une compréhension basique.

#### Code Exemple

```python
from agno.agent import Agent
from agno.models.openai import OpenAIChat
from agno.tools.duckduckgo import DuckDuckGoTools

agno_assist = Agent(
    name="Agno AGI",
    model=OpenAIChat(id="gpt-4.1"),
    description=(
        "You are 'Agno AGI', an autonomous AI Agent that can build agents using the Agno "
        "framework. Your goal is to help developers understand and use Agno by providing "
        "explanations, working code examples, and optional visual and audio explanations "
        "of key concepts."
    ),
    instructions="Search the web for information about Agno.",
    tools=[DuckDuckGoTools()],
    add_datetime_to_instructions=True,
    markdown=True,
)

agno_assist.print_response("What is Agno?", stream=True)
```plaintext
#### Analyse Technique

- **Imports** : Le code importe les modules nécessaires depuis Agno (`Agent`, `OpenAIChat`, `DuckDuckGoTools`).
- **Agent** : L'agent est créé avec :
  - Un nom (`Agno AGI`).
  - Un modèle (`gpt-4.1` d'OpenAI).
  - Une description qui définit son rôle.
  - Des instructions précises ("Search the web for information about Agno").
  - Un outil (`DuckDuckGoTools`) pour effectuer des recherches web.
- **Options** :
  - `add_datetime_to_instructions=True` : Ajoute un horodatage aux instructions, utile pour contextualiser les recherches.
  - `markdown=True` : Les réponses sont formatées en Markdown.
  - `stream=True` : Les réponses sont diffusées en temps réel.

#### Utilité

- **Simplicité** : Ce niveau est idéal pour les débutants ou pour des tâches simples comme la recherche d'informations.
- **Flexibilité** : L'utilisation d'outils comme `DuckDuckGoTools` permet à l'agent d'accéder à des données externes, augmentant ses capacités au-delà des connaissances intégrées au modèle.
- **Cas d'usage** : Utile pour des chatbots ou assistants de base qui doivent répondre à des questions simples ou effectuer des recherches.

#### Ce qui pourrait nous être utile

- **Prototypage rapide** : Ce niveau permet de tester rapidement des idées d'agents sans complexité excessive.
- **Éducation** : Les instructions détaillées (`description` et `instructions`) peuvent être utilisées pour enseigner à l'agent des comportements spécifiques, ce qui est utile pour des projets éducatifs ou des Proof of Concepts (PoC).

---

### Niveau 2 : Agent avec Connaissance et Stockage

#### Description

Le niveau 2 introduit la **connaissance** et le **stockage**. Les agents ont besoin d'accéder à des informations externes (souvent via une recherche de type **RAG - Retrieval-Augmented Generation**) et de sauvegarder leur état pour devenir **stateful** (avec un historique des interactions).

#### Code Exemple

```python
# IMPORTS

# You can also use https://t.co/TL5_full.txt for the full documentation

# See https://agno-agi.com/introduction.md

vector_db_knowledge = [
    {"type": "sqlite", "data": "agno_docs"},
    {"type": "hybrid", "search_type": "hybrid", "embedding": "text-embedding-3-small"},
    {"type": "openaiEmbedding", "id": "text-embedding-3-small"},
    {"type": "cohereReranker", "model": "rerank-multilingual-v3.0"},
]

STORAGE = "SqliteStorage(table_name='agent_sessions', db_file='/tmp/agent.db')"

agno_assist = Agent(
    name="Agno AGI",
    model=OpenAIChat(id="gpt-4.1"),
    description=(
        "You are 'Agno AGI', an autonomous AI Agent that can build agents using the Agno "
        "framework. Your goal is to help developers understand and use Agno by providing "
        "explanations, working code examples, and optional visual and audio explanations "
        "of key concepts."
    ),
    instructions="Search the web for information about Agno.",
    tools=[DuckDuckGoTools()],
    knowledge=vector_db_knowledge,
    storage=STORAGE,
    add_datetime_to_instructions=True,
    markdown=True,
)

# Note: comment this out after first run

# agno_assist.load_knowledge(latest=True)

agno_assist.print_response("WHAT IS Agno?", stream=True)
```plaintext
#### Analyse Technique

- **Connaissance (`knowledge`)** :
  - Une base de données vectorielle (`vector_db_knowledge`) est définie pour stocker des données accessibles à l'agent.
  - Recherche hybride (`hybrid`) : Combine recherche sémantique (via embeddings comme `text-embedding-3-small`) et recherche par mots-clés, avec un reclassement (`cohereReranker`) pour améliorer la pertinence des résultats.
- **Stockage (`storage`)** :
  - Utilise `SqliteStorage` pour sauvegarder les sessions de l'agent dans une base SQLite.
  - Cela permet de maintenir un historique des interactions, rendant l'agent **stateful** (par exemple, comme les sessions de ChatGPT qui persistent après fermeture de l'onglet).
- **Commentaire** : La ligne `load_knowledge(latest=True)` est désactivée après le premier chargement pour éviter des rechargements inutiles.

#### Utilité

- **Recherche Améliorée** : La recherche hybride permet à l'agent de trouver des informations plus pertinentes, ce qui est crucial pour des tâches nécessitant des données externes complexes.
- **Persistance** : Le stockage des sessions permet de reprendre une conversation là où elle s'est arrêtée, idéal pour des applications comme les chatbots ou les assistants personnels.
- **Cas d'usage** : Parfait pour des agents qui doivent gérer des interactions longues ou complexes, comme un assistant de support technique.

#### Ce qui pourrait nous être utile

- **Gestion de Données Externes** : Si nous avons des bases de données ou des documents internes (par exemple, des manuels ou des FAQ), intégrer une recherche hybride peut améliorer la capacité de l'agent à répondre à des questions spécifiques.
- **Continuité** : Le stockage des sessions est essentiel pour des projets où les utilisateurs attendent une continuité dans les interactions, comme dans une application de service client.

---

### Niveau 3 : Agent avec Mémoire et Raisonnement

#### Description

Le niveau 3 ajoute la **mémoire** (pour personnaliser les interactions) et le **raisonnement** (pour améliorer la réussite des tâches complexes). La mémoire permet à l'agent de se souvenir des détails sur l'utilisateur, tandis que le raisonnement augmente la fiabilité des étapes multiples.

#### Code Exemple

```python
# imports

knowledge_base = ...

memory = Memory(
    model=OpenAIChat(id="gpt-4.1"),
    db=SqliteMemoryDB(table_name="user_memories", db_file="/tmp/agent.db"),
    delete_memories=True,
    clear_memories=True,
)

storage = ...

agno_assist = Agent(
    name="Agno AGI",
    model=Claude(id="claude-3-5-sonnet-latest"),
    user_id="user_id",
    description="...",
    instructions="...",
    tools=[PythonTools(), DuckDuckGoTools(), ReasoningTools(add_instructions=True)],
    knowledge=knowledge_base,
    storage=storage,
    memory=memory,
    add_agentic_memory=True,
    markdown=True,
)

# You can comment this out after the first run and the agent will remember

agno_assist.print_response("Always start your messages with 'Hi ava'", stream=True)
```plaintext
#### Analyse Technique

- **Mémoire (`memory`)** :
  - Utilise `SqliteMemoryDB` pour stocker des informations sur l'utilisateur.
  - `delete_memories=True` et `clear_memories=True` permettent de réinitialiser la mémoire si nécessaire.
  - `add_agentic_memory=True` : Active la mémoire agentique, qui permet à l'agent de se souvenir de ses propres actions et décisions.
- **Raisonnement (`ReasoningTools`)** :
  - Ajoute des outils de raisonnement pour améliorer la compréhension et la résolution de tâches complexes.
  - Utile pour augmenter le taux de succès des étapes multiples (par exemple, de 60 % à un pourcentage plus élevé).
- **Personnalisation** : L'agent peut se souvenir des préférences de l'utilisateur (comme commencer les messages par "Hi ava").

#### Utilité

- **Personnalisation** : La mémoire permet des interactions plus engageantes et adaptées, par exemple dans des applications de commerce électronique ou d'éducation.
- **Fiabilité** : Le raisonnement est crucial pour des tâches complexes nécessitant plusieurs étapes, comme la planification ou la résolution de problèmes.
- **Cas d'usage** : Utile pour des agents de support client avancés, des assistants éducatifs, ou des outils de planification.

#### Ce qui pourrait nous être utile

- **Engagement Utilisateur** : La mémoire peut être utilisée pour créer des agents qui se souviennent des préférences ou des historiques des utilisateurs, améliorant l'expérience utilisateur.
- **Tâches Complexes** : Si nous devons automatiser des processus nécessitant plusieurs étapes (par exemple, planifier un voyage ou résoudre un problème technique), le raisonnement est indispensable.

---

### Niveau 4 : Équipes Multi-Agents

#### Description

Le niveau 4 introduit les **équipes multi-agents**, où plusieurs agents spécialisés collaborent pour résoudre des problèmes complexes. Chaque agent a un domaine spécifique et un ensemble limité d'outils (moins de 10). Ashpreet note que les équipes multi-agents autonomes fonctionnent mal en 2025 (moins de 50 % de succès).

#### Code Exemple

```python
# imports

user_team = Agent(
    role="User Team Agent",
    tools=[DuckDuckGoTools()],
)

finance_team = Agent(
    role="Finance Agent",
    tools=["financial data requests"],
    instructions="Provide concise and accurate financial data.",
)

# Team Leader Agent

team_leader = Agent(
    role="Team Leader",
    mode="coordinate",
    members=[user_team, finance_team],
    instructions="Use the financial data from Finance Agent to display stock fundamentals (EV, Market Cap).",
)

team_leader.print_response(
    "Analyze the impact of recent US tariffs on market performance across these key sectors: Tech, Automotive, Consumer Staples, Energy, Industrials, Financials, Healthcare, Materials, Utilities, Real Estate.",
    stream=True
)
```plaintext
#### Analyse Technique

- **Agents Spécialisés** :
  - `user_team` : Gère les interactions utilisateur.
  - `finance_team` : Fournit des données financières.
- **Leader (`team_leader`)** :
  - Mode `coordinate` : Coordonne les actions des membres de l'équipe.
  - Utilise les données du `finance_team` pour répondre à une requête complexe sur l'impact des tarifs.
- **Limitation** : Les équipes multi-agents nécessitent un raisonnement pour gérer des tâches complexes, sinon le leader échoue souvent.

#### Utilité

- **Spécialisation** : Permet de diviser les tâches complexes en sous-tâches gérées par des agents spécialisés.
- **Évolutivité** : Les équipes multi-agents peuvent gérer des problèmes plus larges que les agents uniques.
- **Cas d'usage** : Utile pour des projets comme l'analyse de données complexes, la gestion de projets, ou l'automatisation de workflows.

#### Ce qui pourrait nous être utile

- **Collaboration** : Si nous avons des projets nécessitant plusieurs domaines (par exemple, marketing et finance), une équipe multi-agents peut être une solution.
- **Recherche et Développement** : Bien que les équipes autonomes soient encore expérimentales, elles pourraient être testées pour des projets innovants.

---

### Niveau 5 : Systèmes Agentiques

#### Description

Le niveau 5 concerne les **systèmes agentiques**, des API asynchrones qui traitent les requêtes, sauvegardent l'état, et diffusent les résultats en temps réel. Ce niveau est complexe et représente l'avenir des applications IA rentables.

#### Code Exemple

(Non fourni dans le post, mais décrit comme un système FastAPI avec des tâches asynchrones et des WebSockets.)

#### Analyse Technique

- **Asynchrone** : Les requêtes sont traitées en arrière-plan, avec un état sauvegardé dans une base de données.
- **Diffusion** : Les résultats sont streamés via WebSockets ou des mécanismes similaires.
- **Complexité** : Nécessite une infrastructure robuste (serveurs, bases de données, gestion des erreurs).

#### Utilité

- **Applications Commerciales** : Ce niveau est idéal pour des produits IA à grande échelle, comme des assistants virtuels ou des outils d'analyse en temps réel.
- **Fiabilité** : La gestion asynchrone garantit une exécution fiable même pour des tâches longues.
- **Cas d'usage** : Parfait pour des API d'entreprise, des applications SaaS, ou des systèmes de traitement de données.

#### Ce qui pourrait nous être utile

- **Produits Commerciaux** : Si nous développons une application IA à grande échelle, un système agentique est une étape logique.
- **Performance** : La gestion asynchrone peut améliorer la performance pour des tâches lourdes, comme le traitement de données en temps réel.

---

## Réactions et Commentaires

### Réactions Positives

- **Dinesh Kumar Poobalan** (@dineshkumarmp) : Confirme que l'équipe de Greatify utilise Agno avec succès, louant sa modularité et sa propreté.
- **Elliot Chris** (@ElliotGracewell) : Apprécie la classification et mentionne que Jenova AI suit une approche similaire avec des agents personnalisés et un raisonnement multi-étapes.

### Questions et Suggestions

- **Prem Viswanathan** (@prempv) : Propose une classification à deux axes (complexité système vs complexité IA), car le niveau 5 peut s'appliquer à des agents simples.
- **Matt Mazur** (@mhmazur) : Demande des précisions sur l'avantage des équipes multi-agents par rapport à un agent unique avec 50 outils.
- **Amit Wani** (@mtwn105) : Pose des questions sur l'exécution séquentielle des équipes multi-agents et note des problèmes avec les modèles Gemini.

#### Analyse des Commentaires

- Les retours sont globalement positifs, mais ils soulignent des défis pratiques, comme la fiabilité des équipes multi-agents et la nécessité d'améliorer les modèles sous-jacents (par exemple, Gemini).
- La suggestion de Prem sur une classification à deux axes est pertinente et pourrait aider à clarifier les distinctions entre complexité technique et complexité IA.

---

## Ce Qui Pourrait Nous Être Utile

### Applications Pratiques

1. **Prototypage Rapide (Niveau 1)** : Utiliser Agno pour tester des agents simples dans des projets pilotes.
2. **Amélioration des Interactions (Niveau 2)** : Intégrer la recherche hybride et le stockage pour des chatbots ou des assistants avec continuité.
3. **Personnalisation et Fiabilité (Niveau 3)** : Ajouter la mémoire et le raisonnement pour des applications nécessitant des interactions personnalisées ou des tâches complexes.
4. **Collaboration (Niveau 4)** : Expérimenter avec des équipes multi-agents pour des projets nécessitant plusieurs domaines.
5. **Produits Commerciaux (Niveau 5)** : Développer des API asynchrones pour des applications IA à grande échelle.

### Opportunités de Développement

- **Recherche Hybride** : Implémenter des systèmes de recherche hybride pour améliorer la pertinence des réponses dans nos projets.
- **Mémoire et Raisonnement** : Explorer comment la mémoire peut améliorer l'engagement utilisateur et comment le raisonnement peut augmenter la fiabilité des tâches complexes.
- **Infrastructure Asynchrone** : Investir dans des infrastructures pour supporter des systèmes agentiques, comme FastAPI et WebSockets.

---

## Conclusion

Le post de Ashpreet Bedi offre une classification claire et progressive des agents IA, allant de simples agents avec outils à des systèmes agentiques complexes. Chaque niveau apporte des fonctionnalités supplémentaires qui peuvent être adaptées à différents besoins, du prototypage rapide à la création de produits commerciaux. Pour nos projets, les niveaux 2 et 3 (connaissance, stockage, mémoire, raisonnement) semblent particulièrement pertinents pour améliorer les interactions et la fiabilité, tandis que le niveau 5 pourrait être un objectif à long terme pour des applications à grande échelle.

---

## Références

- Post original : [https://x.com/ashpreetbedi/status/1924193924995744158](https://x.com/ashpreetbedi/status/1924193924995744158)
- Documentation Agno : [https://t.co/WUTRv7IuFr](https://t.co/WUTRv7IuFr)
- GitHub Agno : [https://t.co/SxiAqHQGsx](https://t.co/SxiAqHQGsx)
