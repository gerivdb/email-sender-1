# Integrated Manager

## Rôle

L’integrated-manager est le point d’entrée opérationnel de l’écosystème. Il orchestre l’exécution synchronisée des managers critiques (Branch, Cache, Context Memory, Notification, etc.), centralise les logs, automatise la validation et la cohérence, et prépare la supervision globale.

## Responsabilités principales

- Exécution, intégration et synchronisation des managers métiers.
- Centralisation des logs et états d’exécution.
- Automatisation de la validation et de la cohérence des opérations.
- Préparation de l’export structuré des états, logs, métriques.

## Relations

- Reçoit des ordres de l’orchestrator ou d’autres composants.
- Remonte les états/logs vers le central-coordinator.
- Sert de chef d’orchestre opérationnel pour les managers métiers.

## Interfaces

- API d’intégration et de synchronisation.
- Export d’états, logs, métriques.

---
Pour la vision globale, voir [ecosystem-overview.md](ecosystem-overview.md)
