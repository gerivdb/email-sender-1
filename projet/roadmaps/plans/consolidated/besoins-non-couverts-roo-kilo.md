# Besoins métiers et techniques non couverts – Roo vs Kilo Code

Synthèse basée sur [`gaps-roo-kilo.md`](projet/roadmaps/plans/consolidated/gaps-roo-kilo.md:1) et [`tableau-comparatif-roo-kilo.md`](projet/roadmaps/plans/consolidated/tableau-comparatif-roo-kilo.md:1).

| Besoin / Fonctionnalité                | Mode concerné                | Impact métier / technique                                 | Suggestion d’évolution                        |
|----------------------------------------|------------------------------|-----------------------------------------------------------|-----------------------------------------------|
| Modes personnalisés                    | Orchestrator, Mode Writer    | Limite la spécialisation et l’adaptabilité                | Ajouter la gestion de modes custom            |
| Extension / Marketplace                | Extension Manager            | Impossible d’ajouter des plugins ou d’étendre les capacités| Développer une API d’extension et un marketplace|
| API d’extension                        | Extension Manager, DevOps    | Freine l’intégration et l’automatisation                  | Concevoir une API d’extension                 |
| Synchronisation multi-environnements   | Synchronisation, DevOps      | Risque de désynchronisation, moins de flexibilité         | Améliorer la synchronisation multi-environnements|
| Gestion fine des personas              | Business Needs Expliciter    | Moins de granularité, personnalisation réduite            | Enrichir la gestion des personas              |
| Documentation / Reporting avancés      | Documentation Writer         | Moins de profondeur sur la traçabilité et le reporting    | Renforcer la documentation et le reporting    |
| Monitoring / Feedback personnalisés    | Observability Architect      | Moins d’adaptation aux besoins utilisateurs/personas      | Personnaliser le monitoring et le feedback    |