# Corrélation MANAGERS & ARCHITECTURE

Ce document fait le lien entre chaque manager métier et l’architecture globale.

## Vue d’ensemble

- Tous les managers sont orchestrés par l’integrated-manager ([../ARCHITECTURE/integrated-manager.md](../ARCHITECTURE/integrated-manager.md)).
- La supervision, le monitoring et l’arbitrage global sont assurés par le central-coordinator ([../ARCHITECTURE/central-coordinator.md](../ARCHITECTURE/central-coordinator.md)).
- Les interfaces, flux d’échange et API sont détaillés dans [../ARCHITECTURE/interfaces.md](../ARCHITECTURE/interfaces.md).

## Schéma de relation

```
[orchestrator] → [integrated-manager] → [managers métiers]
                        ↑
                [central-coordinator]
(supervision globale, collecte, arbitrage, alertes)
```

## Pour aller plus loin

- Voir la documentation de chaque manager dans ce dossier.
- Compléter les liens croisés et les exemples d’intégration au fil de l’évolution du projet.
