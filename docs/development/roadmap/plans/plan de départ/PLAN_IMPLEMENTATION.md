# Plan d'Implémentation du Workflow "Email Sender 1"

## Philosophie Générale

- **Corriger d'abord**: Priorité à la réparation des flux de données cassés et des logiques incohérentes dans la partie active (prospection).
- **Clarifier & Simplifier**: Rendre le flux actuel plus lisible et logique.
- **Structurer pour l'Avenir**: Utiliser des Sticky Notes et une disposition claire pour délimiter les phases (actuelles et futures).
- **IA Stratégique**: Intégrer l'IA là où elle apporte une valeur ajoutée claire (génération de contenu, analyse des réponses).
- **Configuration Directe**: Configurer les IDs, credentials et paramètres spécifiques directement dans chaque nœud.

## Phase 0: Suppression du Nœud de Configuration Globale

### Action
- Supprimer le nœud Set Global Config.

### Objectif
- Simplifier le workflow et permettre le test pas-à-pas (Test Step) sans dépendance à un nœud de configuration initial.

### Implémentation
- Retirer le nœud Set Global Config du canvas.
- Configurer manuellement tous les paramètres directement dans les nœuds concernés.

### Avantages
- Débogage plus facile
- Compréhension directe de la configuration de chaque nœud
- Pas besoin de référencer un nœud central

## Phase 1: Gestion des Disponibilités (Correction Critique)

### Action
- Corriger la fusion des indisponibilités Notion & Google Calendar.

### Problème
- Le nœud "Filtrer créneaux" ne reçoit que les données de Google Calendar; les indisponibilités Notion sont ignorées.

### Solution Proposée

#### 1. Nœud Google Calendar (Get Events)
- Configurer directement le Credential approprié
- Entrer directement l'ID du Calendrier: f4641f... (BOOKING1)

#### 2. Nœud Notion (Get Database Pages pour Dispo Membres)
- Configurer directement le Credential approprié
- Entrer directement l'ID de la Base de Données: 1c5814... (Dispo Membres)
- Configurer les filtres et tris pour récupérer les indisponibilités pertinentes

#### 3. Nouveau Nœud Code (Consolider Indisponibilités)
- Connecter la sortie du nœud Google Calendar à l'entrée 0
- Connecter la sortie du nœud Notion (Dispo Membres) à l'entrée 1
- Logique du Code:

```javascript
const googleEvents = $input.all(0); // Items from Google Calendar
const notionPages = $input.all(1); // Items from Notion Dispo Membres

const busyDatesSet = new Set();

// Process Google Calendar Events
googleEvents.forEach(item => {
    // Adjust based on actual GCal node output structure for start/end dates
    const startDate = item.json.start?.date || item.json.start?.dateTime?.split('T')[0];
    const endDate = item.json.end?.date || item.json.end?.dateTime?.split('T')[0];

    if (startDate) {
        let current = new Date(startDate);
        // For multi-day events, add all dates in the range. Handle end date inclusivity.
        // GCal 'date' type end date is exclusive, dateTime is inclusive. Adjust logic if needed.
        const end = new Date(endDate || startDate);
        // If it's an all-day event (date type), the end date is exclusive.
        const endTarget = item.json.start?.date ? new Date(end.setDate(end.getDate() -1)) : end;

        while (current <= endTarget) {
             busyDatesSet.add(current.toISOString().split('T')[0]); // Format YYYY-MM-DD
             current.setDate(current.getDate() + 1);
        }
    }
});

// Process Notion Pages (Indisponibilités Membres)
notionPages.forEach(item => {
    // Adjust 'Date Indispo' based on your actual Notion property name
    const dateProp = item.json.properties['Date Indispo']?.date;
    if (dateProp && dateProp.start) {
        // Assuming simple date property, not range for now
         busyDatesSet.add(dateProp.start); // Format YYYY-MM-DD
         // If it's a date range in Notion, add logic similar to GCal multi-day
    }
});

// Return a single item with the unique busy dates array
return [{ json: { busyDates: Array.from(busyDatesSet) } }];
```

#### 4. Modifier le Nœud Suivant (ancien Filtrer créneaux)
- Renommer en "Calculer Plages Libres"
- Adapter le Code:

