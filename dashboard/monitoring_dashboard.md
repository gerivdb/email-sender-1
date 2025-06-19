# 📊 Monitoring Dashboard Real-Time - N8N/Go Infrastructure

## 1. Objectif

Fournir une vue temps réel sur :

- Statut des queues et workers
- Métriques de performance (latence, throughput, erreurs)
- Santé des instances Go/N8N (load balancer)
- Logs et événements récents

---

## 2. Architecture

```
[Go API/CLI] ←→ [Queue System] ←→ [Monitoring Dashboard] ←→ [N8N]
         ↑             ↑
   [Load Balancer]     |
         |             |
   [Redis/Cache]       |
```

---

## 3. Sources de Données

- **/api/v1/metrics** (Go API)
- **/api/v1/logs** (Go API)
- **/api/v1/events** (Go API)
- **/rest/metrics** (N8N)
- **/rest/logs** (N8N)
- **Redis** (optionnel, stats partagées)

---

## 4. KPIs Affichés

- **Jobs en attente / traités / échoués** (par queue)
- **Latence moyenne / max / min** (par job type)
- **Throughput** (jobs/sec)
- **Nombre de workers actifs / scaling**
- **Santé des instances (load balancer)**
- **Logs récents (erreurs, warnings, info)**
- **Alertes actives**

---

## 5. Exemple de Widgets

- **Queue Status** : Liste des queues, jobs en attente, workers actifs
- **Worker Pool** : Graphique scaling auto, charge par worker
- **Job Latency** : Histogramme des latences
- **Throughput** : Graphique jobs/sec
- **Instance Health** : Tableau des instances Go/N8N (status, latence, load)
- **Logs** : Liste temps réel des logs (filtrage par niveau/type)
- **Alerts** : Notifications en temps réel

---

## 6. Stack Technique Suggérée

- **Backend** : Go API (expose /metrics, /logs, /events)
- **Frontend** : Grafana, Kibana, ou dashboard custom React/Vue
- **Data Source** : Prometheus (scrape /metrics), ELK (logs), Redis (état partagé)
- **Alerting** : Prometheus Alertmanager, Grafana Alerts

---

## 7. Exemple de Dashboard Grafana

- **Datasource** : Prometheus (Go API), Loki (logs), Redis (statut)
- **Panels** :
  - Statut des queues (table)
  - Latence jobs (graph)
  - Throughput (graph)
  - Santé instances (table)
  - Logs récents (logs panel)
  - Alertes (alert list)

---

## 8. API REST pour Dashboard Custom

- **GET /api/v1/metrics** : KPIs temps réel
- **GET /api/v1/logs?level=error&limit=100** : Logs filtrés
- **GET /api/v1/events?type=alert** : Événements critiques
- **GET /api/v1/queue/status** : Statut détaillé des queues

---

## 9. Alertes & Notifications

- **Seuils configurables** (latence, erreurs, workers down)
- **Notifications** : Email, Slack, Teams, Webhook
- **Escalade automatique** (si non résolu)

---

## 10. Sécurité & Accès

- Authentification requise (API Key, JWT)
- Logs d’accès et audit
- Dashboard accessible uniquement en interne ou VPN

---

**Contact monitoring** : <devops@votre-entreprise.com>  
**Dernière mise à jour** : 2025-06-19
