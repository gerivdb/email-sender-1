# Integration - Intégrations

Ce dossier contient les scripts d'intégration du système de roadmap avec d'autres systèmes.

## Structure

- **n8n/** - Intégration avec n8n
- **notion/** - Intégration avec Notion

## Fonctionnalités

### Intégration n8n

Les scripts d'intégration avec n8n permettent:
- De créer des workflows n8n à partir des roadmaps
- De mettre à jour les roadmaps à partir des workflows n8n
- De synchroniser les statuts des tâches entre n8n et les roadmaps

### Intégration Notion

Les scripts d'intégration avec Notion permettent:
- D'importer des roadmaps depuis Notion
- D'exporter des roadmaps vers Notion
- De synchroniser les statuts des tâches entre Notion et les roadmaps

## Utilisation

Pour utiliser l'intégration n8n:

```powershell
.\n8n\Connect-N8nRoadmap.ps1 -RoadmapPath "projet\roadmaps\active\roadmap_active.md" -N8nUrl "http://localhost:5678"
```plaintext
Pour utiliser l'intégration Notion:

```powershell
.\notion\Connect-NotionRoadmap.ps1 -RoadmapPath "projet\roadmaps\active\roadmap_active.md" -NotionDatabaseId "your-database-id"
```plaintext