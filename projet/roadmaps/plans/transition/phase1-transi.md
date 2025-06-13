# Développement Détaillé de la Phase 1 : Analyse et Préparation

## Vue d'ensemble de la Phase 1

La Phase 1 est cruciale car elle pose les fondations de tout le processus de transition. Elle comprend deux étapes principales :

1. Audit des Workflows Existants  
2. Création d'un Environnement de Test

Voici une représentation ASCII de la structure globale de cette phase :  
Copy  
PHASE 1: ANALYSE ET PRÉPARATION  
│  
├── ÉTAPE 1.1: AUDIT DES WORKFLOWS EXISTANTS  
│   ├── Inventaire des Nœuds et Fonctionnalités  
│   ├── Analyse des Credentials  
│   └── Évaluation des Expressions et Variables  
│  
└── ÉTAPE 1.2: CRÉATION D'UN ENVIRONNEMENT DE TEST  
    ├── Duplication des Workflows  
    ├── Configuration des Bases de Données de Test  
    └── Mise en Place d'un Système de Journalisation

## Étape 1.1 : Audit des Workflows Existants

### 1.1.1 Inventaire des Nœuds et Fonctionnalités

#### Workflow d'Inventaire Automatisé

Pour réaliser l'inventaire des nœuds et fonctionnalités, nous allons créer un workflow d'analyse qui parcourt tous les workflows existants et génère un rapport détaillé.  
Nœuds nécessaires :

1. Start Node (Manual Trigger)  
   * Type : n8n-nodes-base.manualTrigger  
   * Configuration : Standard  
2. Get Workflows  
   * Type : n8n-nodes-base.n8n  
   * Configuration :  
   * Copy  
   * {  
   *   "resource": "workflow",  
   *   "operation": "getAll",  
   *   "options": {  
   *     "active": true  
   *   }  
   * }  
3. Filter Email Sender Workflows  
   * Type : n8n-nodes-base.code  
   * Configuration :  
   * Copy  
   * // Filtrer uniquement les workflows Email Sender  
   * return items.filter(item \=\> {  
   *   const name \= item.json.name || '';  
   *   return name.includes('EMAIL\_SENDER') || name.includes('Email Sender');  
   * });  
4. Extract Nodes Information  
   * Type : n8n-nodes-base.code  
   * Configuration :  
   * Copy  
   * const workflowsAnalysis \= \[\];  
   * for (const item of items) {  
   *   const workflow \= item.json;  
   *   const nodes \= workflow.nodes || \[\];  
   *   const nodeTypes \= {};  
   *   const credentials \= {};  
   *   const expressions \= new Set();  
   *     
   *   // Analyser chaque nœud  
   *   for (const node of nodes) {  
   *     // Compter les types de nœuds  
   *     const nodeType \= node.type || 'unknown';  
   *     nodeTypes\[nodeType\] \= (nodeTypes\[nodeType\] || 0\) \+ 1;  
   *       
   *     // Collecter les credentials utilisés  
   *     if (node.credentials) {  
   *       Object.keys(node.credentials).forEach(credType \=\> {  
   *         const credName \= node.credentials\[credType\].name || 'unnamed';  
   *         credentials\[credType\] \= credentials\[credType\] || \[\];  
   *         if (\!credentials\[credType\].includes(credName)) {  
   *           credentials\[credType\].push(credName);  
   *         }  
   *       });  
   *     }  
   *       
   *     // Rechercher les expressions dans les paramètres  
   *     const findExpressions \= (obj) \=\> {  
   *       if (typeof obj \=== 'string' && obj.includes('{{')) {  
   *         // Extraire les expressions entre {{ et }}  
   *         const matches \= obj.match(/\\{\\{(\[^}\]+)\\}\\}/g) || \[\];  
   *         matches.forEach(match \=\> expressions.add(match));  
   *       } else if (typeof obj \=== 'object' && obj \!== null) {  
   *         Object.values(obj).forEach(val \=\> findExpressions(val));  
   *       }  
   *     };  
   *       
   *     if (node.parameters) {  
   *       findExpressions(node.parameters);  
   *     }  
   *   }  
   *     
   *   // Analyser les connexions  
   *   const connections \= workflow.connections || {};  
   *   const connectionMap \= {};  
   *     
   *   Object.entries(connections).forEach((\[sourceNodeName, sourceConnections\]) \=\>   
   *   {  
   *     connectionMap\[sourceNodeName\] \= connectionMap\[sourceNodeName\] || \[\];  
   *       
   *     if (sourceConnections.main) {  
   *       sourceConnections.main.forEach((outputs, outputIndex) \=\> {  
   *         outputs.forEach(connection \=\> {  
   *           connectionMap\[sourceNodeName\].push(connection.node);  
   *         });  
   *       });  
   *     }  
   *   });  
   *     
   *   // Ajouter l'analyse de ce workflow  
   *   workflowsAnalysis.push({  
   *     json: {  
   *       workflowId: workflow.id,  
   *       workflowName: workflow.name,  
   *       nodeCount: nodes.length,  
   *       nodeTypes,  
   *       credentials,  
   *       expressions: Array.from(expressions),  
   *       connections: connectionMap  
   *     }  
   *   });  
   * }  
   * return workflowsAnalysis;  
