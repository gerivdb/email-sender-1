# PILIER 1 : La Donnée Stratégique

## Table des matières

1. [PILIER 1 : La Donnée Stratégique](#section-1)

    1.1. [. Hub de Données Notion (Le Cerveau Opérationnel et Relationnel de l'Agence)](#section-2)

        1.1.1. [. Base Agence_Artistes (Master List - Référentiel Central Absolu)](#section-3)

        1.1.2. [. Espaces Notion par Artiste (Isolation & Collaboration Opérationnelle)](#section-4)

            1.1.2.1. [[Artiste]_LOT_Booking (DB principale du cycle de vente)](#section-5)

            1.1.2.2. [[Artiste]_Agenda_Booking (DB des événements confirmés)](#section-6)

            1.1.2.3. [[Artiste]_Dispo_Membres (DB des indisponibilités)](#section-7)

            1.1.2.4. [[Artiste]_Projets (DB de suivi de production)](#section-8)

            1.1.2.5. [[Artiste]_Contrats (DB des contrats spécifiques)](#section-9)

            1.1.2.6. [[Artiste]_Tâches (DB de gestion de tâches)](#section-10)

            1.1.2.7. [[Artiste]_Merch (DB de stock)](#section-11)

            1.1.2.8. [[Artiste]_Social_Content (DB calendrier éditorial)](#section-12)

            1.1.2.9. [[Artiste]_Feedback (DB retours qualitatifs)](#section-13)

        1.1.3. [. Bases de Données Métier Transversales (Vision 360° Agence)](#section-14)

            1.1.3.1. [Agence_Contacts (CRM Central)](#section-15)

            1.1.3.2. [Agence_Lieux_Structures (Base de données lieux)](#section-16)

            1.1.3.3. [Agence_Équipe (Annuaire interne agence)](#section-17)

            1.1.3.4. [Artiste_Membres (Annuaire musiciens/techniciens par artiste)](#section-18)

            1.1.3.5. [Agence_Monitoring_N8N (Log des exécutions N8N)](#section-19)

            1.1.3.6. [Agence_Finance (Suivi financier global)](#section-20)

            1.1.3.7. [Agence_HR_Personnel (Base RH centrale - Accès Ultra-Restreint)](#section-21)

            1.1.3.8. [Agencedevelopment/templates (Bibliothèque de modèles)](#section-22)

        1.1.4. [. Relations Notion Cohérentes et Stratégiques (Détails Techniques)](#section-23)

            1.1.4.1. [Nommage](#section-24)

            1.1.4.2. [Validation Notion](#section-25)

            1.1.4.3. [Validation N8N (WF-Data-Quality-Checker)](#section-26)

            1.1.4.4. [Qualité Données](#section-27)

            1.1.4.5. [Permissions Notion](#section-28)

            1.1.4.6. [Groupes d'utilisateurs](#section-29)

            1.1.4.7. [Accès Intégration N8N](#section-30)

            1.1.4.8. [Audit](#section-31)

    1.2. [. Stockage Documentaire Centralisé et Structuré (Google Drive)](#section-32)

        1.2.1. [. Arborescence Logique (Détaillée)](#section-33)

        1.2.2. [. Nommage Cohérent & Versioning](#section-34)

            1.2.2.1. [WF-Contract-Archiver](#section-35)

            1.2.2.2. [WF-PressKit-Generator](#section-36)

            1.2.2.3. [WF-GDrive-Permissions-Manager](#section-37)

## 1. PILIER 1 : La Donnée Stratégique <a name='section-1'></a>

*Centralisée, Structurée, Validée, Sécurisée et Accessible (Fondation Notion & Extensions)*

Ce pilier établit la fondation sur laquelle reposent tous les processus automatisés (Pilier 2), l'intelligence augmentée (Pilier 3) et les interfaces utilisateur (Pilier 4). Sa robustesse, sa cohérence et sa sécurité sont non négociables. Notion est choisi comme hub principal pour sa flexibilité et ses capacités relationnelles, complété par Google Drive pour le stockage documentaire structuré.

### 1.1. . Hub de Données Notion (Le Cerveau Opérationnel et Relationnel de l'Agence) <a name='section-2'></a>

**Objectif Technique :** Modéliser les entités métier clés de l'agence (Artistes, Contacts, Lieux, Projets, RH...) sous forme de bases de données Notion interconnectées, fournissant une API implicite (via l'API Notion) pour les opérations CRUD et la lecture par N8N et le CMS.

#### 1.1.1. . Base Agence_Artistes (Master List - Référentiel Central Absolu) <a name='section-3'></a>

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
```plaintext
> **Validation :** La structure et la validité de ce JSON doivent être vérifiées (manuellement ou via WF-Data-Quality-Checker). Une erreur ici bloque tous les workflows N8N pour l'artiste.

- **Lien Espace Notion, Lien Dossier GDrive, Lien Portail CMS** (Type: URL). Utilitaires pour navigation rapide depuis Notion ou le CMS.
- **Contrat Management** (Type: Relation, Base liée: [Artiste]_Contrats, Limite: 1). Lien vers le contrat cadre principal. Utilisé par WF-HR-Compliance-Reminder.
- **Résumé Financier Clé** (Type: Rollup, Relation: Agence_Finance via [Artiste]_Projets ou [Artiste]_Agenda_Booking, Calcul: Ex: sum(Revenus) - sum(Dépenses) filtré sur l'année en cours). Pour dashboarding rapide (CMS, Vue Manager). Attention à la performance sur gros volumes.

**Importance Technique :** Cette base est le point d'injection de configuration pour N8N. Sa mise à jour correcte est critique lors de l'onboarding d'un nouvel artiste. WF-Core-Config dépend entièrement de la récupération et du parsing correct du champ N8N Config.

#### 1.1.2. . Espaces Notion par Artiste (Isolation & Collaboration Opérationnelle) <a name='section-4'></a>

**Structure Technique :** Utilisation des "Teamspaces" Notion ou d'une structure de pages partagées pour isoler les données opérationnelles par artiste. Les permissions sont gérées au niveau de l'espace/page racine de l'artiste (voir 1.6).

**Bases Types par Artiste (Détails Techniques) :**

##### 1.1.2.1. [Artiste]_LOT_Booking (DB principale du cycle de vente) <a name='section-5'></a>

- **AI Sentiment Réponse** (Type: Select). Populated by WF-Booking-Response-Handler (Team 1/3).
- **AI Résumé Réponse** (Type: Text). Populated by WF-Booking-Response-Handler (Team 1/3).
- **Lien GCal Event** (Type: URL). Populated by WF-Booking-Deal-Processor. Permet lien direct vers l'event GCal.
- **Commission Booker** (Type: Number, Format: Pourcentage/Montant). Utilisé par WF-HR-Payroll-Prep.
- **Statut Paiement Dépôt** (Type: Select). Mis à jour manuellement ou via futur WF Finance. Peut déclencher des rappels.

##### 1.1.2.2. [Artiste]_Agenda_Booking (DB des événements confirmés) <a name='section-6'></a>

- **Heure Arrivée, Heure Soundcheck, etc.** (Type: Date avec Time). Utilisé par WF-Musician-Itinerary-Sender.
- **Contact Lieu Jour J** (Type: Text ou Relation -> Agence_Contacts). Utilisé par WF-Musician-Itinerary-Sender.
- **Lien Itinéraire** (Type: URL). Potentiellement généré par Team 4 et stocké par N8N.
- **Statut Logistique** (Type: Select). Mis à jour manuellement ou via complétion des tâches dans [Artiste]_Tâches (Rollup?).
- **Feedback Post-Concert** (Type: Relation, Base liée: [Artiste]_Feedback).

##### 1.1.2.3. [Artiste]_Dispo_Membres (DB des indisponibilités) <a name='section-7'></a>

- **Validé Par Manager** (Type: Checkbox). Peut servir de trigger (via webhook Notion ou scan N8N) pour que WF-Disponibilites prenne en compte l'indispo.
- **Impact Booking** (Type: Select). Utilisé par WF-Disponibilites pour évaluer si la date est réellement bloquée.

##### 1.1.2.4. [Artiste]_Projets (DB de suivi de production) <a name='section-8'></a>

- **Budget Prévisionnel vs Réel** (Type: Formula, nécessite champs Number pour prévisionnel et rollup des dépenses depuis Agence_Finance).
- **Tâches Principales** (Type: Relation, Base liée: [Artiste]_Tâches).
- **Fichiers Clés** (Type: Relation vers une DB [Artiste]_GDrive_Links? Ou Files & Media? Ou URL vers GDrive?). Stratégie à définir pour lier Notion à GDrive de manière robuste via N8N. Un WF WF-GDrive-Linker pourrait être nécessaire pour synchroniser les fichiers GDrive pertinents vers une DB Notion dédiée avec leurs liens.

##### 1.1.2.5. [Artiste]_Contrats (DB des contrats spécifiques) <a name='section-9'></a>

- **Date Expiration** (Type: Date). Trigger pour WF-HR-Compliance-Reminder.
- **Renouvellement Auto** (Type: Checkbox). Logique pour WF-HR-Compliance-Reminder.
- **Alertes Clés** (Type: Date). Peut être mis à jour par N8N (ex: alerte J-30).
- **Parties Signataires** (Type: Text ou Relation -> Agence_Contacts / Agence_Lieux_Structures).

##### 1.1.2.6. [Artiste]_Tâches (DB de gestion de tâches) <a name='section-10'></a>

- **Responsable** (Type: Relation, Bases liées: Agence_Équipe, Artiste_Membres). Permet assignation flexible. Utilisé par WF-Task-Reminder.
- **Échéance** (Type: Date). Trigger pour WF-Task-Reminder.
- **Statut** (Type: Select). Peut déclencher d'autres workflows à la complétion.
- **Projet Lié** (Type: Relation, Base liée: [Artiste]_Projets).
- **Priorité** (Type: Select ou Number). Pour tri et priorisation (manuelle ou CMS).

##### 1.1.2.7. [Artiste]_Merch (DB de stock) <a name='section-11'></a>

- **Stock Actuel** (Type: Number). Mis à jour manuellement ou via future intégration e-commerce/POS.
- **Seuil Alerte Stock** (Type: Number). Comparé au Stock Actuel par WF-Merch-Stock-Alert (Cron N8N).

##### 1.1.2.8. [Artiste]_Social_Content (DB calendrier éditorial) <a name='section-12'></a>

- **Plateforme** (Type: Select).
- **Visuel/Vidéo** (Type: Files & Media ou URL vers GDrive).
- **Statut** (Type: Select). Trigger pour WF-Social-Post-Scheduler quand "Prêt".
- **Performance** (Type: Text). Mis à jour manuellement ou via future intégration API réseaux sociaux.

##### 1.1.2.9. [Artiste]_Feedback (DB retours qualitatifs) <a name='section-13'></a>

- **Type, Source** (Type: Select).
- **Note** (Type: Number). Utilisé par Team 3 pour analyse de sentiment/satisfaction.
- **Commentaire** (Type: Text). Source pour analyse qualitative Team 3.

#### 1.1.3. . Bases de Données Métier Transversales (Vision 360° Agence) <a name='section-14'></a>

**Objectif Technique :** Centraliser les données partagées entre artistes et fonctions agence, évitant la duplication et permettant des analyses et opérations transversales.

**Bases Clés (Détails Techniques) :**

##### 1.1.3.1. Agence_Contacts (CRM Central) <a name='section-15'></a>

- **Source Contact** (Type: Select). Pour analyse efficacité canaux acquisition.
- **Date Dernier Contact N8N** (Type: Date). Mis à jour par WF-Booking-Prospection, WF-Booking-Response-Handler, etc. pour suivi activité.
- **Consentement GDPR** (Type: Checkbox + Date de consentement). Vérifié par WF-Booking-Prospection avant envoi email. Doit être géré rigoureusement (processus de collecte et de retrait).
- **Préférences Communication** (Type: Multi-Select). Utilisé par WF-Notification-Dispatcher.
- **Notes Confidentielles** (Type: Text). Accès restreint via permissions Notion (si possible au niveau propriété) ou géré via CMS (qui filtre l'accès).

##### 1.1.3.2. Agence_Lieux_Structures (Base de données lieux) <a name='section-16'></a>

- **Contact Booking/Technique/Com** (Type: Relation, Base liée: Agence_Contacts).
- **Lien Fiche Technique** (Type: URL vers GDrive ou Files & Media). Utilisé par Team 4.
- **Conditions Accueil Détaillées, Historique Incidents** (Type: Text). Source pour RAG Team 4.
- **Accessibilité PMR** (Type: Select). Filtre important pour certains artistes/publics.
- **Notes Internes Booker/Tech** (Type: Text). Pour partage d'infos équipe.

##### 1.1.3.3. Agence_Équipe (Annuaire interne agence) <a name='section-17'></a>

- **Spécialisations** (Type: Multi-Select). Pour routage tâches/infos.
- **Accès CMS/Notion** (Type: Text). Documentation manuelle des rôles/permissions.
- **Contact Urgence** (Type: Text).
- **Date Entrée/Sortie** (Type: Date). Pour processus Onboarding/Offboarding (WF-HR-Manager).
- Relation vers Agence_HR_Personnel pour lier profil opérationnel et RH.

##### 1.1.3.4. Artiste_Membres (Annuaire musiciens/techniciens par artiste) <a name='section-18'></a>

- **Contact Principal** (Type: Email, Phone).
- **Rôle Scène/Admin/Compo** (Type: Text).
- **Allergies/Régime** (Type: Text). Donnée sensible (santé). Nécessite consentement explicite et accès restreint. Utilisé pour générer briefs catering.
- **Préférences Communication** (Type: Select). Utilisé par WF-Notification-Dispatcher.
- Relation vers Agence_HR_Personnel si contrat direct avec l'agence.

##### 1.1.3.5. Agence_Monitoring_N8N (Log des exécutions N8N) <a name='section-19'></a>

- **Workflow ID, Execution ID** (Type: Text). Récupérés depuis les variables d'environnement N8N ($workflow.id, $execution.id).
- **Sévérité** (Type: Select). Définit l'urgence et le type de notification (WF-Notification-Dispatcher).
- **Données Contextuelles** (Type: Text - JSON stringifié). Contient les données de l'item N8N au moment de l'erreur/log. Attention à la taille et aux données sensibles.
- **Action Corrective Prise** (Type: Text). Mis à jour manuellement après résolution.
- Utilisé par Team 8 pour analyse performance/erreurs.

##### 1.1.3.6. Agence_Finance (Suivi financier global) <a name='section-20'></a>

- **Facture Liée** (Type: Files & Media ou URL vers GDrive).
- **Centre de Coût** (Type: Select). Pour reporting financier.
- **Statut Facturation** (Type: Select). Peut déclencher des workflows de relance.
- **Méthode Paiement** (Type: Select/Text).

##### 1.1.3.7. Agence_HR_Personnel (Base RH centrale - Accès Ultra-Restreint) <a name='section-21'></a>

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

##### 1.1.3.8. Agencedevelopment/templates (Bibliothèque de modèles) <a name='section-22'></a>

- **Nom Template** (Type: Title).
- **Type** (Type: Select). Utilisé par les workflows N8N pour récupérer le bon template (ex: WF-Booking-Prospection cherche Type="Email Prospection").
- **Contenu** (Type: Text - Markdown/HTML ou Files & Media pour .docx/.pdf). Si texte, N8N peut l'utiliser directement. Si fichier, N8N doit le télécharger.

#### 1.1.4. . Relations Notion Cohérentes et Stratégiques (Détails Techniques) <a name='section-23'></a>

**Objectif :** Créer des liens logiques pour la navigation, l'agrégation de données (Rollups) et fournir du contexte aux workflows N8N et au CMS.

**Exemples (avec type de Rollup) :**
- **Agence_Lieux_Structures <-> [Artiste]_Agenda_Booking** (Relation: Concerts dans ce lieu, Rollup sur Agence_Lieux_Structures: countall() -> Nombre total concerts agence).
- **Agence_Contacts <-> [Artiste]_LOT_Booking** (Relation: Opportunités avec ce contact, Rollup sur Agence_Contacts: percent_per_group("Statut", "DEAL") -> Taux de Deal avec ce contact).
- **Agence_HR_Personnel <-> [Artiste]_Tâches** (Relation: Tâches assignées). Permet vue "Mes Tâches" pour employés.
- **Agence_Finance <-> [Artiste]_Projets** (Relation: Dépenses Projet). Rollup sur [Artiste]_Projets: sum("Montant") -> Total Dépenses Projet.

**Considérations :** Limiter le nombre de relations/rollups complexes pour maintenir la performance de Notion. Utiliser des relations bidirectionnelles judicieusement.

##### 1.1.4.1. Nommage <a name='section-24'></a>

Établir un document de conventions strict pour :
- **Bases de données :** [Scope]_[Entité] (ex: Agence_Contacts, Gribitch_LOT_Booking).
- **Propriétés :** CamelCase ou Snake_Case (être cohérent), préfixe optionnel pour type/fonction (ex: link_GCalEvent, config_N8N).
- **Pages Titre :** Format standardisé (ex: [Nom Contact] - [Société], [Date] - [Nom Lieu] - [Artiste]).

##### 1.1.4.2. Validation Notion <a name='section-25'></a>

Utiliser les types de propriétés (Email, URL, Phone, Date, Number). Formules pour validations simples (ex: prop("Date Fin") > prop("Date Début")). Utiliser Person pour relations vers Agence_Équipe. Les validations complexes (regex, unicité conditionnelle) ne sont pas possibles nativement.

##### 1.1.4.3. Validation N8N (WF-Data-Quality-Checker) <a name='section-26'></a>

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

##### 1.1.4.4. Qualité Données <a name='section-27'></a>

Responsabilisation via vues Notion filtrées ("Contacts sans email", "Lieux sans fiche tech", "Deals sans date GCal"). Intégrer la validation comme étape dans les processus métier (ex: un Booker doit valider un contact avant de l'utiliser en prospection).

##### 1.1.4.5. Permissions Notion <a name='section-28'></a>

- **Niveau Workspace :** Définir admins généraux.
- **Niveau Teamspace/Espace :** Isoler données par artiste/fonction (RH, Finance). Inviter utilisateurs avec rôle approprié (Member, Guest).
- **Niveau Page/Database :** Affiner permissions (Full access, Can edit, Can comment, Can view). Utiliser pour restreindre accès aux bases sensibles (Agence_HR_Personnel, Agence_Finance).
- **Limitations :** Pas de permissions au niveau propriété nativement. Pas de véritable sécurité au niveau ligne (un utilisateur avec accès DB voit tout).

##### 1.1.4.6. Groupes d'utilisateurs <a name='section-29'></a>

Créer groupes Notion (Booking Team, Managers, RH Admins, Artiste Gribitch Members) pour simplifier l'attribution des permissions aux espaces/pages.

##### 1.1.4.7. Accès Intégration N8N <a name='section-30'></a>

- Créer un token d'intégration Notion spécifique pour N8N.
- Partager EXPLICITEMENT et MINIMALEMENT les bases de données nécessaires avec cette intégration. Ne pas donner accès à tout le workspace.
- Envisager plusieurs tokens N8N si des niveaux de privilèges différents sont requis par les workflows (ex: un token lecture seule pour reporting, un token écriture pour booking). Stocker ces tokens de manière sécurisée dans les Credentials N8N.

##### 1.1.4.8. Audit <a name='section-31'></a>

Utiliser l'Audit Log de Notion (si plan Enterprise) pour surveiller les accès et modifications sensibles. Compléter par logs N8N (Agence_Monitoring_N8N) et logs CMS (Pilier 4). Révisions périodiques manuelles des partages.

### 1.2. . Stockage Documentaire Centralisé et Structuré (Google Drive) <a name='section-32'></a>

**Objectif Technique :** Fournir un système de fichiers fiable, versionné et accessible via API pour les documents non structurés ou binaires (contrats signés, fiches techniques, assets promo, masters audio...).

#### 1.2.1. . Arborescence Logique (Détaillée) <a name='section-33'></a>

La structure proposée est logique et granulaire. Elle permet une bonne organisation et facilite la gestion des permissions au niveau dossier.

```plaintext
Agence/
├── Admin_Finance/ (Factures, Bilans...)
├── Admin_HR/ (Contrats équipe, Politiques...)
├── Admin_Legal/ (Statuts, Assurances...)
├── Marketingdevelopment/templates/ (Logos, Chartes...)
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

**Considération :** Assurer la création automatique de cette arborescence pour chaque nouvel artiste via WF-HR-Onboarding ou un workflow dédié.

```plaintext
#### 1.2.2. . Nommage Cohérent & Versioning <a name='section-34'></a>

**Technique :** Appliquer la convention de nommage via les workflows N8N qui uploadent/gèrent les fichiers (WF-Contract-Archiver, WF-PressKit-Generator). Utiliser les fonctions de date et de manipulation de chaînes N8N/JS.

**Versioning :** Google Drive gère le versioning automatiquement. La convention de nommage (_V1, _V2) est pour la clarté humaine et pour pouvoir référencer une version spécifique si besoin.

##### 1.2.2.1. WF-Contract-Archiver <a name='section-35'></a>

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

##### 1.2.2.2. WF-PressKit-Generator <a name='section-36'></a>

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

##### 1.2.2.3. WF-GDrive-Permissions-Manager <a name='section-37'></a>

- **Trigger :** Webhook depuis CMS/Système RH lors d'onboarding/offboarding.
- **Input :** `{ "userEmail": "...", "artistFolderId": "...", "permissionRole": "viewer/commenter/editor/owner/none" }`.
- **Étapes N8N :**
  1. Read Trigger Data.
  2. Google Drive Node (Manage Permissions): Appliquer le rôle spécifié au userEmail sur le artistFolderId (et potentiellement ses sous-dossiers - vérifier options de propagation). Gérer le cas none pour supprimer les permissions.
  3. WF-Monitoring (Log): Logger l'action effectuée.

**Sécurité :** Ce workflow est critique. Le webhook doit être sécurisé. Le credential Google utilisé par N8N doit avoir les droits suffisants pour gérer les permissions.

