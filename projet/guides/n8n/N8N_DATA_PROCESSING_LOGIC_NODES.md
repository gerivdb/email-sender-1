# Nœuds de Traitement de Données et de Logique dans n8n

Ce document détaille les nœuds essentiels pour le traitement des données et la logique conditionnelle dans les workflows n8n, avec des exemples de configuration JSON.

## Nœud Code (Function)

Le nœud Code (anciennement appelé Function) permet d'écrire du JavaScript personnalisé (et dans les versions récentes, optionnellement du Python) pour manipuler des données. Il peut opérer sur des éléments entrants ou générer de nouvelles données.

### Exemple : Ajouter un nouveau champ à chaque élément

```json
{
  "name": "Add Field",
  "type": "n8n-nodes-base.function",
  "typeVersion": 1,
  "parameters": {
    "functionCode": "for (const item of items) {\n item.json.newField = item.json.someField + 100;\n}\nreturn items;"
  }
}
```plaintext
**Explication :** Ce code JavaScript parcourt chaque élément d'entrée (`items` est un tableau d'objets `{ json: {...}, binary: {...} }`) et ajoute un nouveau champ. Ici, nous définissons `newField` comme `someField + 100`. Le nœud doit retourner `items;` à la fin. Après l'exécution, les nœuds en aval voient les éléments modifiés.

