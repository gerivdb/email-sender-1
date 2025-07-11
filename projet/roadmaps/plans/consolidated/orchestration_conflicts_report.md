# Rapport de Conflits d’Orchestration et Plan de Convergence

## 1. Points d’entrée et scripts d’orchestration identifiés

- `cmd/go/roadmap-orchestrator/roadmap_orchestrator.go` : Orchestrateur Go pour phases de roadmap.
- `cmd/auto_roadmap_runner/auto_roadmap_runner.go` : Orchestrateur global de scripts.
- `cmd/gen_orchestrator_spec/gen_orchestrator_spec.go` : Générateur de spécification d’orchestrateur.
- `cmd/audit_orchestration/audit_orchestration.go` : Audit des scripts d’orchestration et dépendances.
- `cmd/smart-infrastructure/smart_infrastructure.go` et `cmd/infrastructure-api-server/infrastructure_api_server.go` : Orchestration infrastructure.
- Intégration Jan/ContextManager : Orchestration séquentielle multi-personas.

## 2. Conflits et redondances détectés

- Multiplicité des orchestrateurs (plusieurs points d’entrée Go).
- Redondance entre orchestrateurs de roadmap, d’infrastructure et d’audit.
- Divergences de conventions (mono-agent Jan vs multi-agent, gestion des dépendances, reporting).
- Scripts factorisés partiellement, absence d’orchestrateur global unique.

## 3. Plan de convergence

- Unifier les points d’entrée dans un orchestrateur global (`cmd/auto_roadmap_runner/auto_roadmap_runner.go`).
- Factoriser les scripts d’orchestration, harmoniser la gestion des dépendances et du reporting.
- Centraliser la logique d’orchestration séquentielle (Jan/ContextManager) dans le même orchestrateur.
- Documenter la nouvelle architecture et supprimer les doublons.

## 4. Critères de validation

- Zéro conflit, points d’entrée unifiés, scripts factorisés.
- Documentation à jour sur l’orchestration globale.

*Rapport généré automatiquement – à valider et compléter lors de la convergence effective.*