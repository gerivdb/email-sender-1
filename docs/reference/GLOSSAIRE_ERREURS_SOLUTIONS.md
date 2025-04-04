# Glossaire des Erreurs et Solutions N8N

## Sources d'Erreurs Courantes et Leurs Solutions

| Erreur | Cause racine | Solution apportée |
|--------|--------------|-------------------|
| Cannot read json of undefined | Node non connecté en input 0 | Connexion explicite faite ✅ |
| map is not a function | input1 ou input2 n'était pas un tableau | Conversion toArray(...) ajoutée ✅ |
| Message d'intention manquant | Mauvaise entrée ou fallback non prévu | Valeur par défaut message mise ✅ |

## Apprentissages Clés sur le Comportement de N8N

### Exécution et Flux de Données

#### Branche Parallèle (Exécution)
**Constat**: Une branche de workflow (ex: celle partant de Get Notion Contacts LOT1) ne s'exécute pas automatiquement si elle n'est pas connectée, directement ou indirectement, au flux de données initié par le Trigger principal (ex: Start Manual).

**Implication**: Pour que des données issues de branches différentes soient disponibles en même temps pour un node de fusion (comme Merge), toutes ces branches de départ doivent être déclenchées par le même événement initial (en connectant le Trigger à chacune).

#### Données d'Exécution (Visualisation)
**Constat**: Les compteurs X items et la couleur des "fils" (connexions) entre les nodes reflètent l'état de la dernière exécution affichée.

**Implication**: Un fil gris indique qu'aucune donnée n'a transité par cette connexion lors de cette exécution spécifique, même si le node source pourrait produire des données s'il était exécuté. Essentiel pour suivre le flux réel.

#### Exécution Basée sur les Items (Comportement par défaut)
**Constat**: La plupart des nodes N8N (Set, Code, HTTP Request...) s'exécutent une fois pour chaque item reçu sur leur entrée principale.

**Implication**: Si un node en amont produit accidentellement plusieurs items (ex: return [ {...}, {...} ] dans un node Code), tous les nodes suivants s'exécuteront plusieurs fois, propageant l'exécution multiple. La clé est de s'assurer que chaque étape produit le nombre d'items attendu (souvent 1 seul item par "logique métier").

#### Merge Node (Mode Combine By Position)
**Constat**: Ce mode est très strict. Il nécessite exactement le même nombre d'items sur ses deux (ou plus) inputs, et ces items doivent arriver dans le contexte de la même exécution globale pour être appairés (1er avec 1er, 2ème avec 2ème...).

**Implication**: Si une branche fournit 1 item et l'autre 0 (ou si les données arrivent en décalé), l'appariement échoue et l'output est vide par défaut. La synchronisation des branches via un trigger commun est souvent la solution.

#### Notion Node (Simplify Option - implicite/explicite)
**Constat**: L'activation (même si non visible dans le JSON exporté parfois) de l'option Simplify change radicalement la structure des données retournées, notamment pour les types complexes comme les Relations et les Agrégations (Rollups).

**Implication**: Avec Simplify, une agrégation d'email peut devenir directement accessible via $json['NomColonneEmail'][0], tandis que sans Simplify, il faut naviguer dans la structure complète ($json.properties['NomColonneEmail'].rollup.array[0].email). Connaître l'état de cette option est crucial pour écrire les bonnes expressions.

#### Nodes "Orphelins" (dans une Exécution Globale)
**Constat**: Les nodes ou branches non reliés au Trigger actif ne sont pas exécutés lors d'un lancement global ("Execute Workflow").

**Implication**: Cela explique pourquoi des branches entières peuvent rester "grises". Il ne s'agit pas forcément d'une erreur dans ces nodes, mais d'une absence de déclenchement dans ce contexte.

#### Test step (Bouton sur Node)
**Constat**: Conçu pour exécuter uniquement le node sélectionné, en utilisant les dernières données disponibles sur ses entrées (issues d'exécutions précédentes ou d'autres "Test step"). Permet d'isoler et de tester la logique d'un node spécifique.

**Implication**: L'erreur "Connect a trigger..." obtenue lors de son utilisation était anormale et indiquait probablement un glitch de l'interface ou de l'état du workflow, non lié au fonctionnement standard de "Test step".

#### Trigger (Rôle Fondamental)
**Constat**: Le point de départ de toute exécution automatique ou manuelle globale du workflow. C'est lui qui injecte le premier item (souvent vide pour Manual Trigger) qui initie le flux de données.

**Implication**: Pour coordonner des actions parallèles qui doivent converger, relier le Trigger à chaque point de départ de ces actions est une stratégie valide et nécessaire.

## Terminologie N8N

### Concepts Fondamentaux

#### Workflow
**Définition**: L'ensemble du processus d'automatisation que tu crées dans n8n. Il est composé de Nœuds connectés entre eux sur le Canevas.

#### Node (Nœud)
**Définition**: Un bloc fonctionnel dans un Workflow qui effectue une action spécifique. Il peut s'agir d'un Déclencheur (Trigger) ou d'un Nœud Régulier (Regular Node).

