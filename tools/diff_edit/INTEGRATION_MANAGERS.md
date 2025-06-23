# INTEGRATION_MANAGERS.md — Points d’intégration diff Edit avec les managers système

- **Process manager** : hooks pour notifier le lancement/fin de batch, logs d’état, gestion des workers.
- **Memory manager** : monitoring mémoire, adaptation dynamique du nombre de workers, logs d’alerte si dépassement seuil.
- **Cache manager** : gestion des buffers, invalidation de cache si besoin après patch massif.
- **Monitoring externe** : possibilité d’exposer des métriques via Prometheus, logs ou API REST.
- **Conventions** : tous les scripts Go sont conçus pour être appelés par des outils externes (CLI, API, hooks).

## Exemples d’intégration

- Appel du script Go depuis un orchestrateur (ex : systemd, supervisor, Kubernetes job).
- Utilisation de logs pour déclencher des alertes ou des actions correctives.
- Adaptation dynamique du batch selon la charge système détectée par le manager.
