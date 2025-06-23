# Rapport de Dépendances - Phase 2 DocManager v66

| Manager        | Dépendances détectées         |
|----------------|------------------------------|
| security       | audit, interfaces            |
| audit          | security                     |
| interfaces     | apigateway                   |
| orchestrator   | loadbalancer, replication    |
| loadbalancer   | orchestrator                 |
| apigateway     | interfaces                   |
| replication    | orchestrator                 |

Généré automatiquement par DetectDependencies.
