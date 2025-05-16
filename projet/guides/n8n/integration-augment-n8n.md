# Intégration Augment-n8n
*Version 2025-05-15*

Ce guide présente les meilleures pratiques pour l'intégration entre Augment et n8n dans le cadre du projet EMAIL SENDER 1.

## 1. Vue d'ensemble

L'intégration entre Augment et n8n permet de combiner la puissance de l'IA générative avec l'automatisation des workflows. Cette synergie est particulièrement utile pour :

- Générer et personnaliser des emails avec l'IA
- Analyser les réponses aux emails
- Automatiser les décisions basées sur l'analyse IA
- Créer et maintenir des workflows n8n complexes

## 2. Architecture d'intégration

### 2.1 Schéma global

```
+-------------+      +----------------+      +----------------+      +-------------+
|  Augment    | ---> | PowerShell/    | ---> | MCP Servers    | ---> | n8n         |
| (IA Agent)  |      | Python Scripts |      | (Context)      |      | (Workflows) |
+-------------+      +----------------+      +----------------+      +-------------+
       |                     |                      |                      |
       |                     |                      |                      |
       v                     v                      v                      v
+-----------------------------------------------------------------------------------+
|                           Sources de données (Notion, Google Calendar)             |
+-----------------------------------------------------------------------------------+
```

### 2.2 Composants clés

1. **Augment** : Agent IA qui génère du code, des configurations et des analyses
2. **Scripts PowerShell/Python** : Intermédiaires entre Augment et les autres composants
3. **MCP (Model Context Protocol)** : Fournit du contexte aux modèles IA
4. **n8n** : Plateforme d'automatisation des workflows
5. **Sources de données** : Notion, Google Calendar, etc.

## 3. Méthodes d'intégration

### 3.1 Node Augment Client pour n8n

Un node personnalisé a été développé pour faciliter l'intégration entre n8n et Augment :

```
src/n8n/nodes/augment-client/
```

Ce node permet d'exécuter directement les modes opérationnels d'Augment depuis n8n.

#### Installation du node

1. Naviguez vers le répertoire du node Augment Client :
   ```
   cd src/n8n/nodes/augment-client
   ```

2. Exécutez le script d'installation :
   ```
   .\Install-AugmentNode.ps1
   ```
   ou
   ```
   .\install-node.cmd
   ```

3. Redémarrez n8n pour charger le nouveau node.

#### Opérations disponibles

Le node Augment Client prend en charge les opérations suivantes :

- **Execute Mode** : Exécute un mode opérationnel Augment sur un fichier ou une tâche spécifique
- **Update Memories** : Met à jour les mémoires Augment avec un nouveau contenu
- **Get Mode Description** : Récupère la description d'un mode opérationnel Augment

#### Exemples de workflows

Des workflows d'exemple sont disponibles dans :
```
src/n8n/workflows/examples/
```

### 3.2 Génération de workflows n8n par Augment

Augment peut générer des workflows n8n complets ou partiels :

```powershell
# Exemple : Générer un workflow n8n avec Augment
Invoke-AugmentMode -Mode "DEV-R" -Task "Créer un workflow n8n pour la prospection initiale" -OutputPath "src/n8n/workflows/email-sender-phase1.json"
```

#### Bonnes pratiques

- Fournir à Augment des exemples de workflows n8n existants
- Spécifier clairement les nœuds n8n à utiliser
- Demander une documentation détaillée pour chaque nœud
- Valider manuellement les workflows générés avant déploiement

### 3.2 Appel de n8n depuis les scripts générés par Augment

Les scripts PowerShell/Python générés par Augment peuvent déclencher des workflows n8n :

```powershell
# Exemple : Script PowerShell appelant un webhook n8n
function Invoke-EmailSenderWorkflow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ContactId,

        [Parameter(Mandatory = $false)]
        [string]$WebhookUrl = $env:N8N_WEBHOOK_URL
    )

    $payload = @{
        contactId = $ContactId
        timestamp = Get-Date -Format "o"
        source = "PowerShell"
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $payload -ContentType "application/json"
}
```

#### Bonnes pratiques

- Stocker les URLs de webhook dans des variables d'environnement ou des fichiers de configuration sécurisés
- Implémenter une gestion d'erreur robuste
- Utiliser des timeouts appropriés
- Journaliser les appels et les réponses

