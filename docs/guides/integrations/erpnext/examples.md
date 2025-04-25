# Exemples d'utilisation de l'intégration ERPNext

Cette page présente des exemples concrets d'utilisation de l'intégration ERPNext avec le journal de bord.

## Exemple 1: Entrée de journal créée à partir d'une tâche ERPNext

Voici un exemple d'entrée de journal créée automatiquement à partir d'une tâche ERPNext:

```markdown
---
title: Tâche ERPNext: Implémenter l'authentification
date: 2023-04-05
tags: [erpnext, task, project:Journal RAG, status:Open, priority:High]
---

# Tâche ERPNext: Implémenter l'authentification

## Détails de la tâche
- **ID**: TASK-001
- **Sujet**: Implémenter l'authentification
- **Projet**: Journal RAG
- **Statut**: Open
- **Priorité**: High
- **Date de début**: 2023-04-05
- **Date de fin**: 2023-04-12

## Description
Implémenter un système d'authentification pour l'application Journal RAG. Utiliser JWT pour l'authentification API et sessions pour l'interface web.

## Actions réalisées
- Synchronisation depuis ERPNext le 2023-04-05 15:30

## Notes
- Cette entrée a été générée automatiquement à partir d'une tâche ERPNext.
- Pour mettre à jour la tâche dans ERPNext, modifiez cette entrée et exécutez la synchronisation vers ERPNext.
```

## Exemple 2: Mise à jour d'une tâche ERPNext à partir d'une entrée de journal

Voici un exemple d'entrée de journal modifiée pour mettre à jour une tâche ERPNext:

```markdown
---
title: Tâche ERPNext: Implémenter l'authentification
date: 2023-04-05
tags: [erpnext, task, project:Journal RAG, status:In Progress, priority:High]
---

# Tâche ERPNext: Implémenter l'authentification

## Détails de la tâche
- **ID**: TASK-001
- **Sujet**: Implémenter l'authentification
- **Projet**: Journal RAG
- **Statut**: In Progress
- **Priorité**: High
- **Date de début**: 2023-04-05
- **Date de fin**: 2023-04-12

## Description
Implémenter un système d'authentification pour l'application Journal RAG. Utiliser JWT pour l'authentification API et sessions pour l'interface web.

## Actions réalisées
- Synchronisation depuis ERPNext le 2023-04-05 15:30
- Implémentation de l'authentification JWT pour l'API
- Configuration des routes protégées

## Notes
- Cette entrée a été générée automatiquement à partir d'une tâche ERPNext.
- Pour mettre à jour la tâche dans ERPNext, modifiez cette entrée et exécutez la synchronisation vers ERPNext.
```

Après avoir modifié cette entrée et exécuté la synchronisation vers ERPNext, la tâche TASK-001 sera mise à jour avec:
- Statut: "In Progress"
- Description: Mise à jour pour inclure les actions réalisées

## Exemple 3: Création d'une note ERPNext à partir d'une entrée de journal

Voici un exemple d'entrée de journal qui sera convertie en note ERPNext:

```markdown
---
title: Réflexions sur l'architecture du système
date: 2023-04-10
tags: [erpnext, architecture, design]
---

# Réflexions sur l'architecture du système

Après avoir travaillé sur le système d'authentification, j'ai quelques réflexions sur l'architecture globale du système:

1. Nous devrions séparer l'API en microservices
2. L'authentification devrait être gérée par un service dédié
3. Nous devrions utiliser un système de messagerie pour la communication entre les services

Ces changements permettraient d'améliorer la scalabilité et la maintenabilité du système.
```

Cette entrée sera convertie en note ERPNext avec:
- Titre: "Réflexions sur l'architecture du système"
- Contenu: Le contenu complet de l'entrée

## Exemple 4: Utilisation du script Python pour la synchronisation

Voici un exemple d'utilisation du script Python pour synchroniser les tâches ERPNext vers le journal:

```bash
# Configurer l'intégration
python scripts/python/journal/integrations/erpnext_integration.py \
  --url "https://erpnext.example.com" \
  --key "votre-cle-api" \
  --secret "votre-secret-api"

# Tester la connexion
python scripts/python/journal/integrations/erpnext_integration.py --test

# Synchroniser les tâches ERPNext vers le journal
python scripts/python/journal/integrations/erpnext_integration.py --sync-to-journal

# Synchroniser le journal vers ERPNext
python scripts/python/journal/integrations/erpnext_integration.py --sync-from-journal

# Récupérer les projets
python scripts/python/journal/integrations/erpnext_integration.py --projects

# Récupérer les tâches d'un projet
python scripts/python/journal/integrations/erpnext_integration.py --tasks --project "Journal RAG"

# Créer une tâche
python scripts/python/journal/integrations/erpnext_integration.py \
  --create-task \
  --subject "Nouvelle tâche" \
  --description "Description de la nouvelle tâche" \
  --project "Journal RAG"
```

## Exemple 5: Utilisation de l'API pour la synchronisation

Voici un exemple d'utilisation de l'API pour synchroniser les tâches ERPNext vers le journal:

```javascript
// Configurer l'intégration
async function configureIntegration() {
  const response = await fetch('/api/integrations/erpnext/config', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      enabled: true,
      api_url: 'https://erpnext.example.com',
      api_key: 'votre-cle-api',
      api_secret: 'votre-secret-api'
    })
  });
  return response.json();
}

// Tester la connexion
async function testConnection() {
  const response = await fetch('/api/integrations/erpnext/test-connection', {
    method: 'POST'
  });
  return response.json();
}

// Synchroniser les tâches ERPNext vers le journal
async function syncToJournal() {
  const response = await fetch('/api/integrations/erpnext/sync-to-journal', {
    method: 'POST'
  });
  return response.json();
}

// Synchroniser le journal vers ERPNext
async function syncFromJournal() {
  const response = await fetch('/api/integrations/erpnext/sync-from-journal', {
    method: 'POST'
  });
  return response.json();
}
```

## Exemple 6: Workflow complet d'utilisation

Voici un exemple de workflow complet d'utilisation de l'intégration ERPNext:

1. **Configuration initiale**:
   - Configurer l'intégration ERPNext avec l'URL, la clé API et le secret API
   - Tester la connexion pour s'assurer que tout fonctionne

2. **Synchronisation initiale**:
   - Synchroniser les tâches ERPNext vers le journal pour créer des entrées pour toutes les tâches existantes
   - Vérifier que les entrées ont été créées correctement

3. **Travail quotidien**:
   - Consulter les entrées de journal créées à partir des tâches ERPNext
   - Mettre à jour les entrées avec les progrès réalisés
   - Synchroniser le journal vers ERPNext pour mettre à jour les tâches

4. **Création de nouvelles tâches**:
   - Créer de nouvelles tâches dans ERPNext
   - Synchroniser ERPNext vers le journal pour créer des entrées pour les nouvelles tâches
   - Ou créer des entrées de journal avec le tag "erpnext" et "task" et synchroniser vers ERPNext

5. **Documentation**:
   - Créer des entrées de journal avec le tag "erpnext" pour documenter des aspects du projet
   - Synchroniser le journal vers ERPNext pour créer des notes ERPNext

6. **Automatisation**:
   - Configurer des tâches planifiées pour synchroniser automatiquement ERPNext et le journal
   - Configurer des webhooks pour déclencher la synchronisation lors de la création ou de la mise à jour de tâches
