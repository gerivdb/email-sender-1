Développement détaillé du **PILIER 2 : Le Moteur de Processus N8N**, en adoptant une perspective résolument technique destinée aux ingénieurs, tout en assurant la cohérence avec les autres piliers.

---

**PILIER 2 : Le Moteur de Processus \- Modulaire, Robuste, Intelligent et Orienté Utilisateur (Workflows N8N)**

Ce pilier est le système nerveux central de l'automatisation. Il orchestre les flux de données et les actions entre Notion (Pilier 1), les services externes (Google Workspace, API IA...), et le CMS (Pilier 4), en s'appuyant sur l'intelligence des équipes IA (Pilier 3). L'architecture doit être modulaire (micro-services via Execute Workflow), robuste (gestion d'erreurs, idempotence), et maintenable.

**3\. Architecture N8N Modulaire (Micro-services Fonctionnels Étendus) :**

* **Objectif Technique :** Décomposer la logique métier complexe en workflows plus petits, spécialisés et réutilisables (Execute Workflow). Chaque workflow a une responsabilité unique, des inputs/outputs définis, et une gestion d'erreurs encapsulée.  
* **3.1. Workflows Utilitaires Fondamentaux (Étendus) :**  
  * Ces workflows sont les briques de base, appelées par de nombreux autres workflows. Ils doivent être particulièrement robustes et optimisés.  
  * **WF-Core-Config**  
    * *Rôle Technique :* Service de configuration dynamique par artiste. Point d'entrée unique pour récupérer tous les IDs et paramètres spécifiques à un artiste.  
    * *Trigger :* Execute Workflow.  
    * *Input :* { "artistName": "Nom Artiste" } ou { "artistId": "UUID" }.  
    * *Logique Principale :*  
      * **Notion API Call (Get Database Pages) :** Interroger Agence\_Artistes.  
        * Filtre : Nom Artiste equals input.artistName OU artistId (propriété dédiée) equals input.artistId.  
        * Limite : 2 (pour détecter les doublons).  
      *   
      * **Validation (Code Node / IF Node) :**  
        * Vérifier si items.length \=== 1\.  
        * Si 0 ou \>1 :  
          * Appeler WF-Monitoring : { "severity": "Critical", "message": "Config Artiste introuvable/ambiguë pour: " \+ (input.artistName || input.artistId), ... }.  
          * **Stopper le workflow (Stop and Error Node ou retourner { "error": true, "message": "..." })**.  
        *   
      *   
      * **Parsing Config (Code Node) :**  
        * const configJson \= JSON.parse(items\[0\].json.properties\['N8N Config'\].rich\_text\[0\].plain\_text); (dans un try...catch).  
        * Si parsing échoue, appeler WF-Monitoring (Critical) et stopper.  
      *   
      * **Enrichissement (Optionnel mais recommandé) :**  
        * Extraire les IDs de relation Manager Référent et Booker Principal.  
        * **Notion API Call (Get Database Pages) :** Interroger Agence\_Équipe (ou Agence\_HR\_Personnel) pour récupérer les Person ID Notion ou emails associés à ces relations. Nécessite potentiellement 2 appels Get Page.  
      *   
      * **Formatage Output (Set Node ou Code Node) :**  
        * Retourner un objet JSON unique contenant la configuration parsée et les informations enrichies.  
      *   
    *   
    * *Output :* { "config": { ...parsed JSON... }, "manager": { "notionUserId": "...", "email": "..." }, "booker": { ... }, "error": false } OU { "error": true, "message": "..." }.  
    * *Dépendances :* Agence\_Artistes, Agence\_Équipe, WF-Monitoring.  
  *   
  * **WF-Monitoring**  
    * *Rôle Technique :* Service centralisé de logging des événements et erreurs N8N vers Notion.  
    * *Trigger :* Execute Workflow.  
    * *Input :* { "workflowId": string, "executionId": string, "nodeName": string, "severity": "Info" | "Warning" | "Error" | "Critical", "message": string, "contextData"?: object }. Les IDs peuvent être récupérés via $workflow.id, $execution.id.  
    * *Logique Principale :*  
      * **Préparation Données (Code Node) :**  
        * Stringifier contextData : JSON.stringify(input.contextData || {}, null, 2). Gérer la taille max (tronquer si nécessaire) et potentiellement masquer/anonymiser des données sensibles.  
      *   
      * **Notion API Call (Create Database Page) :** Créer une page dans Agence\_Monitoring\_N8N.  
        * Mapper les inputs aux propriétés Notion correspondantes.  
      *   
      * **Alerte Critique (IF Node) :** Si input.severity \=== "Critical".  
        * **Appel WF-Notification-Dispatcher :** Envoyer une alerte immédiate au groupe admin/dev défini (via un userId spécifique ou un groupe). Input : { "userId": "ID\_Admin\_RH", "message": "CRITICAL ERROR in WF " \+ input.workflowId \+ ": " \+ input.message, "channelPreference": "Signal", "severity": "Urgent" }.  
      *   
      * **Création Tâche (Optionnel \- IF Node) :** Si input.severity \=== "Error" || input.severity \=== "Critical".  
        * **Appel WF-Notion-Helper :** Créer une tâche dans Agence\_Tâches\_Admin. Input : { "operation": "createTask", "title": "Error in WF " \+ input.workflowId, "details": input.message, "assigneeId": "ID\_Dev\_Lead", "priority": "High" }.  
      *   
    *   
    * *Output :* { "logCreated": true, "notionPageId": "..." } ou { "logCreated": false, "error": "..." }.  
    * *Dépendances :* Agence\_Monitoring\_N8N, WF-Notification-Dispatcher (potentiel), WF-Notion-Helper (potentiel).  
  *   
  * **WF-API-Key-Selector**  
    * *Rôle Technique :* Gérer la sélection et la rotation des clés API pour les services externes (spécifiquement OpenRouter ici). Encapsule la logique de gestion des clés échouées (rate limits, erreurs serveur).  
    * *Trigger :* Execute Workflow.  
    * *Input :* { "aiTeamName": "Team1" | "Team2" | ... }.  
    * *Logique Principale :* (Détaillée dans Pilier 3, mais implique la lecture/écriture de N8N Static Data via Workflow \- Static Data node ou API N8N interne si auto-hébergé).  
    * *Output :* { "apiKeyName": "Nom\_Credential\_N8N", "modelUsed": "nom/modele", "error": false } OU { "error": true, "message": "All keys unavailable" }.  
    * *Dépendances :* N8N Static Data.  
  *   
  * **WF-API-Retry-Logic**  
    * *Rôle Technique :* Fournir une logique de retry standardisée pour les appels API externes échoués (erreurs 5xx, 429 si non géré par WF-API-Key-Selector). Décide s'il faut retenter et avec quel délai.  
    * *Trigger :* Execute Workflow.  
    * *Input :* { "failedNodeOutput": object, "originalInput": object, "retryCount": number, "maxRetries": number (default: 3), "baseDelaySeconds": number (default: 5\) }.  
    * *Logique Principale (Code Node) :*  
      * Vérifier si input.retryCount \< input.maxRetries.  
      * Si oui :  
        * Calculer délai (ex: delay \= input.baseDelaySeconds \* Math.pow(2, input.retryCount) \+ Math.random()).  
        * Appeler WF-Monitoring (Severity: Warning, Message: "Retrying operation... Attempt " \+ (input.retryCount \+ 1)).  
        * Retourner { "shouldRetry": true, "nextRetryCount": input.retryCount \+ 1, "delaySeconds": delay }.  
      *   
      * Si non :  
        * Appeler WF-Monitoring (Severity: Error/Critical, Message: "Max retries reached for operation. Final error: " \+ JSON.stringify(input.failedNodeOutput)).  
        * Retourner { "shouldRetry": false, "error": true, "message": "Max retries reached", "finalErrorOutput": input.failedNodeOutput }.  
      *   
    *   
    * *Output :* { "shouldRetry": boolean, ... }.  
    * *Implémentation :* Le workflow *appelant* doit implémenter la boucle de retry. Il appelle ce WF depuis sa branche d'erreur, vérifie shouldRetry, utilise un Wait node avec delaySeconds, puis re-route vers le nœud API initial avec nextRetryCount et originalInput.  
    * *Dépendances :* WF-Monitoring.  
  *   
  * **WF-Notification-Dispatcher**  
    * *Rôle Technique :* Service centralisé d'envoi de notifications multi-canaux basé sur les préférences utilisateur.  
    * *Trigger :* Execute Workflow.  
    * *Input :* { "userId": "Notion\_User\_ID\_from\_HR\_Personnel", "message": string, "channelPreference": "Auto" | "Signal" | "Email" | "Telegram", "severity": "Info" | "Urgent" }.  
    * *Logique Principale :*  
      * **Notion API Call (Get Database Page) :** Lire Agence\_HR\_Personnel via input.userId. Gérer erreur si user non trouvé.  
      * **Extraction Coordonnées (Code Node) :** Récupérer Préférences Communication Interne, Email, Phone (pour Signal), Telegram Chat ID.  
      * **Sélection Canal (Code Node ou Switch Node) :**  
        * Déterminer le canal cible basé sur input.channelPreference et les données récupérées.  
        * Logique de fallback : Si Auto et pref \= Signal mais pas de numéro \-\> Email. Si canal spécifique demandé mais coordonnée manquante \-\> Email.  
      *   
      * **Routage (Switch Node basé sur canal cible) :**  
        * Branche Email : Gmail Send Node. Input : to: email, subject: "\[Urgent/Info\] Notification Agence", body: input.message. Utiliser credential agence global ou spécifique.  
        * Branche Signal : Signal Send Node. Input : recipient: phone, message: input.message. Utiliser credential Signal configuré.  
        * Branche Telegram : Telegram Bot Node (Send Message). Input : chatId: telegramChatId, text: input.message. Utiliser credential Bot Telegram.  
      *   
      * **Gestion Erreurs Envoi (Code Node après chaque branche d'envoi) :**  
        * Si l'envoi principal échoue (vérifier output du nœud d'envoi) :  
          * Logguer via WF-Monitoring (Warning).  
          * Si ce n'était pas déjà le fallback Email, tenter d'envoyer par Email.  
        *   
      *   
    *   
    * *Output :* { "dispatchStatus": "Success/Partial/Failed", "channelUsed": "Email/Signal/Telegram", "error?": "..." }.  
    * *Dépendances :* Agence\_HR\_Personnel, WF-Monitoring, Credentials Gmail/Signal/Telegram.  
  *   
  * **WF-Data-Quality-Checker**  
    * *Rôle Technique :* Détecteur proactif d'incohérences et d'erreurs dans les données Notion critiques.  
    * *Trigger :* Cron Node (ex: 0 3 \* \* \* \- tous les jours à 3h du matin).  
    * *Logique Principale :*  
      * **Définition des Règles (Set Node ou Code Node) :** Stocker les règles de validation par base de données (ex: { "Agence\_Contacts": \[{ field: "Email", rule: "isEmail" }, { field: "Téléphone", rule: "isMobilePhone", params: \["fr-FR"\] }, { field: "Consentement GDPR", rule: "isNotEmpty" }\], ... }).  
      * **Boucle sur les Bases (Loop Over Items ou Code Node) :** Itérer sur les bases à vérifier.  
      * *Dans la boucle (par base) :*  
        * **Notion API Call (Get Many Database Pages) :** Récupérer les items (utiliser pagination si nécessaire avec start\_cursor).  
        * **SplitInBatches Node :** Traiter par lots (ex: 100 items).  
        * **Code Node (Validation Batch) :**  
          * Input : Batch d'items Notion, règles pour cette base.  
          * Utiliser validator.js (si dispo) ou regex pour isEmail, isURL, isMobilePhone.  
          * Vérifier champs non vides (property.type \!== 'empty').  
          * Vérifier validité JSON (JSON.parse dans try...catch).  
          * *Détection Doublons (Simple) :* Créer un Map des emails/noms dans le batch, détecter collisions. Plus avancé : comparer avec un échantillon externe via Redis/DB CMS.  
          * Output : \[{ notionItemId: "...", field: "...", errorDescription: "...", value: "..." }\] pour chaque anomalie.  
        *   
        * **IF Node :** Si output.length \> 0\.  
        * **Code Node (Format Task) :** Agréger les erreurs par item, formater un message Markdown.  
        * **WF-Notion-Helper (Execute Workflow) :** Créer une page dans Agence\_Data\_Quality\_Issues. Input : { operation: "createDataQualityIssue", baseName: "...", issues: \[{ itemId: "...", summary: "..." }, ...\] }.  
      *   
    *   
    * *Output :* Log final via WF-Monitoring (Info, avec résumé des anomalies trouvées).  
    * *Dépendances :* Bases Notion cibles, WF-Notion-Helper, WF-Monitoring. Nécessite potentiellement validator.js (via NODE\_FUNCTION\_ALLOW\_EXTERNAL si N8N auto-hébergé).  
  *   
  * **WF-Notion-Helper**  
    * *Rôle Technique :* Façade robuste pour les opérations Notion courantes, encapsulant la logique API, le parsing de la réponse, et la gestion d'erreur basique.  
    * *Trigger :* Execute Workflow.  
    * *Input :* { "operation": string, ...params }. Exemples d'opérations :  
      * findPage: { operation: "findPage", dbId: "...", filter: { property: "Name", title: { equals: "..." } } }  
      * createPage: { operation: "createPage", dbId: "...", properties: { ...Notion API properties object... } }  
      * updatePage: { operation: "updatePage", pageId: "...", properties: { ...Notion API properties object... } }  
      * getPage: { operation: "getPage", pageId: "..." }  
    *   
    * *Logique Principale (Switch Node basé sur input.operation) :*  
      * Chaque branche contient le nœud Notion API correspondant (Get Many, Create, Update, Get).  
      * **Gestion d'Erreur :** Connecter la sortie d'erreur du nœud Notion à WF-API-Retry-Logic (si pertinent) ou directement à WF-Monitoring. Retourner un format d'erreur standardisé.  
      * **Parsing Réponse (Code Node si nécessaire) :** Simplifier la structure de la réponse Notion si besoin avant de la retourner.  
    *   
    * *Output :* { "success": true, "data": { ...Notion API response data... } } OU { "success": false, "error": "...", "details": { ...Error details... } }.  
    * *Dépendances :* Notion Credentials, WF-API-Retry-Logic, WF-Monitoring.  
  *   
*   
* **3.2. Workflows Métier Principaux (Orchestrateurs Étendus) :**  
  * Ces workflows définissent la logique métier de haut niveau. Ils sont déclenchés par des événements externes ou internes et coordonnent l'appel des sous-workflows utilitaires et spécialisés.  
  * **WF-Booking-Manager**  
    * *Rôle Technique :* Orchestrateur du cycle de vie d'une opportunité de booking.  
    * *Triggers Possibles :*  
      * Manual Trigger (pour tests).  
      * Webhook Node (appelé par le CMS via API sécurisée \- Pilier 4). Payload : { action: "startProspection", artistId: "...", lotName: "LOT1", targetFilters: {...} } ou { action: "validateDeal", lotItemId: "..." }.  
      * Notion Trigger Node (sur mise à jour de \[Artiste\]\_LOT\_Booking, ex: Statut change). *Attention : fiabilité et délais des webhooks Notion peuvent varier.*  
      * Cron Node (pour des actions périodiques comme les relances \- moins idéal pour un orchestrateur principal).  
    *   
    * *Logique Principale :*  
      * **Identifier Contexte (Code Node) :** Extraire artistId / lotItemId / action du trigger data.  
      * **Appel WF-Core-Config (Execute Workflow) :** Récupérer la config artiste. Gérer erreur si output.error.  
      * **Routage (Switch Node basé sur action ou statut Notion) :**  
        * Cas "startProspection":  
          * Appel WF-Disponibilites.  
          * Appel WF-Booking-Prospection (passer config, dispos, targetFilters).  
        *   
        * Cas "responseReceived" (déclenché par WF-Booking-Response-Handler via Execute Workflow? Ou directement par trigger Gmail?):  
          * Logique de suivi post-analyse IA (créer tâche, notifier manager...).  
        *   
        * Cas "validateDeal":  
          * Appel WF-Booking-Deal-Processor (passer config, lotItemId).  
        *   
        * Cas "remindLogistics":  
          * Appel WF-Booking-Logistics-Reminder.  
        *   
        * Cas "sendPostConcert":  
          * Appel WF-Booking-Post-Concert.  
        *   
      *   
      * **Gestion des Retours (Set Node / Code Node) :** Formater une réponse pour le trigger initial (ex: pour le webhook CMS) ou logguer le résultat final.  
    *   
    * *Dépendances :* WF-Core-Config, tous les sous-workflows WF-Booking-\*, WF-Disponibilites.  
  *   
  * **WF-Promotion-Manager, WF-Production-Manager, WF-HR-Manager :** Suivent une structure similaire d'orchestration, appelant leurs sous-workflows respectifs en fonction des triggers et du contexte.  
*   
* **3.3. Sous-Workflows Spécialisés (Exécutants Détaillés) :**  
  * Ces workflows implémentent des étapes métier spécifiques. Ils sont appelés par les orchestrateurs et utilisent les workflows utilitaires.  
  * **WF-Disponibilites**  
    * *Rôle Technique :* Calculer les plages de disponibilité d'un artiste en agrégeant les données de GCal et Notion.  
    * *Trigger :* Execute Workflow.  
    * *Input :* { "config": object }.  
    * *Logique Principale :*  
      * **Google Calendar Node (Get Many Events) :** Lire config.gCalIndispoId. Paramètres : startDate (now), endDate (now \+ X months), timeZone.  
      * **WF-Notion-Helper (Execute Workflow) :** Lire config.notionDbDispo. Input : { operation: "findPage", dbId: config.notionDbDispo, filter: { property: "Validé Par Manager", checkbox: { equals: true } } }.  
      * **Code Node (Consolidate Busy Dates) :**  
        * Input 0: GCal items, Input 1: Notion items.  
        * Initialiser const busyDates \= new Set();.  
        * Traiter GCal events : gérer date vs dateTime, fuseaux horaires (convertir en UTC ou date locale cohérente), événements multi-jours (itérer du start au end). Ajouter YYYY-MM-DD au Set.  
        * Traiter Notion pages : extraire Date Indispo (start/end), gérer fuseaux horaires, ajouter YYYY-MM-DD au Set.  
        * Retourner \[{ json: { busyDates: Array.from(busyDates) } }\].  
      *   
      * **Code Node (Calculate Free Slots) :**  
        * Input : Item de l'étape 3\.  
        * const busySet \= new Set(items\[0\].json.busyDates);.  
        * Itérer sur les N prochains jours (configurable?).  
        * Pour chaque date : formater en YYYY-MM-DD. Vérifier si \!busySet.has(date) ET dayOfWeek \=== 5 || dayOfWeek \=== 6\.  
        * Si disponible, ajouter { json: { date: "YYYY-MM-DD", status: "available" } } à un tableau de résultats.  
        * Retourner le tableau de résultats.  
      *   
    *   
    * *Output :* Array d'items, chacun représentant un slot disponible : \[{ json: { date: "YYYY-MM-DD", status: "available" } }, ...\].  
    * *Dépendances :* WF-Notion-Helper, Google Calendar Credentials.  
  *   
  * **WF-Booking-Prospection**  
    * *Rôle Technique :* Gérer l'envoi massif et personnalisé d'emails de prospection.  
    * *Trigger :* Execute Workflow.  
    * *Input :* { "config": object, "availableDates": string\[\], "targetFilters"?: object }.  
    * *Logique Principale :*  
      * **Appel WF-AI-Team-Executor (Team 1\) :** Générer message de base. Input : { aiTeamName: "Team1", prompt: "Rédige email base pour artiste X proposant dates: " \+ input.availableDates.join(', '), ... }. Gérer erreur.  
      * **WF-Notion-Helper (Find Contacts) :** Lire config.notionDbContactsId. Input : { operation: "findPage", dbId: config.notionDbContactsId, filter: { and: \[ { property: "Statut Email", select: { does\_not\_equal: "PROSPECT📨 Envoyé" } }, ...input.targetFilters \] } }. Gérer pagination si \> 100 contacts.  
      * **SplitInBatches Node :** Configurer batchSize (ex: 5 ou 10, potentiellement depuis config). Connecter la sortie "Done" pour terminer. Connecter la sortie de la dernière étape de la boucle à l'input "Execute Next Batch".  
      * *Dans la boucle (sortie "Batch") :*  
        * **Code Node (Get Details) :** Pour chaque item (contact), extraire pageId, email, prénom, structureId (relation lieu).  
        * **(Optionnel) WF-Notion-Helper (Get Lieu Details) :** Si structureId existe, récupérer détails du lieu (Agence\_Lieux\_Structures).  
        * **Appel WF-AI-Team-Executor (Team 2\) :** Personnaliser message. Input : { aiTeamName: "Team2", prompt: "Personnalise ce message base: \[baseMsg\] pour \[Prénom\] de \[Structure\] (infos lieu: \[lieuDetails\])...", ... }. Gérer erreur.  
        * **Get Template (IF Node \+ WF-Notion-Helper / Gmail Get Draft) :**  
          * Si template dans Notion : WF-Notion-Helper { operation: "getPage", pageId: config.templateId }. Extraire contenu.  
          * Si template Gmail : Gmail Get Draft Node (filtrer par config.gmailTemplateSubject). Extraire bodyHtml.  
        *   
        * **Code Node (Inject Content) :** Remplacer placeholder (ex: {{CONTENT}}) dans le template HTML/texte avec le message personnalisé de l'IA. Gérer échappement HTML si nécessaire.  
        * **Gmail Create Draft Node :** to: contact.email, subject: ..., bodyType: HTML, message: finalHtml. Utiliser config.gmailCredentialName.  
        * **WF-Notion-Helper (Update Status) :** Mettre à jour la page contact Notion. Input : { operation: "updatePage", pageId: contact.pageId, properties: { "Statut Email": { select: { name: "PROSPECT📧 Brouillon créé" } }, "Date Dernier Contact N8N": { date: { start: new Date().toISOString() } } } }. Gérer erreur.  
        * **Wait Node :** Délai randomisé (ex: {{ Math.random() \* (60 \- 30\) \+ 30 }} secondes, min/max depuis config?).  
      *   
      * *Après la boucle (sortie "Done" de SplitInBatches) :*  
        * **Appel WF-Monitoring :** Logguer la fin de la campagne avec le nombre total traité.  
      *   
    *   
    * *Output :* { "status": "Completed", "totalProcessed": number }.  
    * *Dépendances :* WF-AI-Team-Executor, WF-Notion-Helper, Gmail Credentials, Agence\_Templates (si utilisé).  
  *   
  * **WF-Booking-Response-Handler**  
    * *Rôle Technique :* Traiter les réponses emails, qualifier avec l'IA, mettre à jour Notion et notifier.  
    * *Trigger :* Gmail Trigger (On Message) OU (Cron \+ Gmail Search/List \+ Code pour éviter retraitement). *Gmail Trigger est plus temps réel mais peut nécessiter gestion état pour éviter doublons si N8N redémarre.*  
    * *Input :* Gmail message object.  
    * *Logique Principale :*  
      * **Extraction (Code Node) :** senderEmail, subject, plainBody, threadId, messageId.  
      * **Context Identification (Code Node) :**  
        * Rechercher senderEmail dans Agence\_Contacts. Si trouvé, récupérer contactId.  
        * Rechercher dans toutes les bases \[Artiste\]\_LOT\_Booking (nécessite de lister les artistes actifs et leurs DB IDs via Agence\_Artistes) un item lié à contactId OU dont le threadId (si stocké lors de l'envoi) correspond. *Logique potentiellement complexe et coûteuse en appels Notion.*  
        * Si match trouvé, récupérer lotItemId et artistId.  
      *   
      * **IF Node :** Contexte trouvé (lotItemId et artistId) ?  
        * *Branche Oui :*  
          * **Appel WF-Core-Config**. Gérer erreur.  
          * **Appel WF-Notion-Helper (Update Status) :** Mettre à jour LOT item { operation: "updatePage", pageId: lotItemId, properties: { "Statut Email": { select: { name: "PROSPECT🧐 Réponse reçue" } } } }.  
          * **Appel WF-AI-Team-Executor (Team 1 ou 3\) :** Analyser email. Input : { aiTeamName: "Team1", prompt: "Analyse cet email: \[plainBody\]. Extrait: sentiment (Positif/Négatif/Neutre), intention (Info/Négo/Refus), dates proposées, questions clés. Réponds en JSON: { sentiment: '...', intention: '...', dates: \[...\], questions: \[...\] }", ... }. Gérer erreur.  
          * **Code Node (Parse AI Response) :** Extraire le JSON de la réponse IA. Gérer parsing error.  
          * **Code Node (Determine Final Status) :** Logique pour mapper sentiment/intention vers un statut Notion final (ex: "Négo", "Refus Poli", "A recontacter").  
          * **Appel WF-Notion-Helper (Update Details) :** Mettre à jour LOT item avec AI Sentiment Réponse, AI Résumé Réponse (généré par IA ou extrait), et le Statut Email final.  
          * **Appel WF-Notification-Dispatcher :** Alerter Booker/Manager. Input : { userId: config.booker.notionUserId, message: "Réponse reçue pour \[Contact\] / \[Artiste\]. Sentiment: " \+ aiSentiment \+ ". Statut: " \+ finalStatus, ... }.  
        *   
        * *Branche Non :*  
          * **Appel WF-Monitoring :** Logguer (Warning) "Email reçu de \[senderEmail\] non associé à une prospection active."  
        *   
      *   
    *   
    * *Output :* { "processingStatus": "Success/Skipped/Error", "lotItemId?": "...", "artistId?": "..." }.  
    * *Dépendances :* Gmail Trigger/Credentials, Agence\_Contacts, \[Artiste\]\_LOT\_Booking (tous), WF-Core-Config, WF-Notion-Helper, WF-AI-Team-Executor, WF-Notification-Dispatcher, WF-Monitoring.  
  *   
  * **WF-Booking-Deal-Processor**  
    * *Rôle Technique :* Synchroniser un accord de booking (DEAL) entre Notion LOT, Notion Agenda et Google Calendar.  
    * *Trigger :* Execute Workflow (appelé par WF-Booking-Manager).  
    * *Input :* { "config": object, "lotItemId": string }.  
    * *Logique Principale :*  
      * **Appel WF-Notion-Helper (Get LOT Item) :** Récupérer les détails du lotItemId (Date, Lieu Relation, Artiste...).  
      * **Validation (IF Node) :** Vérifier que le statut est bien "DEAL" ou similaire.  
      * **Génération ID Synchro (Code Node) :** const syncId \= "notion\_" \+ input.lotItemId;.  
      * **Appel WF-Notion-Helper (Update LOT Item) :** Stocker syncId dans un champ GCal\_Sync\_ID sur le LOT item.  
      * **Google Calendar Node (List Events) :** Rechercher dans config.gCalBookingId un événement avec privateExtendedProperty ou description contenant syncId.  
      * **Préparation Event Data (Code Node) :** Formater les données pour GCal (start/end dateTime avec timezone, summary, description, location...). Inclure syncId dans extendedProperties.private.syncId ou description.  
      * **IF Node :** Événement GCal trouvé à l'étape 5 ?  
        * *Branche Oui :* **Google Calendar Node (Update Event)**. Utiliser l'eventId trouvé.  
        * *Branche Non :* **Google Calendar Node (Create Event)**.  
      *   
      * **Code Node (Extract GCal ID) :** Récupérer l'eventId retourné par GCal (Create ou Update).  
      * **Appel WF-Notion-Helper (Update LOT Item) :** Stocker eventId dans GCal\_Event\_ID.  
      * **Appel WF-Notion-Helper (Create/Update Agenda Notion) :**  
        * Chercher page dans config.notionDbAgenda avec GCal\_Sync\_ID \== syncId.  
        * Si trouvée, mettre à jour.  
        * Si non trouvée, créer une nouvelle page, en liant au LOT item et en stockant GCal\_Event\_ID et GCal\_Sync\_ID.  
      *   
      * **(Optionnel) Appel WF-Notion-Helper (Create Task) :** Créer tâche logistique dans config.notionDbTaches.  
    *   
    * *Output :* { "syncStatus": "Success/Error", "gCalEventId?": "...", "notionAgendaPageId?": "..." }.  
    * *Dépendances :* WF-Notion-Helper, Google Calendar Credentials, \[Artiste\]\_LOT\_Booking, \[Artiste\]\_Agenda\_Booking, \[Artiste\]\_Tâches.  
  *   
  * **WF-Booking-Logistics-Reminder, WF-Booking-Post-Concert, WF-Musician-Availability-Reminder, WF-Musician-Itinerary-Sender, WF-Task-Reminder, WF-HR-Onboarding, WF-HR-Payroll-Prep :** Suivent des logiques similaires : déclencheur (Cron/Webhook/GCal), récupération de contexte (Notion/GCal), potentiellement appel IA (Team 2/4/6), action finale (Notification/Email/Update Notion/Création Tâche). La clé est l'utilisation systématique des workflows utilitaires (WF-Core-Config, WF-Notion-Helper, WF-Notification-Dispatcher, WF-AI-Team-Executor, WF-Monitoring).  
*   
* **4\. Robustesse, Tests et Documentation (Intégrés et Approfondis) :**  
  * **4.1. Gestion d'Erreurs Systématique et Graduée :**  
    * **try...catch dans Code Nodes :** Essentiel pour parser JSON, manipuler dates, logique complexe. Le catch doit appeler WF-Monitoring et retourner/throw une erreur structurée.  
    * **Connexion Sorties Erreur :** Systématique.  
      * Nœuds API (Notion, GCal, Gmail, HTTP Request vers IA) : Connecter sortie erreur vers WF-API-Retry-Logic. Si WF-API-Retry-Logic retourne shouldRetry: false, connecter vers WF-Monitoring.  
      * Nœuds Execute Workflow : Connecter sortie erreur vers WF-Monitoring. Le WF appelé doit gérer ses propres erreurs internes.  
      * Autres nœuds (Set, IF, Switch...) : Les erreurs sont rares mais si elles surviennent (ex: expression invalide), elles arrêtent l'exécution et sont gérées par l'Error Trigger global.  
    *   
    * **Error Trigger Global :** Configuré pour appeler WF-Monitoring avec Severity: Critical. Capture les erreurs non interceptées.  
  *   
  * **4.2. Idempotence Renforcée :**  
    * **Stratégie :** "Check-then-Act" ou utilisation d'identifiants uniques.  
    * *Exemple GCal Sync (WF-Booking-Deal-Processor) :* Utilisation de GCal\_Sync\_ID (basé sur lotItemId) pour rechercher l'événement *avant* de créer. Si trouvé, on met à jour. Garantit qu'un seul événement GCal est créé même si le WF est déclenché plusieurs fois.  
    * *Exemple Envoi Email (WF-Booking-Prospection) :* Le statut Notion ("Brouillon créé", "Envoyé") empêche de renvoyer au même contact.  
    * *Exemple Création Tâche :* Si une tâche a un titre/identifiant prévisible, rechercher si elle existe avant de la créer.  
  *   
  * **4.3. Validation des Données Stricte (Schémas) :**  
    * **Nœud Schema Validation ou Code \+ zod :**  
      * Placer au début des workflows déclenchés par des sources externes non fiables (Webhook, Gmail Trigger). Valider le payload/message entrant.  
      * Placer avant les appels Execute Workflow pour s'assurer que les inputs sont corrects.  
      * Placer avant les nœuds API critiques (ex: Create GCal Event, Notion Create Page) pour valider les données formatées.  
    *   
    * **Définition Schémas :** Stocker les schémas Zod/JSON Schema dans Agence\_Documentation ou un repo Git dédié. Versionner les schémas.  
  *   
  * **4.4. Stratégie de Test Multi-Niveaux (Détaillée) :**  
    * **Unitaire (Test Step) :** Isoler un nœud. Utiliser "Edit Input Data" pour fournir des cas de test variés (données valides, invalides, limites). Vérifier "Output Data".  
    * **Intégration (Sous-WF via "Test Harness") :**  
      * Créer un WF Test\_\[Nom\_Sous\_WF\].  
      * Manual Trigger.  
      * Set Node(s) pour simuler les inputs requis par le sous-WF (y compris l'objet config).  
      * Execute Workflow Node appelant le sous-WF.  
      * Code Node (Assertions) : Vérifier si l'output du sous-WF correspond aux attentes (expect(output.data.status).toBe('Success');). Throw error si assertion échoue.  
      * Vérifier manuellement les effets de bord (Notion, GCal...).  
    *   
    * **Intégration (Manager WF / End-to-End) :**  
      * Nécessite un environnement de test isolé (Staging N8N, Notion "Test Artist", GCal "Test", Gmail "Test").  
      * Préparer les données initiales (ex: contact Notion à prospecter).  
      * Déclencher le Manager WF (manuellement ou via webhook de test).  
      * Suivre l'exécution dans N8N.  
      * Vérifier les états finaux dans Notion, GCal, Gmail.  
      * Nettoyer les données de test.  
    *   
    * **Tests de Charge (Basique N8N) :**  
      * Créer un WF simple : Manual Trigger \-\> Loop Over Items (ex: 1000 itérations) \-\> Execute Workflow (appelant le WF à tester via Webhook si possible, ou directement).  
      * Monitorer l'utilisation CPU/RAM de l'instance N8N.  
      * Vérifier les logs Agence\_Monitoring\_N8N pour les erreurs de rate limit (429).  
      * Mesurer le temps total d'exécution.  
    *   
    * **Tests Utilisateur (UAT) :**  
      * Définir des scénarios utilisateur clairs (ex: "Prospecter 10 contacts pour Gribitch", "Valider le deal pour le concert X", "Soumettre mes indisponibilités pour le mois prochain").  
      * Fournir un accès à l'environnement Staging (CMS/Notion/N8N si pertinent).  
      * Utiliser un outil de suivi de feedback (Trello, Jira, Notion DB).  
    *   
  *   
  * **4.5. Documentation Vivante et Accessible :**

**Sticky Notes :** Utiliser Markdown :  
      \#\#\#\# WF-Booking-Prospection Loop Item

\*\*// OBJECTIF:\*\* Personnaliser et envoyer un email de prospection à un contact.  
\*\*// INPUT:\*\* Item du SplitInBatches (données contact Notion), Message Base IA (depuis nœud précédent).  
\*\*// OUTPUT:\*\* Statut de l'envoi/mise à jour Notion pour ce contact.  
\*\*// LOGIQUE CLÉ:\*\*  
1\. Récupérer détails lieu (si pertinent).  
2\. Appel Team 2 pour personnalisation.  
3\. Récupérer template Gmail/Notion.  
4\. Injecter contenu personnalisé.  
5\. Créer Brouillon Gmail.  
6\. Mettre à jour statut contact Notion via WF-Notion-Helper.  
7\. Attendre délai randomisé.  
\*\*// ERREURS:\*\* Gérées par WF-API-Retry-Logic / WF-Monitoring.

*      
  * **Nommage :** Préfixes Util\_, Booking\_, HR\_, Notion\_, GCal\_, AI\_. Suffixes \_Main (Orchestrateur), \_Sub (Exécutant).  
    * **Organisation Visuelle :** Cadres (Sticky Note large, couleur par phase/type). Alignement logique des nœuds.  
    * **Documentation Externe (Agence\_Documentation \- Notion DB) :**  
      * *Type de Page :* Workflow Spec, Architecture Diagram, Convention Guide, API Endpoint, Glossary Term.  
      * *Propriétés Workflow Spec :* Nom Workflow (Title), ID N8N (Text), Lien N8N Editor (URL), Version (Text), Statut (Select: Dev, Staging, Prod, Deprecated), Responsable Dev (Relation \-\> Agence\_Équipe), Description (Text), Triggers (Multi-Select), Inputs Schema (Text \- JSON Schema/Zod), Outputs Schema (Text \- JSON Schema/Zod), Dépendances WF (Relation \-\> Agence\_Documentation), Dépendances Externes (Multi-Select: Notion, GCal, Team1...), Notes Techniques (Text).  
      * Utiliser des synced blocks Notion pour partager des diagrammes ou conventions entre plusieurs pages.  
    *   
  *   
  * **Matrices ACRI :** Les matrices fournies sont un excellent point de départ. Les affiner pour chaque sous-processus critique (ex: Gestion erreur API, Validation données qualité) et les intégrer dans Agence\_Documentation.  
* 

---

Ce développement approfondi du Pilier 2 fournit aux ingénieurs une vision technique détaillée de l'architecture N8N proposée, des interactions entre workflows, de la gestion des données et des erreurs, ainsi que des stratégies de test et de documentation nécessaires pour construire et maintenir un système robuste et évolutif.