#### Trigger Node (Nœud Déclencheur)
**Définition**: Le nœud spécial qui initie l'exécution d'un Workflow. Il réagit à un événement (ex: horaire, webhook, nouvel email). Un workflow commence toujours par un trigger.

#### Regular Node (Nœud Régulier)
**Définition**: Tout nœud qui n'est pas un déclencheur. Il reçoit des données des nœuds précédents, effectue une opération (ex: lire une base de données, envoyer un message, transformer des données), et passe les résultats aux nœuds suivants.

#### Connection (Connexion)
**Définition**: Le lien visuel entre deux nœuds sur le Canevas. Il définit le chemin et la direction du flux de données et détermine l'ordre d'exécution (Execution Order).

#### Credentials (Identifiants)
**Définition**: Informations d'authentification stockées (clés API, logins OAuth, etc.) que les Nœuds utilisent pour se connecter de manière sécurisée à des services externes (Gmail, Notion, API REST...).

### Données et Exécution

#### Execution (Exécution)
**Définition**: Une unique instance de fonctionnement d'un Workflow, depuis le déclenchement par le Trigger Node jusqu'à sa fin (ou une erreur). Chaque exécution traite un ensemble de données (Items).

#### Item (Élément)
**Définition**: L'unité fondamentale de données traitée par un Workflow. Une exécution peut impliquer le traitement de plusieurs Items. Chaque Item est généralement une structure de données (souvent JSON) contenant les informations pertinentes à une étape donnée.

#### JSON (JavaScript Object Notation)
**Définition**: Le format standard utilisé par n8n pour structurer et échanger les données (Items) entre les nœuds.

#### Expression
**Définition**: Un petit morceau de code (syntaxe proche de JavaScript) utilisé dans les paramètres des nœuds pour accéder dynamiquement aux données des Items ($json, $item), manipuler ces données, ou prendre des décisions logiques. Crucial pour la personnalisation.

### Logique de Flux

#### Flow Logic (Logique de Flux)
**Définition**: L'ensemble des concepts et mécanismes qui contrôlent comment les données (Items) circulent et comment les Nœuds sont exécutés dans un Workflow. Inclut le splitting, merging, looping, waiting, error handling, etc.

#### Splitting (Séparation / Traitement par Item)
**Définition**: Le comportement par défaut de la plupart des nœuds : lorsqu'un nœud reçoit plusieurs Items en entrée, il exécute son action une fois pour chaque Item individuellement, avant de passer les résultats (potentiellement un Item par exécution) au nœud suivant.

#### Merging (Fusion)
**Définition**: Le processus de combinaison des données provenant de différentes branches d'un workflow ou de regroupement des Items après qu'ils aient été traités séparément (par splitting ou looping). Souvent réalisé avec le nœud Merge, qui propose différentes stratégies (par index, par clé).

#### Looping (Boucle)
**Définition**: La capacité de répéter une séquence spécifique de Nœuds plusieurs fois. Peut être basé sur un nombre fixe de répétitions ou itérer sur une liste d'Items (ex: avec le nœud Loop Over Items). Différent du splitting qui est implicite.

#### Waiting / Pausing (Attente / Pause)
**Définition**: L'action d'interrompre délibérément l'exécution d'un Workflow pendant une période définie, jusqu'à une heure précise, ou en attendant un événement externe (comme un appel webhook). Généralement réalisé avec le nœud Wait.

#### Subworkflow / Execute Workflow (Sous-Workflow)
**Définition**: Une technique permettant d'appeler et d'exécuter un autre Workflow n8n depuis le Workflow courant. Favorise la modularité et la réutilisabilité du code/logique. Réalisé avec le nœud Execute Workflow.

#### Error Handling (Gestion des Erreurs)
**Définition**: L'ensemble des stratégies et outils pour gérer les échecs qui peuvent survenir pendant l'exécution d'un Workflow. Inclut des options sur les nœuds (Continue on Fail, Retry on Fail) et des workflows dédiés déclenchés par un Error Trigger.

#### Execution Order (Ordre d'Exécution)
**Définition**: La séquence dans laquelle les nœuds d'un workflow sont exécutés. Elle est principalement déterminée par les Connexions entre les nœuds. Les données circulent le long de ces connexions, déclenchant l'exécution du nœud suivant. Les branches parallèles peuvent entraîner une exécution simultanée (ou quasi-simultanée) de différentes parties du workflow.

## Spécificités Notion dans N8N

### Gestion des Relations et Rollups

#### 1. Utilisation de Simplify dans Get Many (Database Page)

| Cas d'usage | Comportement |
|-------------|--------------|
| Simplify: ✅ | Les propriétés sont simplifiées en tableaux de valeurs directement accessibles (ex: E-mail[0]) |
| Simplify: ❌ | Structure complexe : rollup.array[0].email ou title[0].plain_text |

**Conclusion**: Active Simplify quand tu veux éviter les IIFE ((() => { })()) pour accéder à des relations, rollups, multi-selects.

