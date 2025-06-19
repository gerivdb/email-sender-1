# 🚀 Guide de Déploiement Production - Infrastructure Hybride N8N/Go

## 1. Prérequis

- **Go** ≥ 1.20
- **Node.js** ≥ 18.x
- **N8N** ≥ 1.20 (self-hosted recommandé)
- **Docker** (optionnel, recommandé)
- **Redis** (optionnel, pour cache distribué)
- **Outils sécurité** : nmap, nikto, ZAP (optionnel)

## 2. Structure des Fichiers

```
.
├── cli.exe / api-server.exe         # Binaires Go
├── n8n-custom-nodes/GoCliExecutor.node.ts
├── pkg/bridge/parameter_bridge.go
├── pkg/queue/async_queue_system.go
├── pkg/managers/n8n_manager_simple.go
├── tests/
├── docs/
└── docker-compose.yml (optionnel)
```

## 3. Déploiement Go CLI/API

### 3.1 Compilation

```bash
go build -o cli.exe ./cmd/cli
go build -o api-server.exe ./cmd/api-server
```

### 3.2 Lancement

```bash
./cli.exe --help
./api-server.exe --config config.yaml
```

## 4. Déploiement Node N8N Custom

### 4.1 Copier le fichier

- Copier `n8n-custom-nodes/GoCliExecutor.node.ts` dans le dossier custom nodes de votre instance N8N.

### 4.2 Redémarrer N8N

```bash
n8n stop
n8n start
```

ou via Docker :

```bash
docker restart n8n
```

### 4.3 Vérifier l’apparition du node “Go CLI Executor” dans l’UI N8N

## 5. Configuration Manager & Queue

- Modifier `pkg/managers/N8NManagerConfig` et `pkg/queue/QueueConfig` selon vos besoins.
- Exemple : voir `docs/TECHNICAL_DOCUMENTATION.md` section “Configuration Exemple”.

## 6. Lancement des Tests

```bash
go test ./tests/integration/...
go test ./tests/performance/...
bash tests/compatibility/cross_platform_compat_test.sh
bash tests/security/security_scan.sh
```

## 7. Monitoring & Logs

- Accéder aux métriques via `/api/v1/metrics` (Go) ou `/rest/metrics` (N8N)
- Logs : `/api/v1/logs`, `/rest/logs`
- Dashboard Prometheus/Grafana possible via export `/metrics`

## 8. Sécurité

- Scanner régulièrement avec ZAP, Nikto, nmap
- Vérifier headers HTTP, authentification, audit logs

## 9. Mise à l’échelle (Scaling)

- Augmenter `queue_workers`, `max_concurrency`, utiliser Redis pour cache distribué
- Déployer plusieurs instances Go API/CLI derrière un load balancer

## 10. Dépannage

- **Node N8N non visible** : vérifier le chemin du fichier et redémarrer N8N
- **Jobs bloqués** : augmenter workers ou queue_capacity
- **Timeouts** : ajuster `job_timeout`, `default_timeout`
- **Logs manquants** : vérifier `log_level` et permissions fichiers

---

**Contact déploiement** : <devops@votre-entreprise.com>  
**Dernière mise à jour** : 2025-06-19
