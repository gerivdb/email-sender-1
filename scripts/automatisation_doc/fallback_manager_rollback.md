# Procédures de rollback — FallbackManager Roo

## Contexte et objectifs

Le rollback du `FallbackManager` vise à restaurer un état documentaire cohérent après l’échec ou la dérive d’une stratégie de fallback. Il s’applique lors d’une erreur critique, d’une mauvaise configuration YAML ou d’un plugin défaillant.

## Procédures détaillées

### 1. Rollback YAML Roo

- Restaurer la dernière version valide du fichier YAML de configuration des stratégies fallback (`fallback_schema.yaml`).
- Utiliser la sauvegarde automatique générée avant chaque modification.
- Valider la conformité du schéma restauré via les tests unitaires.

### 2. Rollback plugin

- Désactiver le plugin fautif via le registre du FallbackManager.
- Restaurer la configuration précédente du plugin (si versionnée).
- Consigner l’opération dans les logs Roo pour audit.

### 3. Rollback d’état documentaire

- Rejouer la dernière opération documentaire réussie avant l’échec.
- Utiliser les snapshots d’état si activés (intégration avec ContextManager).
- Vérifier l’intégrité documentaire après restauration.

### 4. Rollback global (multi-stratégies)

- Appliquer séquentiellement les procédures ci-dessus pour chaque stratégie ayant échoué.
- Générer un rapport de rollback détaillé (logs, statuts, erreurs rencontrées).

## Critères de validation

- Restauration complète de la configuration YAML et des plugins.
- Absence d’erreur bloquante lors du redémarrage du FallbackManager.
- Traçabilité de toutes les opérations de rollback dans les logs Roo.
- Validation croisée par tests unitaires et revue humaine.

## Risques & mitigation

- **Perte de configuration** : sauvegarde automatique avant chaque modification.
- **Rollback partiel** : rapport détaillé, alerte via NotificationManager.
- **Plugin non versionné** : recommander la version automatique des plugins critiques.

## Liens croisés

- Schéma YAML Roo : [`fallback_schema.yaml`](fallback_schema.yaml)
- Implémentation Go : [`fallback_manager.go`](fallback_manager.go)
- Rapport d’audit : [`fallback_manager_report.md`](fallback_manager_report.md)
- Tests unitaires : [`fallback_manager_test.go`](fallback_manager_test.go)
- Documentation centrale : [README.md](../../README.md), [AGENTS.md](../../AGENTS.md)

---