### 3.3 Appel d'Augment depuis n8n

n8n peut appeler des scripts qui interagissent avec Augment :

```javascript
// Exemple : Nœud Function dans n8n appelant un script PowerShell
const { exec } = require('child_process');

function executeAugmentScript(contactData) {
  return new Promise((resolve, reject) => {
    const command = `powershell -Command "& {Import-Module AugmentIntegration; Invoke-AugmentAnalysis -ContactData '${JSON.stringify(contactData)}' -Mode 'ANALYZE'}"`;

    exec(command, (error, stdout, stderr) => {
      if (error) {
        reject(`Error: ${error.message}`);
        return;
      }
      if (stderr) {
        reject(`Stderr: ${stderr}`);
        return;
      }
      resolve(JSON.parse(stdout));
    });
  });
}

// Utilisation dans un nœud Function de n8n
items.forEach(async (item) => {
  try {
    const result = await executeAugmentScript(item.json);
    item.json.analysis = result;
  } catch (error) {
    item.json.error = error;
  }
});

return items;
```

#### Bonnes pratiques

- Limiter les appels à Augment aux cas nécessitant une IA avancée
- Mettre en cache les résultats pour éviter des appels répétés
- Implémenter des timeouts et des retries
- Sécuriser les données sensibles

## 4. Intégration via MCP

### 4.1 Architecture MCP

MCP (Model Context Protocol) sert d'intermédiaire entre n8n et les services IA :

```
+-------------+      +----------------+      +----------------+
| n8n         | ---> | MCP Server     | ---> | OpenRouter/   |
| (Workflow)  |      | (Context)      |      | DeepSeek      |
+-------------+      +----------------+      +----------------+
       |                     ^
       |                     |
       v                     |
+----------------+    +----------------+
| Notion/GCal    |    | Context Sources|
| (Data Source)  |    | (Files, DB)    |
+----------------+    +----------------+
```

### 4.2 Configuration MCP pour n8n

```javascript
// Exemple : Configuration d'un appel MCP dans un nœud Function de n8n
const mcpConfig = {
  server: "http://localhost:3000/api/context",
  sources: ["notion", "calendar", "history"],
  model: "deepseek/deepseek-chat",
  maxTokens: 1000
};

async function getMCPResponse(prompt, contactData) {
  const response = await $http.post(
    mcpConfig.server,
    {
      prompt: prompt,
      context: {
        contact: contactData,
        sources: mcpConfig.sources
      },
      model: mcpConfig.model,
      max_tokens: mcpConfig.maxTokens
    },
    {
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${$credentials.mcpApi.apiKey}`
      }
    }
  );

  return response.data.completion;
}

// Utilisation dans un nœud Function de n8n
for (const item of items) {
  const prompt = `Rédige un email de prospection pour ${item.json.firstName} ${item.json.lastName} de ${item.json.company}.`;
  item.json.personalizedEmail = await getMCPResponse(prompt, item.json);
}