```javascript
// Assuming the input comes from 'Consolider Indisponibilités'
const inputItem = items[0];
const busyDates = new Set(inputItem.json.busyDates || []);

const availableSlots = [];
const today = new Date();
const numberOfDaysToCheck = 90; // Or however many days you want to project

for (let i = 0; i < numberOfDaysToCheck; i++) {
    const currentDate = new Date(today);
    currentDate.setDate(today.getDate() + i);
    const formattedDate = currentDate.toISOString().split('T')[0]; // YYYY-MM-DD

    // Check if the date is NOT in the busy set AND is a Friday or Saturday
    const dayOfWeek = currentDate.getDay(); // 0 = Sunday, 6 = Saturday
    if (!busyDates.has(formattedDate) && (dayOfWeek === 5 || dayOfWeek === 6)) {
        availableSlots.push({ json: { date: formattedDate, status: 'available' } });
    }
}

if (availableSlots.length === 0) {
  // Handle the case where no slots are found, maybe return an empty array
  // or a specific message item? For now, returning empty array.
  return [];
}

// Return the list of available Friday/Saturday slots
return availableSlots;
```

#### 5. Nettoyage
- Supprimer ou déconnecter clairement (avec une note) les anciens nœuds:
  - Analyse et sync...
  - Créer page Notion
  - Créer event Google

## Phase 2: Génération & Envoi des Emails (Corrections & Logique IA)

### Action 1: Connecter les disponibilités dynamiques à l'IA

#### Problème
- L'IA utilisait des dates statiques.

#### Solution
1. Supprimer les nœuds statiques:
   - Set - Dates GCal Potentielles
   - Set - Dates Bloquées Membres

2. Connecter la sortie de "Calculer Plages Libres" à l'entrée du nœud qui prépare le prompt IA

3. Modifier le nœud "Prepare DeepSeek Request" (Code):
   - Recevoir la liste des dates disponibles
   - Extraire les dates: `const availableDates = items.map(item => item.json.date);`
   - Construire le message pour l'API OpenRouter en incluant ces dates

4. Nœud d'appel IA (OpenRouter, HTTP Request...):
   - Configurer directement le Credential OpenRouter approprié
   - Configurer directement le Modèle IA souhaité (deepseek/deepseek-chat)

### Action 2: Réparer la logique de fusion IA + Contacts

#### Problème
- Le Merge en combineByPosition ne fonctionne pas bien.

#### Solution
1. Exécuter le flux IA une seule fois en amont:
   - Prepare DeepSeek Request → Call DeepSeek AI → Set Message Généré IA

2. Nœud Notion (Get Database Pages pour Contacts):
   - Renommer si besoin (ex: Get Notion Contacts LOT1)
   - Configurer directement le Credential Notion approprié
   - Entrer directement l'ID de la Base de Données: 1c4814... (LOT1)
   - Ajouter les filtres nécessaires (ex: Etat du mail != "PROSPECT📨 Envoyé")

3. Nouveau Nœud Code (Associer Message IA aux Contacts):
   - Connecter la sortie de Set Message Généré IA (1 item avec aiMessage) à l'input 0
   - Connecter la sortie de Get Notion Contacts LOT1 (N items) à l'input 1
   - Logique du Code:

```javascript
// Get the single AI message generated earlier
const aiMessageItem = $input.all(0)[0]; // Assuming the AI message node is connected to input 0
if (!aiMessageItem) {
  throw new Error("Le message IA n'a pas été reçu sur l'entrée 0.");
}
const aiMessage = aiMessageItem.json.aiMessage; // Adjust '.aiMessage' if the property name is different

// Get all the contact items
const contacts = $input.all(1); // Assuming contacts node is connected to input 1

// Return a new item for each contact, merging contact data and the AI message
return contacts.map(contact => {
  // Ensure we don't overwrite existing 'json' properties if contact.json exists
  const contactData = contact.json || {};
  return {
    json: {
      ...contactData, // Spread existing contact data
      // Add Notion page ID for later update step
      notionPageId: contact.json.id, // Assuming the Notion node output includes 'id'
      // Add contact properties needed for personalization
      contactEmail: contact.json.properties['E-mail']?.email, // Adjust property name 'E-mail'
      contactName: contact.json.properties['Prénom']?.title[0]?.plain_text, // Adjust 'Prénom'
      venueName: contact.json.properties['Structure']?.title[0]?.plain_text, // Adjust 'Structure'
      // Add the generic AI message
      aiMessage: aiMessage
    }
  };
});
```

