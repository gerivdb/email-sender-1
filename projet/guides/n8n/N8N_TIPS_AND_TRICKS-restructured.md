# GUIDE COMPLET : DÉFINITIONS JSON DES NŒUDS N8N, TOUS LES OUTILS, NUANCES D'INTÉGRATION ET MANIPULATION D'AGENT IA

## Table des matières

1. [GUIDE COMPLET : DÉFINITIONS JSON DES NŒUDS N8N, TOUS LES OUTILS, NUANCES D'INTÉGRATION ET MANIPULATION D'AGENT IA](#section-1)

        1.0.1. [Vue d'ensemble :](#section-2)

        1.0.2. [Champs principaux de haut niveau :](#section-3)

        1.0.3. [Meilleures pratiques :](#section-4)

        1.0.4. [Objectif :](#section-5)

        1.0.5. [Paramètres clés :](#section-6)

        1.0.6. [Nuances :](#section-7)

        1.0.7. [Objectif :](#section-8)

        1.0.8. [Paramètres clés :](#section-9)

        1.0.9. [Conseils d'utilisation :](#section-10)

        1.0.10. [Objectif :](#section-11)

        1.0.11. [Paramètres clés :](#section-12)

        1.0.12. [Intégration & Mémoire :](#section-13)

        1.0.13. [Nuances :](#section-14)

        1.0.14. [Exemples de snippets :](#section-15)

        1.0.15. [Objectif :](#section-16)

        1.0.16. [Paramètres clés :](#section-17)

        1.0.17. [Conseils d'utilisation :](#section-18)

    1.1. [. OUTILS D'INTÉGRATION & LEURS OPÉRATIONS](#section-19)

        1.1.1. [. PINECONE](#section-20)

        1.1.2. [. AIRTABLE](#section-21)

        1.1.3. [. POSTGRESQL](#section-22)

        1.1.4. [. GOOGLE DOCS](#section-23)

        1.1.5. [. GOOGLE CALENDAR](#section-24)

        1.1.6. [. TELEGRAM](#section-25)

        1.1.7. [. REQUÊTE HTTP](#section-26)

        1.1.8. [. OUTIL SERPAPI](#section-27)

        1.1.9. [. OUTIL WORKFLOW](#section-28)

        1.1.10. [. OUTIL GMAIL](#section-29)

        1.1.11. [. SUPABASE](#section-30)

        1.1.12. [. NŒUDS GÉNÉRIQUES & AUXILIAIRES](#section-31)

    1.2. [. NOTES SUPPLÉMENTAIRES SUR LA MANIPULATION D'AGENT IA & DE MÉMOIRE](#section-32)

    1.3. [. PROBLÈMES COURANTS DE VALEUR DE PROPRIÉTÉ AVEC LE JSON GÉNÉRÉ PAR LLM](#section-33)

    1.4. [. CONCLUSIONS FINALES](#section-34)

## 1. GUIDE COMPLET : DÉFINITIONS JSON DES NŒUDS N8N, TOUS LES OUTILS, NUANCES D'INTÉGRATION ET MANIPULATION D'AGENT IA <a name='section-1'></a>

Ce document combine une vue d'ensemble des structures JSON des nœuds n8n avec des sections détaillées sur tous les outils rencontrés — des déclencheurs de chat et notes autocollantes aux intégrations avec Pinecone, Airtable, PostgreSQL, Google Docs, Google Calendar, Telegram, API HTTP, SerpAPI, outils de Workflow, et plus encore. Il couvre également les meilleures pratiques pour manipuler le module Agent IA et aborde les problèmes courants de valeur de propriété lors de la génération de JSON via les LLM.

#### 1.0.1. Vue d'ensemble : <a name='section-2'></a>

- Chaque nœud est défini comme un objet JSON avec un ensemble commun de clés.
- Ces clés s'appliquent à tous les types de nœuds, qu'ils gèrent des déclencheurs, le traitement de données, la documentation ou des intégrations externes.

#### 1.0.2. Champs principaux de haut niveau : <a name='section-3'></a>

- **id :** Identifiant unique (généralement un UUID). Doit être unique au sein d'un workflow.
- **name :** Étiquette lisible par l'humain (ex : "When Chat Message Received", "Airtable - Update Records").
- **type :** Définit la fonctionnalité du nœud ; exemples :
  - `"@n8n/n8n-nodes-langchain.chatTrigger"` pour les déclencheurs de chat.
  - `"n8n-nodes-base.stickyNote"` pour les annotations.
  - D'autres outils utilisent des identifiants de type spécifiques.
- **typeVersion :** Version du schéma (communément 1, 1.1, 1.7, etc.). Les versions supérieures peuvent prendre en charge des fonctionnalités supplémentaires.
- **position :** Un tableau `[x, y]` déterminant le placement du nœud sur le canevas visuel.
- **parameters :** Un objet imbriqué contenant des configurations spécifiques au nœud (actions, identifiants, texte d'interface utilisateur, etc.).

#### 1.0.3. Meilleures pratiques : <a name='section-4'></a>

- Utilisez des noms descriptifs et des positions logiques pour maintenir un workflow organisé.
- Exploitez le langage d'expression de n8n (ex : `={{ $json["field"] }}`) pour le contenu dynamique.
- Validez votre JSON (ex : avec un linter) pour détecter les problèmes de valeur de propriété comme les guillemets inappropriés, les virgules traînantes ou les incompatibilités de type.

#### 1.0.4. Objectif : <a name='section-5'></a>

- Écouter les messages de chat entrants via des webhooks ou des widgets de chat intégrés.
- Agir comme point d'entrée pour les workflows basés sur la conversation.

#### 1.0.5. Paramètres clés : <a name='section-6'></a>

- **webhookId :** Identifiant unique liant le nœud à son point de terminaison webhook.
- **mode :** Généralement `"webhook"` pour indiquer le mode de réception d'événements.
- **public (boolean) :** Détermine si le point de terminaison du chat est ouvert à l'accès public. Utilisez avec des `allowedOrigins` sécurisés.
- **initialMessages :** Texte de salutation ou d'instruction prédéfini (prend en charge Markdown et les expressions dynamiques).
- **options :** Paramètres avancés incluant :
  - **responseMode :** Comment les réponses sont envoyées (ex : `"responseNode"`).
  - **allowedOrigins :** Domaines autorisés à accéder au point de terminaison du chat.
  - **title/subtitle :** Texte d'interface utilisateur personnalisé.
  - **allowFileUploads :** Activer/désactiver les téléchargements de fichiers.
  - **loadPreviousSession :** Gère la persistance de session (ex : `"memory"`).

#### 1.0.6. Nuances : <a name='section-7'></a>

- Assurez-vous que le webhookId de chaque Chat Trigger est unique.
- Les expressions dynamiques dans initialMessages permettent une personnalisation à l'exécution.
- Différentes typeVersions (1 vs. 1.1) peuvent offrir des paramètres variables.

#### 1.0.7. Objectif : <a name='section-8'></a>

- Fournir de la documentation, des annotations ou des rappels dans le workflow.
- N'affectent pas le flux de données ; purement à usage informatif.

#### 1.0.8. Paramètres clés : <a name='section-9'></a>

- **content :** Le texte affiché (prend en charge Markdown pour les en-têtes, listes, blocs de code, liens, images).
- **width & height :** Définissent les dimensions visuelles sur le canevas.
- **color (optionnel) :** Code numérique pour attribuer une couleur de fond pour la différenciation visuelle.

#### 1.0.9. Conseils d'utilisation : <a name='section-10'></a>

- Placez les notes autocollantes près des nœuds associés pour ajouter du contexte.
- Utilisez un formatage Markdown clair et concis.
- Mettez à jour les notes régulièrement à mesure que les workflows évoluent.

#### 1.0.10. Objectif : <a name='section-11'></a>

- Traiter les entrées utilisateur et générer des réponses interactives contextuelles.
- Invoquer dynamiquement d'autres outils en fonction du contexte de conversation et de la mémoire.

#### 1.0.11. Paramètres clés : <a name='section-12'></a>

- **text :** Entrée principale, généralement définie dynamiquement (ex : `={{ $json.chatInput }}`).
- **options :** Contient un `systemMessage` détaillé qui :
  - Définit le rôle et le comportement de l'agent IA.
  - Fournit des directives pour la gestion de la mémoire et l'invocation d'outils.
  - Peut inclure des instructions supplémentaires pour le formatage des réponses.
- **promptType :** Généralement `"define"`, appliquant les règles du message système.

#### 1.0.12. Intégration & Mémoire : <a name='section-13'></a>

- Se connecte avec des sous-fonctions via des ports comme `ai_tool`, `ai_memory`, et `ai_languageModel`.
- Souvent associé à des nœuds de mémoire (ex : `memoryBufferWindow`) pour fournir l'historique de conversation.

#### 1.0.13. Nuances : <a name='section-14'></a>

- Élaborez soigneusement le systemMessage pour gérer divers scénarios.
- Validez la sortie JSON pour les problèmes de valeur de propriété (voir Section 6).
- Expérimentez avec différents modèles (ex : "gpt-4o" vs. "gpt-4o-mini") pour l'équilibre performance/coût.

#### 1.0.14. Exemples de snippets : <a name='section-15'></a>

*Configuration minimale d'Agent IA :*
```json
{
  "id": "agent-1",
  "name": "AI Agent for Chat",
  "type": "@n8n/n8n-nodes-langchain.agent",
  "position": [100, 100],
  "parameters": {
      "text": "={{ $json.chatInput }}",
      "options": { "systemMessage": "=You are a helpful assistant." },
      "promptType": "define"
  },
  "typeVersion": 1.7
}
```plaintext
*Agent IA avec intégration de Calendrier :*
  "id": "agent-2",
  "name": "Calendar AI Agent",
  "position": [200, 200],
      "options": { "systemMessage": "=You are a Google Calendar assistant. Ask for event details before creating an event." },

*Agent IA avec intégration de Mémoire :*
  "id": "agent-3",
  "name": "AI Agent with Memory",
  "position": [300, 300],
      "options": { "systemMessage": "=Use long-term memory to provide context-aware responses." },

#### 1.0.15. Objectif : <a name='section-16'></a>

- Gérer l'historique temporaire de conversation pour l'agent IA.

#### 1.0.16. Paramètres clés : <a name='section-17'></a>

- **sessionKey :** Identifiant pour la session de mémoire (peut être dynamique).
- **contextWindowLength :** Nombre de messages à conserver dans la fenêtre de contexte.

#### 1.0.17. Conseils d'utilisation : <a name='section-18'></a>

- Ajustez contextWindowLength en fonction de la complexité de la conversation.
- Utilisez des clés de session cohérentes pour maintenir la continuité de la mémoire.

### 1.1. . OUTILS D'INTÉGRATION & LEURS OPÉRATIONS <a name='section-19'></a>

Cette section détaille chaque outil externe rencontré et ses nuances spécifiques.

#### 1.1.1. . PINECONE <a name='section-20'></a>

**Objectif :**
- Interface avec la base de données vectorielle de Pinecone pour l'indexation, l'insertion et l'interrogation de vecteurs.

**Opérations clés :**
- Création/Mise à jour d'index – Définir les noms d'index, dimensions et métriques.
- Insertion de vecteurs – Mapper les champs JSON aux données vectorielles ; le schéma doit correspondre à l'index.
- Interrogation de vecteurs – Récupérer des vecteurs similaires basés sur des paramètres de requête.

**Nuances :**
- Assurez-vous que les identifiants API et les mappages de champs sont précis.
- Utilisez des noms de nœuds descriptifs (ex : "Pinecone - Upsert Vectors").

#### 1.1.2. . AIRTABLE <a name='section-21'></a>

**Objectif :**
- Gérer les enregistrements dans les bases Airtable.

**Opérations clés :**
- Lecture, Création, Mise à jour et Suppression d'enregistrements.
- Mappage de champs : les clés JSON doivent correspondre exactement aux noms de colonnes Airtable.

**Nuances :**
- Sécurisez les clés API via les identifiants.
- Utilisez des expressions dynamiques pour gérer les données d'enregistrement.

#### 1.1.3. . POSTGRESQL <a name='section-22'></a>

**Objectif :**
- Exécuter des requêtes SQL pour manipuler des données.

**Opérations clés :**
- Requêtes SELECT, INSERT, UPDATE, DELETE.
- Utilisez des requêtes paramétrées pour éviter l'injection SQL.

**Nuances :**
- Assurez-vous que la syntaxe SQL est valide et que les valeurs dynamiques sont correctement insérées.
- Utilisez des nœuds comme postgresTool pour les tâches de manipulation JSON.

#### 1.1.4. . GOOGLE DOCS <a name='section-23'></a>

**Objectif :**
- Récupérer ou mettre à jour des Google Docs pour stocker la mémoire à long terme ou des notes.

**Opérations clés :**
- "get" pour la récupération et "update" pour l'insertion de contenu.
- Utilisez actionsUi (dans googleDocsTool) pour définir les charges utiles JSON pour les opérations.

**Nuances :**
- Liez les identifiants OAuth corrects.
- Mappez correctement les champs dynamiques (ex : dates, contenu de mémoire).

#### 1.1.5. . GOOGLE CALENDAR <a name='section-24'></a>

**Objectif :**
- Récupérer ou créer des événements dans Google Calendar.

**Opérations clés :**
- Get Events : Utilisez des filtres de plage de dates avec des expressions dynamiques.
- Create Events : Spécifiez début, fin, résumé, description et champs supplémentaires (participants, données de conférence).

**Nuances :**
- Validez les formats de date (YYYY-MM-DD HH:mm:ss).
- Assurez-vous que les mappages de champs de calendrier correspondent à l'API Google Calendar.

#### 1.1.6. . TELEGRAM <a name='section-25'></a>

**Objectif :**
- Gérer la messagerie via Telegram.

**Types de nœuds clés :**
- telegramTrigger : Pour recevoir des messages.
- telegram : Pour envoyer des réponses textuelles.
- telegramTool : Pour envoyer des fichiers/documents.

**Paramètres clés :**
- webhookId (pour les déclencheurs), chatId, text, file (URL), et additionalFields (ex : parse_mode).

**Nuances :**
- Utilisez des expressions dynamiques pour récupérer les IDs de chat.
- Testez avec des identifiants sandbox lorsque c'est possible.

#### 1.1.7. . REQUÊTE HTTP <a name='section-26'></a>

**Objectif :**
- Effectuer des appels API HTTP génériques (ex : pour la génération d'image DALL-E).

**Paramètres clés :**
- url, method, sendBody, sendHeaders.
- authentication : Identifiants prédéfinis ou génériques.

**Nuances :**
- Assurez-vous que les corps JSON sont valides.
- Utilisez ce nœud pour appeler des API externes comme DALL-E en définissant le modèle dans la charge utile.

#### 1.1.8. . OUTIL SERPAPI <a name='section-27'></a>

**Objectif :**
- Interroger les données de moteur de recherche via SerpAPI.

**Paramètres clés :**
- options : Paramètres de requête supplémentaires.

**Nuances :**
- Liez les identifiants SerpAPI appropriés.
- Formulez des requêtes de recherche dynamiques basées sur l'entrée utilisateur.

#### 1.1.9. . OUTIL WORKFLOW <a name='section-28'></a>

**Objectif :**
- Déclencher ou exécuter des workflows séparés (ex : création de tâche).

**Paramètres clés :**
- name, workflowId, schemaType, et inputSchema.

**Nuances :**
- Validez que le schéma JSON d'entrée correspond au workflow cible.
- Utilisez pour automatiser des sous-workflows.

#### 1.1.10. . OUTIL GMAIL <a name='section-29'></a>

**Objectif :**
- Envoyer des emails via Gmail.

**Paramètres clés :**
- sendTo, subject, message, additionalFields.

**Nuances :**
- Personnalisez les emails avec des expressions dynamiques.
- Assurez-vous que les identifiants OAuth sont correctement définis.

#### 1.1.11. . SUPABASE <a name='section-30'></a>

**Objectif :**
- Interagir avec les bases de données Supabase.

**Paramètres clés :**
- tableId, fieldsUi (mappage des données JSON aux champs de table).

**Nuances :**
- Assurez-vous que le schéma de données s'aligne avec votre table Supabase.
- Sécurisez les clés API via les identifiants.

#### 1.1.12. . NŒUDS GÉNÉRIQUES & AUXILIAIRES <a name='section-31'></a>

**Objectif :**
- Gérer des opérations générales telles que les assignations de valeurs, la fusion de données, la division des sorties, les conditionnels et le déclenchement de sous-workflows.

**Exemples clés :**
- Nœuds Set : Pour assigner des valeurs (ex : prompts système).
- Merge, Aggregate, Split Out : Pour l'orchestration de données.
- Nœuds If : Pour la logique conditionnelle.
- Execute Workflow Trigger & Respond To Webhook : Pour le contrôle de flux.

**Nuances :**
- Gardez les configurations propres et validez les expressions dynamiques.

### 1.2. . NOTES SUPPLÉMENTAIRES SUR LA MANIPULATION D'AGENT IA & DE MÉMOIRE <a name='section-32'></a>

- Le module Agent IA orchestre des réponses intelligentes et des appels d'outils.
- Les fonctionnalités clés incluent :
  - Traitement de l'entrée utilisateur via le paramètre "text".
  - Guidage du comportement avec un "options.systemMessage" détaillé (qui peut inclure la mémoire, les règles d'appel d'outils et les réponses de secours).
  - Connexion aux nœuds de mémoire (ex : memoryBufferWindow) pour la rétention de contexte.
- Meilleures pratiques :
  - Élaborez des messages système complets qui couvrent les cas limites.
  - Utilisez des expressions dynamiques pour s'adapter aux entrées variables.
  - Testez le flux conversationnel complet pour garantir que les valeurs dynamiques (ex : détails d'événement) passent correctement entre les nœuds.
  - Validez les sorties JSON pour éviter les problèmes courants de valeur de propriété (voir Section 6).

### 1.3. . PROBLÈMES COURANTS DE VALEUR DE PROPRIÉTÉ AVEC LE JSON GÉNÉRÉ PAR LLM <a name='section-33'></a>

- **Guillemets :**  
  - Utilisez des guillemets doubles pour les noms de propriété et les valeurs de chaîne.
- **Virgules traînantes :**  
  - Évitez les virgules traînantes après le dernier élément dans les objets ou tableaux.
- **Incompatibilités de type de données :**  
  - N'enveloppez pas les valeurs numériques ou booléennes dans des guillemets.
- **Sensibilité à la casse :**  
  - Assurez-vous que les noms de propriété correspondent à la casse attendue.
- **Crochets/Accolades :**  
  - Confirmez que toutes les structures JSON sont correctement ouvertes et fermées.
- **Validation :**  
  - Exécutez votre JSON à travers des validateurs pour détecter les erreurs de syntaxe.
- **Prompting LLM :**  
  - Lorsque vous instruisez les LLM pour générer du JSON, spécifiez "output valid JSON" et avertissez de ces pièges courants.

### 1.4. . CONCLUSIONS FINALES <a name='section-34'></a>

- **Nœuds déclencheurs de chat :**  
  - Agissent comme points d'entrée pour les workflows basés sur la conversation avec des paramètres nuancés pour l'accès public et les salutations dynamiques.
- **Nœuds Sticky Note :**  
  - Servent de documentation dans le workflow et sont essentiels pour la clarté dans les workflows complexes.
- **Module Agent IA :**  
  - Intègre l'entrée utilisateur, la mémoire dynamique et les appels d'outils pour générer des réponses contextuelles.
- **Outils d'intégration :**  
  - Chaque outil externe (Pinecone, Airtable, PostgreSQL, Google Docs/Calendar, Telegram, Requête HTTP, SerpAPI, Outil Workflow, Gmail, Supabase) a des besoins de configuration spécifiques et nécessite des mappages de champs précis.
- **JSON généré par LLM :**  
  - Abordez les problèmes courants de valeur de propriété par un formatage et une validation soigneux.
- **Globalement :**  
  - Combiner des structures de nœuds bien documentées avec des configurations d'intégration rigoureuses conduit à des workflows robustes et maintenables.

