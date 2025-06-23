# Interfaces et Flux d’Échange

## Interfaces principales

- **Orchestrator → Integrated Manager**
  - Appels d’exécution de jobs/workflows
  - Suivi d’état, logs d’exécution

- **Integrated Manager → Central Coordinator**
  - Export structuré des états, logs, métriques
  - Notifications d’événements critiques

- **Central Coordinator → Integrated Manager**
  - Ordres de supervision, arbitrage, alertes
  - Requêtes de reporting, collecte d’état

## Flux d’information

1. L’orchestrator déclenche des jobs ou workflows, qui sont pris en charge par l’integrated-manager.
2. L’integrated-manager exécute, synchronise, et remonte les états/logs vers le central-coordinator.
3. Le central-coordinator supervise, agrège, arbitre, et peut piloter ou alerter l’integrated-manager.

## À compléter

- Spécifications d’API (REST, gRPC, events, etc.)
- Diagrammes de séquence
- Exemples de payloads échangés