5. Generate Inventory Report  
   * Type : n8n-nodes-base.code  
   * Configuration :  
   * Copy  
   * // Générer un rapport d'inventaire au format Markdown  
   * const workflowsData \= items.map(item \=\> item.json);  
   * let report \= \`\# Inventaire des Workflows Email Sender\\n\\n\`;  

   * report \+= \`Date de génération: ${new Date().toISOString()}\\n\\n\`;  
   * report \+= \`\#\# Vue d'ensemble\\n\\n\`;  

   * report \+= \`Nombre total de workflows: ${workflowsData.length}\\n\\n\`;  
   * // Tableau des workflows  
   * report \+= \`\#\# Liste des Workflows\\n\\n\`;  

   * report \+= \`| ID | Nom | Nombre de Nœuds |\\n\`;  
   * report \+= \`|-----|-----|---------------|\\n\`;  
   * workflowsData.forEach(wf \=\> {  
   *   report \+= \`| ${wf.workflowId} | ${wf.workflowName} | ${wf.nodeCount} |\\n\`;  
   * });  
   * // Statistiques sur les types de nœuds  
   * report \+= \`\\n\#\# Types de Nœuds Utilisés\\n\\n\`;  

   * const allNodeTypes \= {};  
   * workflowsData.forEach(wf \=\> {  
   *   Object.entries(wf.nodeTypes).forEach((\[type, count\]) \=\> {  
   *     allNodeTypes\[type\] \= (allNodeTypes\[type\] || 0\) \+ count;  
   *   });  
   * });  
   * report \+= \`| Type de Nœud | Nombre d'Occurrences |\\n\`;  
   * report \+= \`|-------------|----------------------|\\n\`;  
   * Object.entries(allNodeTypes)  
   *   .sort((a, b) \=\> b\[1\] \- a\[1\])  
   *   .forEach((\[type, count\]) \=\> {  
   *     report \+= \`| ${type} | ${count} |\\n\`;  
   *   });  
   * // Credentials utilisés  
   * report \+= \`\\n\#\# Credentials Utilisés\\n\\n\`;  

   * const allCredentials \= {};  
   * workflowsData.forEach(wf \=\> {  
   *   Object.entries(wf.credentials).forEach((\[type, names\]) \=\> {  
   *     allCredentials\[type\] \= allCredentials\[type\] || new Set();  
   *     names.forEach(name \=\> allCredentials\[type\].add(name));  
   *   });  
   * });  
   * report \+= \`| Type de Credential | Noms |\\n\`;  
   * report \+= \`|-------------------|------|\\n\`;  
   * Object.entries(allCredentials).forEach((\[type, namesSet\]) \=\> {  
   *   const names \= Array.from(namesSet).join(', ');  
   *   report \+= \`| ${type} | ${names} |\\n\`;  
   * });  
   * // Expressions utilisées  
   * report \+= \`\\n\#\# Expressions Couramment Utilisées\\n\\n\`;  

   * const expressionCount \= {};  
   * workflowsData.forEach(wf \=\> {  
   *   wf.expressions.forEach(expr \=\> {  
   *     expressionCount\[expr\] \= (expressionCount\[expr\] || 0\) \+ 1;  
   *   });  
   * });  
   * report \+= \`| Expression | Nombre d'Occurrences |\\n\`;  
   * report \+= \`|------------|----------------------|\\n\`;  
   * Object.entries(expressionCount)  
   *   .sort((a, b) \=\> b\[1\] \- a\[1\])  
   *   .slice(0, 20\) // Top 20 des expressions les plus utilisées  
   *   .forEach((\[expr, count\]) \=\> {  
   *     report \+= \`| \\\`${expr}\\\` | ${count} |\\n\`;  
   *   });  
   * // Analyse des dépendances entre workflows  
   * report \+= \`\\n\#\# Dépendances entre Workflows\\n\\n\`;  

   * // Cette partie nécessiterait une analyse plus approfondie des connexions  
   * // entre les workflows, ce qui pourrait être complexe à automatiser.  
   * report \+= \`\*Cette section nécessite une analyse manuelle approfondie.\*\\n\\n\`;  
   * // Détails par workflow  
   * report \+= \`\\n\#\# Détails par Workflow\\n\\n\`;  

   * workflowsData.forEach(wf \=\> {  
   *   report \+= \`\#\#\# ${wf.workflowName}\\n\\n\`;  

   *   report \+= \`- \*\*ID\*\*: ${wf.workflowId}\\n\`;  
   *   report \+= \`- \*\*Nombre de nœuds\*\*: ${wf.nodeCount}\\n\\n\`;  
   *     
   *   report \+= \`\#\#\#\# Types de Nœuds\\n\\n\`;  

   *   report \+= \`| Type | Nombre |\\n\`;  
   *   report \+= \`|------|--------|\\n\`;  
   *     
   *   Object.entries(wf.nodeTypes)  
   *     .sort((a, b) \=\> b\[1\] \- a\[1\])  
   *     .forEach((\[type, count\]) \=\> {  
   *       report \+= \`| ${type} | ${count} |\\n\`;  
   *     });  
   *     
   *   report \+= \`\\n\#\#\#\# Flux de Données\\n\\n\`;  

   *   report \+= \`\\\`\\\`\\\`\\n\`;  
   *     
   *   // Représentation ASCII du flux de données  
   *   const processedNodes \= new Set();  
   *   const renderFlow \= (nodeName, depth \= 0\) \=\> {  
   *     if (processedNodes.has(nodeName)) return;  
   *     processedNodes.add(nodeName);  
   *       
   *     const indent \= '  '.repeat(depth);  
   *     report \+= \`${indent}${nodeName}\\n\`;  
   *       
   *     if (wf.connections\[nodeName\]) {  
   *       wf.connections\[nodeName\].forEach(targetNode \=\> {  
   *         report \+= \`${indent}  ↓\\n\`;  
   *         renderFlow(targetNode, depth \+ 1);  
   *       });  
   *     }  
   *   };  
   *     
   *   // Trouver les nœuds de départ (sans connexions entrantes)  
   *   const allTargetNodes \= new Set();  
   *   Object.values(wf.connections).forEach(targets \=\> {  
   *     targets.forEach(target \=\> allTargetNodes.add(target));  
   *   });  
   *     
   *   const startNodes \= Object.keys(wf.connections).filter(node \=\>   
   *   \!allTargetNodes.has(node));  
   *     
   *   startNodes.forEach(startNode \=\> {  
   *     renderFlow(startNode);  
   *   });  
   *     
   *   report \+= \`\\\`\\\`\\\`\\n\\n\`;  
   * });  
   * return \[{ json: { report } }\];  
6. Save Report to File  
   * Type : n8n-nodes-base.writeTextFile  
   * Configuration :  
   * Copy  
   * {  
   *   "fileName": "EMAIL\_SENDER\_INVENTORY\_REPORT.md",  
   *   "text": "={{ $json.report }}",  
   *   "append": false,  
   *   "encoding": "utf8"  
   * }

#### Diagramme de Flux pour l'Inventaire

Copy  
┌─────────────────┐     ┌───────────────┐     ┌──────────────────────┐  
│                 │     │               │     │                      │  
│  Manual Trigger │────▶│ Get Workflows │────▶│ Filter Email Sender  │  
│                 │     │               │     │      Workflows       │  
└─────────────────┘     └───────────────┘     └──────────────────────┘  
                                                         │  
                                                         ▼  
┌─────────────────┐     ┌───────────────────┐     ┌──────────────────┐  
│                 │     │                   │     │                  │  
│  Save Report    │◀────│ Generate Inventory│◀────│ Extract Nodes    │  
│    to File      │     │      Report       │     │   Information    │  
│                 │     │                   │     │                  │  
└─────────────────┘     └───────────────────┘     └──────────────────┘

### 1.1.2 Analyse des Credentials

#### Workflow d'Analyse des Credentials

Pour analyser les credentials utilisés dans les workflows existants, nous allons créer un workflow spécifique.  
Nœuds nécessaires :

1. Start Node (Manual Trigger)  
   * Type : n8n-nodes-base.manualTrigger  
   * Configuration : Standard  
2. Get Credentials  
   * Type : n8n-nodes-base.n8n  
   * Configuration :  
   * Copy  
   * {  
   *   "resource": "credential",  
   *   "operation": "getAll"  
   * }  
3. Extract Credentials Info  
   * Type : n8n-nodes-base.code  
   * Configuration :  
   * Copy  
   * // Extraire les informations pertinentes sur les credentials  
   * const credentialsInfo \= \[\];  
   * for (const item of items) {  
   *   const credential \= item.json;  
   *     
   *   credentialsInfo.push({  
   *     json: {  
   *       id: credential.id,  
   *       name: credential.name,  
   *       type: credential.type,  
   *       createdAt: credential.createdAt,  
   *       updatedAt: credential.updatedAt  
   *     }  
   *   });  
   * }  
   * return credentialsInfo;  
4. Get Workflows for Credential Usage  
   * Type : n8n-nodes-base.n8n  
   * Configuration :  
   * Copy  
   * {  
   *   "resource": "workflow",  
   *   "operation": "getAll"  
   * }  
5. Analyze Credential Usage  
   * Type : n8n-nodes-base.code  
   * Configuration :  
   * Copy  
   * // Analyser l'utilisation des credentials dans les workflows  
   * const credentials \= $input.item(0).json;  
   * const workflows \= $input.item(1).json;  
   * // Créer un mapping des credentials par ID pour un accès rapide  
   * const credentialsById \= {};  
   * credentials.forEach(cred \=\> {  
   *   credentialsById\[cred.id\] \= cred;  
   * });  
   * // Analyser l'utilisation des credentials dans chaque workflow  
   * const credentialUsage \= {};  
   * workflows.forEach(workflow \=\> {  
   *   const nodes \= workflow.nodes || \[\];  
   *     
   *   nodes.forEach(node \=\> {  
   *     if (node.credentials) {  
   *       Object.entries(node.credentials).forEach((\[credType, credInfo\]) \=\> {  
   *         const credId \= credInfo.id;  
   *           
   *         if (credId) {  
   *           credentialUsage\[credId\] \= credentialUsage\[credId\] || {  
   *             credential: credentialsById\[credId\] || { id: credId, name:   
   *             'Unknown', type: credType },  
   *             workflows: new Set(),  
   *             nodeTypes: new Set()  
   *           };  
   *             
   *           credentialUsage\[credId\].workflows.add(workflow.name);  
   *           credentialUsage\[credId\].nodeTypes.add(node.type);  
   *         }  
   *       });  
   *     }  
   *   });  
   * });  
   * // Convertir les ensembles en tableaux pour le rapport  
   * const usageReport \= Object.values(credentialUsage).map(usage \=\> ({  
   *   json: {  
   *     credentialId: usage.credential.id,  
   *     credentialName: usage.credential.name,  
   *     credentialType: usage.credential.type,  
   *     workflowCount: usage.workflows.size,  
   *     workflows: Array.from(usage.workflows),  
   *     nodeTypes: Array.from(usage.nodeTypes)  
   *   }  
   * }));  
   * return usageReport;  
6. Generate Credentials Report  
   * Type : n8n-nodes-base.code  
   * Configuration :  
   * Copy  
   * // Générer un rapport sur l'utilisation des credentials  
   * const usageData \= items.map(item \=\> item.json);  
   * let report \= \`\# Analyse des Credentials pour Email Sender\\n\\n\`;  

   * report \+= \`Date de génération: ${new Date().toISOString()}\\n\\n\`;  
   * report \+= \`\#\# Vue d'ensemble\\n\\n\`;  

   * report \+= \`Nombre total de credentials analysés: ${usageData.length}\\n\\n\`;  
   * // Tableau des credentials  
   * report \+= \`\#\# Liste des Credentials\\n\\n\`;  

   * report \+= \`| ID | Nom | Type | Nombre de Workflows |\\n\`;  
   * report \+= \`|-----|-----|------|--------------------|\\n\`;  
   * usageData.forEach(cred \=\> {  
   *   report \+= \`| ${cred.credentialId} | ${cred.credentialName} | ${cred.  
   *   credentialType} | ${cred.workflowCount} |\\n\`;  
   * });  
   * // Détails par credential  
   * report \+= \`\\n\#\# Détails par Credential\\n\\n\`;  

   * usageData.forEach(cred \=\> {  
   *   report \+= \`\#\#\# ${cred.credentialName} (${cred.credentialType})\\n\\n\`;  

   *   report \+= \`- \*\*ID\*\*: ${cred.credentialId}\\n\`;  
   *   report \+= \`- \*\*Utilisé dans ${cred.workflowCount} workflow(s)\*\*\\n\\n\`;  
   *     
   *   report \+= \`\#\#\#\# Workflows\\n\\n\`;  

   *   cred.workflows.forEach(wf \=\> {  
   *     report \+= \`- ${wf}\\n\`;  
   *   });  
   *     
   *   report \+= \`\\n\#\#\#\# Types de Nœuds\\n\\n\`;  

   *   cred.nodeTypes.forEach(nodeType \=\> {  
   *     report \+= \`- ${nodeType}\\n\`;  
   *   });  
   *     
   *   report \+= \`\\n\`;  
   * });  
   * // Recommandations  
   * report \+= \`\#\# Recommandations\\n\\n\`;  

   * // Identifier les credentials potentiellement réutilisables  
   * const reusableCredentials \= usageData.filter(cred \=\> cred.workflowCount \=== 1);  
   * if (reusableCredentials.length \> 0\) {  
   *   report \+= \`\#\#\# Credentials Potentiellement Réutilisables\\n\\n\`;  

   *   report \+= \`Les credentials suivants ne sont utilisés que dans un seul   
   *   workflow et pourraient être réutilisés dans la nouvelle architecture:\\n\\n\`;  
   *     
   *   reusableCredentials.forEach(cred \=\> {  
   *     report \+= \`- \*\*${cred.credentialName}\*\* (${cred.credentialType}) \-   
   *     Actuellement utilisé dans: ${cred.workflows\[0\]}\\n\`;  
   *   });  
   * }  
   * // Identifier les services externes utilisés  
   * const serviceTypes \= new Set();  
   * usageData.forEach(cred \=\> {  
   *   serviceTypes.add(cred.credentialType);  
   * });  
   * report \+= \`\\n\#\#\# Services Externes Utilisés\\n\\n\`;  

   * Array.from(serviceTypes).forEach(service \=\> {  
   *   report \+= \`- ${service}\\n\`;  
   * });  
   * return \[{ json: { report } }\];  
7. Save Credentials Report  
   * Type : n8n-nodes-base.writeTextFile  
   * Configuration :  
   * Copy  
   * {  
   *   "fileName": "EMAIL\_SENDER\_CREDENTIALS\_REPORT.md",  
   *   "text": "={{ $json.report }}",  
   *   "append": false,  
   *   "encoding": "utf8"  
   * }

#### Diagramme de Flux pour l'Analyse des Credentials

Copy  
┌─────────────────┐     ┌───────────────┐     ┌──────────────────────┐  
│                 │     │               │     │                      │  
│  Manual Trigger │────▶│ Get Credentials │──┬─▶│ Extract Credentials  │  
│                 │     │               │  │  │      Info            │  
└─────────────────┘     └───────────────┘  │  └──────────────────────┘  
                                          │             │  
                                          │             ▼  
                                          │  ┌──────────────────────┐  
                                          │  │                      │  
                                          └─▶│ Get Workflows for    │  
                                             │  Credential Usage    │  
                                             └──────────────────────┘  
                                                         │  
                                                         ▼  
┌─────────────────┐     ┌───────────────────┐     ┌──────────────────┐  
│                 │     │                   │     │                  │  
│  Save Credentials│◀────│ Generate Credentials│◀────│ Analyze Credential│  
│    Report       │     │      Report       │     │      Usage       │  
│                 │     │                   │     │                  │  
└─────────────────┘     └───────────────────┘     └──────────────────┘

### 1.1.3 Évaluation des Expressions et Variables

#### Workflow d'Analyse des Expressions

Pour évaluer les expressions et variables utilisées dans les workflows, nous allons créer un workflow d'analyse spécifique.  
Nœuds nécessaires :

1. Start Node (Manual Trigger)  
   * Type : n8n-nodes-base.manualTrigger  
   * Configuration : Standard  
2. Get Workflows  
   * Type : n8n-nodes-base.n8n  
   * Configuration :  
   * Copy  
   * {  
   *   "resource": "workflow",  
   *   "operation": "getAll",  
   *   "options": {  
   *     "active": true  
   *   }  
   * }  
3. Filter Email Sender Workflows  
   * Type : n8n-nodes-base.code  
   * Configuration :  
   * Copy  
   * // Filtrer uniquement les workflows Email Sender  
   * return items.filter(item \=\> {  
   *   const name \= item.json.name || '';  
   *   return name.includes('EMAIL\_SENDER') || name.includes('Email Sender');  
   * });  
4. Extract Expressions  
   * Type : n8n-nodes-base.code  
   * Configuration :  
   * Copy  
   * // Extraire toutes les expressions des workflows  
   * const workflowExpressions \= \[\];  
   * for (const item of items) {  
   *   const workflow \= item.json;  
   *   const nodes \= workflow.nodes || \[\];  
   *   const expressions \= \[\];  
   *     
   *   // Fonction récursive pour trouver les expressions dans un objet  
   *   const findExpressions \= (obj, path \= '') \=\> {  
   *     if (typeof obj \=== 'string' && obj.includes('{{')) {  
   *       // Extraire les expressions entre {{ et }}  
   *       const matches \= obj.match(/\\{\\{(\[^}\]+)\\}\\}/g) || \[\];  
   *       matches.forEach(match \=\> {  
   *         expressions.push({  
   *           expression: match,  
   *           path: path,  
   *           cleaned: match.replace(/\\{\\{|\\}\\}/g, '').trim()  
   *         });  
   *       });  
   *     } else if (typeof obj \=== 'object' && obj \!== null) {  
   *       Object.entries(obj).forEach((\[key, val\]) \=\> {  
   *         const newPath \= path ? \`${path}.${key}\` : key;  
   *         findExpressions(val, newPath);  
   *       });  
   *     }  
   *   };  
   *     
   *   // Analyser chaque nœud  
   *   nodes.forEach(node \=\> {  
   *     if (node.parameters) {  
   *       findExpressions(node.parameters, \`${node.name}.parameters\`);  
   *     }  
   *   });  
   *     
   *   // Regrouper les expressions par type  
   *   const expressionTypes \= {  
   *     json: \[\],  
   *     node: \[\],  
   *     input: \[\],  
   *     item: \[\],  
   *     parameters: \[\],  
   *     env: \[\],  
   *     workflow: \[\],  
   *     other: \[\]  
   *   };  
   *     
   *   expressions.forEach(expr \=\> {  
   *     const cleaned \= expr.cleaned;  
   *       
   *     if (cleaned.startsWith('$json')) {  
   *       expressionTypes.json.push(expr);  
   *     } else if (cleaned.startsWith('$node')) {  
   *       expressionTypes.node.push(expr);  
   *     } else if (cleaned.startsWith('$input')) {  
   *       expressionTypes.input.push(expr);  
   *     } else if (cleaned.startsWith('$item')) {  
   *       expressionTypes.item.push(expr);  
   *     } else if (cleaned.startsWith('$parameter')) {  
   *       expressionTypes.parameters.push(expr);  
   *     } else if (cleaned.startsWith('$env')) {  
   *       expressionTypes.env.push(expr);  
   *     } else if (cleaned.startsWith('$workflow')) {  
   *       expressionTypes.workflow.push(expr);  
   *     } else {  
   *       expressionTypes.other.push(expr);  
   *     }  
   *   });  
   *     
   *   workflowExpressions.push({  
   *     json: {  
   *       workflowId: workflow.id,  
   *       workflowName: workflow.name,  
   *       expressionCount: expressions.length,  
   *       expressions: expressions,  
   *       expressionTypes: expressionTypes  
   *     }  
   *   });  
   * }  
   * return workflowExpressions;  
5. Generate Expressions Report  
   * Type : n8n-nodes-base.code  
   * Configuration :  
   * Copy  
   * // Générer un rapport sur les expressions utilisées  
   * const workflowsData \= items.map(item \=\> item.json);  
   * let report \= \`\# Analyse des Expressions pour Email Sender\\n\\n\`;  

   * report \+= \`Date de génération: ${new Date().toISOString()}\\n\\n\`;  
   * report \+= \`\#\# Vue d'ensemble\\n\\n\`;  

   * report \+= \`Nombre total de workflows analysés: ${workflowsData.length}\\n\\n\`;  
   * // Tableau des workflows  
   * report \+= \`\#\# Expressions par Workflow\\n\\n\`;  

   * report \+= \`| Workflow | Nombre d'Expressions | $json | $node | $input |   
   * $item | $parameter | $env | $workflow | Autres |\\n\`;  
   * report \+= \`|----------|---------------------|-------|-------|--------|-------|  
   * \------------|------|-----------|--------|\\n\`;  
   * workflowsData.forEach(wf \=\> {  
   *   const types \= wf.expressionTypes;  
   *   report \+= \`| ${wf.workflowName} | ${wf.expressionCount} | ${types.json.  
   *   length} | ${types.node.length} | ${types.input.length} | ${types.item.  
   *   length} | ${types.parameters.length} | ${types.env.length} | ${types.  
   *   workflow.length} | ${types.other.length} |\\n\`;  
   * });  
   * // Expressions courantes  
   * report \+= \`\\n\#\# Expressions $json Courantes\\n\\n\`;  

   * const allJsonExpressions \= {};  
   * workflowsData.forEach(wf \=\> {  
   *   wf.expressionTypes.json.forEach(expr \=\> {  
   *     const cleaned \= expr.cleaned;  
   *     allJsonExpressions\[cleaned\] \= (allJsonExpressions\[cleaned\] || 0\) \+ 1;  
   *   });  
   * });  
   * report \+= \`| Expression | Occurrences |\\n\`;  
   * report \+= \`|------------|-------------|\\n\`;  
   * Object.entries(allJsonExpressions)  
   *   .sort((a, b) \=\> b\[1\] \- a\[1\])  
   *   .slice(0, 20\) // Top 20  
   *   .forEach((\[expr, count\]) \=\> {  
   *     report \+= \`| \\\`${expr}\\\` | ${count} |\\n\`;  
   *   });  
   * // Expressions $node  
   * report \+= \`\\n\#\# Expressions $node Courantes\\n\\n\`;  

   * const allNodeExpressions \= {};  
   * workflowsData.forEach(wf \=\> {  
   *   wf.expressionTypes.node.forEach(expr \=\> {  
   *     const cleaned \= expr.cleaned;  
   *     allNodeExpressions\[cleaned\] \= (allNodeExpressions\[cleaned\] || 0\) \+ 1;  
   *   });  
   * });  
   * report \+= \`| Expression | Occurrences |\\n\`;  
   * report \+= \`|------------|-------------|\\n\`;  
   * Object.entries(allNodeExpressions)  
   *   .sort((a, b) \=\> b\[1\] \- a\[1\])  
   *   .slice(0, 20\) // Top 20  
   *   .forEach((\[expr, count\]) \=\> {  
   *     report \+= \`| \\\`${expr}\\\` | ${count} |\\n\`;  
   *   });  
   * // Variables et leur portée  
   * report \+= \`\\n\#\# Variables et leur Portée\\n\\n\`;  

   * report \+= \`\#\#\# Variables $json\\n\\n\`;  

   * report \+= \`Les variables $json sont limitées au contexte de l'item courant   
   * dans le workflow.\\n\\n\`;  
   * report \+= \`\#\#\# Variables $node\\n\\n\`;  

   * report \+= \`Les variables $node permettent d'accéder aux données d'un nœud   
   * spécifique, indépendamment du flux de données.\\n\\n\`;  
   * report \+= \`\#\#\# Variables $input\\n\\n\`;  

   * report \+= \`Les variables $input sont utilisées principalement dans les nœuds   
   * Code pour accéder aux données d'entrée.\\n\\n\`;  
   * // Expressions qui pourraient nécessiter une adaptation  
   * report \+= \`\\n\#\# Expressions Nécessitant Potentiellement une Adaptation\\n\\n\`;  

   * // Expressions faisant référence à des nœuds spécifiques  
   * const nodeReferences \= new Set();  
   * workflowsData.forEach(wf \=\> {  
   *   wf.expressionTypes.node.forEach(expr \=\> {  
   *     const match \= expr.cleaned.match(/\\$node\\\["(\[^"\]+)"\\\]/);  
   *     if (match) {  
   *       nodeReferences.add(match\[1\]);  
   *     }  
   *   });  
   * });  
   * report \+= \`\#\#\# Références à des Nœuds Spécifiques\\n\\n\`;  

   * report \+= \`Les expressions suivantes font référence à des nœuds spécifiques et   
   * pourraient nécessiter une adaptation dans la nouvelle architecture:\\n\\n\`;  
   * Array.from(nodeReferences).forEach(nodeName \=\> {  
   *   report \+= \`- \\\`$node\["${nodeName}"\]\\\`\\n\`;  
   * });  
   * // Variables d'environnement  
   * const envVariables \= new Set();  
   * workflowsData.forEach(wf \=\> {  
   *   wf.expressionTypes.env.forEach(expr \=\> {  
   *     const match \= expr.cleaned.match(/\\$env\\.(\[a-zA-Z0-9\_\]+)/);  
   *     if (match) {  
   *       envVariables.add(match\[1\]);  
   *     }  
   *   });  
   * });  
   * if (envVariables.size \> 0\) {  
   *   report \+= \`\\n\#\#\# Variables d'Environnement\\n\\n\`;  

   *   report \+= \`Les variables d'environnement suivantes sont utilisées et devront   
   *   être configurées dans le nouvel environnement:\\n\\n\`;  
   *     
   *   Array.from(envVariables).forEach(envVar \=\> {  
   *     report \+= \`- \\\`$env.${envVar}\\\`\\n\`;  
   *   });  
   * }  
   * return \[{ json: { report } }\];  
6. Save Expressions Report  
   * Type : n8n-nodes-base.writeTextFile  
   * Configuration :  
   * Copy  
   * {  
   *   "fileName": "EMAIL\_SENDER\_EXPRESSIONS\_REPORT.md",  
   *   "text": "={{ $json.report }}",  
   *   "append": false,  
   *   "encoding": "utf8"  
   * }

#### Diagramme de Flux pour l'Analyse des Expressions

Copy  
┌─────────────────┐     ┌───────────────┐       
thumb\_up  
thumb\_down  
Tu t'es interrompu juste avant "6. Save Expressions Report", termine \!  
Augment  
Je vais terminer le développement détaillé de la Phase 1, en reprenant à partir du diagramme de flux pour l'analyse des expressions.

#### Diagramme de Flux pour l'Analyse des Expressions

Copy  
┌─────────────────┐     ┌───────────────┐     ┌──────────────────────┐  
│                 │     │               │     │                      │  
│  Manual Trigger │────▶│ Get Workflows │────▶│ Filter Email Sender  │  
│                 │     │               │     │      Workflows       │  
└─────────────────┘     └───────────────┘     └──────────────────────┘  
                                                         │  
                                                         ▼  
┌─────────────────┐     ┌───────────────────┐     ┌──────────────────┐  
│                 │     │                   │     │                  │  
│  Save Expressions│◀────│ Generate Expressions│◀────│ Extract Expressions│  
│    Report       │     │      Report       │     │                  │  
│                 │     │                   │     │                  │  
└─────────────────┘     └───────────────────┘     └──────────────────┘

## Étape 1.2 : Création d'un Environnement de Test

### 1.2.1 Duplication des Workflows

#### Workflow de Duplication Automatisée

Pour dupliquer les workflows existants et créer un environnement de test, nous allons créer un workflow d'automatisation.  
Nœuds nécessaires :

1. Start Node (Manual Trigger)  
   * Type : n8n-nodes-base.manualTrigger  
   * Configuration : Standard  
2. Get Workflows  
   * Type : n8n-nodes-base.n8n  
   * Configuration :  
   * Copy  
   * {  
   *   "resource": "workflow",  
   *   "operation": "getAll",  
   *   "options": {  
   *     "active": true  
   *   }  
   * }  
3. Filter Email Sender Workflows  
   * Type : n8n-nodes-base.code  
   * Configuration :  
   * Copy  
   * // Filtrer uniquement les workflows Email Sender  
   * return items.filter(item \=\> {  
   *   const name \= item.json.name || '';  
   *   return (name.includes('EMAIL\_SENDER') || name.includes('Email Sender')) &&   
   *   \!name.includes('TEST\_');  
   * });  
4. Prepare Duplicate Workflows  
   * Type : n8n-nodes-base.code  
   * Configuration :  
   * Copy  
   * // Préparer les workflows à dupliquer  
   * const workflowsToDuplicate \= \[\];  
   * for (const item of items) {  
   *   const workflow \= item.json;  
   *     
   *   // Créer une copie du workflow avec un nouveau nom  
   *   const duplicatedWorkflow \= {  
   *     ...workflow,  
   *     name: \`TEST\_${workflow.name}\`,  
   *     active: false // Désactiver par défaut  
   *   };  
   *     
   *   // Supprimer l'ID pour que n8n en génère un nouveau  
   *   delete duplicatedWorkflow.id;  
   *     
   *   workflowsToDuplicate.push({  
   *     json: {  
   *       originalName: workflow.name,  
   *       duplicatedWorkflow  
   *     }  
   *   });  
   * }  
   * return workflowsToDuplicate;  
5. Create Duplicate Workflows  
   * Type : n8n-nodes-base.n8n  
   * Configuration :  
   * Copy  
   * {  
   *   "resource": "workflow",  
   *   "operation": "create",  
   *   "workflowData": "={{ $json.duplicatedWorkflow }}"  
   * }  
6. Generate Duplication Report  
   * Type : n8n-nodes-base.code  
   * Configuration :  
   * Copy  
   * // Générer un rapport sur les workflows dupliqués  
   * const duplicatedWorkflows \= items.map(item \=\> ({  
   *   originalName: item.json.originalName,  
   *   newName: item.json.name,  
   *   newId: item.json.id  
   * }));  
   * let report \= \`\# Rapport de Duplication des Workflows Email Sender\\n\\n\`;  

   * report \+= \`Date de génération: ${new Date().toISOString()}\\n\\n\`;  
   * report \+= \`\#\# Workflows Dupliqués\\n\\n\`;  

   * report \+= \`| Workflow Original | Workflow de Test | ID |\\n\`;  
   * report \+= \`|------------------|-----------------|----|\\n\`;  
   * duplicatedWorkflows.forEach(wf \=\> {  
   *   report \+= \`| ${wf.originalName} | ${wf.newName} | ${wf.newId} |\\n\`;  
   * });  
   * report \+= \`\\n\#\# Prochaines Étapes\\n\\n\`;  

   * report \+= \`1. Configurer les bases de données Notion de test\\n\`;  
   * report \+= \`2. Configurer un calendrier Google de test\\n\`;  
   * report \+= \`3. Mettre en place des comptes email de test\\n\`;  
   * report \+= \`4. Ajouter des nœuds de journalisation\\n\`;  
   * return \[{ json: { report } }\];  
7. Save Duplication Report  
   * Type : n8n-nodes-base.writeTextFile  
   * Configuration :  
   * Copy  
   * {  
   *   "fileName": "EMAIL\_SENDER\_DUPLICATION\_REPORT.md",  
   *   "text": "={{ $json.report }}",  
   *   "append": false,  
   *   "encoding": "utf8"  
   * }

#### Diagramme de Flux pour la Duplication des Workflows

Copy  
┌─────────────────┐     ┌───────────────┐     ┌──────────────────────┐  
│                 │     │               │     │                      │  
│  Manual Trigger │────▶│ Get Workflows │────▶│ Filter Email Sender  │  
│                 │     │               │     │      Workflows       │  
└─────────────────┘     └───────────────┘     └──────────────────────┘  
                                                         │  
                                                         ▼  
┌─────────────────┐     ┌───────────────────┐     ┌──────────────────┐  
│                 │     │                   │     │                  │  
│  Save Duplication│◀────│ Generate Duplication│◀────│ Create Duplicate │  
│    Report       │     │      Report       │     │    Workflows     │  
│                 │     │                   │     │                  │  
└─────────────────┘     └───────────────────┘     └──────────────────┘  
                                                         ▲  
                                                         │  
                                                  ┌──────────────────┐  
                                                  │                  │  
                                                  │ Prepare Duplicate│  
                                                  │    Workflows     │  
                                                  │                  │  
                                                  └──────────────────┘

### 1.2.2 Configuration des Bases de Données de Test

#### Workflow de Configuration des Bases de Données de Test

Pour configurer les bases de données de test, nous allons créer un workflow qui duplique les bases de données Notion existantes.  
Nœuds nécessaires :

1. Start Node (Manual Trigger)  
   * Type : n8n-nodes-base.manualTrigger  
   * Configuration : Standard  
2. Get Notion Databases  
   * Type : n8n-nodes-base.notion  
   * Configuration :  
   * Copy  
   * {  
   *   "resource": "database",  
   *   "operation": "getAll"  
   * }  
3. Filter Relevant Databases  
   * Type : n8n-nodes-base.code  
   * Configuration :  
   * Copy  
   * // Filtrer les bases de données pertinentes pour Email Sender  
   * const relevantDatabases \= \[\];  
   * const keywordFilters \= \['LOT1', 'Dispo', 'Booking', 'Contact'\];  
   * for (const item of items) {  
   *   const database \= item.json;  
   *   const title \= database.title?.\[0\]?.plain\_text || '';  
   *     
   *   // Vérifier si le titre contient l'un des mots-clés  
   *   if (keywordFilters.some(keyword \=\> title.includes(keyword))) {  
   *     relevantDatabases.push({  
   *       json: {  
   *         id: database.id,  
   *         title: title,  
   *         properties: database.properties,  
   *         url: database.url  
   *       }  
   *     });  
   *   }  
   * }  
   * return relevantDatabases;  
4. Prepare Test Database Configuration  
   * Type : n8n-nodes-base.code  
   * Configuration :  
   * Copy  
   * // Préparer la configuration des bases de données de test  
   * const testDatabases \= \[\];  
   * for (const item of items) {  
   *   const database \= item.json;  
   *     
   *   testDatabases.push({  
   *     json: {  
   *       originalId: database.id,  
   *       originalTitle: database.title,  
   *       testTitle: \`TEST\_${database.title}\`,  
   *       properties: database.properties,  
   *       url: database.url  
   *     }  
   *   });  
   * }  
   * return testDatabases;  
5. Generate Database Configuration Guide  
   * Type : n8n-nodes-base.code  
   * Configuration :  
   * Copy  
   * // Générer un guide de configuration pour les bases de données de test  
   * const databases \= items.map(item \=\> item.json);  
   * let guide \= \`\# Guide de Configuration des Bases de Données de Test\\n\\n\`;  

   * guide \+= \`Date de génération: ${new Date().toISOString()}\\n\\n\`;  
   * guide \+= \`\#\# Bases de Données à Dupliquer\\n\\n\`;  

   * guide \+= \`| Base de Données Originale | ID | URL |\\n\`;  
   * guide \+= \`|---------------------------|----|----|\`;  
   * databases.forEach(db \=\> {  
   *   guide \+= \`\\n| ${db.originalTitle} | ${db.originalId} | ${db.url} |\`;  
   * });  
   * guide \+= \`\\n\\n\#\# Instructions de Duplication\\n\\n\`;  

   * guide \+= \`Pour chaque base de données listée ci-dessus, suivez ces   
   * étapes:\\n\\n\`;  
   * guide \+= \`1. Ouvrez la base de données dans Notion en utilisant l'URL   
   * fournie\\n\`;  
   * guide \+= \`2. Cliquez sur les trois points (...) dans le coin supérieur   
   * droit\\n\`;  
   * guide \+= \`3. Sélectionnez "Duplicate"\\n\`;  
   * guide \+= \`4. Renommez la copie en ajoutant le préfixe "TEST\_"\\n\`;  
   * guide \+= \`5. Videz le contenu de la base de données dupliquée (supprimez   
   * toutes les entrées)\\n\`;  
   * guide \+= \`6. Ajoutez quelques entrées de test\\n\\n\`;  
   * guide \+= \`\#\# Configuration des Credentials Notion\\n\\n\`;  

   * guide \+= \`Après avoir dupliqué toutes les bases de données, vous devrez:\\n\\n\`;  
   * guide \+= \`1. Créer un nouvel intégration Notion pour l'environnement de   
   * test\\n\`;  
   * guide \+= \`2. Partager chaque base de données dupliquée avec cette nouvelle   
   * intégration\\n\`;  
   * guide \+= \`3. Créer un nouveau credential Notion dans n8n avec le token de   
   * cette intégration\\n\`;  
   * guide \+= \`4. Mettre à jour les workflows de test pour utiliser ce nouveau   
   * credential\\n\\n\`;  
   * guide \+= \`\#\# Mise à Jour des IDs de Base de Données\\n\\n\`;  

   * guide \+= \`Après avoir dupliqué les bases de données, vous devrez mettre à jour   
   * les IDs dans les workflows de test:\\n\\n\`;  
   * databases.forEach(db \=\> {  
   *   guide \+= \`- Remplacer l'ID \\\`${db.originalId}\\\` par l'ID de la nouvelle base   
   *   de données \\\`TEST\_${db.originalTitle}\\\`\\n\`;  
   * });  
   * return \[{ json: { guide } }\];  
6. Save Database Configuration Guide  
   * Type : n8n-nodes-base.writeTextFile  
   * Configuration :  
   * Copy  
   * {  
   *   "fileName": "EMAIL\_SENDER\_TEST\_DATABASES\_GUIDE.md",  
   *   "text": "={{ $json.guide }}",  
   *   "append": false,  
   *   "encoding": "utf8"  
   * }

#### Diagramme de Flux pour la Configuration des Bases de Données de Test

Copy  
┌─────────────────┐     ┌───────────────────┐     ┌──────────────────────┐  
│                 │     │                   │     │                      │  
│  Manual Trigger │────▶│ Get Notion Databases │──▶│ Filter Relevant     │  
│                 │     │                   │     │    Databases         │  
└─────────────────┘     └───────────────────┘     └──────────────────────┘  
                                                             │  
                                                             ▼  
┌─────────────────────┐     ┌───────────────────────┐     ┌──────────────────┐  
│                     │     │                       │     │                  │  
│  Save Database      │◀────│ Generate Database     │◀────│ Prepare Test     │  
│  Configuration Guide│     │ Configuration Guide   │     │ Database Config  │  
│                     │     │                       │     │                  │  
└─────────────────────┘     └───────────────────────┘     └──────────────────┘

### 1.2.3 Mise en Place d'un Système de Journalisation

#### Workflow de Création du Système de Journalisation

Pour mettre en place un système de journalisation, nous allons créer un workflow central de journalisation et des nœuds réutilisables.  
Nœuds nécessaires pour le Workflow Central de Journalisation :

1. Start Node (Webhook Trigger)  
   * Type : n8n-nodes-base.webhook  
   * Configuration :  
   * Copy  
   * {  
   *   "path": "log",  
   *   "responseMode": "onReceived",  
   *   "options": {  
   *     "responseData": "firstEntryJson"  
   *   }  
   * }  
2. Process Log Entry  
   * Type : n8n-nodes-base.code  
   * Configuration :  
   * Copy  
   * // Traiter l'entrée de journal  
   * const logEntry \= $json;  
   * // Ajouter un timestamp s'il n'existe pas  
   * if (\!logEntry.timestamp) {  
   *   logEntry.timestamp \= new Date().toISOString();  
   * }  
   * // Standardiser le format  
   * const standardizedEntry \= {  
   *   timestamp: logEntry.timestamp,  
   *   level: logEntry.level || 'INFO',  
   *   source: logEntry.source || 'Unknown',  
   *   message: logEntry.message || '',  
   *   details: logEntry.details || {},  
   *   workflow: {  
   *     id: logEntry.workflowId || '',  
   *     name: logEntry.workflowName || ''  
   *   },  
   *   node: {  
   *     id: logEntry.nodeId || '',  
   *     name: logEntry.nodeName || ''  
   *   }  
   * };  
   * // Ajouter une représentation formatée pour l'affichage  
   * standardizedEntry.formatted \= \`\[${standardizedEntry.timestamp}\] \[$  
   * {standardizedEntry.level}\] \[${standardizedEntry.source}\] ${standardizedEntry.  
   * message}\`;  
   * return { json: standardizedEntry };  
3. Save Log to File  
   * Type : n8n-nodes-base.writeTextFile  
   * Configuration :  
   * Copy  
   * {  
   *   "fileName": "EMAIL\_SENDER\_LOGS.jsonl",  
   *   "text": "={{ JSON.stringify($json) \+ '\\\\n' }}",  
   *   "append": true,  
   *   "encoding": "utf8"  
   * }  
4. Conditional Alert for Errors  
   * Type : n8n-nodes-base.if  
   * Configuration :  
   * Copy  
   * {  
   *   "conditions": {  
   *     "string": \[  
   *       {  
   *         "value1": "={{ $json.level }}",  
   *         "operation": "equals",  
   *         "value2": "ERROR"  
   *       }  
   *     \]  
   *   }  
   * }  
5. Send Error Alert (If True Branch)  
   * Type : n8n-nodes-base.emailSend  
   * Configuration :  
   * Copy  
   * {  
   *   "fromEmail": "alerts@example.com",  
   *   "toEmail": "admin@example.com",  
   *   "subject": "EMAIL SENDER ERROR: {{ $json.message }}",  
   *   "text": "=Error details:\\n\\nTimestamp: {{ $json.timestamp }}\\nSource: {{   
   *   $json.source }}\\nWorkflow: {{ $json.workflow.name }}\\nNode: {{ $json.node.  
   *   name }}\\n\\nMessage: {{ $json.message }}\\n\\nDetails: {{ JSON.stringify($json.  
   *   details, null, 2\) }}"  
   * }

Nœud de Journalisation Réutilisable (à ajouter aux workflows de test) :

1. Logger Node (Code)  
   * Type : n8n-nodes-base.code  
   * Configuration :  
   * Copy  
   * // Nœud de journalisation réutilisable  
   * // Configuration  
   * const config \= {  
   *   logLevel: 'INFO', // Peut être 'DEBUG', 'INFO', 'WARNING', 'ERROR'  
   *   source: $workflow.name || 'Unknown',  
   *   logEndpoint: 'http://localhost:5678/webhook/log' // URL du webhook de   
   *   journalisation  
   * };  
   * // Fonction de journalisation  
   * const log \= async (level, message, details \= {}) \=\> {  
   *   // Ne journaliser que si le niveau est suffisant  
   *   const levels \= { 'DEBUG': 0, 'INFO': 1, 'WARNING': 2, 'ERROR': 3 };  
   *   if (levels\[level\] \< levels\[config.logLevel\]) {  
   *     return null;  
   *   }  
   *     
   *   // Créer l'entrée de journal  
   *   const logEntry \= {  
   *     timestamp: new Date().toISOString(),  
   *     level,  
   *     source: config.source,  
   *     message,  
   *     details,  
   *     workflowId: $workflow.id,  
   *     workflowName: $workflow.name,  
   *     nodeId: $node.id,  
   *     nodeName: $node.name  
   *   };  
   *     
   *   // Envoyer au webhook de journalisation  
   *   try {  
   *     const response \= await $http.post(config.logEndpoint, logEntry);  
   *     return response;  
   *   } catch (error) {  
   *     console.error('Failed to send log entry:', error.message);  
   *     return null;  
   *   }  
   * };  
   * // Journaliser l'entrée actuelle  
   * const message \= $json.message || 'No message provided';  
   * const level \= $json.level || 'INFO';  
   * const details \= $json.details || {};  
   * log(level, message, details);  
   * // Retourner l'item original pour ne pas perturber le flux  
   * return items;  
2. Logger Workflow Subworkflow  
   * Type : n8n-nodes-base.executeWorkflow  
   * Configuration :  
   * Copy  
   * {  
   *   "workflowId": "={{ $json.loggerWorkflowId }}",  
   *   "additionalData": {  
   *     "level": "={{ $json.level || 'INFO' }}",  
   *     "message": "={{ $json.message }}",  
   *     "details": "={{ $json.details || {} }}",  
   *     "source": "={{ $workflow.name }}",  
   *     "workflowId": "={{ $workflow.id }}",  
   *     "workflowName": "={{ $workflow.name }}",  
   *     "nodeId": "={{ $node.id }}",  
   *     "nodeName": "={{ $node.name }}"  
   *   }  
   * }

#### Diagramme de Flux pour le Système de Journalisation

Copy  
┌─────────────────┐     ┌───────────────────┐     ┌──────────────────────┐  
│                 │     │                   │     │                      │  
│ Webhook Trigger │────▶│ Process Log Entry │────▶│ Save Log to File     │  
│                 │     │                   │     │                      │  
└─────────────────┘     └───────────────────┘     └──────────────────────┘  
                                                             │  
                                                             ▼  
                                                  ┌──────────────────────┐  
                                                  │                      │  
                                                  │ Conditional Alert    │  
                                                  │    for Errors        │  
                                                  └──────────────────────┘  
                                                       ┌──────┴──────┐  
                                                       │             │  
                                                       ▼             ▼  
                                          ┌─────────────────┐      (End)  
                                          │                 │  
                                          │ Send Error Alert│  
                                          │                 │  
                                          └─────────────────┘

#### Diagramme d'Intégration du Système de Journalisation dans les Workflows de Test

Copy  
┌─────────────────┐     ┌───────────────────┐     ┌──────────────────────┐  
│                 │     │                   │     │                      │  
│ Workflow Node   │────▶│ Processing Node   │────▶│ Next Node            │  
│                 │     │                   │     │                      │  
└─────────────────┘     └───────────────────┘     └──────────────────────┘  
                                 │  
                                 │  
                                 ▼  
                        ┌─────────────────┐  
                        │                 │  
                        │ Logger Node     │────────────────┐  
                        │                 │                │  
                        └─────────────────┘                │  
                                                           │  
                                                           │  
                                                           ▼  
                                                ┌──────────────────────┐  
                                                │                      │  
                                                │ Central Logging      │  
                                                │    Workflow          │  
                                                └──────────────────────┘

## Liens avec les Phases Précédentes et Suivantes

### Liens avec les Phases Précédentes

Cette Phase 1 est la première étape du plan de transition, donc il n'y a pas de phase précédente à proprement parler. Cependant, elle s'appuie sur l'état actuel des workflows Email Sender, qui sont organisés en 6 phases distinctes:

1. Phase 1: Gestion des Disponibilités  
2. Phase 2: Génération & Envoi des Emails  
3. Phase 3: Traitement des Réponses  
4. Phase 4: Gestion des Concerts Confirmés  
5. Phase 5: Suivi Post-Concert  
6. Phase 6: Évaluation et Planification Future

### Liens avec les Phases Suivantes

La Phase 1 (Analyse et Préparation) prépare le terrain pour les phases suivantes du plan de transition:

1. Phase 2: Refactorisation et Standardisation  
   * Utilise les rapports générés dans la Phase 1 pour standardiser les noms, optimiser les nœuds Code et standardiser les structures de données.  
2. Phase 3: Intégration avec le Plan Magistral V5  
   * S'appuie sur l'environnement de test créé dans la Phase 1 pour mettre en place les piliers du Plan Magistral V5.  
3. Phase 4: Tests et Validation  
   * Utilise le système de journalisation mis en place dans la Phase 1 pour surveiller et valider les tests.  
4. Phase 5: Déploiement et Suivi  
   * Utilise les rapports et la documentation générés dans la Phase 1 pour guider le déploiement et le suivi.

## Événements de Fond et Tâches Répétitives

### Tâches Régulières Répétitives

1. Surveillance des Logs  
   * Fréquence: Toutes les heures  
   * Description: Analyse les logs générés par le système de journalisation pour détecter des problèmes potentiels.  
   * Implémentation: Workflow Cron qui lit le fichier de logs, analyse les entrées récentes et génère des alertes si nécessaire.  
2. Vérification des Credentials  
   * Fréquence: Quotidienne  
   * Description: Vérifie que tous les credentials sont valides et fonctionnels.  
   * Implémentation: Workflow Cron qui teste chaque credential en effectuant une opération simple et journalise les résultats.  
3. Sauvegarde des Workflows  
   * Fréquence: Quotidienne  
   * Description: Exporte tous les workflows et les sauvegarde dans un emplacement sécurisé.  
   * Implémentation: Workflow Cron qui utilise l'API n8n pour exporter les workflows et les sauvegarder.

### Événements de Fond

1. Surveillance des Erreurs  
   * Déclencheur: Entrée de log de niveau ERROR  
   * Description: Envoie une alerte par email et/ou Slack lorsqu'une erreur est détectée.  
   * Implémentation: Webhook qui écoute les entrées de log et déclenche des alertes en fonction du niveau de gravité.  
2. Mise à Jour des Rapports  
   * Déclencheur: Modification d'un workflow  
   * Description: Met à jour les rapports d'inventaire, de credentials et d'expressions lorsqu'un workflow est modifié.  
   * Implémentation: Webhook qui écoute les événements de modification de workflow et déclenche les workflows d'analyse.  
3. Synchronisation des Environnements  
   * Déclencheur: Déploiement d'un changement dans l'environnement de production  
   * Description: Synchronise les changements entre l'environnement de production et l'environnement de test.  
   * Implémentation: Webhook qui écoute les événements de déploiement et déclenche un workflow de synchronisation.

## Conclusion

La Phase 1 du plan de transition est une étape cruciale qui pose les fondations pour la migration vers le Plan Magistral V5. Elle comprend une analyse approfondie des workflows existants, la création d'un environnement de test et la mise en place d'un système de journalisation robuste.  
Les workflows et outils développés dans cette phase permettront de:

* Comprendre en détail la structure et le fonctionnement des workflows existants  
* Identifier les dépendances et les points d'intégration  
* Créer un environnement de test isolé pour expérimenter sans risque  
* Mettre en place un système de surveillance et de journalisation pour faciliter le débogage

Une fois cette phase terminée, l'équipe disposera de toutes les informations et outils nécessaires pour procéder à la refactorisation et à la standardisation des workflows dans la Phase 2\.  
