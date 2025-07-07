# Guide technique d’intégration MCPManager & GCP MCP

## 1. Introduction

Ce guide centralise la documentation, les logs, FAQ, captures, bonnes pratiques et scénarios de test liés à l’intégration du serveur GCP MCP avec MCPManager.

## 2. Installation & Configuration

- Prérequis : binaire MCP-Gateway v0.4.6, accès réseau, credentials GCP valides.
  > **Note de Dépréciation :** Le "MCP-Gateway v0.4.6" (binaire, port 5235) mentionné dans ce document est un composant plus ancien. Un nouveau `gateway-manager` (Go-natif, situé dans `development/managers/gateway-manager/`) est en cours de développement et est destiné à le remplacer pour l'orchestration des services backend. Ce guide conserve la référence historique pour le contexte de l'intégration MCPManager décrite.
- Installation : placer le binaire, configurer `proxy-mock-server.yaml` (port 5235).
- Démarrage :
  - `./mcp-gateway --config proxy-mock-server.yaml`
  - Vérification : `curl http://localhost:5235/health_check` (doit répondre OK)

## 3. Détection automatique & gestion des serveurs

- Ajout/suppression de serveurs via MCPManager.
- Détection automatique documentée (voir logs/scénarios ci-dessous).

## 4. Pilotage (start/stop/restart) & gestion des erreurs

- Commandes de gestion centralisées dans MCPManager.
- Robustesse testée (voir logs/scénarios).
- Gestion des erreurs : logs détaillés dans `logs/mcp/`, FAQ ci-dessous.

## 5. Logs & centralisation

- Tous les logs, captures et scénarios de test sont archivés dans `logs/mcp/`.
- Exemples de logs : démarrage, arrêt, erreurs, accès API Google.

## 6. FAQ & dépannage

- **Q : Le serveur ne démarre pas ?**
  - Vérifier le port (5235), la config, les droits d’exécution.
- **Q : L’endpoint /health_check ne répond pas ?**
  - Vérifier que le binaire tourne, que le port n’est pas bloqué.
- **Q : Problème d’accès API Google ?**
  - Vérifier les credentials, les droits IAM, la connectivité réseau.
- **Q : Où trouver les logs détaillés ?**
  - Dans `logs/mcp/`.
- **Q : Comment ajouter un nouveau serveur ?**
  - Suivre la procédure d’ajout dans MCPManager, adapter la config si besoin.

## 7. Bonnes pratiques

- Centraliser tous les logs et scénarios de test.
- Documenter chaque évolution ou incident dans ce guide.
- Réaliser des tests multi-OS à chaque release.
- Automatiser l’archivage des logs/scénarios.
- Effectuer un audit sécurité/RGPD à chaque évolution majeure.

## 8. Scénarios de test

- Test de bout en bout : client → proxy → MCPManager → GCP MCP → API Google.
- Vérification de la cohérence, sécurité, conformité.
- Accès à la console Google via MCP validé.
- Logs, captures et checklist sécurité archivés.

## 9. Procédures de validation

- Checklist de validation globale (voir plan-dev-v31-integration-gcp-mcp.md).
- Archivage des résultats de test et logs.
- Mise à jour continue de la FAQ et des procédures.

## 10. Limitations & points de vigilance

- Tests multi-OS à poursuivre.
- FAQ/dépannage à enrichir.
- Documentation multi-serveurs à compléter si besoin.
- Optimisation de l’archivage automatique des logs/scénarios.
- Audit sécurité/RGPD à chaque évolution.

---

*Guide à jour au 2025-05-23. Voir le plan de développement pour l’état d’avancement global.*
