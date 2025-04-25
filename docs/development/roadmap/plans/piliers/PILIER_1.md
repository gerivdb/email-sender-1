# PILIER 1 : La Donnée Stratégique

*Centralisée, Structurée, Validée, Sécurisée et Accessible (Fondation Notion & Extensions)*

Ce pilier établit la fondation sur laquelle reposent tous les processus automatisés (Pilier 2), l'intelligence augmentée (Pilier 3) et les interfaces utilisateur (Pilier 4). Sa robustesse, sa cohérence et sa sécurité sont non négociables. Notion est choisi comme hub principal pour sa flexibilité et ses capacités relationnelles, complété par Google Drive pour le stockage documentaire structuré.

## 1. Hub de Données Notion (Le Cerveau Opérationnel et Relationnel de l'Agence)

**Objectif Technique :** Modéliser les entités métier clés de l'agence (Artistes, Contacts, Lieux, Projets, RH...) sous forme de bases de données Notion interconnectées, fournissant une API implicite (via l'API Notion) pour les opérations CRUD et la lecture par N8N et le CMS.

### 1.1. Base Agence_Artistes (Master List - Référentiel Central Absolu)

**Rôle Technique :** Table de configuration paramétrique pour l'ensemble de l'écosystème par artiste. Sert de point d'entrée pour WF-Core-Config afin d'initialiser les workflows N8N spécifiques à un artiste. Agit comme SSoT (Single Source of Truth) pour les métadonnées artiste.

**Champs Critiques (Détails Techniques) :**

- **Nom Artiste** (Type: Title, Contrainte: Unique - à valider via WF-Data-Quality-Checker ou procédure manuelle).
- **Statut Agence** (Type: Select, Options: Prospect, Actif, En Pause, Archive). Utilisé par les workflows N8N pour filtrer les artistes à traiter (ex: WF-Booking-Prospection ne cible que les Actif).
- **Manager Référent, Booker Principal** (Type: Relation, Base liée: Agence_Équipe, Limite: 1). Essentiel pour le routage des notifications (WF-Notification-Dispatcher) et l'assignation des tâches (WF-Task-Reminder, [Artiste]_Tâches).
- **N8N Config** (Type: Text - Multiligne, Format: JSON Validé). Clé de voûte pour N8N.
  - **Objectif :** Fournir tous les identifiants et paramètres spécifiques à un artiste à WF-Core-Config.
  - **Structure JSON Détaillée :**

```json
{
  "artistId": "uuid-de-l-artiste-genere", 
  "notionDbBookingPrefix": "Gribitch_LOT_", 
  "notionDbAgenda": "db_id_agenda_artiste", 
  "notionDbDispo": "db_id_dispo_artiste", 
  "notionDbProjets": "db_id_projets_artiste", 
  "notionDbContrats": "db_id_contrats_artiste", 
  "notionDbMerch": "db_id_merch_artiste", 
  "notionDbTaches": "db_id_taches_artiste", 
  "notionDbSocialContent": "db_id_social_artiste", 
  "notionDbFeedback": "db_id_feedback_artiste", 
  "gCalBookingId": "id_cal_booking@group.calendar.google.com", 
  "gCalIndispoId": "id_cal_indispo@group.calendar.google.com", 
  "gDriveFolderId": "gdrive_folder_id_artiste", 
  "gmailCredentialName": "Gmail Credential Artiste X", 
  "signalGroupId": "signal_group_id_base64_ou_autre", 
  "telegramChatId": "telegram_chat_id_numeric", 
  "aiTeamStaticDataPrefix": "aiApiKeys_Gribitch_" 
}
```

> **Validation :** La structure et la validité de ce JSON doivent être vérifiées (manuellement ou via WF-Data-Quality-Checker). Une erreur ici bloque tous les workflows N8N pour l'artiste.