4. Adapter le Nœud Personnalisation Message (Code):
   - Recevoir des items contenant: notionPageId, contactEmail, contactName, venueName, aiMessage
   - Ajuster le code pour utiliser item.json.aiMessage comme base et injecter les champs de personnalisation
   - Retourner un item contenant l'HTML final du message

### Action 3: Simplifier et corriger la séquence d'envoi

#### Problème
- Nœuds redondants ou mal placés.

#### Solution
1. Flux Principal:
   - Associer Message IA aux Contacts → Personnalisation Message → Get Gmail Template → Inject Message into HTML → Create Final Gmail Draft → Update Notion Status → Wait Anti-Spam

2. Nœud Get Gmail Template:
   - Configurer directement le Credential Gmail approprié
   - Utiliser l'opération Get ou List avec un filtre sur le Sujet

3. Nœud Inject Message into HTML (Code, si besoin):
   - Prendre l'HTML du template (Input 0) et le contenu personnalisé (Input 1)
   - Remplacer un placeholder dans l'HTML du template
   - Retourner l'HTML final avec les autres données nécessaires

4. Nœud d'Action Gmail (Create Draft - Recommandé pour test):
   - Configurer directement le Credential Gmail approprié
   - Opération: Create
   - Resource: Draft
   - To: `{{ $json.contactEmail }}`
   - Subject: Le sujet souhaité
   - Message Body Type: HTML
   - Message: `{{ $json.finalHtml }}`

5. Nœud Notion (Update Page):
   - Renommer en Update Notion Status
   - Configurer directement le Credential Notion approprié
   - Opération: Update
   - Resource: Database Page
   - Page ID: `{{ $json.notionPageId }}`
   - Propriétés: Ajouter la propriété à mettre à jour (ex: Etat du mail)

6. Nœud Wait:
   - Renommer en Wait Anti-Spam
   - Configurer le délai souhaité (ex: 30 secondes)
   - Connecter après Update Notion Status

7. Nettoyage:
   - Supprimer les nœuds:
     - Rédac draft
     - verif délai entre les envois
     - Envoi du msg ssi délai respecté avec attente réponse
     - Fin Phase 1

## Phase 3 et Suivantes: Structuration pour l'Avenir

### Action
- Délimiter visuellement les phases futures.

### Problème
- Les nœuds des phases 3+ sont présents mais déconnectés et mélangés.

### Solution
- Regrouper physiquement les nœuds par phase future
- Utiliser des grands Sticky Notes colorés pour encadrer chaque groupe
- Placer le nœud déclencheur prévu pour chaque phase au début du groupe (désactivé pour l'instant)

## Améliorations & Potentiel IA

### Points d'amélioration par IA plus avancée
- **Analyse des Réponses** (Phase 4 Future): Candidat idéal pour intégration DeepSeek dans un nœud Code
- **Génération de Remerciements** (Phase 9 Future): IA pour email personnalisé
- **Interactions complexes**: Pour les phases nécessitant des décisions sophistiquées

### Recommandation
- Implémenter d'abord le flux de base corrigé
- Attaquer ensuite l'analyse des réponses (Phase 4)

## Prochaines Étapes Immédiates

1. Appliquer les corrections des Phases 1 et 2 (Disponibilités, Génération/Envoi Email)
2. Tester soigneusement ce flux corrigé de prospection:
   - Vérifier que les nœuds GCal et Notion récupèrent les bonnes données
   - Vérifier que les bonnes disponibilités sont calculées et utilisées dans le prompt IA
   - Vérifier que le nœud IA utilise le bon modèle/credential et génère un message
   - Vérifier que le message IA est correctement associé à chaque contact
   - Vérifier que les brouillons Gmail sont créés correctement pour chaque contact
   - Vérifier que le statut Notion est mis à jour pour chaque contact
   - Vérifier que le délai Wait fonctionne entre les traitements
3. Une fois la prospection stable, commencer à connecter et implémenter la Phase 3 (Suivi des Réponses)
