# DocManager

## Rôle

Orchestrateur central de la gestion documentaire (création, coordination, cohérence).

## Interfaces principales

- `Store(*Document) error`, `Retrieve(string) (*Document, error)`
- `RegisterPlugin(PluginInterface) error`

## Utilisation

Toutes les opérations documentaires passent par DocManager. Extension possible via plugins.

## Entrée/Sortie

- Documents structurés, résultats d’opérations, logs.

## Corrélations

- Voir [../ARCHITECTURE/integrated-manager.md](../ARCHITECTURE/integrated-manager.md)
- Voir [../ARCHITECTURE/ecosystem-overview.md](../ARCHITECTURE/ecosystem-overview.md)