Vous pouvez utiliser `console.log()` ou effectuer des transformations plus complexes. Si vous configurez "Pas d'entrées", le nœud Code peut agir comme un générateur de données (par exemple, créer un tableau d'objets à partir de zéro).

**Note :** n8n prend également en charge un mode Code (Python) séparé si activé. Dans le JSON, cela inclurait `"language": "python"` et le code dans un champ similaire.

## Nœud IF (Conditionnel)

Le nœud IF achemine les données en fonction de conditions (vrai/faux). Il possède deux sorties : vrai (première sortie) et faux (deuxième sortie).

### Exemple : Vérifier si le champ status est égal à "success"

```json
{
  "name": "Check Status",
  "type": "n8n-nodes-base.if",
  "typeVersion": 2,
  "parameters": {
    "conditions": {
      "conditions": [
        {
          "leftValue": "={{ $json[\"status\"] }}",
          "rightValue": "success",
          "operator": {
            "type": "string",
            "operation": "equals"
          }
        }
      ],
      "combinator": "and"
    }
  }
}
```plaintext
**Explication :** Ce nœud IF dirigera tout élément entrant vers la branche vrai si le champ `status` de l'élément est la chaîne "success". Tous les autres éléments vont vers la branche faux.

La structure JSON sous `parameters.conditions` peut inclure plusieurs règles ; ici, nous avons une règle comparant une chaîne. `leftValue` utilise une expression pour extraire le statut de l'élément. Nous définissons le type d'opérateur sur "string" et l'opération "equals".

Le nœud IF prend en charge d'autres opérations (par exemple, contains, greater, less, regex matches, etc.) et types de données (number, boolean, date, etc.). Le combinateur est utilisé si vous avez plusieurs conditions – par exemple, vous pourriez définir deux conditions et utiliser `"combinator": "and"` pour exiger que les deux soient vraies.

**Important :** Le nœud IF ne filtre pas complètement les éléments ; il les achemine. Les éléments vont donc toujours soit vers la sortie vrai, soit vers la sortie faux. Si vous voulez arrêter des éléments, vous pourriez utiliser une logique supplémentaire (ou utiliser le IF en combinaison avec le nœud Merge pour filtrer).

## Nœud Switch (Routage Multiple)

Le nœud Switch est comme un multi-IF ou une instruction switch/case. Il vous permet de définir plusieurs règles et jusqu'à plusieurs sorties. Chaque élément entrant va vers la première sortie correspondante (ou toutes les correspondantes, si configuré), ou vers une sortie par défaut si aucune règle ne correspond.

### Exemple : Routage basé sur un champ category

```json
{
  "name": "Route by Category",
  "type": "n8n-nodes-base.switch",
  "typeVersion": 1,
  "parameters": {
    "dataType": "string",
    "value1": "={{ $json[\"category\"] }}",
    "rules": {
      "rules": [
        { "operation": "equal", "value2": "support" },
        { "operation": "equal", "value2": "sales" }
      ]
    },
    "fallbackOutput": 2
  }
}
```plaintext
**Explication :** Ce nœud Switch examine la valeur de `category`. Si elle est égale à "support", l'élément sort via la sortie 0 (première sortie) ; si "sales", via la sortie 1 ; tout le reste passe par la sortie 2 (la sortie par défaut).

Nous définissons `dataType: "string"` puisque nous comparons des chaînes. Le tableau `rules` définit deux cas. `fallbackOutput: 2` signifie que nous avons configuré une troisième sortie pour "aucune des options ci-dessus". Dans l'éditeur, vous définiriez le nombre de sorties à 3 dans ce cas.

Vous pouvez ajouter plus de règles pour des sorties supplémentaires. Les opérations peuvent être l'égalité, contient, supérieur à, etc., similaires à IF. Vous pouvez également basculer sur des nombres, des booléens, des dates, ou même utiliser un mode d'expression JavaScript pour diriger les éléments vers un index de sortie.

Le nœud Switch est utile pour la logique de branchement dans les workflows (par exemple, traiter différemment différents types d'événements ou catégories).

## Nœud Set (Éditer les Champs)

Le nœud Set permet d'ajouter, supprimer ou renommer des champs dans les données JSON sans coder. Il est souvent utilisé pour préparer ou nettoyer des données.

### Exemple : Définir deux nouveaux champs et conserver les données existantes

```json
{
  "name": "Set Fields",
  "type": "n8n-nodes-base.set",
  "typeVersion": 3,
  "parameters": {
    "keepOnlySet": false,
    "values": {
      "number": [
        {
          "name": "year",
          "value": 2025
        }
      ],
      "string": [
        {
          "name": "statusMessage",
          "value": "Processed by n8n"
        }
      ]
    }
  }
}
```plaintext
**Explication :** Ce nœud Set ajoutera un champ numérique `year` avec la valeur 2025 et un champ chaîne `statusMessage` avec un texte statique. Comme `keepOnlySet` est false, il conservera tous les champs existants des éléments d'entrée et ajoutera simplement ces deux-là.

Si `keepOnlySet` était true, la sortie n'aurait que les champs que nous définissons explicitement (utile si vous voulez écarter d'autres données).

Le nœud Set peut gérer plusieurs types de données (notez que nous avons utilisé un nombre et une chaîne ; vous pourriez également définir des booléens, des dates, etc. en utilisant les sections respectives).

Si vous voulez supprimer certains champs, vous pouvez utiliser l'option Remove Fields (dans le JSON, il y aurait un `options.removeFields` que vous pourriez lister).

Le nœud Set est pratique pour mapper des données avant de les envoyer à une API ou après avoir reçu des données pour simplifier la sortie.

## Nœud Merge (Fusion)

Le nœud Merge prend deux flux d'entrée et les combine. Il peut fonctionner dans différents modes : Append (concatène simplement les éléments), Wait (attend les deux entrées puis sort ensemble), Merge By Index (apparie les éléments un à un par leur index), ou Merge By Key (fait correspondre les éléments des deux entrées sur une valeur clé).

### Exemple : Utilisation de Merge en mode "By Key" pour joindre des données de deux sources sur un champ id

```json
{
  "name": "Merge on ID",
  "type": "n8n-nodes-base.merge",
  "typeVersion": 1,
  "parameters": {
    "mode": "mergeByKey",
    "propertyName": "id",
    "outputDataFrom": "both"
  }
}
```plaintext
**Explication :** Ce Merge est configuré pour `mergeByKey` sur le champ `id`. Il s'attend à ce que chaque entrée ait des éléments avec une propriété `id`. Il produira un flux unique d'éléments fusionnés : chaque élément de sortie combine le JSON de input1 et input2 où l'id correspondait.

Le `outputDataFrom: "both"` signifie que l'élément de sortie inclura les champs des deux entrées (vous pourriez également choisir de ne sortir que les données d'un côté, l'autre étant juste utilisé pour la correspondance).

Pour utiliser Merge, connectez un nœud à l'entrée 1 et un autre à l'entrée 2 de ce nœud. Si un id d'un côté ne trouve pas de correspondance de l'autre côté, cet élément peut être supprimé ou transmis en fonction d'options supplémentaires (`options.outputMissing...`).

**Autres modes :**
- **Append** concatène simplement les éléments Input1 et Input2 (l'un après l'autre)
- **Wait** fait une pause jusqu'à ce que les deux entrées aient été exécutées (puis sort les deux ensembles ; utile pour synchroniser des branches parallèles)
- **Merge By Index** prend l'élément 0 de Input1 avec l'élément 0 de Input2, l'élément 1 avec l'élément 1, etc., combinant leur JSON (vous n'utiliseriez généralement cela que si les deux entrées ont la même longueur et le même ordre)

Le nœud Merge est crucial pour des flux plus complexes où les données se divisent et doivent se rejoindre.

## Nœud Item Lists (Aggregate)

Le nœud Item Lists (précédemment appelé Aggregate dans certains contextes) aide à manipuler des tableaux d'éléments – par exemple, diviser un tableau en éléments individuels ou agréger plusieurs éléments en un seul tableau.

### Exemple : Configuration pour diviser un tableau

```json
{
  "name": "Split Array",
  "type": "n8n-nodes-base.itemLists",
  "typeVersion": 1,
  "parameters": {
    "operation": "splitIntoItems",
    "property": "results"
  }
}
```plaintext
**Explication :** Si un élément entrant a un champ `results` qui est un tableau (par exemple, d'une réponse HTTP ou d'un calcul précédent), ce nœud produira chaque élément de `results` comme un élément n8n séparé. L'opération `"splitIntoItems"` et la spécification de la propriété à diviser font cela.

L'inverse peut être fait avec `operation: "aggregateItems"` qui peut collecter toutes les données des éléments d'entrée dans un seul tableau sur un élément (vous spécifiez comment agréger, comme collecter toutes les valeurs d'un champ dans un tableau).

Il existe également d'autres opérations de liste (comme supprimer les doublons, trier les éléments par un champ, etc.).

Le nœud Item Lists est très utile pour gérer les données de tableau sans écrire de code – par exemple, diviser une réponse API qui a retourné une liste d'enregistrements en éléments individuels pour un traitement ultérieur.

## Boucles (Split/Batches)

n8n n'utilise pas de boucles traditionnelles ; à la place, il traite plusieurs éléments en parallèle à travers les nœuds. Pour boucler explicitement d'une certaine manière, vous pouvez utiliser le nœud Split In Batches (appelé "Loop Over Items" dans l'interface).

### Exemple : Traiter 10 éléments à la fois

```json
{
  "name": "Batch Loop",
  "type": "n8n-nodes-base.splitInBatches",
  "typeVersion": 1,
  "parameters": {
    "batchSize": 10
  }
}
```plaintext
**Explication :** Connectez le nœud SplitInBatches dans votre flux où vous voulez limiter ou parcourir des éléments. Lors de la première exécution, il passera les 10 premiers éléments et retiendra le reste.

À la fin de la boucle (vous devez connecter le dernier nœud de la boucle à l'entrée 2 du nœud SplitInBatches), le nœud SplitInBatches enverra le prochain lot lorsqu'il sera déclenché depuis cette deuxième entrée. Cela crée essentiellement une boucle : après le dernier nœud, connectez-le à nouveau au SplitInBatches (sélectionnez l'entrée "Execute Next Batch").

C'est une utilisation avancée pour les scénarios où vous devez éviter de traiter tous les éléments à la fois (par exemple, limiter les appels API ou traiter de grandes listes morceau par morceau).

La boucle se termine lorsqu'il ne reste plus d'éléments ; vous pouvez détecter cela en utilisant un Run IF connecté à la sortie "No Items" de SplitInBatches (ou simplement laisser le workflow se terminer après qu'il n'y a plus de lots).

## Gestion des Erreurs (Try/Catch)

Pour l'automatisation, vous pourriez vouloir gérer les erreurs avec élégance. n8n a un nœud Error Trigger qui peut capturer les erreurs de workflow globalement, et une option Continue On Fail par nœud.

Dans le JSON du workflow, vous pouvez définir `"continueOnFail": true` sur les paramètres de n'importe quel nœud pour empêcher qu'une défaillance du nœud n'arrête le workflow.

### Exemple : Nœud Stop And Error pour arrêter délibérément l'exécution

```json
{
  "name": "Stop on Condition",
  "type": "n8n-nodes-base.stopAndError",
  "typeVersion": 1,
  "parameters": {
    "message": "Terminating workflow due to business rule X"
  }
}
```plaintext
**Explication :** Si ce nœud s'exécute, il arrêtera le workflow et produira une erreur avec le message donné. Utilisez-le après un IF ou une autre vérification si vous voulez arrêter gracieusement lorsque quelque chose ne va pas (au lieu de continuer).

Pour capturer les erreurs, l'Error Trigger est placé dans un workflow séparé ; lorsqu'un workflow génère une erreur, il peut capturer les détails et, par exemple, envoyer une alerte par email ou Slack.
