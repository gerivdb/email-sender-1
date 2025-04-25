# Instructions pour Projet N8N

## Table des matières

1. [Instructions pour Projet N8N](#section-1)
    1.1. [Objectif](#section-2)
        1.1.1. [. Utilisation des Ressources de Référence](#section-3)
        1.1.2. [. Structure du Workflow](#section-4)
        1.1.3. [. Configuration Spécifique des Nœuds](#section-5)
        1.1.4. [. Intégrité du JSON](#section-6)
        1.1.5. [. Clarification des Détails Manquants](#section-7)
        1.1.6. [. Format de Sortie](#section-8)
    1.2. [Objectif Final](#section-9)
    1.3. [Exemple de Structure de Base](#section-10)

## 1. Instructions pour Projet N8N <a name='section-1'></a>

### 1.1. Objectif <a name='section-2'></a>

Créer un workflow N8N fonctionnel et complet sous forme de fichier JSON valide, prêt à être importé dans l'interface N8N.

#### 1.1.1. . Utilisation des Ressources de Référence <a name='section-3'></a>

- Intégrer les meilleures pratiques et structures JSON des documents suivants:
  - **Guide des astuces N8N**
  - **N8N Cheat Sheet Guide**
  - **Workflow de gestion de communication + stockage de notes**
  - Autres workflows d'exemple fournis
- Respecter les directives concernant la structure des nœuds, les connexions, la gestion de la mémoire et le traitement des erreurs.

#### 1.1.2. . Structure du Workflow <a name='section-4'></a>

- Commencer par un nœud **Déclencheur de Chat** qui reçoit les messages utilisateur
- Intégrer un nœud de **Traitement Principal** qui peut appeler plusieurs outils (outil de temps, calculatrice, etc.)
- Inclure des nœuds **Sticky Note** aux endroits stratégiques pour documenter le workflow
- S'assurer que chaque nœud référence correctement les données en amont (en utilisant `$node["NomDuNoeud"]`) et transmet le contexte pertinent

#### 1.1.3. . Configuration Spécifique des Nœuds <a name='section-5'></a>

- Pour les nœuds **OpenRouter**, toujours configurer:
  - `"operation": "complete"`
  - `"resource": "text"`
  - `"model": "deepseek/deepseek-chat-v3-0324:free"`
  - Paramètre `"temperature"` approprié (ex: 0.1 pour des tâches précises, 0.7 pour des tâches créatives)
- Chaque nœud **OpenRouter** qui renvoie des données structurées doit avoir `"responseFormat": "json_object"`
- Vérifier que **tous les nœuds** sont correctement connectés dans la section `"connections"`
- Les nœuds de code doivent inclure une gestion des erreurs (try/catch)
- Fournir des références aux credentials (sans exposer les clés réelles)
- Ajouter des nœuds finaux qui marquent clairement la fin du workflow

#### 1.1.4. . Intégrité du JSON <a name='section-6'></a>

- Ne pas utiliser de placeholders comme `"API_KEY_HERE"` ou `[VOTRE_ID_DOC]`
- Utiliser des références génériques si nécessaire (ex: `"{{ mesCredentials }}"`)
- Le JSON doit être complet et prêt à être copié-collé, avec un minimum de modifications manuelles

#### 1.1.5. . Clarification des Détails Manquants <a name='section-7'></a>

- Si des détails sur certains nœuds sont manquants, demander des clarifications avant de générer le JSON final

#### 1.1.6. . Format de Sortie <a name='section-8'></a>

- Produire uniquement un JSON valide dans un bloc de code
- Pas d'images ou de tentatives de capture d'écran
- Pas de commentaires superflus en dehors du bloc de code

### 1.2. Objectif Final <a name='section-9'></a>

Fournir un fichier JSON autonome qui peut être importé directement dans N8N, représentant un flux de communication avec traitement avancé, incluant des outils pertinents et des notes explicatives, en s'appuyant sur les meilleures pratiques de la base de connaissances.

### 1.3. Exemple de Structure de Base <a name='section-10'></a>

```json
{
  "name": "Workflow Communication Avancée",
  "nodes": [
      "parameters": {
        "chatTriggerConfig": {
          "option1": "value1"
        }
      },
      "name": "Déclencheur Chat",
      "type": "n8n-nodes-base.chatTrigger",
      "position": [100, 300]
        "operation": "complete",
        "resource": "text",
        "model": "deepseek/deepseek-chat-v3-0324:free",
        "temperature": 0.7
      "name": "Traitement Principal",
      "type": "n8n-nodes-base.openRouter",
      "position": [300, 300]
  ],
  "connections": {
    "Déclencheur Chat": {
      "main": [
        [
            "node": "Traitement Principal",
            "type": "main",
            "index": 0
        ]
```

Si des détails sur certains nœuds sont manquants ou peu clairs, veuillez les lister et demander des précisions avant de produire le JSON final.