return items;
```

#### Bonnes pratiques

- Configurer MCP pour charger automatiquement le contexte pertinent
- Optimiser les prompts pour réduire l'utilisation de tokens
- Mettre en cache les contextes fréquemment utilisés
- Surveiller les performances et ajuster les paramètres

## 5. Cas d'utilisation pratiques

### 5.1 Génération d'emails personnalisés

```javascript
// Exemple : Nœud Function pour générer un email personnalisé
async function generatePersonalizedEmail(items) {
  for (const item of items) {
    const contactData = {
      name: item.json.firstName + " " + item.json.lastName,
      company: item.json.company,
      role: item.json.role,
      interests: item.json.interests || []
    };

    const artistData = {
      name: "Nom de l'artiste",
      genre: "Style musical",
      achievements: ["Prix XYZ", "Concert à ABC"],
      availableDates: ["2025-06-15", "2025-06-22", "2025-07-10"]
    };

    const prompt = `
    Rédige un email de prospection personnalisé avec les caractéristiques suivantes :
    - Destinataire : ${contactData.name}, ${contactData.role} chez ${contactData.company}
    - Intérêts connus : ${contactData.interests.join(", ")}
    - Présentation de l'artiste ${artistData.name} (${artistData.genre})
    - Mention des réalisations : ${artistData.achievements.join(", ")}
    - Proposition de dates : ${artistData.availableDates.join(", ")}
    - Ton professionnel mais chaleureux
    - Longueur : environ 200 mots
    - Structure : introduction, présentation, proposition, conclusion
    `;

    item.json.emailBody = await getMCPResponse(prompt, { contact: contactData, artist: artistData });
  }

  return items;
}
```

### 5.2 Analyse des réponses aux emails

```javascript
// Exemple : Nœud Function pour analyser une réponse
async function analyzeEmailResponse(items) {
  for (const item of items) {
    const responseText = item.json.emailBody;

    const prompt = `
    Analyse cette réponse à un email de prospection et extrais les informations suivantes :
    - Sentiment général (positif, neutre, négatif)
    - Intérêt exprimé (très intéressé, intéressé, peu intéressé, pas intéressé)
    - Dates mentionnées (au format YYYY-MM-DD)
    - Questions posées
    - Informations supplémentaires demandées
    - Actions requises de notre part

    Réponse à analyser :
    "${responseText}"

    Format de sortie : JSON
    `;

    const analysisResult = await getMCPResponse(prompt, { responseText });
    item.json.analysis = JSON.parse(analysisResult);

    // Déterminer le nouveau statut en fonction de l'analyse
    if (item.json.analysis.interest === "très intéressé" || item.json.analysis.interest === "intéressé") {
      item.json.newStatus = "Intéressé";
    } else if (item.json.analysis.requestedInfo && item.json.analysis.requestedInfo.length > 0) {
      item.json.newStatus = "Demande d'informations";
    } else if (item.json.analysis.sentiment === "négatif") {
      item.json.newStatus = "Pas intéressé";
    } else {
      item.json.newStatus = "Suivi requis";
    }
  }

  return items;
}
```

### 5.3 Génération et maintenance de workflows n8n

Augment peut aider à créer et maintenir des workflows n8n complexes :

```powershell
# Exemple : Script pour générer un workflow n8n complet
function New-EmailSenderWorkflow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Phase1", "Phase2", "Phase3", "Config")]
        [string]$Phase,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "src/n8n/workflows/email-sender-$Phase.json"
    )

    # Préparer la description du workflow en fonction de la phase
    $description = switch ($Phase) {
        "Phase1" { "Workflow de prospection initiale" }
        "Phase2" { "Workflow de suivi des propositions" }
        "Phase3" { "Workflow de traitement des réponses" }
        "Config" { "Workflow de configuration centralisée" }
    }

    # Appeler Augment pour générer le workflow
    $result = Invoke-AugmentMode -Mode "DEV-R" -Task "Créer un workflow n8n pour $description" -OutputFormat "JSON"

    # Sauvegarder le résultat
    $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8

    Write-Output "Workflow généré avec succès : $OutputPath"
}
```

## 6. Bonnes pratiques générales

### 6.1 Sécurité

- **Ne jamais exposer les secrets** dans les workflows n8n ou les scripts
- Utiliser les **credentials n8n** pour stocker les clés API
- Implémenter une **authentification** pour tous les webhooks
- Valider et **sanitizer toutes les entrées** externes

### 6.2 Performance

- **Limiter les appels API** en regroupant les opérations
- **Mettre en cache** les résultats fréquemment utilisés
- Utiliser des **timeouts appropriés** pour éviter les blocages
- **Surveiller l'utilisation des tokens** IA

### 6.3 Maintenabilité

- **Documenter** chaque nœud dans les workflows n8n
- Utiliser des **noms descriptifs** pour les variables et les nœuds
- **Versionner** les workflows dans Git
- Créer des **workflows modulaires** et réutilisables

## 7. Ressources additionnelles

- [Guide des bonnes pratiques n8n](/projet/guides/n8n/bonnes-pratiques-n8n.md)
- [Guide des prompts efficaces pour Augment](/docs/guides/augment/prompts-efficaces.md)
- [Décisions architecturales pour EMAIL SENDER 1](/projet/guides/architecture/decisions-architecturales.md)
- [Documentation officielle n8n](https://docs.n8n.io/)
- [API MCP](/src/mcp/docs/api.md)

---

> **Conseil** : Commencez par des intégrations simples et itérez progressivement. Testez chaque composant individuellement avant de les intégrer ensemble.