- **Lien Espace Notion, Lien Dossier GDrive, Lien Portail CMS** (Type: URL). Utilitaires pour navigation rapide depuis Notion ou le CMS.
- **Contrat Management** (Type: Relation, Base liée: [Artiste]_Contrats, Limite: 1). Lien vers le contrat cadre principal. Utilisé par WF-HR-Compliance-Reminder.
- **Résumé Financier Clé** (Type: Rollup, Relation: Agence_Finance via [Artiste]_Projets ou [Artiste]_Agenda_Booking, Calcul: Ex: sum(Revenus) - sum(Dépenses) filtré sur l'année en cours). Pour dashboarding rapide (CMS, Vue Manager). Attention à la performance sur gros volumes.

**Importance Technique :** Cette base est le point d'injection de configuration pour N8N. Sa mise à jour correcte est critique lors de l'onboarding d'un nouvel artiste. WF-Core-Config dépend entièrement de la récupération et du parsing correct du champ N8N Config.

### 1.2. Espaces Notion par Artiste (Isolation & Collaboration Opérationnelle)

**Structure Technique :** Utilisation des "Teamspaces" Notion ou d'une structure de pages partagées pour isoler les données opérationnelles par artiste. Les permissions sont gérées au niveau de l'espace/page racine de l'artiste (voir 1.6).

**Bases Types par Artiste (Détails Techniques) :**

#### [Artiste]_LOT_Booking (DB principale du cycle de vente)
- **AI Sentiment Réponse** (Type: Select). Populated by WF-Booking-Response-Handler (Team 1/3).
- **AI Résumé Réponse** (Type: Text). Populated by WF-Booking-Response-Handler (Team 1/3).
- **Lien GCal Event** (Type: URL). Populated by WF-Booking-Deal-Processor. Permet lien direct vers l'event GCal.
- **Commission Booker** (Type: Number, Format: Pourcentage/Montant). Utilisé par WF-HR-Payroll-Prep.
- **Statut Paiement Dépôt** (Type: Select). Mis à jour manuellement ou via futur WF Finance. Peut déclencher des rappels.

#### [Artiste]_Agenda_Booking (DB des événements confirmés)
- **Heure Arrivée, Heure Soundcheck, etc.** (Type: Date avec Time). Utilisé par WF-Musician-Itinerary-Sender.
- **Contact Lieu Jour J** (Type: Text ou Relation -> Agence_Contacts). Utilisé par WF-Musician-Itinerary-Sender.
- **Lien Itinéraire** (Type: URL). Potentiellement généré par Team 4 et stocké par N8N.
- **Statut Logistique** (Type: Select). Mis à jour manuellement ou via complétion des tâches dans [Artiste]_Tâches (Rollup?).
- **Feedback Post-Concert** (Type: Relation, Base liée: [Artiste]_Feedback).

#### [Artiste]_Dispo_Membres (DB des indisponibilités)
- **Validé Par Manager** (Type: Checkbox). Peut servir de trigger (via webhook Notion ou scan N8N) pour que WF-Disponibilites prenne en compte l'indispo.
- **Impact Booking** (Type: Select). Utilisé par WF-Disponibilites pour évaluer si la date est réellement bloquée.

#### [Artiste]_Projets (DB de suivi de production)
- **Budget Prévisionnel vs Réel** (Type: Formula, nécessite champs Number pour prévisionnel et rollup des dépenses depuis Agence_Finance).
- **Tâches Principales** (Type: Relation, Base liée: [Artiste]_Tâches).
- **Fichiers Clés** (Type: Relation vers une DB [Artiste]_GDrive_Links? Ou Files & Media? Ou URL vers GDrive?). Stratégie à définir pour lier Notion à GDrive de manière robuste via N8N. Un WF WF-GDrive-Linker pourrait être nécessaire pour synchroniser les fichiers GDrive pertinents vers une DB Notion dédiée avec leurs liens.

#### [Artiste]_Contrats (DB des contrats spécifiques)
- **Date Expiration** (Type: Date). Trigger pour WF-HR-Compliance-Reminder.
- **Renouvellement Auto** (Type: Checkbox). Logique pour WF-HR-Compliance-Reminder.
- **Alertes Clés** (Type: Date). Peut être mis à jour par N8N (ex: alerte J-30).
- **Parties Signataires** (Type: Text ou Relation -> Agence_Contacts / Agence_Lieux_Structures).

#### [Artiste]_Tâches (DB de gestion de tâches)
- **Responsable** (Type: Relation, Bases liées: Agence_Équipe, Artiste_Membres). Permet assignation flexible. Utilisé par WF-Task-Reminder.
- **Échéance** (Type: Date). Trigger pour WF-Task-Reminder.
- **Statut** (Type: Select). Peut déclencher d'autres workflows à la complétion.
- **Projet Lié** (Type: Relation, Base liée: [Artiste]_Projets).
- **Priorité** (Type: Select ou Number). Pour tri et priorisation (manuelle ou CMS).

#### [Artiste]_Merch (DB de stock)
- **Stock Actuel** (Type: Number). Mis à jour manuellement ou via future intégration e-commerce/POS.
- **Seuil Alerte Stock** (Type: Number). Comparé au Stock Actuel par WF-Merch-Stock-Alert (Cron N8N).

#### [Artiste]_Social_Content (DB calendrier éditorial)
- **Plateforme** (Type: Select).
- **Visuel/Vidéo** (Type: Files & Media ou URL vers GDrive).
- **Statut** (Type: Select). Trigger pour WF-Social-Post-Scheduler quand "Prêt".
- **Performance** (Type: Text). Mis à jour manuellement ou via future intégration API réseaux sociaux.

#### [Artiste]_Feedback (DB retours qualitatifs)
- **Type, Source** (Type: Select).
- **Note** (Type: Number). Utilisé par Team 3 pour analyse de sentiment/satisfaction.
- **Commentaire** (Type: Text). Source pour analyse qualitative Team 3.

### 1.3. Bases de Données Métier Transversales (Vision 360° Agence)

**Objectif Technique :** Centraliser les données partagées entre artistes et fonctions agence, évitant la duplication et permettant des analyses et opérations transversales.

**Bases Clés (Détails Techniques) :**

#### Agence_Contacts (CRM Central)
- **Source Contact** (Type: Select). Pour analyse efficacité canaux acquisition.
- **Date Dernier Contact N8N** (Type: Date). Mis à jour par WF-Booking-Prospection, WF-Booking-Response-Handler, etc. pour suivi activité.
- **Consentement GDPR** (Type: Checkbox + Date de consentement). Vérifié par WF-Booking-Prospection avant envoi email. Doit être géré rigoureusement (processus de collecte et de retrait).
- **Préférences Communication** (Type: Multi-Select). Utilisé par WF-Notification-Dispatcher.
- **Notes Confidentielles** (Type: Text). Accès restreint via permissions Notion (si possible au niveau propriété) ou géré via CMS (qui filtre l'accès).

#### Agence_Lieux_Structures (Base de données lieux)
- **Contact Booking/Technique/Com** (Type: Relation, Base liée: Agence_Contacts).
- **Lien Fiche Technique** (Type: URL vers GDrive ou Files & Media). Utilisé par Team 4.
- **Conditions Accueil Détaillées, Historique Incidents** (Type: Text). Source pour RAG Team 4.
- **Accessibilité PMR** (Type: Select). Filtre important pour certains artistes/publics.
- **Notes Internes Booker/Tech** (Type: Text). Pour partage d'infos équipe.

#### Agence_Équipe (Annuaire interne agence)
- **Spécialisations** (Type: Multi-Select). Pour routage tâches/infos.
- **Accès CMS/Notion** (Type: Text). Documentation manuelle des rôles/permissions.
- **Contact Urgence** (Type: Text).
- **Date Entrée/Sortie** (Type: Date). Pour processus Onboarding/Offboarding (WF-HR-Manager).
- Relation vers Agence_HR_Personnel pour lier profil opérationnel et RH.

#### Artiste_Membres (Annuaire musiciens/techniciens par artiste)
- **Contact Principal** (Type: Email, Phone).
- **Rôle Scène/Admin/Compo** (Type: Text).
- **Allergies/Régime** (Type: Text). Donnée sensible (santé). Nécessite consentement explicite et accès restreint. Utilisé pour générer briefs catering.
- **Préférences Communication** (Type: Select). Utilisé par WF-Notification-Dispatcher.
- Relation vers Agence_HR_Personnel si contrat direct avec l'agence.

#### Agence_Monitoring_N8N (Log des exécutions N8N)
- **Workflow ID, Execution ID** (Type: Text). Récupérés depuis les variables d'environnement N8N ($workflow.id, $execution.id).
- **Sévérité** (Type: Select). Définit l'urgence et le type de notification (WF-Notification-Dispatcher).
- **Données Contextuelles** (Type: Text - JSON stringifié). Contient les données de l'item N8N au moment de l'erreur/log. Attention à la taille et aux données sensibles.
- **Action Corrective Prise** (Type: Text). Mis à jour manuellement après résolution.
- Utilisé par Team 8 pour analyse performance/erreurs.

#### Agence_Finance (Suivi financier global)
- **Facture Liée** (Type: Files & Media ou URL vers GDrive).
- **Centre de Coût** (Type: Select). Pour reporting financier.
- **Statut Facturation** (Type: Select). Peut déclencher des workflows de relance.
- **Méthode Paiement** (Type: Select/Text).

#### Agence_HR_Personnel (Base RH centrale - Accès Ultra-Restreint)
- **Sécurité :** Doit être dans un espace Notion séparé avec permissions minimales. L'intégration N8N doit avoir un token spécifique avec accès uniquement à cette base si nécessaire (et idéalement en lecture seule sauf pour WFs RH spécifiques). Le CMS doit gérer l'accès via des rôles RH stricts.
- **Type Contrat** (Type: Select).
- **Date Début/Fin Contrat** (Type: Date). Trigger pour WF-HR-Compliance-Reminder.
- **Poste/Rôle** (Type: Text/Select).
- **Manager Direct** (Type: Relation, Base liée: Agence_Équipe).
- **Coordonnées Perso, IBAN, Num Sécu** (Type: Text). Données hautement sensibles. Envisager stockage crypté hors Notion (ex: coffre-fort numérique type HashiCorp Vault) ou gestion exclusive via CMS sécurisé qui ne stocke que des références. Notion n'est peut-être pas idéal pour ces données spécifiques. Si stocké dans Notion, accès via API doit être proscrit sauf pour processus RH validé.
- **Statut Congés/Absences** (Type: Rollup depuis une DB Agence_HR_Absences ou mis à jour par WF-HR-Leave-Processor).
- **Date Prochaine Révision Perf** (Type: Date). Trigger pour WF-HR-Performance-Reminder.
- **Documents RH** (Type: Relation vers GDrive via WF-GDrive-Linker ou Files & Media avec stockage Notion).
- **Préférences Communication Interne** (Type: Select). Utilisé par WF-Notification-Dispatcher pour comms RH.

#### Agence_Templates (Bibliothèque de modèles)
- **Nom Template** (Type: Title).
- **Type** (Type: Select). Utilisé par les workflows N8N pour récupérer le bon template (ex: WF-Booking-Prospection cherche Type="Email Prospection").
- **Contenu** (Type: Text - Markdown/HTML ou Files & Media pour .docx/.pdf). Si texte, N8N peut l'utiliser directement. Si fichier, N8N doit le télécharger.

### 1.4. Relations Notion Cohérentes et Stratégiques (Détails Techniques)

**Objectif :** Créer des liens logiques pour la navigation, l'agrégation de données (Rollups) et fournir du contexte aux workflows N8N et au CMS.

**Exemples (avec type de Rollup) :**
- **Agence_Lieux_Structures <-> [Artiste]_Agenda_Booking** (Relation: Concerts dans ce lieu, Rollup sur Agence_Lieux_Structures: countall() -> Nombre total concerts agence).
- **Agence_Contacts <-> [Artiste]_LOT_Booking** (Relation: Opportunités avec ce contact, Rollup sur Agence_Contacts: percent_per_group("Statut", "DEAL") -> Taux de Deal avec ce contact).
- **Agence_HR_Personnel <-> [Artiste]_Tâches** (Relation: Tâches assignées). Permet vue "Mes Tâches" pour employés.
- **Agence_Finance <-> [Artiste]_Projets** (Relation: Dépenses Projet). Rollup sur [Artiste]_Projets: sum("Montant") -> Total Dépenses Projet.

**Considérations :** Limiter le nombre de relations/rollups complexes pour maintenir la performance de Notion. Utiliser des relations bidirectionnelles judicieusement.

### 1.5. Conventions de Nommage, Validation Rigoureuse & Qualité Données

#### Nommage
Établir un document de conventions strict pour :
- **Bases de données :** [Scope]_[Entité] (ex: Agence_Contacts, Gribitch_LOT_Booking).
- **Propriétés :** CamelCase ou Snake_Case (être cohérent), préfixe optionnel pour type/fonction (ex: link_GCalEvent, config_N8N).
- **Pages Titre :** Format standardisé (ex: [Nom Contact] - [Société], [Date] - [Nom Lieu] - [Artiste]).

#### Validation Notion
Utiliser les types de propriétés (Email, URL, Phone, Date, Number). Formules pour validations simples (ex: prop("Date Fin") > prop("Date Début")). Utiliser Person pour relations vers Agence_Équipe. Les validations complexes (regex, unicité conditionnelle) ne sont pas possibles nativement.

#### Validation N8N (WF-Data-Quality-Checker)
- **Trigger :** Cron (ex: quotidien/hebdomadaire).
- **Logique :**
  1. Lire les bases critiques (Agence_Contacts, Agence_Lieux_Structures...).
  2. Pour chaque item, appliquer des règles dans un Code node (JavaScript avec potentiellement des libs comme validator.js) :
     - Format Email/URL/Phone (Regex/libs).
     - Champs obligatoires non vides.
     - Cohérence dates.
     - Détection de doublons potentiels (ex: similarité nom/email via string-similarity ou autre algo simple).
     - Vérification existence relations clés.
     - Validation structure JSON dans champs Text (ex: N8N Config).
  3. Si anomalies détectées, formater un rapport/tâche.
  4. Utiliser WF-Notion-Helper pour créer une page dans Agence_Data_Quality_Issues (ou Agence_Tâches_Admin) avec détails de l'anomalie et lien vers l'item Notion concerné.

#### Qualité Données
Responsabilisation via vues Notion filtrées ("Contacts sans email", "Lieux sans fiche tech", "Deals sans date GCal"). Intégrer la validation comme étape dans les processus métier (ex: un Booker doit valider un contact avant de l'utiliser en prospection).

### 1.6. Sécurité et Gestion Fine des Accès Notion

#### Permissions Notion
- **Niveau Workspace :** Définir admins généraux.
- **Niveau Teamspace/Espace :** Isoler données par artiste/fonction (RH, Finance). Inviter utilisateurs avec rôle approprié (Member, Guest).
- **Niveau Page/Database :** Affiner permissions (Full access, Can edit, Can comment, Can view). Utiliser pour restreindre accès aux bases sensibles (Agence_HR_Personnel, Agence_Finance).
- **Limitations :** Pas de permissions au niveau propriété nativement. Pas de véritable sécurité au niveau ligne (un utilisateur avec accès DB voit tout).

#### Groupes d'utilisateurs
Créer groupes Notion (Booking Team, Managers, RH Admins, Artiste Gribitch Members) pour simplifier l'attribution des permissions aux espaces/pages.

#### Accès Intégration N8N
- Créer un token d'intégration Notion spécifique pour N8N.
- Partager EXPLICITEMENT et MINIMALEMENT les bases de données nécessaires avec cette intégration. Ne pas donner accès à tout le workspace.
- Envisager plusieurs tokens N8N si des niveaux de privilèges différents sont requis par les workflows (ex: un token lecture seule pour reporting, un token écriture pour booking). Stocker ces tokens de manière sécurisée dans les Credentials N8N.

#### Audit
Utiliser l'Audit Log de Notion (si plan Enterprise) pour surveiller les accès et modifications sensibles. Compléter par logs N8N (Agence_Monitoring_N8N) et logs CMS (Pilier 4). Révisions périodiques manuelles des partages.

## 2. Stockage Documentaire Centralisé et Structuré (Google Drive)

**Objectif Technique :** Fournir un système de fichiers fiable, versionné et accessible via API pour les documents non structurés ou binaires (contrats signés, fiches techniques, assets promo, masters audio...).

### 2.1. Arborescence Logique (Détaillée)

La structure proposée est logique et granulaire. Elle permet une bonne organisation et facilite la gestion des permissions au niveau dossier.

```
Agence/
├── Admin_Finance/ (Factures, Bilans...)
├── Admin_HR/ (Contrats équipe, Politiques...)
├── Admin_Legal/ (Statuts, Assurances...)
├── Marketing_Templates/ (Logos, Chartes...)
└── Artistes/
    └── [Nom Artiste]/
        ├── 01_Booking/ (Offres, Contrats signés, Riders...)
        ├── 02_Production/
        │   ├── [Nom Projet Album]/ (Masters, Textes, Crédits...)
        │   └── [Nom Projet Clip]/ (Rushs, Storyboard...)
        ├── 03_Promotion/ (Press Kits, Photos HD, Logos Artiste, Communiqués...)
        ├── 04_Technique/ (Fiches Tech, Plans de scène...)
        ├── 05_Legal_Admin/ (Contrats Label/Edition, Sacem...)
        └── 06_Archives/
```

**Considération :** Assurer la création automatique de cette arborescence pour chaque nouvel artiste via WF-HR-Onboarding ou un workflow dédié.

### 2.2. Nommage Cohérent & Versioning

**Technique :** Appliquer la convention de nommage via les workflows N8N qui uploadent/gèrent les fichiers (WF-Contract-Archiver, WF-PressKit-Generator). Utiliser les fonctions de date et de manipulation de chaînes N8N/JS.

**Versioning :** Google Drive gère le versioning automatiquement. La convention de nommage (_V1, _V2) est pour la clarté humaine et pour pouvoir référencer une version spécifique si besoin.

### 2.3. Intégration N8N Robuste (Détails Techniques)

#### WF-Contract-Archiver
- **Trigger :** Notion Trigger (sur update de page [Artiste]_Contrats où Statut = "Signé") ou Webhook depuis CMS.
- **Étapes N8N :**
  1. Read Trigger Data: Récupérer l'ID de la page Notion et le champ Fichier/URL du contrat.
  2. Get Notion Page: Récupérer les détails de la page (Nom artiste, Nom contrat...).
  3. WF-Core-Config: Obtenir gDriveFolderId de l'artiste.
  4. Google Drive Node (List): Vérifier si le sous-dossier 01_Booking/Contrats Signés/ existe dans le dossier artiste.
  5. IF Node: Si dossier n'existe pas -> Google Drive Node (Create Folder).
  6. HTTP Request Node (ou Notion Node Get Block si fichier uploadé sur Notion): Télécharger le fichier contrat depuis Notion/URL.
  7. Set Node: Construire le nom de fichier final selon la convention.
  8. Google Drive Node (Upload): Uploader le fichier dans le dossier cible, avec le nom final. Gérer les conflits si fichier existe déjà (renommer, écraser?).
  9. Google Drive Node (Get): Récupérer les métadonnées du fichier uploadé, notamment webViewLink ou alternateLink.
  10. WF-Notion-Helper (Update Page): Mettre à jour la page Notion [Artiste]_Contrats avec le lien GDrive permanent dans un champ Lien GDrive Contrat Signé (Type: URL).
  11. WF-Monitoring (Log): Logger succès ou échec avec détails.

#### WF-PressKit-Generator
- **Trigger :** Manual Trigger, Cron, ou Webhook depuis CMS.
- **Étapes N8N :**
  1. WF-Core-Config: Obtenir IDs Notion/GDrive artiste.
  2. Notion Node (Get Page/DB): Récupérer bio, liens streaming depuis Agence_Artistes ou base dédiée.
  3. Google Drive Node (List/Download): Récupérer photos HD, logo, fiche tech depuis les dossiers GDrive appropriés (03_Promotion, 04_Technique).
  4. Set Node: Organiser les données récupérées.
  5. Assemblage PDF/ZIP :
     - **Option A (API Externe) :** HTTP Request Node vers service type PDFMonkey, Docupilot, etc. Envoyer les données structurées (texte, liens images) pour génération PDF.
     - **Option B (ZIP) :** Si simple assemblage de fichiers -> Créer un dossier temporaire, télécharger tous les assets dedans, utiliser un Execute Command Node (si N8N auto-hébergé) pour zipper le dossier, puis uploader le ZIP.
     - **Option C (Code Node + Libs) :** Si N8N auto-hébergé, utiliser un Code node avec des librairies JS (ex: pdf-lib pour PDF, jszip pour ZIP). Complexe.
  6. Google Drive Node (Upload): Uploader le PDF/ZIP généré dans Artistes/[Nom Artiste]/03_Promotion/PressKits/ avec nommage versionné.
  7. Google Drive Node (Get): Récupérer le lien du fichier généré.
  8. WF-Notion-Helper (Update Page): Mettre à jour le champ Lien Dernier Press Kit (Type: URL) dans Agence_Artistes.
  9. WF-Monitoring (Log).

#### WF-GDrive-Permissions-Manager
- **Trigger :** Webhook depuis CMS/Système RH lors d'onboarding/offboarding.
- **Input :** `{ "userEmail": "...", "artistFolderId": "...", "permissionRole": "viewer/commenter/editor/owner/none" }`.
- **Étapes N8N :**
  1. Read Trigger Data.
  2. Google Drive Node (Manage Permissions): Appliquer le rôle spécifié au userEmail sur le artistFolderId (et potentiellement ses sous-dossiers - vérifier options de propagation). Gérer le cas none pour supprimer les permissions.
  3. WF-Monitoring (Log): Logger l'action effectuée.

**Sécurité :** Ce workflow est critique. Le webhook doit être sécurisé. Le credential Google utilisé par N8N doit avoir les droits suffisants pour gérer les permissions.
