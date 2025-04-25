# Synchronisation ERPNext

## Types de synchronisation

L'intégration ERPNext propose deux types de synchronisation:

1. **ERPNext → Journal**: Synchronise les tâches ERPNext vers le journal de bord
2. **Journal → ERPNext**: Synchronise les entrées de journal vers ERPNext (notes et tâches)

## Synchronisation ERPNext → Journal

### Via l'interface utilisateur

Pour synchroniser les tâches ERPNext vers le journal:

1. Accédez à la page d'intégration ERPNext
2. Cliquez sur le bouton "Synchroniser ERPNext → Journal"
3. Attendez que la synchronisation soit terminée
4. Les tâches ERPNext seront converties en entrées de journal

### Via l'API

```bash
curl -X POST http://localhost:8000/api/integrations/erpnext/sync-to-journal
```

### Via le script Python

```bash
python scripts/python/journal/integrations/erpnext_integration.py --sync-to-journal
```

### Comportement

Lors de la synchronisation ERPNext → Journal:

1. Toutes les tâches ERPNext sont récupérées
2. Pour chaque tâche, une entrée de journal est créée ou mise à jour
3. Les entrées de journal sont créées avec les tags appropriés (erpnext, task, project, status, priority)
4. Les entrées existantes sont mises à jour si elles correspondent à une tâche ERPNext

## Synchronisation Journal → ERPNext

### Via l'interface utilisateur

Pour synchroniser les entrées de journal vers ERPNext:

1. Accédez à la page d'intégration ERPNext
2. Cliquez sur le bouton "Synchroniser Journal → ERPNext"
3. Attendez que la synchronisation soit terminée
4. Les entrées de journal avec le tag "erpnext" seront converties en notes ERPNext
5. Les entrées avec le tag "task" seront utilisées pour mettre à jour les tâches ERPNext

### Via l'API

```bash
curl -X POST http://localhost:8000/api/integrations/erpnext/sync-from-journal
```

### Via le script Python

```bash
python scripts/python/journal/integrations/erpnext_integration.py --sync-from-journal
```

### Comportement

Lors de la synchronisation Journal → ERPNext:

1. Toutes les entrées de journal avec le tag "erpnext" sont récupérées
2. Pour chaque entrée, une note ERPNext est créée
3. Si l'entrée contient également le tag "task", la tâche ERPNext correspondante est mise à jour
4. Les informations de la tâche sont extraites de l'entrée de journal (sujet, description, statut, priorité)

## Création d'une entrée de journal à partir d'une tâche

### Via l'interface utilisateur

Pour créer une entrée de journal à partir d'une tâche ERPNext:

1. Accédez à la page d'intégration ERPNext
2. Cliquez sur un projet dans la liste des projets
3. Sélectionnez une tâche dans la liste des tâches du projet
4. Cliquez sur le bouton "Créer une entrée" à côté de la tâche
5. Une nouvelle entrée de journal sera créée avec les informations de la tâche

### Via l'API

```bash
curl -X POST http://localhost:8000/api/integrations/erpnext/create-entry \
  -H "Content-Type: application/json" \
  -d '{
    "task_id": "TASK-001"
  }'
```

### Via le script Python

```bash
python scripts/python/journal/integrations/erpnext_integration.py \
  --create-entry --task-id "TASK-001"
```

## Fréquence de synchronisation

Par défaut, la synchronisation est manuelle. Vous pouvez automatiser la synchronisation en:

1. Configurant une tâche planifiée pour exécuter le script de synchronisation
2. Utilisant n8n pour créer un workflow de synchronisation
3. Configurant un webhook ERPNext pour déclencher la synchronisation lors de la création ou de la mise à jour d'une tâche

### Exemple de tâche planifiée (Windows)

```powershell
# Créer une tâche planifiée pour synchroniser ERPNext vers le journal tous les jours à 9h
schtasks /create /tn "SyncERPNextToJournal" /tr "python scripts/python/journal/integrations/erpnext_integration.py --sync-to-journal" /sc daily /st 09:00

# Créer une tâche planifiée pour synchroniser le journal vers ERPNext tous les jours à 17h
schtasks /create /tn "SyncJournalToERPNext" /tr "python scripts/python/journal/integrations/erpnext_integration.py --sync-from-journal" /sc daily /st 17:00
```
