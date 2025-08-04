# Fiche technique atomique Roo — MonitoringManager (v113b)

---

## 1. API REST/GraphQL exposée

### 1.1 Endpoints REST

- `GET /api/monitoring/metrics`
  - **Description** : Récupère les métriques système et applicatives courantes.
  - **Réponse** :  
    ```json
    {
      "timestamp": "2025-08-03T23:48:00Z",
      "metrics": { "cpu": 0.12, "mem": 512, "latency_ms": 15, ... }
    }
    ```
  - **Codes** : 200 (OK), 500 (Erreur interne)

- `POST /api/monitoring/alerts`
  - **Description** : Configure une alerte personnalisée.
  - **Payload** :  
    ```json
    {
      "type": "latency",
      "threshold": 100,
      "action": "notify"
    }
    ```
  - **Réponse** : 201 (Créé), 400 (Erreur de validation), 500

- `GET /api/monitoring/history?duration=24h`
  - **Description** : Récupère l’historique des métriques sur la période.
  - **Réponse** :  
    ```json
    {
      "history": [
        { "timestamp": "...", "metrics": { ... } },
        ...
      ]
    }
    ```
  - **Codes** : 200, 400, 500

- `POST /api/monitoring/report`
  - **Description** : Génère un rapport de performance sur une période.
  - **Payload** :  
    ```json
    { "duration": "24h" }
    ```
  - **Réponse** :  
    ```json
    { "report_url": "/reports/perf_20250803.md" }
    ```
  - **Codes** : 201, 400, 500

### 1.2 Contrats d’interface JSON Schema

- **metrics** :
    ```json
    {
      "type": "object",
      "properties": {
        "cpu": { "type": "number" },
        "mem": { "type": "number" },
        "latency_ms": { "type": "number" },
        "throughput": { "type": "number" }
      },
      "required": ["cpu", "mem", "latency_ms", "throughput"]
    }
    ```
- **alertConfig** :
    ```json
    {
      "type": "object",
      "properties": {
        "type": { "type": "string", "enum": ["latency", "cpu", "mem", "custom"] },
        "threshold": { "type": "number" },
        "action": { "type": "string", "enum": ["notify", "scale", "log"] }
      },
      "required": ["type", "threshold", "action"]
    }
    ```

---

## 2. Matrice de dépendances inter-modulaires

| Module                | Dépend de                | Exposé à                | Type de dépendance         |
|-----------------------|-------------------------|-------------------------|----------------------------|
| MonitoringManager     | PluginInterface, ErrorManager, NotificationManager, AlertManager | API REST, CI/CD, DocManager | Extension, gestion erreurs, alerting |
| PluginInterface       | -                       | MonitoringManager       | Extension dynamique        |
| ErrorManager          | -                       | MonitoringManager       | Centralisation erreurs     |
| NotificationManager   | -                       | MonitoringManager       | Alerting                   |
| AlertManager          | -                       | MonitoringManager       | Alerting                   |

---

## 3. Patterns architecturaux d’implémentation

- **Factory** : Génération dynamique de plugins de collecte/alerting.
    ```go
    func NewPlugin(name string) PluginInterface { ... }
    ```
- **Observer** : Plugins notifiés à chaque collecte ou alerte.
    ```go
    type PluginInterface interface {
      OnMetricCollected(metric SystemMetrics)
      OnAlertTriggered(alert AlertConfig)
    }
    ```
- **Strategy** : Sélection dynamique de la stratégie d’alerte (notify, scale, log).
    ```go
    func (m *MonitoringManager) ApplyAlertStrategy(a AlertConfig) { ... }
    ```
- **Command** : Exécution d’actions sur déclenchement d’alerte.
    ```go
    type AlertCommand interface {
      Execute(ctx context.Context, alert AlertConfig) error
    }
    ```

---

## 4. Seuils de performance quantifiés

- **Latence collecte métrique** : ≤ 20 ms/opération
- **Throughput collecte** : ≥ 1000 metrics/minute
- **Empreinte mémoire** : ≤ 50 Mo pour 24h d’historique
- **Détection alerte** : ≤ 100 ms entre seuil franchi et notification

---

## 5. Jeux de tests unitaires (Go)

- **Test collecte métrique**
    ```go
    func TestCollectMetrics(t *testing.T) {
      mm := &MonitoringManager{}
      metrics, err := mm.CollectMetrics(context.Background())
      assert.NoError(t, err)
      assert.Greater(t, metrics.CPU, 0)
    }
    ```
- **Test déclenchement alerte**
    ```go
    func TestAlertTrigger(t *testing.T) {
      mm := &MonitoringManager{}
      cfg := AlertConfig{Type: "latency", Threshold: 10, Action: "notify"}
      err := mm.ConfigureAlerts(context.Background(), &cfg)
      assert.NoError(t, err)
      // Simuler franchissement de seuil
      // ...
    }
    ```
- **Test plugin**
    ```go
    func TestRegisterPlugin(t *testing.T) {
      mm := &MonitoringManager{}
      plugin := &MockPlugin{}
      err := mm.RegisterPlugin(plugin)
      assert.NoError(t, err)
    }
    ```

---

## 6. Configuration d’environnement

- **Fichier** : `monitoring_schema.yaml`
- **Variables d’environnement** :
    - `MONITORING_ALERT_EMAIL`
    - `MONITORING_METRICS_INTERVAL` (ex : 10s)
    - `MONITORING_HISTORY_RETENTION` (ex : 7d)
- **Secrets** : accès NotificationManager, AlertManager

---

## 7. Points d’extension et hooks personnalisables

- **PluginInterface** : ajout à chaud de plugins Go
- **Hooks** :  
    - `OnMetricCollected`
    - `OnAlertTriggered`
    - `OnReportGenerated`
- **Extension YAML** : ajout de nouveaux types de métriques ou d’alertes via `monitoring_schema.yaml`

---

## 8. Monitoring et logging structurés

- **Format log** : JSON structuré, horodaté, niveau (info/warn/error)
    ```json
    { "ts": "2025-08-03T23:48:00Z", "level": "info", "event": "metric_collected", "cpu": 0.12, ... }
    ```
- **Alertes** : loggées et transmises à NotificationManager
- **Audit** : historique complet exportable (`GET /api/monitoring/history`)

---

## 9. Procédures de rollback et recovery

- **Rollback** :  
    - Restauration de la config précédente (`monitoring_schema.yaml.bak`)
    - Rollback des plugins à la version précédente
    - Suppression des alertes mal configurées
- **Recovery** :  
    - Redémarrage automatique du MonitoringManager en cas de crash
    - Notification d’incident à ErrorManager
    - Génération d’un rapport d’incident (`monitoring_manager_rollback.md`)

---

## 10. Traçabilité requirements fonctionnels et non-fonctionnels

- **Fonctionnels** :  
    - Collecte, reporting, alerting, extension, audit, rollback
- **Non-fonctionnels** :  
    - Performance, résilience, sécurité (secrets), traçabilité, CI/CD, documentation croisée

---

*Spécification technique Roo exhaustive, transposable en code Go natif, conforme à la stack Roo v113b.*