#### 2. Accès aux Rollups de Relations dans Simplify ✅

```javascript
{{ $json['E-mail'][0] || '⚠️ Email manquant' }}
```

Cela fonctionne uniquement si :
- Le champ "E-mail" est une agrégation (rollup) vers une propriété type email dans la base liée (bdd-Lieux ici)
- Simplify est activé dans le Get Many

#### 3. Traduction JSON simplifiée pour les contacts (cas réel)

```json
{
  "emailContact": "{{ $json['E-mail'][0] || '⚠️ Email manquant' }}",
  "contactName": "{{ $json['Name'] || 'Nom inconnu' }}",
  "structure": "{{ $json['bdd-Lieux'][0] || 'Structure inconnue' }}",
  "ville": "{{ $json['Ville'][0] || 'Ville inconnue' }}",
  "etatDuMail": "{{ $json['Etat du mail'][0] || 'État non renseigné' }}"
}
```

#### 4. Structure standard à retenir pour Notion

| Type de champ | Accès avec Simplify ✅ | Exemple |
|---------------|------------------------|---------|
| Title (Name) | Name | "Jean Jean" |
| Email (Rollup) | E-mail[0] | "lubbin@gmail.com" |
| Multi-select | Etat du mail[0] | "PROSPECT ⚠️ En attente d'envoi" |
| Relation (base liée) | bdd-Lieux[0] | "11a81449-f795..." (ID page liée) |

### Pièges et Solutions Spécifiques

#### 1. Rollup ≠ JSON standard : structure atypique

Un champ de type Rollup (Agrégation) ne donne pas un simple champ comme "email": "xx@yy.com".

Il retourne une structure du type :
```json
"E-mail": {
  "rollup": {
    "array": [ { "type": "email", "email": "xx@yy.com" } ]
  }
}
```

Même si le champ Notion est un email, il faut extraire .rollup.array[0].email.

#### 2. Accéder proprement à un rollup dans un Set Node

En mode non-simplifié :
```javascript
{{ (() => {
  const roll = $json["E-mail"]?.rollup?.array;
  return roll?.[0]?.email || "⚠️ Email manquant";
})() }}
```

En mode simplifié :
```javascript
{{ $json["E-mail"][0] || "⚠️ Email manquant" }}
```

**Règle**: Toujours tester la structure du champ avec console.log($json) dans un Function ou Set si doute.

#### 3. Erreur fréquente avec filtre dans Get Many (Filter JSON)

Tentative problématique :
```json
{
  "filter": {
    "property": "Name",
    "title": { "equals": "{{ $json['bdd-Lieux']?.[0]?.name }}" }
  }
}
```

**Échec**: N8N ne parse pas les expressions dans les JSON de filtres Notion.

**Solution**: Filtrer en amont ou utiliser un node IF/Function pour filtrer manuellement après récupération de toutes les données.

#### 4. Éviter les requêtes GetAll inutiles

Problème identifié: Get Lieux Details récupérait 2415 items alors qu'un seul était nécessaire.

**Leçon**: Si Simplify est activé dans Get Notion Contacts, et que la Relation est présente, tu peux éviter complètement le Get Details Notion et utiliser directement les rollups/IDs dans le contact.

#### 5. Fusionner deux objets (ex: Contact + Lieu)

Pattern appliqué dans Fusion LOT1 + Lieux :
```javascript
return [{
  json: {
    ...contactJson,
    lieuEmail: matchedLieu?.properties?.['E-mail']?.email || null,
    lieuStructure: matchedLieu?.properties?.['Structure']?.title?.[0]?.plain_text || 'Structure inconnue',
    ...
  }
}]
```

**Bonnes pratiques**:
- Utiliser `...contactJson` pour propager toutes les clés du contact
- Préférer `?.` + fallback (`||`) pour les champs liés

#### 6. Stratégie durable pour Notion modulaire multi-bases

**Leçon stratégique**:
Un flux Notion/N8N doit intégrer une logique générique qui détecte :
- quelles propriétés sont des relations
- quelles sont les aggregations
- pour ensuite les naviguer dynamiquement

**Préconisation**:
- Regrouper les métadonnées de structure des bases dans un node Set d'initialisation
- Gérer dynamiquement les accès à la donnée selon leur type Notion

#### 7. Utiliser Function Node pour debug et mapping ciblé

Quand les Rollups ou Relations sont trop complexes, utiliser un Function node pour naviguer manuellement dans le JSON:

```javascript
const roll = $json['E-mail']?.rollup?.array;
return [{ json: { email: roll?.[0]?.email || '⚠️' }}];
```

#### 8. Conseil UX Notion : renommage de propriétés

Problème identifié:
- Champ dans bdd-Lieux : "E-mail contact lieu"
- Dans LOT1, le rollup s'appelait juste "E-mail", générant des ambiguïtés

**Bonne pratique**: Toujours faire précéder un rollup du nom original de sa base:
- Rollup_Email_Lieux ou email_bddLieux
