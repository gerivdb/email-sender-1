# Glossaire des Erreurs et Solutions N8N

## Table des matières

1. [Glossaire des Erreurs et Solutions N8N](#section-1)
    1.1. [Sources d'Erreurs Courantes et Leurs Solutions](#section-2)
            1.1.0.1. [Branche Parallèle (Exécution)](#section-3)
            1.1.0.2. [Données d'Exécution (Visualisation)](#section-4)
            1.1.0.3. [Exécution Basée sur les Items (Comportement par défaut)](#section-5)
            1.1.0.4. [Merge Node (Mode Combine By Position)](#section-6)
            1.1.0.5. [Notion Node (Simplify Option - implicite/explicite)](#section-7)
            1.1.0.6. [Nodes "Orphelins" (dans une Exécution Globale)](#section-8)
            1.1.0.7. [Test step (Bouton sur Node)](#section-9)
            1.1.0.8. [Trigger (Rôle Fondamental)](#section-10)
            1.1.0.9. [Workflow](#section-11)
            1.1.0.10. [Node (Nœud)](#section-12)
            1.1.0.11. [Trigger Node (Nœud Déclencheur)](#section-13)
            1.1.0.12. [Regular Node (Nœud Régulier)](#section-14)
            1.1.0.13. [Connection (Connexion)](#section-15)
            1.1.0.14. [Credentials (Identifiants)](#section-16)
            1.1.0.15. [Execution (Exécution)](#section-17)
            1.1.0.16. [Item (Élément)](#section-18)
            1.1.0.17. [JSON (JavaScript Object Notation)](#section-19)
            1.1.0.18. [Expression](#section-20)
            1.1.0.19. [Flow Logic (Logique de Flux)](#section-21)
            1.1.0.20. [Splitting (Séparation / Traitement par Item)](#section-22)
            1.1.0.21. [Merging (Fusion)](#section-23)
            1.1.0.22. [Looping (Boucle)](#section-24)
            1.1.0.23. [Waiting / Pausing (Attente / Pause)](#section-25)
            1.1.0.24. [Subworkflow / Execute Workflow (Sous-Workflow)](#section-26)
            1.1.0.25. [Error Handling (Gestion des Erreurs)](#section-27)
            1.1.0.26. [Execution Order (Ordre d'Exécution)](#section-28)
            1.1.0.27. [. Utilisation de Simplify dans Get Many (Database Page)](#section-29)
            1.1.0.28. [. Accès aux Rollups de Relations dans Simplify ✅](#section-30)
            1.1.0.29. [. Traduction JSON simplifiée pour les contacts (cas réel)](#section-31)
            1.1.0.30. [. Structure standard à retenir pour Notion](#section-32)
            1.1.0.31. [. Rollup ≠ JSON standard : structure atypique](#section-33)
            1.1.0.32. [. Accéder proprement à un rollup dans un Set Node](#section-34)
            1.1.0.33. [. Erreur fréquente avec filtre dans Get Many (Filter JSON)](#section-35)
            1.1.0.34. [. Éviter les requêtes GetAll inutiles](#section-36)
            1.1.0.35. [. Fusionner deux objets (ex: Contact + Lieu)](#section-37)
            1.1.0.36. [. Stratégie durable pour Notion modulaire multi-bases](#section-38)
            1.1.0.37. [. Utiliser Function Node pour debug et mapping ciblé](#section-39)
            1.1.0.38. [. Conseil UX Notion : renommage de propriétés](#section-40)

## 1. Glossaire des Erreurs et Solutions N8N <a name='section-1'></a>

### 1.1. Sources d'Erreurs Courantes et Leurs Solutions <a name='section-2'></a>

| Erreur | Cause racine | Solution apportée |
|--------|--------------|-------------------|
| Cannot read json of undefined | Node non connecté en input 0 | Connexion explicite faite ✅ |
| map is not a function | input1 ou input2 n'était pas un tableau | Conversion toArray(...) ajoutée ✅ |
| Message d'intention manquant | Mauvaise entrée ou fallback non prévu | Valeur par défaut message mise ✅ |

##### 1.1.0.1. Branche Parallèle (Exécution) <a name='section-3'></a>

**Constat**: Une branche de workflow (ex: celle partant de Get Notion Contacts LOT1) ne s'exécute pas automatiquement si elle n'est pas connectée, directement ou indirectement, au flux de données initié par le Trigger principal (ex: Start Manual).

**Implication**: Pour que des données issues de branches différentes soient disponibles en même temps pour un node de fusion (comme Merge), toutes ces branches de départ doivent être déclenchées par le même événement initial (en connectant le Trigger à chacune).

##### 1.1.0.2. Données d'Exécution (Visualisation) <a name='section-4'></a>

**Constat**: Les compteurs X items et la couleur des "fils" (connexions) entre les nodes reflètent l'état de la dernière exécution affichée.

**Implication**: Un fil gris indique qu'aucune donnée n'a transité par cette connexion lors de cette exécution spécifique, même si le node source pourrait produire des données s'il était exécuté. Essentiel pour suivre le flux réel.

##### 1.1.0.3. Exécution Basée sur les Items (Comportement par défaut) <a name='section-5'></a>

**Constat**: La plupart des nodes N8N (Set, Code, HTTP Request...) s'exécutent une fois pour chaque item reçu sur leur entrée principale.

**Implication**: Si un node en amont produit accidentellement plusieurs items (ex: return [ {...}, {...} ] dans un node Code), tous les nodes suivants s'exécuteront plusieurs fois, propageant l'exécution multiple. La clé est de s'assurer que chaque étape produit le nombre d'items attendu (souvent 1 seul item par "logique métier").

##### 1.1.0.4. Merge Node (Mode Combine By Position) <a name='section-6'></a>

**Constat**: Ce mode est très strict. Il nécessite exactement le même nombre d'items sur ses deux (ou plus) inputs, et ces items doivent arriver dans le contexte de la même exécution globale pour être appairés (1er avec 1er, 2ème avec 2ème...).

**Implication**: Si une branche fournit 1 item et l'autre 0 (ou si les données arrivent en décalé), l'appariement échoue et l'output est vide par défaut. La synchronisation des branches via un trigger commun est souvent la solution.

##### 1.1.0.5. Notion Node (Simplify Option - implicite/explicite) <a name='section-7'></a>

**Constat**: L'activation (même si non visible dans le JSON exporté parfois) de l'option Simplify change radicalement la structure des données retournées, notamment pour les types complexes comme les Relations et les Agrégations (Rollups).

**Implication**: Avec Simplify, une agrégation d'email peut devenir directement accessible via $json['NomColonneEmail'][0], tandis que sans Simplify, il faut naviguer dans la structure complète ($json.properties['NomColonneEmail'].rollup.array[0].email). Connaître l'état de cette option est crucial pour écrire les bonnes expressions.

##### 1.1.0.6. Nodes "Orphelins" (dans une Exécution Globale) <a name='section-8'></a>

**Constat**: Les nodes ou branches non reliés au Trigger actif ne sont pas exécutés lors d'un lancement global ("Execute Workflow").

**Implication**: Cela explique pourquoi des branches entières peuvent rester "grises". Il ne s'agit pas forcément d'une erreur dans ces nodes, mais d'une absence de déclenchement dans ce contexte.

##### 1.1.0.7. Test step (Bouton sur Node) <a name='section-9'></a>

**Constat**: Conçu pour exécuter uniquement le node sélectionné, en utilisant les dernières données disponibles sur ses entrées (issues d'exécutions précédentes ou d'autres "Test step"). Permet d'isoler et de tester la logique d'un node spécifique.

**Implication**: L'erreur "Connect a trigger..." obtenue lors de son utilisation était anormale et indiquait probablement un glitch de l'interface ou de l'état du workflow, non lié au fonctionnement standard de "Test step".

##### 1.1.0.8. Trigger (Rôle Fondamental) <a name='section-10'></a>

**Constat**: Le point de départ de toute exécution automatique ou manuelle globale du workflow. C'est lui qui injecte le premier item (souvent vide pour Manual Trigger) qui initie le flux de données.

**Implication**: Pour coordonner des actions parallèles qui doivent converger, relier le Trigger à chaque point de départ de ces actions est une stratégie valide et nécessaire.

##### 1.1.0.9. Workflow <a name='section-11'></a>

**Définition**: L'ensemble du processus d'automatisation que tu crées dans n8n. Il est composé de Nœuds connectés entre eux sur le Canevas.

##### 1.1.0.10. Node (Nœud) <a name='section-12'></a>

**Définition**: Un bloc fonctionnel dans un Workflow qui effectue une action spécifique. Il peut s'agir d'un Déclencheur (Trigger) ou d'un Nœud Régulier (Regular Node).

##### 1.1.0.11. Trigger Node (Nœud Déclencheur) <a name='section-13'></a>

**Définition**: Le nœud spécial qui initie l'exécution d'un Workflow. Il réagit à un événement (ex: horaire, webhook, nouvel email). Un workflow commence toujours par un trigger.

##### 1.1.0.12. Regular Node (Nœud Régulier) <a name='section-14'></a>

**Définition**: Tout nœud qui n'est pas un déclencheur. Il reçoit des données des nœuds précédents, effectue une opération (ex: lire une base de données, envoyer un message, transformer des données), et passe les résultats aux nœuds suivants.

##### 1.1.0.13. Connection (Connexion) <a name='section-15'></a>

**Définition**: Le lien visuel entre deux nœuds sur le Canevas. Il définit le chemin et la direction du flux de données et détermine l'ordre d'exécution (Execution Order).

##### 1.1.0.14. Credentials (Identifiants) <a name='section-16'></a>

**Définition**: Informations d'authentification stockées (clés API, logins OAuth, etc.) que les Nœuds utilisent pour se connecter de manière sécurisée à des services externes (Gmail, Notion, API REST...).

##### 1.1.0.15. Execution (Exécution) <a name='section-17'></a>

**Définition**: Une unique instance de fonctionnement d'un Workflow, depuis le déclenchement par le Trigger Node jusqu'à sa fin (ou une erreur). Chaque exécution traite un ensemble de données (Items).

##### 1.1.0.16. Item (Élément) <a name='section-18'></a>

**Définition**: L'unité fondamentale de données traitée par un Workflow. Une exécution peut impliquer le traitement de plusieurs Items. Chaque Item est généralement une structure de données (souvent JSON) contenant les informations pertinentes à une étape donnée.

##### 1.1.0.17. JSON (JavaScript Object Notation) <a name='section-19'></a>

**Définition**: Le format standard utilisé par n8n pour structurer et échanger les données (Items) entre les nœuds.

##### 1.1.0.18. Expression <a name='section-20'></a>

**Définition**: Un petit morceau de code (syntaxe proche de JavaScript) utilisé dans les paramètres des nœuds pour accéder dynamiquement aux données des Items ($json, $item), manipuler ces données, ou prendre des décisions logiques. Crucial pour la personnalisation.

##### 1.1.0.19. Flow Logic (Logique de Flux) <a name='section-21'></a>

**Définition**: L'ensemble des concepts et mécanismes qui contrôlent comment les données (Items) circulent et comment les Nœuds sont exécutés dans un Workflow. Inclut le splitting, merging, looping, waiting, error handling, etc.

##### 1.1.0.20. Splitting (Séparation / Traitement par Item) <a name='section-22'></a>

**Définition**: Le comportement par défaut de la plupart des nœuds : lorsqu'un nœud reçoit plusieurs Items en entrée, il exécute son action une fois pour chaque Item individuellement, avant de passer les résultats (potentiellement un Item par exécution) au nœud suivant.

##### 1.1.0.21. Merging (Fusion) <a name='section-23'></a>

**Définition**: Le processus de combinaison des données provenant de différentes branches d'un workflow ou de regroupement des Items après qu'ils aient été traités séparément (par splitting ou looping). Souvent réalisé avec le nœud Merge, qui propose différentes stratégies (par index, par clé).

##### 1.1.0.22. Looping (Boucle) <a name='section-24'></a>

**Définition**: La capacité de répéter une séquence spécifique de Nœuds plusieurs fois. Peut être basé sur un nombre fixe de répétitions ou itérer sur une liste d'Items (ex: avec le nœud Loop Over Items). Différent du splitting qui est implicite.

##### 1.1.0.23. Waiting / Pausing (Attente / Pause) <a name='section-25'></a>

**Définition**: L'action d'interrompre délibérément l'exécution d'un Workflow pendant une période définie, jusqu'à une heure précise, ou en attendant un événement externe (comme un appel webhook). Généralement réalisé avec le nœud Wait.

##### 1.1.0.24. Subworkflow / Execute Workflow (Sous-Workflow) <a name='section-26'></a>

**Définition**: Une technique permettant d'appeler et d'exécuter un autre Workflow n8n depuis le Workflow courant. Favorise la modularité et la réutilisabilité du code/logique. Réalisé avec le nœud Execute Workflow.

##### 1.1.0.25. Error Handling (Gestion des Erreurs) <a name='section-27'></a>

**Définition**: L'ensemble des stratégies et outils pour gérer les échecs qui peuvent survenir pendant l'exécution d'un Workflow. Inclut des options sur les nœuds (Continue on Fail, Retry on Fail) et des workflows dédiés déclenchés par un Error Trigger.

##### 1.1.0.26. Execution Order (Ordre d'Exécution) <a name='section-28'></a>

**Définition**: La séquence dans laquelle les nœuds d'un workflow sont exécutés. Elle est principalement déterminée par les Connexions entre les nœuds. Les données circulent le long de ces connexions, déclenchant l'exécution du nœud suivant. Les branches parallèles peuvent entraîner une exécution simultanée (ou quasi-simultanée) de différentes parties du workflow.

##### 1.1.0.27. . Utilisation de Simplify dans Get Many (Database Page) <a name='section-29'></a>

| Cas d'usage | Comportement |
|-------------|--------------|
| Simplify: ✅ | Les propriétés sont simplifiées en tableaux de valeurs directement accessibles (ex: E-mail[0]) |
| Simplify: ❌ | Structure complexe : rollup.array[0].email ou title[0].plain_text |

**Conclusion**: Active Simplify quand tu veux éviter les IIFE ((() => { })()) pour accéder à des relations, rollups, multi-selects.

##### 1.1.0.28. . Accès aux Rollups de Relations dans Simplify ✅ <a name='section-30'></a>

```javascript
{{ $json['E-mail'][0] || '⚠️ Email manquant' }}
```

Cela fonctionne uniquement si :
- Le champ "E-mail" est une agrégation (rollup) vers une propriété type email dans la base liée (bdd-Lieux ici)
- Simplify est activé dans le Get Many

##### 1.1.0.29. . Traduction JSON simplifiée pour les contacts (cas réel) <a name='section-31'></a>

```json
{
  "emailContact": "{{ $json['E-mail'][0] || '⚠️ Email manquant' }}",
  "contactName": "{{ $json['Name'] || 'Nom inconnu' }}",
  "structure": "{{ $json['bdd-Lieux'][0] || 'Structure inconnue' }}",
  "ville": "{{ $json['Ville'][0] || 'Ville inconnue' }}",
  "etatDuMail": "{{ $json['Etat du mail'][0] || 'État non renseigné' }}"
}
```

##### 1.1.0.30. . Structure standard à retenir pour Notion <a name='section-32'></a>

| Type de champ | Accès avec Simplify ✅ | Exemple |
|---------------|------------------------|---------|
| Title (Name) | Name | "Jean Jean" |
| Email (Rollup) | E-mail[0] | "lubbin@gmail.com" |
| Multi-select | Etat du mail[0] | "PROSPECT ⚠️ En attente d'envoi" |
| Relation (base liée) | bdd-Lieux[0] | "11a81449-f795..." (ID page liée) |

##### 1.1.0.31. . Rollup ≠ JSON standard : structure atypique <a name='section-33'></a>

Un champ de type Rollup (Agrégation) ne donne pas un simple champ comme "email": "xx@yy.com".

Il retourne une structure du type :
```json
"E-mail": {
  "rollup": {
    "array": [ { "type": "email", "email": "xx@yy.com" } ]
  }
```

Même si le champ Notion est un email, il faut extraire .rollup.array[0].email.

##### 1.1.0.32. . Accéder proprement à un rollup dans un Set Node <a name='section-34'></a>

En mode non-simplifié :
```javascript
{{ (() => {
  const roll = $json["E-mail"]?.rollup?.array;
  return roll?.[0]?.email || "⚠️ Email manquant";
})() }}
```

En mode simplifié :
{{ $json["E-mail"][0] || "⚠️ Email manquant" }}

**Règle**: Toujours tester la structure du champ avec console.log($json) dans un Function ou Set si doute.

##### 1.1.0.33. . Erreur fréquente avec filtre dans Get Many (Filter JSON) <a name='section-35'></a>

Tentative problématique :
```json
{
  "filter": {
    "property": "Name",
    "title": { "equals": "{{ $json['bdd-Lieux']?.[0]?.name }}" }
  }
```

**Échec**: N8N ne parse pas les expressions dans les JSON de filtres Notion.

**Solution**: Filtrer en amont ou utiliser un node IF/Function pour filtrer manuellement après récupération de toutes les données.

##### 1.1.0.34. . Éviter les requêtes GetAll inutiles <a name='section-36'></a>

Problème identifié: Get Lieux Details récupérait 2415 items alors qu'un seul était nécessaire.

**Leçon**: Si Simplify est activé dans Get Notion Contacts, et que la Relation est présente, tu peux éviter complètement le Get Details Notion et utiliser directement les rollups/IDs dans le contact.

##### 1.1.0.35. . Fusionner deux objets (ex: Contact + Lieu) <a name='section-37'></a>

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

##### 1.1.0.36. . Stratégie durable pour Notion modulaire multi-bases <a name='section-38'></a>

**Leçon stratégique**:
Un flux Notion/N8N doit intégrer une logique générique qui détecte :
- quelles propriétés sont des relations
- quelles sont les aggregations
- pour ensuite les naviguer dynamiquement

**Préconisation**:
- Regrouper les métadonnées de structure des bases dans un node Set d'initialisation
- Gérer dynamiquement les accès à la donnée selon leur type Notion

##### 1.1.0.37. . Utiliser Function Node pour debug et mapping ciblé <a name='section-39'></a>

Quand les Rollups ou Relations sont trop complexes, utiliser un Function node pour naviguer manuellement dans le JSON:

```javascript
const roll = $json['E-mail']?.rollup?.array;
return [{ json: { email: roll?.[0]?.email || '⚠️' }}];
```

##### 1.1.0.38. . Conseil UX Notion : renommage de propriétés <a name='section-40'></a>

Problème identifié:
- Champ dans bdd-Lieux : "E-mail contact lieu"
- Dans LOT1, le rollup s'appelait juste "E-mail", générant des ambiguïtés

**Bonne pratique**: Toujours faire précéder un rollup du nom original de sa base:
- Rollup_Email_Lieux ou email_bddLieux

