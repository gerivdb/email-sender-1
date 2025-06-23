# Central Coordinator

## Rôle

Le central-coordinator est le composant de supervision omnisciente de l’écosystème. Il est responsable de la vision d’ensemble, de la cohérence globale, du monitoring transverse, de la gouvernance, de la priorisation et de la gestion des états de tout l’écosystème de managers.

## Responsabilités principales

- Supervision globale et monitoring transverse.
- Collecte des métriques, états, logs de tous les managers (dont integrated-manager).
- Déclenchement d’alertes, arbitrage des conflits, gestion d’état.
- Fourniture d’une interface de monitoring centralisée (API, dashboard).
- Gouvernance, priorisation, reporting global.

## Relations

- Pilote integrated-manager et les autres managers.
- Collecte et agrège les informations de l’ensemble de l’écosystème.
- Peut arbitrer, déclencher des alertes, fournir des rapports consolidés.

## Interfaces

- API de supervision, monitoring, reporting.
- Dashboard centralisé, alerting, export d’états.

---
Pour la vision globale, voir [ecosystem-overview.md](ecosystem-overview.md)
